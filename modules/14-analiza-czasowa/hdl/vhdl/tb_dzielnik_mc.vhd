-- Testbench dzielnik_mc: 300 dzieleń z losowymi argumentami (5 % z dzielnikiem 0), start także w trakcie
-- pracy (musi być zignorowany). Sprawdzane: wynik, opóźnienie dokładnie N taktów, q i r zmieniają się
-- tylko w takcie z done = '1' (warunek, na którym opiera się ograniczenie wielotaktowe).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_dzielnik_mc is
end entity tb_dzielnik_mc;

architecture sim of tb_dzielnik_mc is
  constant W : positive := 16;
  constant V : positive := 8;
  constant N : positive := 4;

  signal clk   : std_logic := '0';
  signal fin   : boolean   := false;
  signal rst   : std_logic := '1';
  signal start : std_logic := '0';
  signal a     : unsigned(W - 1 downto 0) := (others => '0');
  signal b     : unsigned(V - 1 downto 0) := (others => '0');
  signal busy  : std_logic;
  signal done  : std_logic;
  signal q     : unsigned(W - 1 downto 0);
  signal r     : unsigned(V - 1 downto 0);
  signal errs_stab : natural := 0;
begin
  clk <= not clk after 5 ns when not fin;

  dut : entity work.dzielnik_mc
    generic map (W => W, V => V, N => N)
    port map (clk => clk, rst => rst, start => start, a => a, b => b, busy => busy, done => done, q => q, r => r);

  -- wynik zmienia się tylko razem z done
  stab : process (clk)
    variable q_prev : unsigned(W - 1 downto 0);
    variable r_prev : unsigned(V - 1 downto 0);
  begin
    if falling_edge(clk) then
      if rst = '0' and done = '0' and
         (std_logic_vector(q) /= std_logic_vector(q_prev) or std_logic_vector(r) /= std_logic_vector(r_prev)) then
        errs_stab <= errs_stab + 1;
      end if;
      q_prev := q;
      r_prev := r;
    end if;
  end process;

  stim : process
    variable seed1, seed2 : positive := 14;
    variable x            : real;
    variable ea, eq       : unsigned(W - 1 downto 0);
    variable eb, er       : unsigned(V - 1 downto 0);
    variable lat          : natural;
    variable errors, n_zero, n_one, n_ignored : natural := 0;
    variable l            : line;

    impure function rnd(nb : positive) return unsigned is
    begin
      uniform(seed1, seed2, x);
      return to_unsigned(integer(floor(x * real(2 ** nb))), nb);
    end function;
  begin
    wait until falling_edge(clk);
    wait until falling_edge(clk);
    rst <= '0';
    for k in 0 to 299 loop
      ea := rnd(W);
      eb := rnd(V);
      uniform(seed1, seed2, x);
      if x < 0.05 then eb := (others => '0'); end if;
      if k mod 50 = 7 then eb := to_unsigned(1, V); end if;
      if eb = 0 then
        n_zero := n_zero + 1;
        eq     := (others => '1');
        er     := ea(V - 1 downto 0);
      else
        eq := ea / resize(eb, W);
        er := resize(ea mod resize(eb, W), V);
      end if;
      if eb = 1 then n_one := n_one + 1; end if;
      a <= ea; b <= eb; start <= '1';
      wait until falling_edge(clk);
      if busy /= '1' then
        report "start nieprzyjety" severity warning;
        errors := errors + 1;
      end if;
      lat := 0;
      loop
        uniform(seed1, seed2, x);
        if x < 0.25 then
          start <= '1'; a <= rnd(W); b <= rnd(V);
          n_ignored := n_ignored + 1;
        else
          start <= '0';
        end if;
        wait until falling_edge(clk);
        lat := lat + 1;
        exit when done = '1' or lat >= N + 2;
      end loop;
      start <= '0';
      if lat /= N or q /= eq or r /= er then
        report "op " & integer'image(k) & ": zly wynik albo opoznienie " & integer'image(lat) severity warning;
        errors := errors + 1;
      end if;
      uniform(seed1, seed2, x);
      for i in 1 to integer(floor(x * 3.0)) loop
        wait until falling_edge(clk);
      end loop;
    end loop;
    if n_zero = 0 or n_one = 0 or n_ignored = 0 then
      report "pokrycie niepelne" severity warning;
      errors := errors + 1;
    end if;
    errors := errors + errs_stab;
    write(l, "dzielen: 300, z b=0: " & integer'image(n_zero) & ", startow zignorowanych: " & integer'image(n_ignored));
    writeline(output, l);
    if errors = 0 then
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
