-- Moduł nadrzędny DECA - VHDL. Pamięć QSPI flash (23.03), tylko odczyt: ID JEDEC, 16 bajtów od adresu 0
-- rozkazem 0x03 (1-1-1) i 0x6B (1-1-4), porównanie. Diody jak w deca_top.v. KEY(1) - powtórzenie, KEY(0) - reset.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deca_top is
  port (
    MAX10_CLK1_50 : in    std_logic;
    KEY           : in    std_logic_vector(1 downto 0);
    SW            : in    std_logic_vector(1 downto 0);
    LED           : out   std_logic_vector(7 downto 0);   -- '0' = świeci
    FLASH_DCLK    : out   std_logic;
    FLASH_NCSO    : out   std_logic;
    FLASH_RESET_n : out   std_logic;
    FLASH_DATA    : inout std_logic_vector(3 downto 0)
  );
end entity deca_top;

architecture rtl of deca_top is
  type id_t is array (0 to 2) of std_logic_vector(7 downto 0);
  signal clk, rst, nacisk, rwazne, gotowy, wpobierz : std_logic;
  signal rs : std_logic_vector(1 downto 0) := "00";
  signal s_sw : std_logic_vector(1 downto 0) := "00";
  signal s_k : std_logic_vector(1 downto 0) := "11";
  signal k_pop : std_logic := '1';
  signal start, z_adresem, quad, zgodne, koniec : std_logic := '0';
  signal rozkaz, rdane, pokaz : std_logic_vector(7 downto 0) := x"00";
  signal puste : std_logic_vector(3 downto 0) := "0000";
  signal dlugosc : std_logic_vector(8 downto 0) := (others => '0');
  signal dq_o, dq_oe : std_logic_vector(3 downto 0);
  signal id : id_t := (others => x"00");
  signal a, b : std_logic_vector(127 downto 0) := (others => '0');
  signal n : natural range 0 to 3 := 0;
  signal krok : natural range 0 to 6 := 0;
  attribute altera_attribute : string;
  attribute altera_attribute of s_sw : signal is "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS";
begin
  clk <= MAX10_CLK1_50;
  process (clk, KEY)
  begin
    if KEY(0) = '0' then
      rs <= "00";
    elsif rising_edge(clk) then
      rs <= rs(0) & '1';
    end if;
  end process;
  rst <= not rs(1);

  process (clk)
  begin
    if rising_edge(clk) then
      s_sw  <= SW;
      s_k   <= s_k(0) & KEY(1);
      k_pop <= s_k(1);
    end if;
  end process;
  nacisk <= k_pop and not s_k(1);

  u_qspi : entity work.qspi_master generic map (DIV => 2)
    port map (clk => clk, rst => rst, start => start, rozkaz => rozkaz, adres => x"000000", z_adresem => z_adresem,
              puste => puste, dlugosc => dlugosc, zapis => '0', quad => quad, wdane => x"00", wpobierz => wpobierz,
              rdane => rdane, rwazne => rwazne, gotowy => gotowy, sclk => FLASH_DCLK, cs_n => FLASH_NCSO,
              dq_o => dq_o, dq_oe => dq_oe, dq_i => FLASH_DATA);
  g_dq : for i in 0 to 3 generate
    FLASH_DATA(i) <= dq_o(i) when dq_oe(i) = '1' else 'Z';
  end generate;
  FLASH_RESET_n <= '1';

  process (clk)
  begin
    if rising_edge(clk) then
      start <= '0';
      if rst = '1' or nacisk = '1' then
        krok   <= 0;
        koniec <= '0';
      else
        case krok is
          when 0 =>
            if gotowy = '1' then
              rozkaz <= x"9F"; z_adresem <= '0'; puste <= "0000"; dlugosc <= std_logic_vector(to_unsigned(3, 9));
              quad <= '0'; start <= '1'; n <= 0; krok <= 1;
            end if;
          when 1 =>
            if rwazne = '1' then id(n) <= rdane; n <= (n + 1) mod 4;
            elsif gotowy = '1' and start = '0' then krok <= 2; end if;
          when 2 =>
            rozkaz <= x"03"; z_adresem <= '1'; puste <= "0000"; dlugosc <= std_logic_vector(to_unsigned(16, 9));
            quad <= '0'; start <= '1'; krok <= 3;
          when 3 =>
            if rwazne = '1' then a <= a(119 downto 0) & rdane;
            elsif gotowy = '1' and start = '0' then krok <= 4; end if;
          when 4 =>
            rozkaz <= x"6B"; z_adresem <= '1'; puste <= "1000"; dlugosc <= std_logic_vector(to_unsigned(16, 9));
            quad <= '1'; start <= '1'; krok <= 5;
          when 5 =>
            if rwazne = '1' then b <= b(119 downto 0) & rdane;
            elsif gotowy = '1' and start = '0' then
              zgodne <= '1' when a = b else '0';
              koniec <= '1';
              krok   <= 6;
            end if;
          when others => null;
        end case;
      end if;
    end if;
  end process;

  with s_sw select pokaz <=
    id(0) when "00",
    id(1) when "01",
    id(2) when "10",
    zgodne & koniec & "00" & a(123 downto 120) when others;
  LED <= not pokaz;
end architecture rtl;
