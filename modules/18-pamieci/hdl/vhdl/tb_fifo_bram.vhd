-- Testbench fifo_bram: wersje standardowa i FWFT na tym samym pobudzeniu w trzech fazach (przewaga
-- zapisów, przewaga odczytów, po równo). Sprawdzane: dane i kolejność, count, flagi, odrzucanie zapisu przy
-- full; pokrycie: każda flaga osiągnięta.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_fifo_bram is
end entity tb_fifo_bram;

architecture sim of tb_fifo_bram is
  constant W  : positive := 8;
  constant AW : positive := 4;
  constant DEPTH : positive := 2 ** AW;
  constant AF : natural := 12;
  constant AE : natural := 2;
  type kol_t is array (0 to 63) of std_logic_vector(W - 1 downto 0);
  signal clk, rst : std_logic := '1';
  signal wr_en, rd_en : std_logic := '0';
  signal din : std_logic_vector(W - 1 downto 0) := (others => '0');
  signal dout0, dout1 : std_logic_vector(W - 1 downto 0);
  signal full0, full1, af0, af1, empty0, empty1, ae0, ae1 : std_logic;
  signal cnt0, cnt1 : std_logic_vector(AW + 1 downto 0);
  signal fin : boolean := false;
begin
  clk <= not clk after 5 ns when not fin else clk;
  u0 : entity work.fifo_bram generic map (W => W, AW => AW, FWFT => false, AF => AF, AE => AE)
    port map (clk, rst, wr_en, din, full0, af0, rd_en, dout0, empty0, ae0, cnt0);
  u1 : entity work.fifo_bram generic map (W => W, AW => AW, FWFT => true, AF => AF, AE => AE)
    port map (clk, rst, wr_en, din, full1, af1, rd_en, dout1, empty1, ae1, cnt1);

  process
    variable s1, s2 : positive := 17;
    variable r : real;
    variable l : line;
    variable q0, q1 : kol_t;
    variable h0, t0, h1, t1, pw : integer := 0;
    variable errors, c_full0, c_full1, c_empty, c_af, c_ae, odrz : integer := 0;
    variable oczek0, dv : std_logic_vector(W - 1 downto 0);
    variable czekam0 : boolean := false;
    variable wv, rv : std_logic;
    variable c0, c1 : integer;
    procedure blad(co : string) is
    begin
      write(l, co); writeline(output, l);
      errors := errors + 1;
    end procedure;
    impure function los(n : positive) return natural is
    begin
      uniform(s1, s2, r);
      return integer(floor(r * real(n))) mod n;
    end function;
  begin
    wait for 23 ns;
    rst <= '0';
    for n in 0 to 5999 loop
      wait until falling_edge(clk);
      c0 := to_integer(unsigned(cnt0)); c1 := to_integer(unsigned(cnt1));
      if czekam0 and dout0 /= oczek0 then blad("std: zla dana"); end if;
      czekam0 := false;
      if c0 /= t0 - h0 then blad("std: count"); end if;
      if (empty0 = '1') /= (t0 = h0) then blad("std: empty"); end if;
      if (full0 = '1') /= (t0 - h0 = DEPTH) then blad("std: full"); end if;
      if c1 /= t1 - h1 then blad("fwft: count"); end if;
      if empty1 = '0' and dout1 /= q1(h1 mod 64) then blad("fwft: zla dana na wyjsciu"); end if;
      if full1 = '1' and t1 - h1 < DEPTH then blad("fwft: full za wczesnie"); end if;
      if (af0 = '1') /= (c0 >= AF) or (ae0 = '1') /= (c0 <= AE) then blad("std: almost"); end if;
      if (af1 = '1') /= (c1 >= AF) or (ae1 = '1') /= (c1 <= AE) then blad("fwft: almost"); end if;
      if full0 = '1' then c_full0 := c_full0 + 1; end if;
      if full1 = '1' then c_full1 := c_full1 + 1; end if;
      if empty0 = '1' and empty1 = '1' then c_empty := c_empty + 1; end if;
      if af0 = '1' then c_af := c_af + 1; end if;
      if ae0 = '1' then c_ae := c_ae + 1; end if;
      if n mod 1500 < 500 then pw := 80; elsif n mod 1500 < 1000 then pw := 20; else pw := 50; end if;
      if los(100) < pw then wv := '1'; else wv := '0'; end if;
      if los(100) < 100 - pw then rv := '1'; else rv := '0'; end if;
      dv := std_logic_vector(to_unsigned(los(256), W));
      wr_en <= wv; rd_en <= rv; din <= dv;
      if wv = '1' and full0 = '0' then q0(t0 mod 64) := dv; t0 := t0 + 1; end if;
      if wv = '1' and full0 = '1' then odrz := odrz + 1; end if;
      if rv = '1' and empty0 = '0' then oczek0 := q0(h0 mod 64); h0 := h0 + 1; czekam0 := true; end if;
      if wv = '1' and full1 = '0' then q1(t1 mod 64) := dv; t1 := t1 + 1; end if;
      if rv = '1' and empty1 = '0' then h1 := h1 + 1; end if;
    end loop;
    write(l, "slow: std " & integer'image(t0) & ", fwft " & integer'image(t1) & "; takty full "
          & integer'image(c_full0) & "/" & integer'image(c_full1) & ", empty " & integer'image(c_empty)
          & ", odrzucone " & integer'image(odrz));
    writeline(output, l);
    if errors = 0 and c_full0 > 0 and c_full1 > 0 and c_empty > 0 and c_af > 0 and c_ae > 0 and odrz > 0 then
      write(l, string'("PASS"));
    else
      write(l, "FAIL: " & integer'image(errors) & " bledow");
    end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
