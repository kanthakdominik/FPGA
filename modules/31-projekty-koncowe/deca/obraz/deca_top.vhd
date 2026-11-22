-- DECA — projekt 5 (31.05), VHDL: potok obróbki obrazu na generatorze RAW Bayer, wyjście HDMI. Opis jak
-- w deca_top.v. altpll i altddio_out (altera_mf) wiąże Quartus; w GHDL pozostają niepowiązane.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deca_top is
  port (
    MAX10_CLK1_50 : in    std_logic;
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
  signal pll_in : std_logic_vector(1 downto 0);
  signal pll_clk : std_logic_vector(4 downto 0);
  signal zeg : std_logic_vector(0 downto 0);
  signal clk, locked, rst, de, hs, vs, scl_o, sda_o, gotowe : std_logic;
  signal rs, s_sw : std_logic_vector(1 downto 0) := "00";
  signal k1 : std_logic_vector(1 downto 0) := "11";
  signal licz_ms : natural range 0 to 24999 := 0;
  signal tryb : unsigned(2 downto 0) := "000";
  signal rgb : std_logic_vector(23 downto 0);
  signal suma_y, srednia : unsigned(31 downto 0);
begin
  u_pll : altpll
    generic map (
      intended_device_family => "MAX 10", lpm_type => "altpll", operation_mode => "NORMAL", pll_type => "AUTO",
      inclk0_input_frequency => 20000, clk0_multiply_by => 1, clk0_divide_by => 2, clk0_duty_cycle => 50,
      clk0_phase_shift => "0", compensate_clock => "CLK0", width_clock => 5)
    port map (inclk => pll_in, areset => '0', clk => pll_clk, locked => locked);
  pll_in <= '0' & MAX10_CLK1_50;
  clk <= pll_clk(0);
  u_zeg : altddio_out generic map (width => 1, intended_device_family => "MAX 10")
    port map (datain_h => "0", datain_l => "1", outclock => clk, dataout => zeg);
  HDMI_TX_CLK <= zeg(0);
  HDMI_MCLK <= 'Z'; HDMI_LRCLK <= 'Z'; HDMI_SCLK <= 'Z'; HDMI_I2S <= (others => 'Z');

  process (clk, KEY(0))
  begin
    if KEY(0) = '0' then rs <= "00"; elsif rising_edge(clk) then rs <= rs(0) & locked; end if;
  end process;
  rst <= not rs(1);

  process (clk)
  begin
    if rising_edge(clk) then
      s_sw <= s_sw(0) & SW(0);
      if licz_ms = 24999 then licz_ms <= 0; else licz_ms <= licz_ms + 1; end if;
      if rst = '1' then
        tryb <= "000";
      elsif licz_ms = 0 then
        k1 <= k1(0) & KEY(1);
        if k1 = "10" then
          if tryb = 4 then tryb <= "000"; else tryb <= tryb + 1; end if;
        end if;
      end if;
    end if;
  end process;

  u_obraz : entity work.projekt_obraz
    port map (clk => clk, rst => rst, tryb => tryb, ruch => s_sw(1), de => de, hs => hs, vs => vs, rgb => rgb,
              suma_y => suma_y);
  process (clk)
  begin
    if rising_edge(clk) then
      HDMI_TX_D <= rgb; HDMI_TX_DE <= de; HDMI_TX_HS <= hs; HDMI_TX_VS <= vs;
    end if;
  end process;

  u_adv : entity work.adv7513_konfig
    generic map (F_CLK => 25000000, F_I2C => 100000, OKRES => 25000000)
    port map (clk => clk, rst => rst, start => '0', zajety => open, gotowe => gotowe, blad => open,
              scl_o => scl_o, sda_o => sda_o, sda_i => HDMI_I2C_SDA);
  HDMI_I2C_SCL <= 'Z' when scl_o = '1' else '0';
  HDMI_I2C_SDA <= 'Z' when sda_o = '1' else '0';

  srednia <= shift_right(suma_y, 18);
  LED <= not (std_logic_vector(srednia(7 downto 4)) & gotowe & std_logic_vector(tryb));
end architecture rtl;
