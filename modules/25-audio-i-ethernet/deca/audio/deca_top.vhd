-- DECA — dźwięk (moduł 25, 25.01–25.02): wejście liniowe kodeka TLV320AIC3254 -> biquad -> echo -> wyjście.
-- Zegar 12,5 MHz z PLL = MCLK kodeka, i2s_master: fs = 48,83 kHz. Konfiguracja kodeka przez I2C po resecie.
-- SW(0) — filtr (dolnoprzepustowy 1 kHz; z wciśniętym KEY(1) — górnoprzepustowy), SW(1) — echo 250 ms.
-- Diody: wskaźnik poziomu kanału lewego (co 6 dB); po błędzie I2C wszystkie migają.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deca_top is
  port (
    MAX10_CLK1_50    : in    std_logic;
    KEY              : in    std_logic_vector(1 downto 0);
    SW               : in    std_logic_vector(1 downto 0);
    LED              : out   std_logic_vector(7 downto 0);
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
  signal clk, locked, rst, rst_i2c : std_logic;
  signal rs   : std_logic_vector(1 downto 0) := "00";
  signal lr   : natural range 0 to 37500 := 0;
  signal s_sw : std_logic_vector(1 downto 0) := "00";
  signal s_k1 : std_logic_vector(1 downto 0) := "11";
  signal scl_o, sda_o, k_zaj, k_got, k_blad : std_logic;
  signal rx_l, rx_p : std_logic_vector(23 downto 0);
  signal tx_l, tx_p : std_logic_vector(23 downto 0) := (others => '0');
  signal ramka : std_logic;
  signal b0, b1, b2, a1, a2 : signed(17 downto 0);
  signal f_l, f_p, e_l, e_p : signed(23 downto 0);
  signal fw_l, fw_p, ew_l, ew_p : std_logic;
  signal w_l, w_p : signed(23 downto 0) := (others => '0');
  signal w_we : std_logic := '0';
  signal g : unsigned(7 downto 0);
  signal szczyt : unsigned(22 downto 0) := (others => '0');
  signal dziel  : unsigned(9 downto 0) := (others => '0');
  signal miga   : unsigned(22 downto 0) := (others => '0');
  signal slupek : std_logic_vector(7 downto 0);
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

  process (clk, KEY(0))
  begin
    if KEY(0) = '0' then rs <= "00"; elsif rising_edge(clk) then rs <= rs(0) & locked; end if;
  end process;
  rst <= not rs(1);
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then lr <= 0; elsif lr /= 37500 then lr <= lr + 1; end if;
      s_sw <= SW; s_k1 <= s_k1(0) & KEY(1);
    end if;
  end process;
  AUDIO_RESET_n <= '1' when lr >= 12500 else '0';
  rst_i2c       <= '0' when lr = 37500 else '1';

  u_konf : entity work.i2c_zapisy
    generic map (F_CLK => 12500000, F_I2C => 100000, OKRES => 0, ADRES => "0011000", N => N, TAB => TAB)
    port map (clk => clk, rst => rst_i2c, start => '0', zajety => k_zaj, gotowe => k_got, blad => k_blad,
              scl_o => scl_o, sda_o => sda_o, sda_i => AUDIO_SDA_MOSI);
  AUDIO_SCL_SS_n <= 'Z' when scl_o = '1' else '0';
  AUDIO_SDA_MOSI <= 'Z' when sda_o = '1' else '0';

  u_i2s : entity work.i2s_master
    port map (clk => clk, rst => rst, tx_l => tx_l, tx_p => tx_p, rx_l => rx_l, rx_p => rx_p, ramka => ramka,
              bclk => AUDIO_BCLK, wclk => AUDIO_WCLK, dout => AUDIO_DIN_MFP1, din => AUDIO_DOUT_MFP2);

  b0 <= to_signed(59836, 18)   when s_k1(1) = '0' else to_signed(248, 18);
  b1 <= to_signed(-119671, 18) when s_k1(1) = '0' else to_signed(497, 18);
  b2 <= b0;
  a1 <= to_signed(-119174, 18);
  a2 <= to_signed(54632, 18);
  u_bq_l : entity work.biquad
    port map (clk => clk, rst => rst, we => ramka, x => signed(rx_l), b0 => b0, b1 => b1, b2 => b2, a1 => a1, a2 => a2,
              y => f_l, y_wazne => fw_l);
  u_bq_p : entity work.biquad
    port map (clk => clk, rst => rst, we => ramka, x => signed(rx_p), b0 => b0, b1 => b1, b2 => b2, a1 => a1, a2 => a2,
              y => f_p, y_wazne => fw_p);
  process (clk)
  begin
    if rising_edge(clk) then
      w_we <= fw_l;
      if fw_l = '1' then
        if s_sw(0) = '1' then w_l <= f_l; w_p <= f_p; else w_l <= signed(rx_l); w_p <= signed(rx_p); end if;
      end if;
      if ew_l = '1' then tx_l <= std_logic_vector(e_l); tx_p <= std_logic_vector(e_p); end if;
    end if;
  end process;
  g <= to_unsigned(128, 8) when s_sw(1) = '1' else to_unsigned(0, 8);
  u_ec_l : entity work.echo generic map (D => 12000)
    port map (clk => clk, rst => rst, we => w_we, x => w_l, g => g, y => e_l, y_wazne => ew_l);
  u_ec_p : entity work.echo generic map (D => 12000)
    port map (clk => clk, rst => rst, we => w_we, x => w_p, g => g, y => e_p, y_wazne => ew_p);

  -- wskaźnik poziomu
  process (clk)
    variable modul : unsigned(22 downto 0);
  begin
    if rising_edge(clk) then
      miga <= miga + 1;
      if ramka = '1' then
        if rx_l(23) = '1' then modul := unsigned(not rx_l(22 downto 0)); else modul := unsigned(rx_l(22 downto 0)); end if;
        dziel <= dziel + 1;
        if modul > szczyt then szczyt <= modul;
        elsif dziel = 0 then szczyt <= szczyt - shift_right(szczyt, 3);
        end if;
      end if;
    end if;
  end process;
  gen_slupek : for k in 0 to 7 generate
    slupek(k) <= '1' when szczyt(22 downto 15 + k) /= 0 else '0';
  end generate;
  LED <= (others => miga(22)) when k_blad = '1' else not slupek;
end architecture rtl;
