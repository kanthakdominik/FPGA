-- Testbench ALU: wszystkie operacje i wszystkie pary argumentów 4-bitowych, model na liczbach całkowitych.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_alu is
end entity tb_alu;

architecture sim of tb_alu is
  constant W     : positive := 4;
  constant M     : natural  := 2 ** W;
  signal a, b, y : std_logic_vector(W - 1 downto 0);
  signal op      : std_logic_vector(2 downto 0);
  signal carry   : std_logic;
  signal zero    : std_logic;
begin
  dut : entity work.alu
    generic map (W => W)
    port map (a => a, b => b, op => op, y => y, carry => carry, zero => zero);

  stim : process
    variable errors : natural := 0;
    variable l      : line;
    variable ey, ec : natural;
    variable ua, ub : unsigned(W - 1 downto 0);
    procedure check(ok : boolean; msg : string) is
    begin
      if not ok then
        errors := errors + 1;
        report msg severity warning;
      end if;
    end procedure;
  begin
    for o in 0 to 7 loop
      for i in 0 to M - 1 loop
        for j in 0 to M - 1 loop
          ua := to_unsigned(i, W);
          ub := to_unsigned(j, W);
          a  <= std_logic_vector(ua);
          b  <= std_logic_vector(ub);
          op <= std_logic_vector(to_unsigned(o, 3));
          wait for 1 ns;
          ec := 0;
          case o is
            when 0 => ey := (i + j) mod M;     ec := (i + j) / M;
            when 1 => ey := (i - j + M) mod M; if i >= j then ec := 1; end if;
            when 2 => ey := to_integer(ua and ub);
            when 3 => ey := to_integer(ua or ub);
            when 4 => ey := to_integer(ua xor ub);
            when 5 => ey := (2 * i) mod M;     ec := i / (M / 2);
            when 6 => ey := i / 2;             ec := i mod 2;
            when others => ey := j;
          end case;
          check(to_integer(unsigned(y)) = ey, "y: op=" & integer'image(o) & " a=" & integer'image(i) & " b=" & integer'image(j));
          check((carry = '1') = (ec = 1), "carry: op=" & integer'image(o) & " a=" & integer'image(i) & " b=" & integer'image(j));
          check((zero = '1') = (ey = 0), "zero: op=" & integer'image(o) & " a=" & integer'image(i) & " b=" & integer'image(j));
        end loop;
      end loop;
    end loop;

    if errors = 0 then
      write(l, string'("PASS"));
    else
      write(l, "FAIL: " & integer'image(errors) & " bledow");
    end if;
    writeline(output, l);
    std.env.finish;
    wait;
  end process stim;
end architecture sim;
