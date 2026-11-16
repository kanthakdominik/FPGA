-- Testbench operacji bitowych: wszystkie 256 wartości, model z pętli po bitach.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_bit_tricks is
end entity tb_bit_tricks;

architecture sim of tb_bit_tricks is
  constant W : positive := 8;
  signal x, lowest, rev : std_logic_vector(W - 1 downto 0);
  signal is_pow2, parity, all_ones : std_logic;
begin
  dut : entity work.bit_tricks
    generic map (W => W)
    port map (x => x, is_pow2 => is_pow2, lowest => lowest, rev => rev, parity => parity, all_ones => all_ones);

  stim : process
    variable errors : natural := 0;
    variable l      : line;
    variable v, r, low : std_logic_vector(W - 1 downto 0);
    variable ones   : natural;
    procedure check(ok : boolean; msg : string) is
    begin
      if not ok then
        errors := errors + 1;
        report msg severity warning;
      end if;
    end procedure;
  begin
    for i in 0 to 2 ** W - 1 loop
      v := std_logic_vector(to_unsigned(i, W));
      x <= v;
      wait for 1 ns;
      ones := 0;
      low  := (others => '0');
      for k in W - 1 downto 0 loop
        if v(k) = '1' then
          ones := ones + 1;
          low  := (others => '0');
          low(k) := '1';                         -- pętla od góry: zostaje najmłodsza jedynka
        end if;
        r(W - 1 - k) := v(k);
      end loop;
      check((is_pow2 = '1') = (ones = 1), "is_pow2 dla " & integer'image(i));
      check(lowest = low, "lowest dla " & integer'image(i));
      check(rev = r, "rev dla " & integer'image(i));
      check((parity = '1') = (ones mod 2 = 1), "parity dla " & integer'image(i));
      check((all_ones = '1') = (ones = W), "all_ones dla " & integer'image(i));
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
