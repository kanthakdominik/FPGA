-- Testbench 26.02: biquad_df2t w trzech wariantach kwantyzacji (ZAOKR = 0, 1, 2). 2048 próbek z iir_we.hex;
-- wyniki bit w bit z iir_wy0/1/2.hex; największe |y| w ciszy po impulsie (800..1023) i po szumie (1900..2047).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wektory_pkg.all;

entity tb_iir is
end entity tb_iir;

architecture sim of tb_iir is
  constant CW  : wektor_t := czytaj_hex("iir_wsp.hex", 5, 16);
  constant XW  : wektor_t := czytaj_hex("iir_we.hex", 2048, 16);
  constant W0  : wektor_t := czytaj_hex("iir_wy0.hex", 2048, 16);
  constant W1  : wektor_t := czytaj_hex("iir_wy1.hex", 2048, 16);
  constant W2  : wektor_t := czytaj_hex("iir_wy2.hex", 2048, 16);
  constant B0  : signed(15 downto 0) := signed(CW(0)(15 downto 0));
  constant B1  : signed(15 downto 0) := signed(CW(1)(15 downto 0));
  constant B2  : signed(15 downto 0) := signed(CW(2)(15 downto 0));
  constant A1  : signed(15 downto 0) := signed(CW(3)(15 downto 0));
  constant A2  : signed(15 downto 0) := signed(CW(4)(15 downto 0));
  type y_t is array (0 to 2) of signed(15 downto 0);
  type i3_t is array (0 to 2) of integer;
  signal clk   : std_logic := '0';
  signal fin   : boolean := false;
  signal rst   : std_logic := '1';
  signal we    : std_logic := '0';
  signal x     : signed(15 downto 0) := (others => '0');
  signal yy    : y_t;
  signal vv    : std_logic_vector(0 to 2);
  signal n0    : integer := 0;
  signal bl, ca, cb : i3_t := (others => 0);
begin
  clk <= not clk after 5 ns when not fin else clk;
  gen : for k in 0 to 2 generate
    u : entity work.biquad_df2t generic map (ZAOKR => k) port map (clk, rst, we, x, B0, B1, B2, A1, A2, yy(k), vv(k));
  end generate;

  process (clk)
    variable ozn : std_logic_vector(15 downto 0);
    variable a   : integer;
  begin
    if rising_edge(clk) and rst = '0' and vv(0) = '1' then
      for k in 0 to 2 loop
        if k = 0 then ozn := W0(n0)(15 downto 0); elsif k = 1 then ozn := W1(n0)(15 downto 0);
        else ozn := W2(n0)(15 downto 0); end if;
        if std_logic_vector(yy(k)) /= ozn then
          if bl(k) < 5 then
            pisz("ZAOKR=" & integer'image(k) & ": probka " & integer'image(n0) & ": " & integer'image(to_integer(yy(k)))
                 & ", model " & integer'image(to_integer(signed(ozn))));
          end if;
          bl(k) <= bl(k) + 1;
        end if;
        a := abs(to_integer(yy(k)));
        if n0 >= 800 and n0 < 1024 and a > ca(k) then ca(k) <= a; end if;
        if n0 >= 1900 and a > cb(k) then cb(k) <= a; end if;
      end loop;
      n0 <= n0 + 1;
    end if;
  end process;

  process
  begin
    pisz("wspolczynniki Q2.14: b0 = " & integer'image(to_integer(B0)) & ", b1 = " & integer'image(to_integer(B1))
         & ", b2 = " & integer'image(to_integer(B2)) & ", a1 = " & integer'image(to_integer(A1))
         & ", a2 = " & integer'image(to_integer(A2)));
    for i in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    for i in 0 to 2047 loop
      wait until falling_edge(clk);
      x <= signed(XW(i)(15 downto 0)); we <= '1';
    end loop;
    wait until falling_edge(clk);
    we <= '0';
    for i in 1 to 5 loop wait until falling_edge(clk); end loop;
    for k in 0 to 2 loop
      pisz("ZAOKR=" & integer'image(k) & ": niezgodnych " & integer'image(bl(k)) & "; max |y| po impulsie "
           & integer'image(ca(k)) & ", po szumie " & integer'image(cb(k)));
    end loop;
    if n0 = 2048 and bl = (0, 0, 0) and ca(2) = 0 and cb(2) = 0 then pisz("PASS");
    else pisz("FAIL: niezgodnosci z modelem albo cykle graniczne przy ZAOKR=2"); end if;
    fin <= true;
    wait;
  end process;
end architecture sim;
