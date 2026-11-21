-- DECA — bufor ramki i filtr 3×3 (moduł 24, 24.04 i 24.06): obraz 320×240, 4 bity na piksel, dwie ramki w pamięci
-- na chipie (2 × 9600 słów) za portem Avalon-MM z burstami, wyświetlany 2× (640×480) przez bufor_ramki i
-- filtr3x3, wyjście przez ADV7513. Generator (50 MHz) rysuje pasy i odbijające się koło do ramki niewyświetlanej
-- i zgłasza zamianę; SW(0) = '1' — rysowanie w ramce wyświetlanej (rozdarcie obrazu). Filtr: SW(1) i KEY(1)
-- (wciśnięty = '1'): 00 — bez zmian, 01 — rozmycie, 10 — Sobel, 11 — krawędzie.
-- Diody (0 = świeci): LED(0) ADV7513 skonfigurowany, LED(1) błąd I2C, LED(2) ramka aktywna, LED(3) niedobór
-- danych, LED(7:4) — licznik narysowanych ramek.
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

  signal pll_in  : std_logic_vector(1 downto 0);
  signal pll_clk : std_logic_vector(4 downto 0);
  signal zeg     : std_logic_vector(0 downto 0);
  signal clk_m, clk, locked, rst_p, rst_m : std_logic;
  signal rs_p, rs_m : std_logic_vector(1 downto 0) := "00";
  signal sw_m, sw_p : std_logic_vector(1 downto 0) := "00";
  signal k1_p : std_logic_vector(1 downto 0) := "11";

  -- pamięć ramek
  type pam_t is array (0 to 19199) of std_logic_vector(31 downto 0);
  signal pam : pam_t;
  signal m_adr : unsigned(15 downto 0);
  signal m_read : std_logic;
  signal m_burstcount : unsigned(4 downto 0);
  signal s_akt, m_rvalid : std_logic := '0';
  signal s_adr : natural range 0 to 65535 := 0;
  signal s_ile : natural range 0 to 31 := 0;
  signal m_rdata : std_logic_vector(31 downto 0) := (others => '0');
  signal g_we : std_logic := '0';
  signal g_adr : natural range 0 to 19199 := 0;
  signal g_dane : std_logic_vector(31 downto 0) := (others => '0');

  signal hs, vs, de, nowa_ramka : std_logic;
  signal x, y : unsigned(11 downto 0);
  signal przelacz : std_logic := '0';
  signal aktywny, oczekuje, brak : std_logic;
  signal b_de, b_hs, b_vs : std_logic;
  signal b_piks : std_logic_vector(3 downto 0);

  -- generator
  type g_t is (G_RYSUJ, G_ZAMIANA, G_CZEKAJ);
  signal g_st : g_t := G_RYSUJ;
  signal gx : natural range 0 to 319 := 0;
  signal gy : natural range 0 to 239 := 0;
  signal faza : natural range 0 to 255 := 0;
  signal kx : natural range 0 to 319 := 160;
  signal ky : natural range 0 to 239 := 120;
  signal k_lewo, k_gora : std_logic := '0';
  signal slowo : std_logic_vector(31 downto 0) := (others => '0');
  signal w_adr : natural range 0 to 19200 := 9600;
  signal pauza : natural range 0 to 1048575 := 0;
  signal narysowane : unsigned(3 downto 0) := (others => '0');

  signal tryb : std_logic_vector(1 downto 0);
  signal f_de, f_hs, f_vs : std_logic;
  signal f_piks : std_logic_vector(7 downto 0);
  signal scl_o, sda_o, zajety, gotowe, blad : std_logic;
begin
  clk_m <= MAX10_CLK1_50;
  u_pll : altpll
    generic map (
      intended_device_family => "MAX 10", lpm_type => "altpll", operation_mode => "NORMAL", pll_type => "AUTO",
      inclk0_input_frequency => 20000, clk0_multiply_by => 1, clk0_divide_by => 2, clk0_duty_cycle => 50,
      clk0_phase_shift => "0", compensate_clock => "CLK0", width_clock => 5)
    port map (inclk => pll_in, areset => '0', clk => pll_clk, locked => locked);
  pll_in <= '0' & MAX10_CLK1_50;
  clk    <= pll_clk(0);
  u_zeg : altddio_out generic map (width => 1, intended_device_family => "MAX 10")
    port map (datain_h => "0", datain_l => "1", outclock => clk, dataout => zeg);
  HDMI_TX_CLK <= zeg(0);
  HDMI_MCLK <= 'Z'; HDMI_LRCLK <= 'Z'; HDMI_SCLK <= 'Z'; HDMI_I2S <= (others => 'Z');

  -- resety
  process (clk, KEY(0))
  begin
    if KEY(0) = '0' then rs_p <= "00"; elsif rising_edge(clk) then rs_p <= rs_p(0) & locked; end if;
  end process;
  process (clk_m, KEY(0))
  begin
    if KEY(0) = '0' then rs_m <= "00"; elsif rising_edge(clk_m) then rs_m <= rs_m(0) & locked; end if;
  end process;
  rst_p <= not rs_p(1);
  rst_m <= not rs_m(1);
  process (clk_m) begin if rising_edge(clk_m) then sw_m <= SW; end if; end process;
  process (clk) begin if rising_edge(clk) then sw_p <= SW; k1_p <= k1_p(0) & KEY(1); end if; end process;

  -- pamięć: port A — odczyt burstami (Avalon-MM), port B — zapis generatora
  process (clk_m)
  begin
    if rising_edge(clk_m) then
      m_rvalid <= '0';
      if s_akt = '0' then
        if m_read = '1' then s_akt <= '1'; s_adr <= to_integer(m_adr); s_ile <= to_integer(m_burstcount); end if;
      else
        if s_adr < 19200 then m_rdata <= pam(s_adr); end if;
        m_rvalid <= '1';
        s_adr <= s_adr + 1;
        s_ile <= s_ile - 1;
        if s_ile = 1 then s_akt <= '0'; end if;
      end if;
      if g_we = '1' then pam(g_adr) <= g_dane; end if;
    end if;
  end process;

  u_takt : entity work.takt_wideo
    port map (clk => clk, rst => rst_p, hs => hs, vs => vs, de => de, x => x, y => y, nowa_ramka => nowa_ramka);

  u_bufor : entity work.bufor_ramki
    generic map (SZER => 320, WYS => 240, SK => 1, BURST => 8, AW => 16, BAZA0 => 0, BAZA1 => 9600)
    port map (clk_m => clk_m, rst_m => rst_m, przelacz => przelacz, aktywny => aktywny, oczekuje => oczekuje,
              brak => brak, m_adr => m_adr, m_read => m_read, m_burstcount => m_burstcount, m_wait => s_akt,
              m_rvalid => m_rvalid, m_rdata => m_rdata,
              clk_p => clk, rst_p => rst_p, de => de, hs => hs, vs => vs, x => x, y => y,
              o_de => b_de, o_hs => b_hs, o_vs => b_vs, o_piks => b_piks);

  -- generator obrazu
  process (clk_m)
    variable dx, dy, pas : integer;
    variable p : std_logic_vector(3 downto 0);
  begin
    if rising_edge(clk_m) then
      g_we     <= '0';
      przelacz <= '0';
      if rst_m = '1' then
        g_st <= G_RYSUJ; gx <= 0; gy <= 0; w_adr <= 9600;
      else
        case g_st is
          when G_RYSUJ =>
            dx  := gx - kx;
            dy  := gy - ky;
            pas := (gx mod 256 + gy + faza) mod 32;
            if gx = 0 or gx = 319 or gy = 0 or gy = 239 then p := x"C";
            elsif dx * dx + dy * dy < 1600 then p := x"F";
            elsif pas >= 16 then p := x"6";
            else p := x"2";
            end if;
            slowo <= p & slowo(31 downto 4);
            if gx mod 8 = 7 then
              g_we <= '1'; g_adr <= w_adr; g_dane <= p & slowo(31 downto 4); w_adr <= w_adr + 1;
            end if;
            if gx = 319 then
              gx <= 0;
              if gy = 239 then gy <= 0; g_st <= G_ZAMIANA; else gy <= gy + 1; end if;
            else
              gx <= gx + 1;
            end if;
          when G_ZAMIANA =>
            if sw_m(0) = '0' then przelacz <= '1'; end if;
            pauza <= 833000;
            g_st  <= G_CZEKAJ;
          when G_CZEKAJ =>
            if pauza /= 0 then pauza <= pauza - 1; end if;
            if (sw_m(0) = '1' and pauza = 0) or (sw_m(0) = '0' and oczekuje = '0' and przelacz = '0') then
              if (aktywny xor not sw_m(0)) = '1' then w_adr <= 9600; else w_adr <= 0; end if;
              faza <= (faza + 1) mod 256;
              narysowane <= narysowane + 1;
              if k_lewo = '1' then kx <= kx - 3; else kx <= kx + 3; end if;
              if k_gora = '1' then ky <= ky - 2; else ky <= ky + 2; end if;
              if k_lewo = '0' and kx >= 276 then k_lewo <= '1'; end if;
              if k_lewo = '1' and kx <= 44 then k_lewo <= '0'; end if;
              if k_gora = '0' and ky >= 196 then k_gora <= '1'; end if;
              if k_gora = '1' and ky <= 44 then k_gora <= '0'; end if;
              g_st <= G_RYSUJ;
            end if;
        end case;
      end if;
    end if;
  end process;

  -- filtr i wyjście
  tryb <= sw_p(1) & not k1_p(1);
  u_filtr : entity work.filtr3x3
    generic map (L => 800, PROG => 96)
    port map (clk => clk, tryb => tryb, de => b_de, hs => b_hs, vs => b_vs, piks => b_piks & b_piks,
              o_de => f_de, o_hs => f_hs, o_vs => f_vs, o_piks => f_piks);
  process (clk)
  begin
    if rising_edge(clk) then
      if f_de = '1' then HDMI_TX_D <= f_piks & f_piks & f_piks; else HDMI_TX_D <= (others => '0'); end if;
      HDMI_TX_DE <= f_de; HDMI_TX_HS <= f_hs; HDMI_TX_VS <= f_vs;
    end if;
  end process;

  u_adv : entity work.adv7513_konfig
    generic map (F_CLK => 25000000, F_I2C => 100000, OKRES => 25000000)
    port map (clk => clk, rst => rst_p, start => '0', zajety => zajety, gotowe => gotowe, blad => blad,
              scl_o => scl_o, sda_o => sda_o, sda_i => HDMI_I2C_SDA);
  HDMI_I2C_SCL <= 'Z' when scl_o = '1' else '0';
  HDMI_I2C_SDA <= 'Z' when sda_o = '1' else '0';

  LED <= not (std_logic_vector(narysowane) & brak & aktywny & blad & gotowe);
end architecture rtl;
