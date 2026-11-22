-- DECA — projekt 2 (31.02), VHDL: oscyloskop na ADC MAX 10 z obrazem przez HDMI. Opis sterowania jak w
-- deca_top.v. Komponenty altpll, altddio_out (altera_mf) oraz adc_pll i adc_rdzen (rdzenie z README.md) wiąże
-- Quartus; w GHDL pozostają niepowiązane.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deca_top is
  port (
    MAX10_CLK1_50 : in    std_logic;
    ADC_CLK_10    : in    std_logic;
    KEY           : in    std_logic_vector(1 downto 0);
    SW            : in    std_logic_vector(1 downto 0);
    LED           : out   std_logic_vector(7 downto 0);
    HDMI_TX_D     : out   std_logic_vector(23 downto 0) := (others => '0');
    HDMI_TX_CLK   : out   std_logic;
    HDMI_TX_DE    : out   std_logic := '0';
    HDMI_TX_HS    : out   std_logic := '0';
    HDMI_TX_VS    : out   std_logic := '0';
    HDMI_TX_INT   : in    std_logic;
    HDMI_I2C_SCL  : inout std_logic;
    HDMI_I2C_SDA  : inout std_logic;
    HDMI_MCLK     : inout std_logic;
    HDMI_LRCLK    : inout std_logic;
    HDMI_SCLK     : inout std_logic;
    HDMI_I2S      : inout std_logic_vector(3 downto 0)
  );
end entity deca_top;

architecture rtl of deca_top is
  component altpll
    generic (
      intended_device_family : string; lpm_type : string; operation_mode : string; pll_type : string;
      inclk0_input_frequency : natural; clk0_multiply_by : natural; clk0_divide_by : natural;
      clk0_duty_cycle : natural; clk0_phase_shift : string; compensate_clock : string; width_clock : natural
    );
    port (
      inclk  : in  std_logic_vector(1 downto 0);
      areset : in  std_logic;
      clk    : out std_logic_vector(4 downto 0);
      locked : out std_logic
    );
  end component;
  component altddio_out
    generic (width : natural; intended_device_family : string);
    port (
      datain_h : in  std_logic_vector(width - 1 downto 0);
      datain_l : in  std_logic_vector(width - 1 downto 0);
      outclock : in  std_logic;
      dataout  : out std_logic_vector(width - 1 downto 0)
    );
  end component;
  component adc_pll
    port (inclk0 : in std_logic; c0 : out std_logic; locked : out std_logic);
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

  signal pll_in : std_logic_vector(1 downto 0);
  signal pll_clk : std_logic_vector(4 downto 0);
  signal zeg : std_logic_vector(0 downto 0);
  signal clk_v, v_locked, clk_a, a_locked, rst_v, rst_a, rst_an : std_logic;
  signal rs_v, rs_a : std_logic_vector(1 downto 0) := "00";
  signal s_sw1, s_sw2 : std_logic_vector(1 downto 0) := "00";
  signal licz_ms : natural range 0 to 9999 := 0;
  signal k1 : std_logic_vector(1 downto 0) := "11";
  signal poz_nr : natural range 0 to 2 := 1;
  signal poziom : std_logic_vector(11 downto 0);
  signal dziel : unsigned(7 downto 0);
  signal c_valid, c_sop, c_eop, c_ready, r_valid, nowy : std_logic;
  signal c_kanal, r_kanal : std_logic_vector(4 downto 0);
  signal r_dane, dane : std_logic_vector(11 downto 0);
  signal rgb : std_logic_vector(23 downto 0);
  signal hs, vs, de, wyzw : std_logic;
  signal nr_zrzutu : unsigned(15 downto 0);
  signal scl_o, sda_o, gotowe, blad : std_logic;
  signal s_wyz : std_logic_vector(1 downto 0) := "00";
begin
  -- ---- zegary i rdzenie
  u_pll : altpll
    generic map (
      intended_device_family => "MAX 10", lpm_type => "altpll", operation_mode => "NORMAL", pll_type => "AUTO",
      inclk0_input_frequency => 20000, clk0_multiply_by => 1, clk0_divide_by => 2, clk0_duty_cycle => 50,
      clk0_phase_shift => "0", compensate_clock => "CLK0", width_clock => 5)
    port map (inclk => pll_in, areset => '0', clk => pll_clk, locked => v_locked);
  pll_in <= '0' & MAX10_CLK1_50;
  clk_v  <= pll_clk(0);
  u_zeg : altddio_out generic map (width => 1, intended_device_family => "MAX 10")
    port map (datain_h => "0", datain_l => "1", outclock => clk_v, dataout => zeg);
  HDMI_TX_CLK <= zeg(0);
  HDMI_MCLK <= 'Z'; HDMI_LRCLK <= 'Z'; HDMI_SCLK <= 'Z'; HDMI_I2S <= (others => 'Z');
  u_apll : adc_pll port map (inclk0 => ADC_CLK_10, c0 => clk_a, locked => a_locked);
  u_adc : adc_rdzen
    port map (clock_clk => clk_a, reset_sink_reset_n => rst_an, adc_pll_clock_clk => clk_a,
              adc_pll_locked_export => a_locked, command_valid => c_valid, command_channel => c_kanal,
              command_startofpacket => c_sop, command_endofpacket => c_eop, command_ready => c_ready,
              response_valid => r_valid, response_channel => r_kanal, response_data => r_dane,
              response_startofpacket => open, response_endofpacket => open);

  -- ---- resety obu domen
  process (clk_v, KEY(0))
  begin
    if KEY(0) = '0' then rs_v <= "00"; elsif rising_edge(clk_v) then rs_v <= rs_v(0) & v_locked; end if;
  end process;
  process (clk_a, KEY(0))
  begin
    if KEY(0) = '0' then rs_a <= "00"; elsif rising_edge(clk_a) then rs_a <= rs_a(0) & a_locked; end if;
  end process;
  rst_v <= not rs_v(1);
  rst_a <= not rs_a(1);
  rst_an <= rs_a(1);

  -- ---- nastawy w domenie akwizycji
  process (clk_a)
  begin
    if rising_edge(clk_a) then
      s_sw1 <= SW; s_sw2 <= s_sw1;
      if licz_ms = 9999 then licz_ms <= 0; else licz_ms <= licz_ms + 1; end if;
      if licz_ms = 0 then
        k1 <= k1(0) & KEY(1);
        if k1 = "10" then
          if poz_nr = 2 then poz_nr <= 0; else poz_nr <= poz_nr + 1; end if;
        end if;
      end if;
    end if;
  end process;
  poziom <= std_logic_vector(to_unsigned(1024 * (poz_nr + 1), 12));
  dziel  <= to_unsigned(10, 8) when s_sw2(1) = '1' else to_unsigned(1, 8);

  u_sekw : entity work.adc_sekwencer
    generic map (LICZBA => 1, KANALY => std_logic_vector(to_unsigned(1, 40)))
    port map (clk => clk_a, rst => rst_a, wlacz => '1', command_valid => c_valid, command_channel => c_kanal,
              command_startofpacket => c_sop, command_endofpacket => c_eop, command_ready => c_ready,
              response_valid => r_valid, response_channel => r_kanal, response_data => r_dane, wyniki => open,
              nowy => nowy, kanal => open, dane => dane);

  u_osc : entity work.oscyloskop
    port map (clk_a => clk_a, rst_a => rst_a, we => nowy, probka => dane, poziom => poziom, dziel => dziel,
              tryb_auto => s_sw2(0), wyzwolony => wyzw, clk_v => clk_v, rst_v => rst_v, rgb => rgb, hs => hs,
              vs => vs, de => de, nr_zrzutu => nr_zrzutu);
  process (clk_v)
  begin
    if rising_edge(clk_v) then
      HDMI_TX_D <= rgb; HDMI_TX_DE <= de; HDMI_TX_HS <= hs; HDMI_TX_VS <= vs;
      s_wyz <= s_wyz(0) & wyzw;
    end if;
  end process;

  u_adv : entity work.adv7513_konfig
    generic map (F_CLK => 25000000, F_I2C => 100000, OKRES => 25000000)
    port map (clk => clk_v, rst => rst_v, start => '0', zajety => open, gotowe => gotowe, blad => blad,
              scl_o => scl_o, sda_o => sda_o, sda_i => HDMI_I2C_SDA);
  HDMI_I2C_SCL <= 'Z' when scl_o = '1' else '0';
  HDMI_I2C_SDA <= 'Z' when sda_o = '1' else '0';

  LED <= not (std_logic_vector(nr_zrzutu(4 downto 0)) & s_wyz(1) & blad & gotowe);
end architecture rtl;
