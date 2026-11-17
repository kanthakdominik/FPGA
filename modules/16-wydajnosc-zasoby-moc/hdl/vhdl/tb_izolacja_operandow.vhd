-- Testbench izolacja_operandow: ISO = false i true na tym samym strumieniu (dane ważne co czwarty takt,
-- w pozostałych śmieci). Sprawdzane: iloczyny zgodne z modelem; przełączenia bitów rejestru iloczynu
-- w wersji z izolacją co najmniej 3 razy rzadsze.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_izolacja_operandow is
end entity tb_izolacja_operandow;

architecture sim of tb_izolacja_operandow is
  constant W : positive := 16;
  type kol_t is array (0 to 4095) of std_logic_vector(2 * W - 1 downto 0);
  signal clk, rst : std_logic := '1';
  signal vin      : std_logic := '0';
  signal a, b     : std_logic_vector(W - 1 downto 0) := (others => '0');
  signal v0, v1   : std_logic;
  signal p0, p1   : std_logic_vector(2 * W - 1 downto 0);
  signal q        : kol_t;
  signal wr       : natural := 0;
  signal fin      : boolean := false;
begin
  clk <= not clk after 5 ns when not fin else clk;

  u0 : entity work.izolacja_operandow generic map (W => W, ISO => false)
    port map (clk => clk, rst => rst, in_valid => vin, a => a, b => b, out_valid => v0, p => p0);
  u1 : entity work.izolacja_operandow generic map (W => W, ISO => true)
    port map (clk => clk, rst => rst, in_valid => vin, a => a, b => b, out_valid => v1, p => p1);

  process (clk)
  begin
    if rising_edge(clk) and rst = '0' and vin = '1' then
      q(wr mod 4096) <= std_logic_vector(unsigned(a) * unsigned(b));
      wr <= wr + 1;
    end if;
  end process;

  process
    variable s1, s2 : positive := 13;
    variable r      : real;
    variable l      : line;
    variable errors, rd, t0, t1 : integer := 0;
    variable p0_d, p1_d, x : std_logic_vector(2 * W - 1 downto 0) := (others => '0');
  begin
    wait for 23 ns;
    rst <= '0';
    for n in 1 to 4000 loop
      wait until falling_edge(clk);
      if v0 /= v1 then
        write(l, string'("out_valid rozne")); writeline(output, l);
        errors := errors + 1;
      end if;
      if v0 = '1' then
        if p0 /= q(rd mod 4096) or p1 /= q(rd mod 4096) then
          write(l, "iloczyn " & integer'image(rd) & " niezgodny z modelem"); writeline(output, l);
          errors := errors + 1;
        end if;
        rd := rd + 1;
      end if;
      -- przełączenia bitów rejestru iloczynu
      x := p0 xor p0_d;
      for k in x'range loop
        if x(k) = '1' then t0 := t0 + 1; end if;
      end loop;
      x := p1 xor p1_d;
      for k in x'range loop
        if x(k) = '1' then t1 := t1 + 1; end if;
      end loop;
      p0_d := p0;
      p1_d := p1;
      if n mod 4 = 0 then vin <= '1'; else vin <= '0'; end if;
      uniform(s1, s2, r);
      a <= std_logic_vector(to_unsigned(integer(floor(r * 65536.0)) mod 65536, W));
      uniform(s1, s2, r);
      b <= std_logic_vector(to_unsigned(integer(floor(r * 65536.0)) mod 65536, W));
    end loop;
    write(l, "iloczynow: " & integer'image(rd) & "; przelaczen bitow iloczynu: bez izolacji " & integer'image(t0)
          & ", z izolacja " & integer'image(t1));
    writeline(output, l);
    if errors = 0 and rd > 900 and t1 * 3 < t0 then
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
