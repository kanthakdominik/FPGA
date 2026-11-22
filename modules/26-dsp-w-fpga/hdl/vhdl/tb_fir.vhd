-- Testbench 26.01: fir_transp i fir_sym (N = 31). 2048 próbek z fir_we.hex podawanych z przerwami
-- (co siódma próbka takt przerwy); wyniki obu filtrów bit w bit z fir_wy.hex (model Pythona) i opóźnienia.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wektory_pkg.all;

entity tb_fir is
end entity tb_fir;

architecture sim of tb_fir is
  constant HW  : wektor_t := czytaj_hex("fir_wsp.hex", 31, 16);
  constant XW  : wektor_t := czytaj_hex("fir_we.hex", 2048, 16);
  constant YW  : wektor_t := czytaj_hex("fir_wy.hex", 2048, 16);
  function pakuj return std_logic_vector is
    variable r : std_logic_vector(16 * 31 - 1 downto 0);
  begin
    for i in 0 to 30 loop
      r(16 * i + 15 downto 16 * i) := HW(i)(15 downto 0);
    end loop;
    return r;
  end function;
  constant WSP    : std_logic_vector(16 * 31 - 1 downto 0) := pakuj;
  signal clk      : std_logic := '0';
  signal fin      : boolean := false;
  signal rst      : std_logic := '1';
  signal we       : std_logic := '0';
  signal x        : signed(15 downto 0) := (others => '0');
  signal yt, ys   : signed(15 downto 0);
  signal vt, vs   : std_logic;
  signal takt, t0 : integer := 0;
  signal n_t, n_s, bt, bs, lt, ls : integer := 0;
begin
  clk  <= not clk after 5 ns when not fin else clk;
  takt <= takt + 1 when rising_edge(clk);
  u_t : entity work.fir_transp generic map (N => 31) port map (clk, rst, we, x, WSP, yt, vt);
  u_s : entity work.fir_sym    generic map (N => 31) port map (clk, rst, we, x, WSP, ys, vs);

  process (clk)
  begin
    if rising_edge(clk) and rst = '0' then
      if vt = '1' then
        if std_logic_vector(yt) /= YW(n_t)(15 downto 0) then
          if bt < 5 then pisz("fir_transp: probka " & integer'image(n_t) & ": " & integer'image(to_integer(yt))); end if;
          bt <= bt + 1;
        end if;
        if n_t = 0 then lt <= takt - t0; end if;
        n_t <= n_t + 1;
      end if;
      if vs = '1' then
        if std_logic_vector(ys) /= YW(n_s)(15 downto 0) then
          if bs < 5 then pisz("fir_sym: probka " & integer'image(n_s) & ": " & integer'image(to_integer(ys))); end if;
          bs <= bs + 1;
        end if;
        if n_s = 0 then ls <= takt - t0; end if;
        n_s <= n_s + 1;
      end if;
    end if;
  end process;

  process
  begin
    for i in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    for i in 0 to 2047 loop
      wait until falling_edge(clk);
      x <= signed(XW(i)(15 downto 0)); we <= '1';
      if i = 0 then t0 <= takt; end if;
      if i mod 7 = 6 then
        wait until falling_edge(clk);
        we <= '0';
      end if;
    end loop;
    wait until falling_edge(clk);
    we <= '0';
    for i in 1 to 20 loop wait until falling_edge(clk); end loop;
    pisz("fir_transp: " & integer'image(n_t) & " probek, niezgodnych z modelem " & integer'image(bt)
         & ", opoznienie " & integer'image(lt) & " takt(y)");
    pisz("fir_sym:    " & integer'image(n_s) & " probek, niezgodnych z modelem " & integer'image(bs)
         & ", opoznienie " & integer'image(ls) & " takt(y)");
    if n_t = 2048 and n_s = 2048 and bt = 0 and bs = 0 then pisz("PASS");
    else pisz("FAIL: niezgodnosci z modelem"); end if;
    fin <= true;
    wait;
  end process;
end architecture sim;
