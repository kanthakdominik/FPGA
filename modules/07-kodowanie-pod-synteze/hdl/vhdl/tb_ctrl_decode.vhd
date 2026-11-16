-- Testbench ctrl_decode: wszystkie 32 kombinacje wejść, model zapisany równaniami na bitach.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_ctrl_decode is
end entity tb_ctrl_decode;

architecture sim of tb_ctrl_decode is
  signal op                       : std_logic_vector(2 downto 0) := "000";
  signal valid, busy              : std_logic := '0';
  signal rd_en, wr_en, err        : std_logic;
  signal sel                      : std_logic_vector(1 downto 0);
begin
  dut : entity work.ctrl_decode
    port map (op => op, valid => valid, busy => busy, rd_en => rd_en, wr_en => wr_en, sel => sel, err => err);

  stim : process
    variable errors                 : natural := 0;
    variable l                      : line;
    variable vec                    : std_logic_vector(4 downto 0);
    variable go, e_rd, e_wr, e_err  : std_logic;
    variable e_sel                  : std_logic_vector(1 downto 0);
  begin
    for v in 0 to 31 loop
      vec   := std_logic_vector(to_unsigned(v, 5));
      valid <= vec(4);
      busy  <= vec(3);
      op    <= vec(2 downto 0);
      wait for 1 ns;
      go    := vec(4) and not vec(2) and not vec(3);           -- dozwolona operacja, nic nie blokuje
      e_err := vec(4) and vec(2);
      e_rd  := go and vec(0);                                  -- READ (001) i RMW (011)
      e_wr  := go and vec(1);                                  -- WRITE (010) i RMW (011)
      e_sel := vec(1 downto 0) when go = '1' else "00";
      if rd_en /= e_rd or wr_en /= e_wr or sel /= e_sel or err /= e_err then
        errors := errors + 1;
        report "valid/busy/op = " & to_string(vec) & ": rd=" & to_string(rd_en) & " wr=" & to_string(wr_en)
             & " sel=" & to_string(sel) & " err=" & to_string(err) severity warning;
      end if;
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
