-- Testbench układów arytmetycznych: sumator pełny, sumator ripple-carry, sumator behawioralny, mnożarka.
-- Wszystkie kombinacje wejść dla W = 4, porównanie z arytmetyką liczb całkowitych.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_adders is
end entity tb_adders;

architecture sim of tb_adders is
  constant W : positive := 4;
  signal fa_a, fa_b, fa_c, fa_s, fa_co : std_logic;
  signal a, b                          : std_logic_vector(W - 1 downto 0);
  signal cin                           : std_logic;
  signal s_rca, s_beh                  : std_logic_vector(W - 1 downto 0);
  signal co_rca, co_beh                : std_logic;
  signal p                             : std_logic_vector(2 * W - 1 downto 0);
begin
  u_fa : entity work.full_adder
    port map (a => fa_a, b => fa_b, cin => fa_c, s => fa_s, cout => fa_co);
  u_rca : entity work.rca_adder
    generic map (W => W)
    port map (a => a, b => b, cin => cin, s => s_rca, cout => co_rca);
  u_beh : entity work.adder
    generic map (W => W)
    port map (a => a, b => b, cin => cin, s => s_beh, cout => co_beh);
  u_mul : entity work.mult
    generic map (W => W)
    port map (a => a, b => b, p => p);

  stim : process
    variable errors : natural := 0;
    variable l      : line;
    variable bits   : unsigned(2 downto 0);
    variable suma   : integer;
    variable wynik  : unsigned(1 downto 0);
    variable c_bit  : unsigned(0 downto 0);

    procedure check(ok : boolean; msg : string) is
    begin
      if not ok then
        errors := errors + 1;
        report msg severity warning;
      end if;
    end procedure;
  begin
    -- sumator pełny: 8 kombinacji
    for i in 0 to 7 loop
      bits := to_unsigned(i, 3);
      fa_a <= bits(2); fa_b <= bits(1); fa_c <= bits(0);
      wait for 1 ns;
      suma := to_integer(bits(2 downto 2)) + to_integer(bits(1 downto 1)) + to_integer(bits(0 downto 0));
      wynik := to_unsigned(suma, 2);
      check(fa_s = wynik(0) and fa_co = wynik(1),
            "full_adder: zly wynik dla wejscia " & integer'image(i));
    end loop;

    -- sumatory i mnożarka: wszystkie a, b (i cin dla sumatorów)
    for c in 0 to 1 loop
      for i in 0 to 2 ** W - 1 loop
        for j in 0 to 2 ** W - 1 loop
          a   <= std_logic_vector(to_unsigned(i, W));
          b   <= std_logic_vector(to_unsigned(j, W));
          c_bit := to_unsigned(c, 1);
          cin <= c_bit(0);
          wait for 1 ns;
          suma := i + j + c;
          check(unsigned(co_rca & s_rca) = to_unsigned(suma, W + 1),
                "rca_adder: " & integer'image(i) & "+" & integer'image(j) & "+" & integer'image(c));
          check(unsigned(co_beh & s_beh) = to_unsigned(suma, W + 1),
                "adder: " & integer'image(i) & "+" & integer'image(j) & "+" & integer'image(c));
          check(unsigned(p) = to_unsigned(i * j, 2 * W),
                "mult: " & integer'image(i) & "*" & integer'image(j));
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
