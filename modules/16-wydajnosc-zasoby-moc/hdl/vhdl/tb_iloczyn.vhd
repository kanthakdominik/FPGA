-- Testbench iloczyn_rown i iloczyn_szer: te same losowe wektory. Równoległa - wynik po 2 taktach dla
-- każdych danych; szeregowa - dane przy ready = '1', wynik z done. Sprawdzane: wyniki zgodne z modelem,
-- przy ciągłym starcie szeregowa daje wynik co 4 takty.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_iloczyn is
end entity tb_iloczyn;

architecture sim of tb_iloczyn is
  constant N : positive := 400;
  type kol_t is array (0 to 1023) of unsigned(17 downto 0);

  signal clk, rst      : std_logic := '1';
  signal a, b          : std_logic_vector(31 downto 0) := (others => '0');
  signal vin, start    : std_logic := '0';
  signal vout, ready, done : std_logic;
  signal y_rown, y_szer : std_logic_vector(17 downto 0);
  signal q_r, q_s      : kol_t;
  signal wr_r, wr_s, takt : natural := 0;
  signal fin           : boolean := false;

  function model(fa, fb : std_logic_vector(31 downto 0)) return unsigned is
    variable s : unsigned(17 downto 0) := (others => '0');
  begin
    for k in 0 to 3 loop
      s := s + resize(unsigned(fa(8 * k + 7 downto 8 * k)) * unsigned(fb(8 * k + 7 downto 8 * k)), 18);
    end loop;
    return s;
  end function;
begin
  clk <= not clk after 5 ns when not fin else clk;

  u_r : entity work.iloczyn_rown
    port map (clk => clk, rst => rst, in_valid => vin, a => a, b => b, out_valid => vout, y => y_rown);
  u_s : entity work.iloczyn_szer
    port map (clk => clk, rst => rst, start => start, a => a, b => b, ready => ready, done => done, y => y_szer);

  process (clk)
  begin
    if rising_edge(clk) and rst = '0' then
      takt <= takt + 1;
      if vin = '1' then
        q_r(wr_r mod 1024) <= model(a, b);
        wr_r <= wr_r + 1;
      end if;
      if start = '1' and ready = '1' then
        q_s(wr_s mod 1024) <= model(a, b);
        wr_s <= wr_s + 1;
      end if;
    end if;
  end process;

  process
    variable s1, s2 : positive := 3;
    variable r      : real;
    variable l      : line;
    variable errors, rd_r, rd_s, t_done, odst, odst_ok : integer := 0;
    impure function los32 return std_logic_vector is
      variable v : std_logic_vector(31 downto 0);
    begin
      uniform(s1, s2, r);
      if r < 1.0 / 6.0 then
        return x"FFFFFFFF";
      end if;
      for k in 0 to 3 loop
        uniform(s1, s2, r);
        v(8 * k + 7 downto 8 * k) := std_logic_vector(to_unsigned(integer(floor(r * 256.0)) mod 256, 8));
      end loop;
      return v;
    end function;
  begin
    wait for 23 ns;
    rst <= '0';
    while rd_s < N loop
      wait until falling_edge(clk);
      if vout = '1' then
        if unsigned(y_rown) /= q_r(rd_r mod 1024) then
          write(l, string'("rownolegly: zly wynik")); writeline(output, l);
          errors := errors + 1;
        end if;
        rd_r := rd_r + 1;
      end if;
      if done = '1' then
        if unsigned(y_szer) /= q_s(rd_s mod 1024) then
          write(l, string'("szeregowy: zly wynik")); writeline(output, l);
          errors := errors + 1;
        end if;
        if rd_s > 0 then
          odst := odst + 1;
          if takt - t_done = 4 then
            odst_ok := odst_ok + 1;
          end if;
        end if;
        t_done := takt;
        rd_s := rd_s + 1;
      end if;
      a <= los32;
      b <= los32;
      uniform(s1, s2, r);
      if r < 0.67 then vin <= '1'; else vin <= '0'; end if;
      uniform(s1, s2, r);
      if rd_s >= N / 2 or r < 0.33 then start <= '1'; else start <= '0'; end if;
    end loop;
    write(l, "rownolegly: " & integer'image(rd_r) & " wynikow, szeregowy: " & integer'image(rd_s)
          & " wynikow; odstep 4 takty: " & integer'image(odst_ok) & " z " & integer'image(odst));
    writeline(output, l);
    if errors = 0 and rd_r > N and odst_ok >= N / 2 - 2 then
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
