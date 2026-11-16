-- Testbench konwersji RGB -> szarość: przypadki brzegowe i 300 pikseli pseudolosowych we wszystkich trybach.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_rgb_to_gray is
end entity tb_rgb_to_gray;

architecture sim of tb_rgb_to_gray is
  signal pix_raw : std_logic_vector(23 downto 0);
  signal mode    : std_logic_vector(1 downto 0);
  signal y       : std_logic_vector(7 downto 0);
begin
  dut : entity work.rgb_to_gray
    port map (pix_raw => pix_raw, mode => mode, y => y);

  stim : process
    variable errors : natural := 0;
    variable l      : line;
    variable lfsr   : unsigned(23 downto 0) := x"123456";
    procedure check(ok : boolean; msg : string) is
    begin
      if not ok then
        errors := errors + 1;
        report msg severity warning;
      end if;
    end procedure;
    procedure check_pixel(p : std_logic_vector(23 downto 0)) is
      variable r, g, b, e : natural;
    begin
      r := to_integer(unsigned(p(23 downto 16)));
      g := to_integer(unsigned(p(15 downto 8)));
      b := to_integer(unsigned(p(7 downto 0)));
      for md in 0 to 3 loop
        pix_raw <= p;
        mode    <= std_logic_vector(to_unsigned(md, 2));
        wait for 1 ns;
        case md is
          when 0 => e := (r + 2 * g + b) / 4;
          when 1 => e := (77 * r + 150 * g + 29 * b) / 256;
          when 2 => e := r;
          when others => e := 0;
        end case;
        check(to_integer(unsigned(y)) = e, "tryb " & integer'image(md) & ", r=" & integer'image(r)
              & " g=" & integer'image(g) & " b=" & integer'image(b));
      end loop;
    end procedure;
  begin
    check_pixel(x"000000");
    check_pixel(x"FFFFFF");
    check_pixel(x"FF0000");
    check_pixel(x"00FF00");
    check_pixel(x"0000FF");
    for n in 1 to 300 loop
      if lfsr(0) = '1' then
        lfsr := shift_right(lfsr, 1) xor x"E10000";
      else
        lfsr := shift_right(lfsr, 1);
      end if;
      check_pixel(std_logic_vector(lfsr));
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
