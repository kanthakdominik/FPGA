-- DECA — projekt 3 (31.03), VHDL: syntezator sterowany MIDI (GPIO0_D(1), 31 250 b/s), kodek TLV320AIC3254
-- przez I2S. Opis jak w deca_top.v. altpll i altddio_out (altera_mf) wiąże Quartus; w GHDL niepowiązane.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deca_top is
  port (
    MAX10_CLK1_50    : in    std_logic;
    KEY              : in    std_logic_vector(1 downto 0);
    SW               : in    std_logic_vector(1 downto 0);
    LED              : out   std_logic_vector(7 downto 0);
    GPIO0_D          : inout std_logic_vector(1 downto 0);
    AUDIO_MCLK       : out   std_logic;
    AUDIO_BCLK       : out   std_logic;
    AUDIO_WCLK       : out   std_logic;
    AUDIO_DIN_MFP1   : out   std_logic;
    AUDIO_DOUT_MFP2  : in    std_logic;
    AUDIO_SCLK_MFP3  : inout std_logic;
    AUDIO_SCL_SS_n   : inout std_logic;
    AUDIO_SDA_MOSI   : inout std_logic;
    AUDIO_MISO_MFP4  : inout std_logic;
    AUDIO_SPI_SELECT : out   std_logic;
    AUDIO_RESET_n    : out   std_logic;
    AUDIO_GPIO_MFP5  : inout std_logic
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

  constant N : positive := 42;
  constant TAB : std_logic_vector(16 * N - 1 downto 0) :=
    x"0000" & x"0101" & x"FF01" &
    x"0B81" & x"0C82" & x"0D00" & x"0E80" & x"1281" & x"1382" & x"1480" &
    x"1B20" & x"3C08" & x"3D01" &
    x"0001" & x"0108" & x"0200" & x"7B01" & x"1425" & x"0A00" &
    x"0C08" & x"0D08" & x"0E08" & x"0F08" & x"0300" & x"0400" &
    x"1000" & x"1100" & x"1200" & x"1300" & x"093C" & x"4732" &
    x"3440" & x"3640" & x"3740" & x"3940" & x"3B0C" & x"3C0C" &
    x"0000" & x"3FD6" & x"4000" & x"51C0" & x"5200";

  signal pll_in  : std_logic_vector(1 downto 0);
  signal pll_clk : std_logic_vector(4 downto 0);
  signal mclk    : std_logic_vector(0 downto 0);
  signal clk, locked, rst, rst_i2c, scl_o, sda_o, k_blad, nowa : std_logic;
  signal rs   : std_logic_vector(1 downto 0) := "00";
  signal lr   : natural range 0 to 37500 := 0;
  signal probka : signed(23 downto 0);
  signal aktywne : std_logic_vector(3 downto 0);
  signal szczyt : unsigned(22 downto 0) := (others => '0');
  signal zanik  : unsigned(12 downto 0) := (others => '0');
  signal mig    : unsigned(22 downto 0) := (others => '0');
  signal poziom : std_logic_vector(3 downto 0);
begin
  u_pll : altpll
    generic map (
      intended_device_family => "MAX 10", lpm_type => "altpll", operation_mode => "NORMAL", pll_type => "AUTO",
      inclk0_input_frequency => 20000, clk0_multiply_by => 1, clk0_divide_by => 4, clk0_duty_cycle => 50,
      clk0_phase_shift => "0", compensate_clock => "CLK0", width_clock => 5)
    port map (inclk => pll_in, areset => '0', clk => pll_clk, locked => locked);
  pll_in <= '0' & MAX10_CLK1_50;
  clk    <= pll_clk(0);
  u_mclk : altddio_out generic map (width => 1, intended_device_family => "MAX 10")
    port map (datain_h => "1", datain_l => "0", outclock => clk, dataout => mclk);
  AUDIO_MCLK       <= mclk(0);
  AUDIO_SPI_SELECT <= '0';
  AUDIO_SCLK_MFP3  <= 'Z';
  AUDIO_MISO_MFP4  <= 'Z';
  AUDIO_GPIO_MFP5  <= 'Z';
  GPIO0_D          <= "ZZ";

  process (clk, KEY(0))
  begin
    if KEY(0) = '0' then rs <= "00"; elsif rising_edge(clk) then rs <= rs(0) & locked; end if;
  end process;
  rst <= not rs(1);
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then lr <= 0; elsif lr /= 37500 then lr <= lr + 1; end if;
      mig <= mig + 1;
    end if;
  end process;
  AUDIO_RESET_n <= '1' when lr >= 12500 else '0';
  rst_i2c       <= '0' when lr = 37500 else '1';

  u_konf : entity work.i2c_zapisy
    generic map (F_CLK => 12500000, F_I2C => 100000, OKRES => 0, ADRES => "0011000", N => N, TAB => TAB)
    port map (clk => clk, rst => rst_i2c, start => '0', zajety => open, gotowe => open, blad => k_blad,
              scl_o => scl_o, sda_o => sda_o, sda_i => AUDIO_SDA_MOSI);
  AUDIO_SCL_SS_n <= 'Z' when scl_o = '1' else '0';
  AUDIO_SDA_MOSI <= 'Z' when sda_o = '1' else '0';

  u_synt : entity work.projekt_syntezator generic map (CLK_HZ => 12_500_000, BAUD => 31_250)
    port map (clk => clk, rst => rst, rx => GPIO0_D(1), bclk => AUDIO_BCLK, wclk => AUDIO_WCLK,
              dout => AUDIO_DIN_MFP1, probka => probka, nowa => nowa, aktywne => aktywne, blad_ramki => open);

  process (clk)
    variable modul : unsigned(23 downto 0);
  begin
    if rising_edge(clk) then
      if nowa = '1' then
        modul := unsigned(abs(probka));
        zanik <= zanik + 1;
        if modul(22 downto 0) > szczyt then szczyt <= modul(22 downto 0);
        elsif zanik = 0 then szczyt <= shift_right(szczyt, 1);
        end if;
      end if;
    end if;
  end process;
  poziom <= std_logic_vector(szczyt(22 downto 19));
  LED <= (others => mig(22)) when k_blad = '1' else not (poziom & aktywne);
end architecture rtl;
