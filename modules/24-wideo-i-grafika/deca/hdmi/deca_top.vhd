-- DECA — HDMI (moduł 24, 24.01–24.03): 640×480 przy ok. 60 Hz przez ADV7513; zegar piksela 25 MHz z PLL.
-- SW(0) — tło: pasy barw / gradient; SW(1) — nakładki: odcinki (bitmapa 160×120, Bresenham w wygaszaniu),
-- tekst 40×30 i sprite 16×16. KEY(0) — reset, KEY(1) — ponowna konfiguracja ADV7513.
-- Diody (0 = świeci): LED(0) konfiguracja zakończona, LED(1) błąd I2C, LED(2) konfiguracja w toku, LED(7:3) —
-- licznik ramek. Komponenty altpll i altddio_out wiąże Quartus z biblioteką altera_mf; w GHDL są niepowiązane.
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
  signal clk, locked, rst : std_logic;
  signal rs      : std_logic_vector(1 downto 0) := "00";
  signal s_sw    : std_logic_vector(1 downto 0) := "00";
  signal s_k1    : std_logic_vector(1 downto 0) := "11";
  signal k1_d, start_k : std_logic := '1';

  signal hs, vs, de, nowa_ramka : std_logic;
  signal x, y : unsigned(11 downto 0);
  signal scl_o, sda_o, zajety, gotowe, blad : std_logic;

  constant T1 : string(1 to 26) := "MODUL 24 - WIDEO I GRAFIKA";
  constant T2 : string(1 to 26) := "DECA  HDMI  640X480  60 HZ";
  constant T3 : string(1 to 26) := "SW0: TLO     SW1: NAKLADKI";
  signal ti    : natural range 0 to 78 := 0;
  signal t_we  : std_logic := '0';
  signal t_adr : unsigned(10 downto 0) := (others => '0');
  signal t_kod : std_logic_vector(7 downto 0) := x"00";
  signal piks_t : std_logic;

  signal sx : unsigned(11 downto 0) := to_unsigned(100, 12);
  signal sy : unsigned(11 downto 0) := to_unsigned(60, 12);
  signal lewo, gora : std_logic := '0';
  signal nr_ramki : unsigned(4 downto 0) := (others => '0');
  signal sp_w : std_logic;
  signal sp_k : std_logic_vector(1 downto 0);

  type bm_t is array (0 to 19199) of std_logic;
  signal bm : bm_t;
  signal bw_adr : natural range 0 to 32767 := 0;
  signal bw_we, bw_d, bm_q : std_logic := '0';
  type rs_t is (R_CZEKA, R_CZYSC, R_LINIA, R_RYSUJ);
  signal rs_st : rs_t := R_CZEKA;
  signal nr_l : natural range 0 to 3 := 0;
  signal l_start : std_logic := '0';
  signal l_x0, l_y0, l_x1, l_y1 : unsigned(11 downto 0) := (others => '0');
  signal l_got, l_pw, l_kon : std_logic;
  signal l_px, l_py : unsigned(11 downto 0);

  signal tlo1, tlo2 : std_logic_vector(23 downto 0) := (others => '0');
  signal syn1, syn2 : std_logic_vector(2 downto 0) := "000";
  signal sp_w2, bm2 : std_logic := '0';
  signal sp_k2 : std_logic_vector(1 downto 0) := "00";
begin
  -- ---- zegar piksela i zegar dla ADV7513 (zegar odwrócony z rejestru DDR)
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

  -- ---- reset i wejścia
  process (clk, KEY(0))
  begin
    if KEY(0) = '0' then
      rs <= "00";
    elsif rising_edge(clk) then
      rs <= rs(0) & locked;
    end if;
  end process;
  rst <= not rs(1);
  process (clk)
  begin
    if rising_edge(clk) then
      s_sw <= SW; s_k1 <= s_k1(0) & KEY(1); k1_d <= s_k1(1);
    end if;
  end process;
  start_k <= k1_d and not s_k1(1);

  u_takt : entity work.takt_wideo
    port map (clk => clk, rst => rst, hs => hs, vs => vs, de => de, x => x, y => y, nowa_ramka => nowa_ramka);

  u_adv : entity work.adv7513_konfig
    generic map (F_CLK => 25000000, F_I2C => 100000, OKRES => 25000000)
    port map (clk => clk, rst => rst, start => start_k, zajety => zajety, gotowe => gotowe, blad => blad,
              scl_o => scl_o, sda_o => sda_o, sda_i => HDMI_I2C_SDA);
  HDMI_I2C_SCL <= 'Z' when scl_o = '1' else '0';
  HDMI_I2C_SDA <= 'Z' when sda_o = '1' else '0';

  -- ---- tekst
  process (clk)
  begin
    if rising_edge(clk) then
      t_we <= '0';
      if rst = '1' then
        ti <= 0;
      elsif ti < 78 then
        t_we <= '1';
        if ti < 26 then
          t_adr <= to_unsigned(82 + ti, 11);   t_kod <= std_logic_vector(to_unsigned(character'pos(T1(ti + 1)), 8));
        elsif ti < 52 then
          t_adr <= to_unsigned(136 + ti, 11);  t_kod <= std_logic_vector(to_unsigned(character'pos(T2(ti - 25)), 8));
        else
          t_adr <= to_unsigned(1070 + ti, 11); t_kod <= std_logic_vector(to_unsigned(character'pos(T3(ti - 51)), 8));
        end if;
        ti <= ti + 1;
      end if;
    end if;
  end process;
  u_zn : entity work.znaki
    generic map (KOL => 40, WIER => 30, SK => 1)
    port map (clk => clk, we => t_we, wadr => t_adr, wkod => t_kod, x => x, y => y, piks => piks_t);

  -- ---- sprite
  process (clk)
  begin
    if rising_edge(clk) then
      if nowa_ramka = '1' then
        nr_ramki <= nr_ramki + 1;
        if lewo = '1' then sx <= sx - 2; else sx <= sx + 2; end if;
        if gora = '1' then sy <= sy - 1; else sy <= sy + 1; end if;
        if lewo = '0' and sx >= 620 then lewo <= '1'; end if;
        if lewo = '1' and sx <= 2 then lewo <= '0'; end if;
        if gora = '0' and sy >= 462 then gora <= '1'; end if;
        if gora = '1' and sy <= 1 then gora <= '0'; end if;
      end if;
    end if;
  end process;
  u_sp : entity work.sprite16
    port map (clk => clk, x => x, y => y, sx => sx, sy => sy, widoczny => sp_w, kolor => sp_k);

  -- ---- bitmapa z odcinkami
  process (clk)
    variable a : natural;
  begin
    if rising_edge(clk) then
      if bw_we = '1' and bw_adr < 19200 then bm(bw_adr) <= bw_d; end if;
      a := to_integer(y(9 downto 2)) * 160 + to_integer(x(11 downto 2));
      if a < 19200 then bm_q <= bm(a); else bm_q <= bm(0); end if;
    end if;
  end process;

  u_lin : entity work.linia_bres
    port map (clk => clk, rst => rst, start => l_start, x0 => l_x0, y0 => l_y0, x1 => l_x1, y1 => l_y1,
              dalej => '1', gotowy => l_got, px => l_px, py => l_py, pwazny => l_pw, koniec => l_kon);

  process (clk)
  begin
    if rising_edge(clk) then
      l_start <= '0';
      bw_we   <= '0';
      if rst = '1' then
        rs_st <= R_CZEKA;
      else
        case rs_st is
          when R_CZEKA =>
            if x = 0 and y = 480 then rs_st <= R_CZYSC; bw_adr <= 0; end if;
          when R_CZYSC =>
            bw_we <= '1'; bw_d <= '0';
            if bw_we = '1' then bw_adr <= bw_adr + 1; end if;
            if bw_adr = 19199 then rs_st <= R_LINIA; nr_l <= 0; bw_we <= '0'; end if;
          when R_LINIA =>
            if l_got = '1' and l_start = '0' then
              if nr_l mod 2 = 1 then l_x0 <= to_unsigned(159, 12); else l_x0 <= (others => '0'); end if;
              if nr_l >= 2 then l_y0 <= to_unsigned(119, 12); else l_y0 <= (others => '0'); end if;
              l_x1 <= shift_right(sx + 8, 2);
              l_y1 <= shift_right(sy + 8, 2);
              l_start <= '1';
              rs_st <= R_RYSUJ;
            end if;
          when R_RYSUJ =>
            if l_pw = '1' then
              bw_we <= '1'; bw_d <= '1'; bw_adr <= to_integer(l_py(7 downto 0)) * 160 + to_integer(l_px(7 downto 0));
            end if;
            if l_pw = '1' and l_kon = '1' then
              if nr_l = 3 then rs_st <= R_CZEKA; else nr_l <= nr_l + 1; rs_st <= R_LINIA; end if;
            end if;
        end case;
      end if;
    end if;
  end process;

  -- ---- tło i wyrównanie do opóźnienia tekstu (2 takty)
  process (clk)
    variable tlo : std_logic_vector(23 downto 0);
    variable xi  : natural;
  begin
    if rising_edge(clk) then
      xi := to_integer(x);
      if s_sw(0) = '1' then
        tlo := std_logic_vector(x(9 downto 2)) & std_logic_vector(y(8 downto 1)) & x"80";
      elsif xi < 80  then tlo := x"FFFFFF";
      elsif xi < 160 then tlo := x"FFFF00";
      elsif xi < 240 then tlo := x"00FFFF";
      elsif xi < 320 then tlo := x"00FF00";
      elsif xi < 400 then tlo := x"FF00FF";
      elsif xi < 480 then tlo := x"FF0000";
      elsif xi < 560 then tlo := x"0000FF";
      else tlo := x"000000";
      end if;
      tlo1 <= tlo; tlo2 <= tlo1;
      syn1 <= de & hs & vs; syn2 <= syn1;
      sp_w2 <= sp_w; sp_k2 <= sp_k;
      bm2 <= bm_q;
    end if;
  end process;

  -- ---- składanie i rejestry wyjściowe
  process (clk)
    variable kolor : std_logic_vector(23 downto 0);
  begin
    if rising_edge(clk) then
      kolor := tlo2;
      if s_sw(1) = '1' then
        if bm2 = '1' then kolor := x"FF4040"; end if;
        if piks_t = '1' then kolor := x"FFFFFF"; end if;
        if sp_w2 = '1' then
          case sp_k2 is
            when "01"   => kolor := x"000080";
            when "10"   => kolor := x"FFD000";
            when others => kolor := x"000000";
          end case;
        end if;
      end if;
      if syn2(2) = '0' then kolor := x"000000"; end if;
      HDMI_TX_D  <= kolor;
      HDMI_TX_DE <= syn2(2);
      HDMI_TX_HS <= syn2(1);
      HDMI_TX_VS <= syn2(0);
    end if;
  end process;

  LED <= not (std_logic_vector(nr_ramki) & zajety & blad & gotowe);
end architecture rtl;
