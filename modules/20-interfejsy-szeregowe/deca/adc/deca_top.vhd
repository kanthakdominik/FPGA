-- Moduł nadrzędny DECA - VHDL. Wbudowany przetwornik ADC MAX 10 (20.06):
--   rdzeń "Modular ADC Core" w konfiguracji "ADC Control Core Only" (adc_rdzen) i PLL zegara ADC (adc_pll),
--   oba generowane w Quartusie (README.md); sekwencer obiega kanał 1 (ADC1IN1, złącze P9) i termodiodę (17).
--   Uśrednianie po 64 próbkach. Logika i rdzeń pracują na zegarze 10 MHz z PLL.
-- Diody: SW(0) = '0' - linijka: liczba świecących diod ~ napięcie na ADC1IN1 (0...2,5 V),
--        SW(0) = '1' - temperatura układu FPGA w stopniach C (binarnie, z termodiody). KEY(0) - reset.
-- Deklaracje komponentów muszą zgadzać się z portami wygenerowanych rdzeni (README.md).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deca_top is
  port (
    ADC_CLK_10 : in  std_logic;
    KEY        : in  std_logic_vector(1 downto 0);
    SW         : in  std_logic_vector(1 downto 0);
    LED        : out std_logic_vector(7 downto 0)   -- '0' = świeci
  );
end entity deca_top;

architecture rtl of deca_top is
  component adc_pll
    port (
      inclk0 : in  std_logic;
      c0     : out std_logic;
      locked : out std_logic
    );
  end component;

  component adc_rdzen
    port (
      clock_clk              : in  std_logic;
      reset_sink_reset_n     : in  std_logic;
      adc_pll_clock_clk      : in  std_logic;
      adc_pll_locked_export  : in  std_logic;
      command_valid          : in  std_logic;
      command_channel        : in  std_logic_vector(4 downto 0);
      command_startofpacket  : in  std_logic;
      command_endofpacket    : in  std_logic;
      command_ready          : out std_logic;
      response_valid         : out std_logic;
      response_channel       : out std_logic_vector(4 downto 0);
      response_data          : out std_logic_vector(11 downto 0);
      response_startofpacket : out std_logic;
      response_endofpacket   : out std_logic
    );
  end component;

  signal clk, zablok, rst, rst_n : std_logic;
  signal rs, s_sw        : std_logic_vector(1 downto 0) := "00";
  signal c_valid, c_sop, c_eop, c_ready, r_valid, nowy : std_logic;
  signal c_kanal, r_kanal, kanal : std_logic_vector(4 downto 0);
  signal r_dane, dane, s1, s17 : std_logic_vector(11 downto 0);
  signal w1, w17         : std_logic;
  signal temp_c, linijka : std_logic_vector(7 downto 0);
  attribute altera_attribute : string;
  attribute altera_attribute of s_sw : signal is "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS";
begin
  -- reset trzymany do zablokowania PLL
  process (clk, KEY)
  begin
    if KEY(0) = '0' then
      rs <= "00";
    elsif rising_edge(clk) then
      rs <= (rs(0) and zablok) & zablok;
    end if;
  end process;
  rst   <= not rs(1);
  rst_n <= rs(1);

  process (clk)
  begin
    if rising_edge(clk) then
      s_sw <= SW;
    end if;
  end process;

  -- ---- rdzenie
  u_pll : adc_pll port map (inclk0 => ADC_CLK_10, c0 => clk, locked => zablok);
  u_adc : adc_rdzen
    port map (
      clock_clk              => clk,
      reset_sink_reset_n     => rst_n,
      adc_pll_clock_clk      => clk,
      adc_pll_locked_export  => zablok,
      command_valid          => c_valid,
      command_channel        => c_kanal,
      command_startofpacket  => c_sop,
      command_endofpacket    => c_eop,
      command_ready          => c_ready,
      response_valid         => r_valid,
      response_channel       => r_kanal,
      response_data          => r_dane,
      response_startofpacket => open,
      response_endofpacket   => open
    );

  -- ---- sekwencer (kanały 1 i 17), uśrednianie, termodioda
  u_sekw : entity work.adc_sekwencer
    generic map (LICZBA => 2, KANALY => std_logic_vector(to_unsigned(17 * 32 + 1, 40)))
    port map (clk => clk, rst => rst, wlacz => '1', command_valid => c_valid, command_channel => c_kanal,
              command_startofpacket => c_sop, command_endofpacket => c_eop, command_ready => c_ready,
              response_valid => r_valid, response_channel => r_kanal, response_data => r_dane, wyniki => open,
              nowy => nowy, kanal => kanal, dane => dane);

  w1  <= '1' when nowy = '1' and kanal = "00001" else '0';
  w17 <= '1' when nowy = '1' and kanal = "10001" else '0';
  u_s1 : entity work.adc_srednia generic map (W => 12, K => 6)
    port map (clk => clk, rst => rst, wazne => w1, dane => dane, wyj_wazne => open, srednia => s1);
  u_s17 : entity work.adc_srednia generic map (W => 12, K => 6)
    port map (clk => clk, rst => rst, wazne => w17, dane => dane, wyj_wazne => open, srednia => s17);

  u_tsd : entity work.tsd_temperatura port map (clk => clk, kod => s17, temp_c => temp_c);

  -- linijka: 0...8 diod dla 0...4095 (zaokrąglenie: 4095 -> 8 diod)
  process (s1)
    variable ile : natural range 0 to 8;
  begin
    ile := to_integer((resize(unsigned(s1), 13) + 255) / 512);
    linijka <= (others => '0');
    for i in 0 to 7 loop
      if i < ile then linijka(i) <= '1'; end if;
    end loop;
  end process;

  LED <= not temp_c when s_sw(0) = '1' else not linijka;
end architecture rtl;
