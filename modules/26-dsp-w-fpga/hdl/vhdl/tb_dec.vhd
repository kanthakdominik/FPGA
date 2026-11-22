-- Testbench 26.04: cic_dec (N = 3, R = 8) i pf_dec (32 współczynniki, decymacja przez 4). 4096 próbek
-- z dec_we.hex, jedna co 16 taktów; wyniki bit w bit z cic_wy.hex i pfd_wy.hex, zakres tonów po decymacji.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wektory_pkg.all;

entity tb_dec is
end entity tb_dec;

architecture sim of tb_dec is
  constant XW  : wektor_t := czytaj_hex("dec_we.hex", 4096, 16);
  constant CW  : wektor_t := czytaj_hex("cic_wy.hex", 512, 16);
  constant HW  : wektor_t := czytaj_hex("pfd_wsp.hex", 32, 16);
  constant PW  : wektor_t := czytaj_hex("pfd_wy.hex", 1024, 16);
  function pakuj return std_logic_vector is
    variable r : std_logic_vector(16 * 32 - 1 downto 0);
  begin
    for i in 0 to 31 loop
      r(16 * i + 15 downto 16 * i) := HW(i)(15 downto 0);
    end loop;
    return r;
  end function;
  constant WSP   : std_logic_vector(16 * 32 - 1 downto 0) := pakuj;
  signal clk     : std_logic := '0';
  signal fin     : boolean := false;
  signal rst     : std_logic := '1';
  signal we      : std_logic := '0';
  signal x       : signed(15 downto 0) := (others => '0');
  signal yc, yp  : signed(15 downto 0);
  signal vc, vp  : std_logic;
  signal n_c, n_p, bc, bp, cmin, cmax, pmin, pmax : integer := 0;
begin
  clk <= not clk after 5 ns when not fin else clk;
  u_cic : entity work.cic_dec generic map (R => 8) port map (clk, rst, we, x, yc, vc);
  u_pf  : entity work.pf_dec generic map (N => 32) port map (clk, rst, we, x, WSP, yp, vp);

  process (clk)
  begin
    if rising_edge(clk) and rst = '0' then
      if vc = '1' then
        if std_logic_vector(yc) /= CW(n_c)(15 downto 0) then
          if bc < 5 then pisz("cic: probka " & integer'image(n_c) & ": " & integer'image(to_integer(yc))); end if;
          bc <= bc + 1;
        end if;
        if n_c >= 300 and to_integer(yc) > cmax then cmax <= to_integer(yc); end if;
        if n_c >= 300 and to_integer(yc) < cmin then cmin <= to_integer(yc); end if;
        n_c <= n_c + 1;
      end if;
      if vp = '1' then
        if std_logic_vector(yp) /= PW(n_p)(15 downto 0) then
          if bp < 5 then pisz("pf_dec: probka " & integer'image(n_p) & ": " & integer'image(to_integer(yp))); end if;
          bp <= bp + 1;
        end if;
        if n_p >= 600 and to_integer(yp) > pmax then pmax <= to_integer(yp); end if;
        if n_p >= 600 and to_integer(yp) < pmin then pmin <= to_integer(yp); end if;
        n_p <= n_p + 1;
      end if;
    end if;
  end process;

  process
  begin
    for i in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    for i in 0 to 4095 loop
      wait until falling_edge(clk);
      x <= signed(XW(i)(15 downto 0)); we <= '1';
      wait until falling_edge(clk);
      we <= '0';
      for j in 1 to 14 loop wait until falling_edge(clk); end loop;
    end loop;
    for i in 1 to 60 loop wait until falling_edge(clk); end loop;
    pisz("cic_dec: " & integer'image(n_c) & " probek, niezgodnych " & integer'image(bc) & "; tony po decymacji: "
         & integer'image(cmin) & ".." & integer'image(cmax));
    pisz("pf_dec:  " & integer'image(n_p) & " probek, niezgodnych " & integer'image(bp) & "; tony po decymacji: "
         & integer'image(pmin) & ".." & integer'image(pmax));
    if n_c = 512 and n_p = 1024 and bc = 0 and bp = 0 then pisz("PASS");
    else pisz("FAIL: niezgodnosci z modelem"); end if;
    fin <= true;
    wait;
  end process;
end architecture sim;
