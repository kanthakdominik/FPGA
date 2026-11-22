-- Konfiguracja nadajnika HDMI ADV7513 przez I2C (24.02): zapis tablicy rejestrów po resecie, na żądanie (start)
-- i cyklicznie co OKRES taktów. Wpis: START, adres 0x72, rejestr, wartość, STOP. NACK przerywa serię (blad).
-- Linie z otwartym drenem: scl_o / sda_o = '0' — ściągnij, '1' — zwolnij. Wartości: ADV7513 Programming Guide.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adv7513_konfig is
  generic (
    F_CLK : positive := 25000000;
    F_I2C : positive := 100000;
    OKRES : natural  := 25000000;              -- 0 — tylko po resecie i na start
    ADRES : std_logic_vector(6 downto 0) := "0111001"
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
end entity adv7513_konfig;

architecture rtl of adv7513_konfig is
  constant N  : positive := 17;
  constant DZ : positive := F_CLK / (4 * F_I2C);

  type tablica_t is array (0 to N - 1) of std_logic_vector(15 downto 0);
  constant TAB : tablica_t := (
    x"4110",                                     -- zasilanie włączone
    x"9803", x"9AE0", x"9C30", x"9D61", x"A2A4", x"A3A4", x"E0D0", x"F900",   -- rejestry stałe
    x"1500",                                     -- wejście 24-bit RGB 4:4:4, osobne HS/VS/DE
    x"1630",                                     -- wyjście 4:4:4, 8 bitów
    x"1700",                                     -- proporcje 4:3
    x"1846",                                     -- konwersja przestrzeni barw wyłączona
    x"AF16",                                     -- tryb HDMI, bez HDCP
    x"BA60",                                     -- bez opóźnienia zegara
    x"D6C0",                                     -- HPD zawsze aktywne
    x"96F6");                                    -- kasowanie przerwań

  type stan_t is (S_BEZCZ, S_START, S_BIT, S_STOP, S_PRZERWA);
  signal stan    : stan_t := S_BEZCZ;
  signal faza    : unsigned(1 downto 0) := "00";
  signal lt      : natural range 0 to DZ - 1 := 0;
  signal idx     : natural range 0 to N - 1 := 0;
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
        stan <= S_BEZCZ; faza <= "00"; lt <= 0; idx <= 0; b <= 0; ramka <= (others => '0'); lo <= 0;
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
                  wpis  := TAB(idx);
                  ramka <= ADRES & '0' & '1' & wpis(15 downto 8) & '1' & wpis(7 downto 0) & '1';
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
              if faza = "11" then
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
