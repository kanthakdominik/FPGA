-- Moduł nadrzędny DECA - VHDL. Projekt do uruchamiania i debugowania na sprzęcie (moduł 17):
--   LED(0..2) - bicie serca 1 Hz z trzech zegarów: MAX10_CLK1_50, PLL 100 MHz, ADC_CLK_10,
--   LED(3) - PLL zsynchronizowany, LED(4) - echo KEY(1), LED(5) - analizator uzbrojony,
--   LED(6) - analizator zakończył zapis, LED(7) - SW(0) w górze (diody świecą przy '0'),
--   pomiar_czestotliwosci - zegary 100 MHz i 10 MHz mierzone zegarem 50 MHz w oknie 1 ms,
--   mini_ila - 256 próbek po 16 bitów w domenie 100 MHz: {KEY(1), SW(1..0), licznik 13 bitów},
--   In-System Sources and Probes (JTAG): "ILA0" - sterowanie i odczyt analizatora, "FREQ" - pomiar,
--   GPIO0_D(0) - 25 MHz, GPIO0_D(1) - 1 MHz, GPIO0_D(2) - impuls wyzwolenia, GPIO0_D(3) - KEY(1) surowy.
-- Komponenty altpll i altsource_probe wiąże Quartus z biblioteką altera_mf.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deca_top is
  port (
    MAX10_CLK1_50 : in  std_logic;
    ADC_CLK_10    : in  std_logic;
    KEY           : in  std_logic_vector(1 downto 0);   -- '0' = wciśnięty
    SW            : in  std_logic_vector(1 downto 0);   -- '0' = w dół
    LED           : out std_logic_vector(7 downto 0);   -- '0' = świeci
    GPIO0_D       : out std_logic_vector(3 downto 0)
  );
end entity deca_top;

architecture rtl of deca_top is
  component altpll
    generic (
      intended_device_family : string;
      lpm_type               : string;
      operation_mode         : string;
      pll_type               : string;
      inclk0_input_frequency : natural;
      clk0_multiply_by       : natural;
      clk0_divide_by         : natural;
      clk0_duty_cycle        : natural;
      clk0_phase_shift       : string;
      compensate_clock       : string;
      width_clock            : natural
    );
    port (
      inclk  : in  std_logic_vector(1 downto 0);
      areset : in  std_logic;
      clk    : out std_logic_vector(4 downto 0);
      locked : out std_logic
    );
  end component;

  component altsource_probe
    generic (
      enable_metastability    : string;
      instance_id             : string;
      lpm_hint                : string;
      lpm_type                : string;
      probe_width             : natural;
      sld_auto_instance_index : string;
      sld_instance_index      : natural;
      source_initial_value    : string;
      source_width            : natural
    );
    port (
      probe      : in  std_logic_vector(probe_width - 1 downto 0);
      source     : out std_logic_vector(source_width - 1 downto 0);
      source_clk : in  std_logic;
      source_ena : in  std_logic
    );
  end component;

  signal clk50, clk10, clk100, locked : std_logic;
  signal pll_in   : std_logic_vector(1 downto 0);
  signal pll_clk  : std_logic_vector(4 downto 0);
  signal rst_n_async : std_logic;
  signal rs50, rs100, rs10 : std_logic_vector(1 downto 0) := "00";
  signal rst50, rst100, rst10 : std_logic;
  signal hb50, hb100, hb10 : std_logic;
  signal we_s1, we_s2 : std_logic_vector(2 downto 0) := "111";
  signal key1_n   : std_logic;
  signal sw_s     : std_logic_vector(1 downto 0);
  signal f100, f10 : std_logic_vector(23 downto 0);
  signal v100, v10 : std_logic;
  signal licznik  : unsigned(12 downto 0) := (others => '0');
  signal probe    : std_logic_vector(15 downto 0);
  signal ila_src  : std_logic_vector(49 downto 0);   -- arm, zbocze, pre, rd_addr, trig_val, trig_mask
  signal rd_data  : std_logic_vector(15 downto 0);
  signal armed, capturing, done, trig_out : std_logic;
  signal ila_probe  : std_logic_vector(18 downto 0);
  signal freq_probe : std_logic_vector(47 downto 0);
  signal freq_src_nc : std_logic_vector(0 downto 0);
  signal t25, t1  : std_logic := '0';
  signal dz1      : natural range 0 to 24 := 0;

  attribute altera_attribute : string;
  attribute altera_attribute of we_s1, we_s2 : signal is "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS";
begin
  clk50 <= MAX10_CLK1_50;
  clk10 <= ADC_CLK_10;

  -- PLL: 50 MHz -> 100 MHz
  u_pll : altpll
    generic map (
      intended_device_family => "MAX 10",
      lpm_type               => "altpll",
      operation_mode         => "NORMAL",
      pll_type               => "AUTO",
      inclk0_input_frequency => 20000,
      clk0_multiply_by       => 2,
      clk0_divide_by         => 1,
      clk0_duty_cycle        => 50,
      clk0_phase_shift       => "0",
      compensate_clock       => "CLK0",
      width_clock            => 5
    )
    port map (inclk => pll_in, areset => '0', clk => pll_clk, locked => locked);
  pll_in <= '0' & MAX10_CLK1_50;
  clk100 <= pll_clk(0);

  -- reset: KEY(0) albo brak synchronizacji PLL; osobny synchronizator w każdej domenie
  rst_n_async <= KEY(0) and locked;
  process (clk50, rst_n_async)
  begin
    if rst_n_async = '0' then rs50 <= "00"; elsif rising_edge(clk50) then rs50 <= rs50(0) & '1'; end if;
  end process;
  process (clk100, rst_n_async)
  begin
    if rst_n_async = '0' then rs100 <= "00"; elsif rising_edge(clk100) then rs100 <= rs100(0) & '1'; end if;
  end process;
  process (clk10, rst_n_async)
  begin
    if rst_n_async = '0' then rs10 <= "00"; elsif rising_edge(clk10) then rs10 <= rs10(0) & '1'; end if;
  end process;
  rst50  <= not rs50(1);
  rst100 <= not rs100(1);
  rst10  <= not rs10(1);

  -- bicie serca 1 Hz z trzech zegarów
  u_hb50  : entity work.bicie_serca generic map (POLOKRES => 25_000_000) port map (clk => clk50,  rst => rst50,  led => hb50);
  u_hb100 : entity work.bicie_serca generic map (POLOKRES => 50_000_000) port map (clk => clk100, rst => rst100, led => hb100);
  u_hb10  : entity work.bicie_serca generic map (POLOKRES => 5_000_000)  port map (clk => clk10,  rst => rst10,  led => hb10);

  -- wejścia zsynchronizowane z domeną 100 MHz, badany sygnał
  process (clk100)
  begin
    if rising_edge(clk100) then
      we_s1   <= KEY(1) & SW;
      we_s2   <= we_s1;
      licznik <= licznik + 1;
    end if;
  end process;
  key1_n <= we_s2(2);
  sw_s   <= we_s2(1 downto 0);
  probe  <= (not key1_n) & sw_s & std_logic_vector(licznik);

  -- pomiar częstotliwości (okno 50000 taktów 50 MHz = 1 ms)
  u_f100 : entity work.pomiar_czestotliwosci generic map (CW => 24, BRAMKA => 50000)
    port map (clk_ref => clk50, rst => rst50, clk_mier => clk100, wynik => f100, wynik_valid => v100);
  u_f10 : entity work.pomiar_czestotliwosci generic map (CW => 24, BRAMKA => 50000)
    port map (clk_ref => clk50, rst => rst50, clk_mier => clk10, wynik => f10, wynik_valid => v10);

  -- analizator
  u_ila : entity work.mini_ila
    generic map (W => 16, AW => 8)
    port map (clk => clk100, rst => rst100, probe => probe,
              arm => ila_src(49), trig_zbocze => ila_src(48), pre => ila_src(47 downto 40),
              rd_addr => ila_src(39 downto 32), trig_val => ila_src(31 downto 16), trig_mask => ila_src(15 downto 0),
              rd_data => rd_data, armed => armed, capturing => capturing, done => done, trig_out => trig_out);

  -- In-System Sources and Probes (JTAG)
  ila_probe  <= armed & capturing & done & rd_data;
  freq_probe <= f10 & f100;
  u_issp_ila : altsource_probe
    generic map (enable_metastability => "YES", instance_id => "ILA0", lpm_hint => "UNUSED",
                 lpm_type => "altsource_probe", probe_width => 19, sld_auto_instance_index => "YES",
                 sld_instance_index => 0, source_initial_value => "0", source_width => 50)
    port map (probe => ila_probe, source => ila_src, source_clk => clk100, source_ena => '1');
  u_issp_freq : altsource_probe
    generic map (enable_metastability => "NO", instance_id => "FREQ", lpm_hint => "UNUSED",
                 lpm_type => "altsource_probe", probe_width => 48, sld_auto_instance_index => "YES",
                 sld_instance_index => 1, source_initial_value => "0", source_width => 1)
    port map (probe => freq_probe, source => freq_src_nc, source_clk => clk50, source_ena => '1');

  -- wyjścia na złącze P8 (pomiary oscyloskopem)
  process (clk50)
  begin
    if rising_edge(clk50) then
      t25 <= not t25;
      if dz1 = 24 then
        dz1 <= 0;
        t1  <= not t1;
      else
        dz1 <= dz1 + 1;
      end if;
    end if;
  end process;
  GPIO0_D <= KEY(1) & trig_out & t1 & t25;

  -- diody ('0' = świeci)
  LED <= not (sw_s(0) & done & armed & (not key1_n) & locked & hb10 & hb100 & hb50);
end architecture rtl;
