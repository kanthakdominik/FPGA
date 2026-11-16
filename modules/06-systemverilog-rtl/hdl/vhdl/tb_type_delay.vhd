-- Testbench linii opóźniającej parametryzowanej typem: rekord rgb_t (DEPTH = 2) i wektor 8-bitowy (DEPTH = 1).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.img_pkg.all;

entity tb_type_delay is
end entity tb_type_delay;

architecture sim of tb_type_delay is
  subtype byte_t is std_logic_vector(7 downto 0);
  type hist_t is array (0 to 49) of rgb_t;
  signal clk   : std_logic := '0';
  signal done  : boolean   := false;
  signal d_rgb, q_rgb : rgb_t := (others => (others => '0'));
  signal d_8, q_8     : byte_t := (others => '0');
begin
  clk <= not clk after 5 ns when not done;

  u_rgb : entity work.type_delay
    generic map (T => rgb_t, DEPTH => 2)
    port map (clk => clk, d => d_rgb, q => q_rgb);
  u_8 : entity work.type_delay
    generic map (T => byte_t, DEPTH => 1)
    port map (clk => clk, d => d_8, q => q_8);

  stim : process
    variable errors : natural := 0;
    variable l      : line;
    variable hist   : hist_t;
    variable prev8  : byte_t := (others => '0');
    variable lfsr   : unsigned(23 downto 0) := x"ABCDEF";
    procedure check(ok : boolean; msg : string) is
    begin
      if not ok then
        errors := errors + 1;
        report msg severity warning;
      end if;
    end procedure;
  begin
    for k in 0 to 49 loop
      wait until falling_edge(clk);
      if k >= 2 then
        check(q_rgb = hist(k - 2), "rgb, takt " & integer'image(k));
      end if;
      if k >= 1 then
        check(q_8 = prev8, "8 bit, takt " & integer'image(k));
      end if;
      if lfsr(0) = '1' then
        lfsr := shift_right(lfsr, 1) xor x"E10000";
      else
        lfsr := shift_right(lfsr, 1);
      end if;
      hist(k) := to_rgb(std_logic_vector(lfsr));
      d_rgb   <= hist(k);
      prev8   := d_8;
      d_8     <= std_logic_vector(lfsr(7 downto 0) xor lfsr(15 downto 8));
    end loop;

    if errors = 0 then
      write(l, string'("PASS"));
    else
      write(l, "FAIL: " & integer'image(errors) & " bledow");
    end if;
    writeline(output, l);
    done <= true;
    std.env.finish;
    wait;
  end process stim;
end architecture sim;
