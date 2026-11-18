-- Moduł nadrzędny DECA - VHDL. "Oddychające" diody z pamięci (moduł 18): rom_sinus (M9K) w domenie
-- 50 MHz daje jasność ośmiu diod przesuniętych w fazie o 1/8 okresu, ram_sdp z dwoma zegarami przenosi
-- tablicę jasności do domeny 10 MHz (ADC_CLK_10), gdzie działa PWM 8 bitów.
-- KEY(0) - reset, SW(0) w górze - animacja zatrzymana, SW(1) w górze - kierunek odwrócony.
-- Zawartość ROM w Quartusie: atrybut ram_init_file (sinus.mif) - Quartus nie czyta plików przez textio.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deca_top is
  port (
    MAX10_CLK1_50 : in  std_logic;
    ADC_CLK_10    : in  std_logic;
    KEY           : in  std_logic_vector(1 downto 0);
    SW            : in  std_logic_vector(1 downto 0);
    LED           : out std_logic_vector(7 downto 0)   -- '0' = świeci
  );
end entity deca_top;

architecture rtl of deca_top is
  type tab_t is array (0 to 7) of unsigned(7 downto 0);
  signal clk50, clk10   : std_logic;
  signal rs50, rs10     : std_logic_vector(1 downto 0) := "00";
  signal rst50, rst10   : std_logic;
  signal sw1, sw2       : std_logic_vector(1 downto 0) := "00";
  signal dzielnik       : unsigned(17 downto 0) := (others => '0');
  signal faza           : unsigned(7 downto 0) := (others => '0');
  signal idx, idx_d     : unsigned(2 downto 0) := (others => '0');
  signal adr_rom        : std_logic_vector(7 downto 0);
  signal jasnosc, jas_r : std_logic_vector(7 downto 0);
  signal we_tab         : std_logic;
  signal idx_r, idx_r_d : unsigned(2 downto 0) := (others => '0');
  signal tab            : tab_t;
  signal pwm            : unsigned(7 downto 0) := (others => '0');
  signal led_n          : std_logic_vector(7 downto 0) := (others => '1');

  attribute altera_attribute : string;
  attribute altera_attribute of sw1, sw2 : signal is "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS";
begin
  clk50 <= MAX10_CLK1_50;
  clk10 <= ADC_CLK_10;

  process (clk50, KEY(0))
  begin
    if KEY(0) = '0' then rs50 <= "00"; elsif rising_edge(clk50) then rs50 <= rs50(0) & '1'; end if;
  end process;
  process (clk10, KEY(0))
  begin
    if KEY(0) = '0' then rs10 <= "00"; elsif rising_edge(clk10) then rs10 <= rs10(0) & '1'; end if;
  end process;
  rst50 <= not rs50(1);
  rst10 <= not rs10(1);

  -- domena 50 MHz: faza animacji i adres ROM
  process (clk50)
  begin
    if rising_edge(clk50) then
      sw1 <= SW;
      sw2 <= sw1;
      if rst50 = '1' then
        dzielnik <= (others => '0');
        faza     <= (others => '0');
        idx      <= (others => '0');
        idx_d    <= (others => '0');
      else
        dzielnik <= dzielnik + 1;
        if dzielnik = 2 ** 18 - 1 and sw2(0) = '0' then
          if sw2(1) = '1' then faza <= faza - 1; else faza <= faza + 1; end if;
        end if;
        idx   <= idx + 1;
        idx_d <= idx;
      end if;
    end if;
  end process;
  adr_rom <= std_logic_vector(faza + (idx & "00000"));

  u_rom : entity work.rom_sinus
    generic map (W => 8, AW => 8, PLIK => "", PLIK_MIF => "../../hdl/dane/sinus.mif")
    port map (clk => clk50, en => '1', addr => adr_rom, dout => jasnosc);

  we_tab <= not rst50;
  u_tab : entity work.ram_sdp
    generic map (W => 8, AW => 3)
    port map (clk_w => clk50, we => we_tab, addr_w => std_logic_vector(idx_d), din => jasnosc,
              clk_r => clk10, re => '1', addr_r => std_logic_vector(idx_r), dout => jas_r);

  -- domena 10 MHz: odczyt tablicy i PWM
  process (clk10)
  begin
    if rising_edge(clk10) then
      if rst10 = '1' then
        idx_r   <= (others => '0');
        idx_r_d <= (others => '0');
        pwm     <= (others => '0');
        led_n   <= (others => '1');
      else
        idx_r   <= idx_r + 1;
        idx_r_d <= idx_r;
        tab(to_integer(idx_r_d)) <= unsigned(jas_r);
        if idx_r = 7 then
          pwm <= pwm + 1;
        end if;
        for i in 0 to 7 loop
          if pwm < tab(i) then led_n(i) <= '0'; else led_n(i) <= '1'; end if;
        end loop;
      end if;
    end if;
  end process;
  LED <= led_n;
end architecture rtl;
