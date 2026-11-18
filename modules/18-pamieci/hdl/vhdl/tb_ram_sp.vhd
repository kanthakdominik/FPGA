-- Testbench ram_sp: trzy tryby (READ_FIRST, WRITE_FIRST, NO_CHANGE) na tych samych losowych operacjach;
-- model pamięci w testbenchu, sprawdzane wyjście po każdym takcie (także przy zapisie).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_ram_sp is
end entity tb_ram_sp;

architecture sim of tb_ram_sp is
  constant W  : positive := 8;
  constant AW : positive := 4;
  type mem_t is array (0 to 2 ** AW - 1) of std_logic_vector(W - 1 downto 0);
  signal clk  : std_logic := '0';
  signal we   : std_logic := '0';
  signal addr : std_logic_vector(AW - 1 downto 0) := (others => '0');
  signal din  : std_logic_vector(W - 1 downto 0) := (others => '0');
  signal d0, d1, d2 : std_logic_vector(W - 1 downto 0);
  signal fin  : boolean := false;
begin
  clk <= not clk after 5 ns when not fin else clk;
  u0 : entity work.ram_sp generic map (W => W, AW => AW, TRYB => 0) port map (clk, we, addr, din, d0);
  u1 : entity work.ram_sp generic map (W => W, AW => AW, TRYB => 1) port map (clk, we, addr, din, d1);
  u2 : entity work.ram_sp generic map (W => W, AW => AW, TRYB => 2) port map (clk, we, addr, din, d2);

  process
    variable s1, s2 : positive := 3;
    variable r : real;
    variable l : line;
    variable model : mem_t;
    variable e0, e1, e2, dv : std_logic_vector(W - 1 downto 0);
    variable a : natural;
    variable errors, n_zap : integer := 0;
    variable wv : std_logic;
    impure function los(n : positive) return natural is
    begin
      uniform(s1, s2, r);
      return integer(floor(r * real(n))) mod n;
    end function;
  begin
    for i in 0 to 2 ** AW - 1 loop
      wait until falling_edge(clk);
      dv := std_logic_vector(to_unsigned(los(256), W));
      we <= '1'; addr <= std_logic_vector(to_unsigned(i, AW)); din <= dv;
      model(i) := dv;
    end loop;
    wait until falling_edge(clk);
    we <= '0'; addr <= (others => '0');
    wait until falling_edge(clk);
    e2 := model(0);
    for n in 1 to 2000 loop
      wait until falling_edge(clk);
      if los(3) = 0 then wv := '1'; else wv := '0'; end if;
      a  := los(2 ** AW);
      dv := std_logic_vector(to_unsigned(los(256), W));
      we <= wv; addr <= std_logic_vector(to_unsigned(a, AW)); din <= dv;
      e0 := model(a);
      if wv = '1' then e1 := dv; else e1 := model(a); e2 := model(a); end if;
      if wv = '1' then model(a) := dv; n_zap := n_zap + 1; end if;
      wait until rising_edge(clk);
      wait for 1 ns;
      if d0 /= e0 or d1 /= e1 or d2 /= e2 then
        write(l, "takt " & integer'image(n) & ": niezgodne wyjscie"); writeline(output, l);
        errors := errors + 1;
      end if;
    end loop;
    if errors = 0 and n_zap > 400 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
