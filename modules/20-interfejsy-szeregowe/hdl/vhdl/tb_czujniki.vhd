-- Testbench sterowników czujników płytki DECA (20.05) z modelami behawioralnymi czujników:
--   LIS2DH12 — slave SPI w trybie 3: rejestry, bit odczytu i autoinkrementacji, WHO_AM_I = 0x33;
--              sprawdzane: zapis CTRL_REG1 = 0x57 i CTRL_REG4 = 0x88, SCLK w spoczynku wysoki przy CS,
--              odczyt X, Y, Z (dwa różne zestawy wartości),
--   LM71     — 16 bitów wystawianych po zboczu opadającym SC; +25,0625 °C i −10,5 °C,
--   HDC1000  — slave I²C 0x40: zapis konfiguracji, wyzwolenie pomiaru zapisem wskaźnika 0x00,
--              NACK na adres w czasie pomiaru (sterownik ponawia), odczyt 4 bajtów.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_czujniki is
end entity tb_czujniki;

architecture sim of tb_czujniki is
  type bajty_t is array (0 to 63) of std_logic_vector(7 downto 0);
  signal clk : std_logic := '0';
  signal fin : boolean := false;
  signal rst : std_logic := '1';
  signal bl_a, bl_t, bl_h, bl_m : integer := 0;               -- błędy z poszczególnych procesów
  signal ok_a, ok_t, ok_h : boolean := false;
  -- LIS2DH12
  signal a_sclk, a_mosi, a_cs_n, a_nowe, a_id_ok : std_logic;
  signal a_miso   : std_logic := '0';
  signal ax, ay, az : std_logic_vector(15 downto 0);
  signal a_who    : std_logic_vector(7 downto 0);
  signal zestaw   : integer := 0;                             -- który zestaw wartości X, Y, Z
  signal reg20, reg23 : std_logic_vector(7 downto 0);
  signal n_a      : integer := 0;
  -- LM71
  signal t_sc, t_cs_n, t_nowe : std_logic;
  signal t_temp   : std_logic_vector(13 downto 0);
  signal t_c      : std_logic_vector(8 downto 0);
  signal lm_wart  : std_logic_vector(15 downto 0) := x"0000";
  signal lm_sio   : std_logic := '0';
  signal n_t      : integer := 0;
  -- HDC1000
  signal h_scl_oe, h_sda_oe, h_nowe : std_logic;
  signal h_temp, h_wilg : std_logic_vector(15 downto 0);
  signal h_c      : std_logic_vector(8 downto 0);
  signal h_proc   : std_logic_vector(6 downto 0);
  signal h_nacki  : std_logic_vector(7 downto 0);
  signal m_sda_oe : std_logic := '0';
  signal scl, sda : std_logic;
  signal h_t      : std_logic_vector(15 downto 0) := x"6667";
  signal h_rh     : std_logic_vector(15 downto 0) := x"8000";
  signal h_konf   : std_logic_vector(15 downto 0) := x"0000";
  signal h_odcz, n_h : integer := 0;

  function lm71_kod(setne_c : integer) return std_logic_vector is    -- 1/100 °C -> słowo LM71
  begin
    return std_logic_vector(to_signed((setne_c * 32) / 100, 14)) & "11";
  end function;
  function sint(v : std_logic_vector) return integer is
  begin
    return to_integer(signed(v));
  end function;
  function uint(v : std_logic_vector) return integer is
  begin
    return to_integer(unsigned(v));
  end function;
  function hx(v : std_logic_vector) return string is
    variable l : line;
  begin
    hwrite(l, v);
    return l.all;
  end function;
begin
  clk <= not clk after 10 ns when not fin else clk;

  process (clk)
  begin
    if rising_edge(clk) then
      if a_nowe = '1' then n_a <= n_a + 1; end if;
      if t_nowe = '1' then n_t <= n_t + 1; end if;
      if h_nowe = '1' then n_h <= n_h + 1; end if;
    end if;
  end process;

  -- ================= LIS2DH12
  u_akc : entity work.akcel_lis2dh12 generic map (DIV => 4, CZEKAJ => 100, OKRES => 3000)
    port map (clk => clk, rst => rst, sclk => a_sclk, mosi => a_mosi, miso => a_miso, cs_n => a_cs_n,
              x => ax, y => ay, z => az, nowe => a_nowe, who_am_i => a_who, id_ok => a_id_ok);

  lis : process
    variable r : bajty_t := (16#0F# => x"33", 16#20# => x"07", others => x"00");
    variable nb, nbit : integer := 0;
    variable czyt, ms_b : std_logic := '0';
    variable adr  : integer range 0 to 63 := 0;
    variable bajt, wyj : std_logic_vector(7 downto 0) := x"00";
    variable l    : line;
    variable xyz  : std_logic_vector(47 downto 0);
  begin
    wait on a_cs_n, a_sclk, zestaw;
    if zestaw = 0 then xyz := x"4000" & x"FED0" & x"1230"; else xyz := x"0010" & x"7FF0" & x"8000"; end if;
    for i in 0 to 5 loop
      r(16#28# + i) := xyz(8 * i + 7 downto 8 * i);
    end loop;
    if falling_edge(a_cs_n) then
      nb := 0; nbit := 0;
      if a_sclk /= '1' then
        write(l, string'("LIS2DH12: SCLK niski przy CS (tryb 3 wymaga wysokiego)")); writeline(output, l);
        bl_m <= bl_m + 1;
      end if;
    elsif falling_edge(a_sclk) and a_cs_n = '0' and nb > 0 and czyt = '1' then   -- wystawienie bitu
      if nbit = 0 then wyj := r(adr); end if;
      a_miso <= wyj(7 - nbit);
    elsif rising_edge(a_sclk) and a_cs_n = '0' then                                -- próbkowanie MOSI
      bajt := bajt(6 downto 0) & a_mosi;
      nbit := nbit + 1;
      if nbit = 8 then
        nbit := 0;
        if nb = 0 then
          czyt := bajt(7); ms_b := bajt(6); adr := uint(bajt(5 downto 0));
        else
          if czyt = '0' then r(adr) := bajt; end if;
          if ms_b = '1' then adr := (adr + 1) mod 64; end if;
        end if;
        nb := nb + 1;
      end if;
    end if;
    reg20 <= r(16#20#);
    reg23 <= r(16#23#);
  end process;

  -- ================= LM71
  u_lm : entity work.temp_lm71 generic map (DIV => 5, OKRES => 2000)
    port map (clk => clk, rst => rst, sc => t_sc, sio => lm_sio, cs_n => t_cs_n, temp => t_temp, temp_c => t_c,
              nowe => t_nowe);

  process (t_cs_n, t_sc)
    variable sr : std_logic_vector(15 downto 0) := x"0000";
  begin
    if falling_edge(t_cs_n) then
      sr := lm_wart;
    elsif falling_edge(t_sc) and t_cs_n = '0' then
      sr := sr(14 downto 0) & '1';
    end if;
    lm_sio <= sr(15);
  end process;

  -- ================= HDC1000
  scl <= not h_scl_oe;
  sda <= '0' when h_sda_oe = '1' or m_sda_oe = '1' else '1';
  u_hdc : entity work.hdc1000 generic map (ADR => "1000000", DIV => 10, CZEKAJ => 5000, OKRES => 20000)
    port map (clk => clk, rst => rst, scl_i => scl, scl_oe => h_scl_oe, sda_i => sda, sda_oe => h_sda_oe,
              temp_sur => h_temp, wilg_sur => h_wilg, temp_c => h_c, wilg_proc => h_proc, nowe => h_nowe,
              nacki => h_nacki);

  hdc : process
    variable tryb, n, nd : integer := 0;
    variable ptr, bajt   : std_logic_vector(7 downto 0) := x"00";
    variable wyj         : std_logic_vector(31 downto 0) := (others => '0');
    variable rw, mack    : std_logic := '0';
    variable gotowy      : boolean := false;
    variable t_pomiar    : time := 0 ns;
    variable konf        : std_logic_vector(15 downto 0) := x"0000";
  begin
    wait on scl, sda;
    if sda'event and scl = '1' then
      if sda = '0' then                                          -- START
        tryb := 1; n := 0;
      else                                                       -- STOP
        if tryb = 2 and nd = 1 and ptr = x"00" then             -- sam wskaźnik 0x00: wyzwolenie pomiaru
          gotowy   := false;
          t_pomiar := now;
        end if;
        tryb := 0; m_sda_oe <= '0';
      end if;
    elsif rising_edge(scl) then
      if tryb = 1 or tryb = 2 then
        if n < 8 then bajt := bajt(6 downto 0) & sda; end if;
        n := n + 1;
      elsif tryb = 3 then
        if n = 8 then mack := sda; end if;
        n := n + 1;
      end if;
    elsif falling_edge(scl) then
      if not gotowy and now - t_pomiar > 200 us then gotowy := true; end if;   -- pomiar trwa 200 µs
      if (tryb = 1 or tryb = 2) and n = 8 then
        if tryb = 1 then
          if bajt(7 downto 1) = "1000000" and (bajt(0) = '0' or gotowy) then
            m_sda_oe <= '1'; rw := bajt(0);
          else
            tryb := 0;                                           -- NACK (inny adres albo pomiar trwa)
          end if;
        else
          if nd = 0 then
            ptr := bajt;
          elsif ptr = x"02" then
            if nd = 1 then konf(15 downto 8) := bajt; else konf(7 downto 0) := bajt; end if;
          end if;
          nd := nd + 1;
          m_sda_oe <= '1';
        end if;
      elsif n = 9 and tryb /= 0 then
        m_sda_oe <= '0';
        n := 0;
        if tryb = 1 then
          if rw = '1' then
            tryb := 3; wyj := h_t & h_rh; h_odcz <= h_odcz + 1;
            m_sda_oe <= not wyj(31);
          else
            tryb := 2; nd := 0;
          end if;
        elsif tryb = 3 then
          if mack = '0' then
            wyj := wyj(23 downto 0) & x"00";
            m_sda_oe <= not wyj(31);
          else
            tryb := 0;
          end if;
        end if;
      elsif tryb = 3 and n >= 1 and n <= 7 then
        m_sda_oe <= not wyj(31 - n);
      elsif tryb = 3 and n = 8 then
        m_sda_oe <= '0';
      end if;
    end if;
    h_konf <= konf;
  end process;

  -- ================= sprawdzanie (trzy niezależne procesy)
  process
    variable l : line;
  begin
    wait until n_a = 1;
    wait until falling_edge(clk);
    if a_who /= x"33" or a_id_ok /= '1' then
      write(l, "WHO_AM_I = " & hx(a_who)); writeline(output, l); bl_a <= bl_a + 1;
    end if;
    if reg20 /= x"57" or reg23 /= x"88" then
      write(l, "LIS2DH12: CTRL_REG1 = " & hx(reg20) & ", CTRL_REG4 = " & hx(reg23)); writeline(output, l);
      bl_a <= bl_a + 1;
    end if;
    if ax /= x"1230" or ay /= x"FED0" or az /= x"4000" then
      write(l, "LIS2DH12: x=" & hx(ax) & " y=" & hx(ay) & " z=" & hx(az)); writeline(output, l);
      bl_a <= bl_a + 1;
    end if;
    zestaw <= 1;
    wait until n_a = 2;
    wait until falling_edge(clk);
    if ax /= x"8000" or ay /= x"7FF0" or az /= x"0010" then
      write(l, "LIS2DH12 (2): x=" & hx(ax) & " y=" & hx(ay) & " z=" & hx(az)); writeline(output, l);
      bl_a <= bl_a + 1;
    end if;
    ok_a <= true;
    wait;
  end process;

  process
    variable l : line;
  begin
    lm_wart <= lm71_kod(2506);                                   -- 25,06 °C -> 801 = 25,03125 °C
    wait until n_t = 1;
    wait until falling_edge(clk);
    if sint(t_c) /= 25 then
      write(l, "LM71: " & integer'image(sint(t_c)) & " C"); writeline(output, l); bl_t <= bl_t + 1;
    end if;
    lm_wart <= lm71_kod(-1050);                                  -- −10,5 °C
    wait until n_t = 2;
    wait until falling_edge(clk);
    if sint(t_c) /= -11 or sint(t_temp) /= -336 then
      write(l, "LM71 (2): " & integer'image(sint(t_c)) & " C, surowe " & integer'image(sint(t_temp)));
      writeline(output, l);
      bl_t <= bl_t + 1;
    end if;
    ok_t <= true;
    wait;
  end process;

  process
    variable l : line;
  begin
    wait until n_h = 1;
    wait until falling_edge(clk);
    write(l, "HDC1000: konfiguracja " & hx(h_konf) & ", temperatura " & integer'image(sint(h_c)) & " C, wilgotnosc "
          & integer'image(uint(h_proc)) & " %, NACK " & integer'image(uint(h_nacki)) & ", odczytow "
          & integer'image(h_odcz));
    writeline(output, l);
    if h_konf /= x"1000" or h_temp /= x"6667" or h_wilg /= x"8000" or sint(h_c) /= 26 or uint(h_proc) /= 50
       or uint(h_nacki) = 0 then
      bl_h <= bl_h + 1;
    end if;
    h_t  <= x"0000";                                             -- −40 °C, 99 %
    h_rh <= x"FFFF";
    wait until n_h = 2;
    wait until falling_edge(clk);
    if sint(h_c) /= -40 or uint(h_proc) /= 99 then
      write(l, "HDC1000 (2): " & integer'image(sint(h_c)) & " C, " & integer'image(uint(h_proc)) & " %");
      writeline(output, l);
      bl_h <= bl_h + 1;
    end if;
    ok_h <= true;
    wait;
  end process;

  process
    variable l : line;
    variable errors : integer;
  begin
    for q in 1 to 5 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    wait until ok_a and ok_t and ok_h;
    write(l, "LIS2DH12: WHO_AM_I " & hx(a_who) & ", odczyty XYZ " & integer'image(n_a) & "; LM71: "
          & integer'image(sint(t_c)) & " C; HDC1000: " & integer'image(sint(h_c)) & " C, "
          & integer'image(uint(h_proc)) & " %");
    writeline(output, l);
    errors := bl_a + bl_t + bl_h + bl_m;
    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
