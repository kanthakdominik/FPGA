-- Zapis tablicy rejestrów przez I2C (25.01): uogólnienie adv7513_konfig z 24.02 — tablica jako generyk TAB
-- (N wpisów po 16 bitów {rejestr, wartość}, wpis 0 w najstarszych bitach), adres ADRES. Seria po resecie, na
-- żądanie (start) i co OKRES taktów (0 — wyłączone); NACK przerywa serię (blad). Wpis 0xFF n — przerwa n·1024
-- ćwiartek okresu SCL. Linie z otwartym drenem: scl_o / sda_o = '0' — ściągnij.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_zapisy is
  generic (
    F_CLK : positive := 25000000;
    F_I2C : positive := 100000;
    OKRES : natural  := 0;                     -- 0 — tylko po resecie i na start
    ADRES : std_logic_vector(6 downto 0) := "0011000";
    N     : positive := 2;
    TAB   : std_logic_vector := x"00000101"     -- długość 16·N
  );
  port (
    clk    : in  std_logic;
    rst    : in  std_logic;
    start  : in  std_logic;
    zajety : out std_logic := '0';
    gotowe : out std_logic := '0';
    blad   : out std_logic := '0';
    scl_o  : out std_logic := '1';
    sda_o  : out std_logic := '1';
    sda_i  : in  std_logic
  );
end entity i2c_zapisy;

architecture rtl of i2c_zapisy is
  constant DZ : positive := F_CLK / (4 * F_I2C);
  constant TB : std_logic_vector(16 * N - 1 downto 0) := TAB;

  type stan_t is (S_BEZCZ, S_START, S_BIT, S_STOP, S_PRZERWA);
  signal stan    : stan_t := S_BEZCZ;
  signal faza    : unsigned(1 downto 0) := "00";
  signal lt      : natural range 0 to DZ - 1 := 0;
  signal idx     : natural range 0 to N - 1 := 0;
  signal pz      : natural range 0 to 262143 := 0;
  signal b       : natural range 0 to 26 := 0;
  signal ramka   : std_logic_vector(26 downto 0) := (others => '0');
  signal lo      : natural := 0;
  signal nack    : std_logic := '0';
  signal start_w : std_logic := '1';
begin
  process (clk)
    variable wpis : std_logic_vector(15 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        stan <= S_BEZCZ; faza <= "00"; lt <= 0; idx <= 0; pz <= 0; b <= 0; ramka <= (others => '0'); lo <= 0;
        nack <= '0'; start_w <= '1'; zajety <= '0'; gotowe <= '0'; blad <= '0'; scl_o <= '1'; sda_o <= '1';
      else
        if start = '1' then start_w <= '1'; end if;
        if OKRES > 0 and stan = S_BEZCZ then
          if lo >= OKRES - 1 then lo <= 0; start_w <= '1'; else lo <= lo + 1; end if;
        end if;
        if lt = 0 then
          lt   <= DZ - 1;
          faza <= faza + 1;
          case stan is
            when S_BEZCZ =>
              faza <= "00";
              if start_w = '1' then
                start_w <= '0'; zajety <= '1'; idx <= 0; nack <= '0'; stan <= S_START;
              end if;
            when S_START =>                                       -- SDA opada przy SCL = 1
              case faza is
                when "00" =>
                  sda_o <= '1'; scl_o <= '1';
                  wpis  := TB(16 * (N - idx) - 1 downto 16 * (N - 1 - idx));
                  ramka <= ADRES & '0' & '1' & wpis(15 downto 8) & '1' & wpis(7 downto 0) & '1';
                  if wpis(15 downto 8) = x"FF" then                -- wpis-przerwa: bez transakcji
                    pz   <= to_integer(unsigned(wpis(7 downto 0))) * 1024;
                    faza <= "00";
                    stan <= S_PRZERWA;
                  end if;
                when "01"   => sda_o <= '0';
                when "10"   => null;                              -- t_HD;STA ≥ 4 µs
                when others => scl_o <= '0'; b <= 26; stan <= S_BIT;
              end case;
            when S_BIT =>
              case faza is
                when "00"   => sda_o <= ramka(b);                 -- zmiana danych przy SCL = 0
                when "01"   => scl_o <= '1';
                when "10"   =>
                  if (b = 18 or b = 9 or b = 0) and sda_i = '1' then nack <= '1'; end if;
                when others =>
                  scl_o <= '0';
                  if b = 0 then stan <= S_STOP; else b <= b - 1; end if;
              end case;
            when S_STOP =>                                        -- SDA rośnie przy SCL = 1
              case faza is
                when "00"   => sda_o <= '0';
                when "01"   => scl_o <= '1';
                when "10"   => null;                              -- t_SU;STO ≥ 4 µs
                when others => sda_o <= '1'; stan <= S_PRZERWA;
              end case;
            when S_PRZERWA =>                                     -- czas wolnej magistrali
              if pz /= 0 then
                pz   <= pz - 1;
                faza <= "00";
              elsif faza = "11" then
                if nack = '1' or idx = N - 1 then
                  zajety <= '0'; gotowe <= not nack; blad <= nack; stan <= S_BEZCZ;
                else
                  idx <= idx + 1; stan <= S_START;
                end if;
              end if;
          end case;
        else
          lt <= lt - 1;
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
