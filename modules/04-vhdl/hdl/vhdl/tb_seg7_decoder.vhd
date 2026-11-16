-- Testbench dekodera 7-segmentowego. Model jest zapisany inaczej niż układ:
-- dla każdego segmentu maska cyfr, przy których świeci (bit d maski = cyfra d).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_seg7_decoder is
end entity tb_seg7_decoder;

architecture sim of tb_seg7_decoder is
  type mask_array is array (0 to 6) of std_logic_vector(15 downto 0);
  --                                    a        b        c        d        e        f        g
  constant SEG_MASK : mask_array := (x"D7ED", x"279F", x"2FFB", x"7B6D", x"FD45", x"DF71", x"EF7C");
  signal hex : std_logic_vector(3 downto 0);
  signal seg : std_logic_vector(6 downto 0);
begin
  dut : entity work.seg7_decoder
    port map (hex => hex, seg => seg);

  stim : process
    variable errors : natural := 0;
    variable l      : line;
    procedure check(ok : boolean; msg : string) is
    begin
      if not ok then
        errors := errors + 1;
        report msg severity warning;
      end if;
    end procedure;
  begin
    for d in 0 to 15 loop
      hex <= std_logic_vector(to_unsigned(d, 4));
      wait for 1 ns;
      for s in 0 to 6 loop
        check(seg(s) = SEG_MASK(s)(d),
              "cyfra " & integer'image(d) & ", segment " & integer'image(s));
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
