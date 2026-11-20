-- Moduł nadrzędny DECA - VHDL. PWM z czasem martwym, serwomechanizm i enkoder (20.04):
--   GPIO0_D(2), GPIO0_D(3) - wyjścia górne i dolne gałęzi mostka (PWM 25 kHz, czas martwy 400 ns),
--   GPIO0_D(4) - sygnał serwa (50 Hz, 1-2 ms), GPIO0_D(5), GPIO0_D(6) - wejścia A, B enkodera
--   (z podciąganiem w układzie; styk enkodera zwiera do masy).
-- Nastawa (0...255): SW(0) = 0 - pozycja enkodera, SW(0) = 1 - automatyczny przebieg trójkątny (bez enkodera).
-- Nastawa steruje wypełnieniem PWM i pozycją serwa. LED(7) - wyjście górne PWM (jasność = wypełnienie),
-- LED(6 downto 0) - nastawa (7 starszych bitów); SW(1) = 1 - licznik błędów enkodera. KEY(0) - reset.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deca_top is
  port (
    MAX10_CLK1_50 : in    std_logic;
    KEY           : in    std_logic_vector(1 downto 0);
    SW            : in    std_logic_vector(1 downto 0);
    LED           : out   std_logic_vector(7 downto 0);   -- '0' = świeci
    GPIO0_D       : inout std_logic_vector(6 downto 2)
  );
end entity deca_top;

architecture rtl of deca_top is
  signal clk, rst   : std_logic;
  signal rs, s_sw   : std_logic_vector(1 downto 0) := "00";
  signal pozycja    : std_logic_vector(15 downto 0);
  signal bledy      : std_logic_vector(7 downto 0);
  signal wolny      : unsigned(22 downto 0) := (others => '0');
  signal trojkat    : unsigned(7 downto 0) := (others => '0');
  signal w_gore     : std_logic := '1';
  signal z_enk, nastawa : std_logic_vector(7 downto 0);
  signal gora, dol, impuls : std_logic;
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
      s_sw <= SW;
    end if;
  end process;

  -- ---- enkoder (filtr 250 taktów = 5 µs)
  u_enk : entity work.enkoder generic map (W => 16, FILTR => 250)
    port map (clk => clk, rst => rst, a => GPIO0_D(5), b => GPIO0_D(6), pozycja => pozycja, kierunek => open,
              bledy => bledy);
  GPIO0_D(5) <= 'Z';
  GPIO0_D(6) <= 'Z';

  -- ---- przebieg trójkątny (pełny cykl ok. 2,7 s)
  process (clk)
  begin
    if rising_edge(clk) then
      wolny <= wolny + 1;
      if wolny = 0 then
        if w_gore = '1' then
          if trojkat = 254 then w_gore <= '0'; end if;
          trojkat <= trojkat + 1;
        else
          if trojkat = 1 then w_gore <= '1'; end if;
          trojkat <= trojkat - 1;
        end if;
      end if;
    end if;
  end process;

  -- pozycja enkodera x4 na krok - nastawa = pozycja / 4, ograniczona do 0...255
  z_enk <= x"00" when pozycja(15) = '1' else
           x"FF" when unsigned(pozycja(15 downto 2)) > 255 else
           pozycja(9 downto 2);
  nastawa <= std_logic_vector(trojkat) when s_sw(0) = '1' else z_enk;

  -- ---- PWM: 50 MHz / (2*1000) = 25 kHz, czas martwy 20 taktów = 400 ns; wyp = 4*nastawa (powyżej 1000 = 100 %)
  u_pwm : entity work.pwm_mostek generic map (W => 10, OKRES => 1000, MARTWY => 20)
    port map (clk => clk, rst => rst, wyp => nastawa & "00", gora => gora, dol => dol, poczatek => open);
  GPIO0_D(2) <= gora;
  GPIO0_D(3) <= dol;

  -- ---- serwo
  u_serwo : entity work.serwo generic map (CLK_HZ => 50_000_000)
    port map (clk => clk, rst => rst, pozycja => nastawa, impuls => impuls);
  GPIO0_D(4) <= impuls;

  LED <= not (gora & bledy(6 downto 0)) when s_sw(1) = '1' else not (gora & nastawa(7 downto 1));
end architecture rtl;
