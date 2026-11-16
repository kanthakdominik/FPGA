-- Testbench kodu Graya: wszystkie 256 wartości; model liczy kod Graya i parzystość arytmetycznie.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_gray_codec is
end entity tb_gray_codec;

architecture sim of tb_gray_codec is
  constant W : positive := 8;
  signal bin_in, gray_out, gray_in, bin_out : std_logic_vector(W - 1 downto 0);
  signal par : std_logic;
begin
  dut : entity work.gray_codec
    generic map (W => W)
    port map (bin_in => bin_in, gray_out => gray_out, gray_in => gray_in, bin_out => bin_out, par => par);

  stim : process
    variable errors : natural := 0;
    variable l      : line;
    variable u, g   : unsigned(W - 1 downto 0);
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
      u := to_unsigned(i, W);
      g := u xor shift_right(u, 1);          -- model: g = b xor (b >> 1)
      ones := 0;
      for k in 0 to W - 1 loop
        if u(k) = '1' then
          ones := ones + 1;
        end if;
      end loop;
      bin_in  <= std_logic_vector(u);
      gray_in <= std_logic_vector(g);
      wait for 1 ns;
      check(gray_out = std_logic_vector(g), "bin2gray(" & integer'image(i) & ")");
      check(bin_out = std_logic_vector(u), "gray2bin dla " & integer'image(i));
      check((par = '1') = (ones mod 2 = 1), "parity(" & integer'image(i) & ")");
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
