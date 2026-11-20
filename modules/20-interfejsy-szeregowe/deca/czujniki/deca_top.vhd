-- Moduł nadrzędny DECA - VHDL. Czujniki płytki (20.02, 20.03, 20.05):
--   LIS2DH12 (akcelerometr, SPI tryb 3), LM71 (temperatura przy układzie FPGA, SPI 3-przewodowe),
--   HDC1000 (wilgotność i temperatura otoczenia, I2C, adres 0x40).
-- Diody (SW): "00" - poziomica: świeci dioda odpowiadająca przyspieszeniu w osi X (przechyl płytkę),
--   "01" - temperatura LM71 w stopniach C (binarnie), "10" - wilgotność HDC1000 w %, "11" - stan: LED(0)
--   WHO_AM_I = 0x33, LED(1) odczyty LIS2DH12 trwają, LED(2) odczyty HDC1000 trwają, LED(7 downto 4) liczba NACK.
-- Telemetria UART 115 200 8N1 na GPIO0_D(0) co 0,5 s, szesnastkowo:
--   "A xxxx yyyy zzzz T tttt H tttt wwww" + CR LF (akcelerometr X Y Z, LM71, HDC1000 temperatura i wilgotność).
-- KEY(0) - reset.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deca_top is
  port (
    MAX10_CLK1_50   : in    std_logic;
    KEY             : in    std_logic_vector(1 downto 0);
    SW              : in    std_logic_vector(1 downto 0);
    LED             : out   std_logic_vector(7 downto 0);   -- '0' = świeci
    -- akcelerometr
    G_SENSOR_SCLK   : out   std_logic;
    G_SENSOR_SDI    : out   std_logic;
    G_SENSOR_SDO    : in    std_logic;
    G_SENSOR_CS_n   : out   std_logic;
    G_SENSOR_INT1   : in    std_logic;
    G_SENSOR_INT2   : in    std_logic;
    -- LM71
    TEMP_SC         : out   std_logic;
    TEMP_SIO        : inout std_logic;
    TEMP_CS_n       : out   std_logic;
    -- HDC1000
    RH_TEMP_I2C_SCL : inout std_logic;
    RH_TEMP_I2C_SDA : inout std_logic;
    RH_TEMP_DRDY_n  : in    std_logic;
    -- telemetria
    GPIO0_D         : inout std_logic_vector(0 downto 0)
  );
end entity deca_top;

architecture rtl of deca_top is
  signal clk, rst      : std_logic;
  signal rs, s_sw      : std_logic_vector(1 downto 0) := "00";
  signal ax, ay, az    : std_logic_vector(15 downto 0);
  signal who           : std_logic_vector(7 downto 0);
  signal a_nowe, id_ok : std_logic;
  signal lm_t          : std_logic_vector(13 downto 0);
  signal lm_c          : std_logic_vector(8 downto 0);
  signal scl_oe, sda_oe, h_nowe : std_logic;
  signal h_t, h_w      : std_logic_vector(15 downto 0);
  signal h_c           : std_logic_vector(8 downto 0);
  signal h_proc        : std_logic_vector(6 downto 0);
  signal h_nacki       : std_logic_vector(7 downto 0);
  signal a_akt, h_akt  : unsigned(22 downto 0) := (others => '0');
  signal diody         : std_logic_vector(7 downto 0);
  signal tx, gotowy    : std_logic;
  signal start         : std_logic := '0';
  signal znak          : std_logic_vector(7 downto 0) := x"00";
  signal migawka       : std_logic_vector(95 downto 0) := (others => '0');
  signal zi            : natural range 0 to 36 := 0;
  signal nadaje        : std_logic := '0';
  signal okres         : natural range 0 to 24_999_999 := 0;
  attribute altera_attribute : string;
  attribute altera_attribute of s_sw : signal is "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS";

  function hex(n : std_logic_vector(3 downto 0)) return std_logic_vector is
  begin
    if unsigned(n) < 10 then
      return std_logic_vector(to_unsigned(48, 8) + unsigned(n));
    else
      return std_logic_vector(to_unsigned(55, 8) + unsigned(n));
    end if;
  end function;

  -- znak nr i linii: pola po 4 cyfry szesnastkowe (X od 2, Y od 7, Z od 12, LM71 od 19, HDC T od 26, HDC W od 31)
  function znak_linii(i : natural; m : std_logic_vector(95 downto 0)) return std_logic_vector is
    variable pole, cyfra, gora : natural;
  begin
    case i is
      when 0  => return x"41";                                   -- "A"
      when 17 => return x"54";                                   -- "T"
      when 24 => return x"48";                                   -- "H"
      when 1 | 6 | 11 | 16 | 18 | 23 | 25 | 30 => return x"20";
      when 35 => return x"0D";
      when 36 => return x"0A";
      when 2 to 5   => pole := 0; cyfra := i - 2;
      when 7 to 10  => pole := 1; cyfra := i - 7;
      when 12 to 15 => pole := 2; cyfra := i - 12;
      when 19 to 22 => pole := 3; cyfra := i - 19;
      when 26 to 29 => pole := 4; cyfra := i - 26;
      when others   => pole := 5; cyfra := i - 31;
    end case;
    gora := 95 - 16 * pole - 4 * cyfra;
    return hex(m(gora downto gora - 3));
  end function;
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

  -- ---- czujniki
  u_akc : entity work.akcel_lis2dh12 generic map (DIV => 13, CZEKAJ => 250_000, OKRES => 2_500_000)
    port map (clk => clk, rst => rst, sclk => G_SENSOR_SCLK, mosi => G_SENSOR_SDI, miso => G_SENSOR_SDO,
              cs_n => G_SENSOR_CS_n, x => ax, y => ay, z => az, nowe => a_nowe, who_am_i => who, id_ok => id_ok);

  u_lm : entity work.temp_lm71 generic map (DIV => 25, OKRES => 25_000_000)
    port map (clk => clk, rst => rst, sc => TEMP_SC, sio => TEMP_SIO, cs_n => TEMP_CS_n, temp => lm_t,
              temp_c => lm_c, nowe => open);
  TEMP_SIO <= 'Z';                                               -- tylko odczyt

  u_hdc : entity work.hdc1000 generic map (ADR => "1000000", DIV => 125, CZEKAJ => 1_000_000, OKRES => 25_000_000)
    port map (clk => clk, rst => rst, scl_i => RH_TEMP_I2C_SCL, scl_oe => scl_oe, sda_i => RH_TEMP_I2C_SDA,
              sda_oe => sda_oe, temp_sur => h_t, wilg_sur => h_w, temp_c => h_c, wilg_proc => h_proc,
              nowe => h_nowe, nacki => h_nacki);
  RH_TEMP_I2C_SCL <= '0' when scl_oe = '1' else 'Z';            -- open-drain: tylko zero albo wysoka impedancja
  RH_TEMP_I2C_SDA <= '0' when sda_oe = '1' else 'Z';

  -- ---- wskaźniki aktywności (impuls nowe -> dioda świeci przez ok. 0,17 s)
  process (clk)
  begin
    if rising_edge(clk) then
      if a_nowe = '1' then a_akt <= (others => '1'); elsif a_akt /= 0 then a_akt <= a_akt - 1; end if;
      if h_nowe = '1' then h_akt <= (others => '1'); elsif h_akt /= 0 then h_akt <= h_akt - 1; end if;
    end if;
  end process;

  -- ---- diody
  process (all)
    variable poz : natural range 0 to 7;
  begin
    poz := to_integer(unsigned(ax(15 downto 13) xor "100"));    -- -2 g ... +2 g -> 0 ... 7
    case s_sw is
      when "00"   => diody <= (others => '0'); diody(poz) <= '1';
      when "01"   => diody <= lm_c(7 downto 0);
      when "10"   => diody <= '0' & h_proc;
      when others =>
        diody <= h_nacki(3 downto 0) & "0000";
        diody(0) <= id_ok;
        if a_akt /= 0 then diody(1) <= '1'; end if;
        if h_akt /= 0 then diody(2) <= '1'; end if;
    end case;
  end process;
  LED <= not diody;

  -- ---- telemetria
  u_tx : entity work.uart_tx generic map (CLK_HZ => 50_000_000, BAUD => 115_200)
    port map (clk => clk, rst => rst, start => start, dane => znak, gotowy => gotowy, tx => tx);
  GPIO0_D(0) <= tx;

  process (clk)
  begin
    if rising_edge(clk) then
      start <= '0';
      if rst = '1' then
        nadaje <= '0';
        okres  <= 0;
      else
        okres <= 0 when okres = 24_999_999 else okres + 1;
        if okres = 0 and nadaje = '0' then
          migawka <= ax & ay & az & lm_t(13) & lm_t(13) & lm_t & h_t & h_w;
          nadaje  <= '1';
          zi      <= 0;
        elsif nadaje = '1' and gotowy = '1' and start = '0' then
          znak  <= znak_linii(zi, migawka);
          start <= '1';
          if zi = 36 then nadaje <= '0'; else zi <= zi + 1; end if;
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
