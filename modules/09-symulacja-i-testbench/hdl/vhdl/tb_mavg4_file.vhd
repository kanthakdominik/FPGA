-- Testbench mavg4 sterowany wektorami z pliku mavg4_wektory.txt (generator: ../dane/gen_mavg4.py).
-- Wiersz: rst in_valid x exp_out_valid exp_y — wejścia przed zboczem, oczekiwane wyjścia po zboczu.
-- Plik jest kopiowany do katalogu roboczego symulacji (tools/run_hdl_tests.py, sim/Makefile).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_mavg4_file is
end entity tb_mavg4_file;

architecture sim of tb_mavg4_file is
  signal clk       : std_logic := '0';
  signal done      : boolean   := false;
  signal rst       : std_logic := '1';
  signal in_valid  : std_logic := '0';
  signal x         : signed(7 downto 0) := (others => '0');
  signal out_valid : std_logic;
  signal y         : signed(7 downto 0);
begin
  clk <= not clk after 5 ns when not done;

  dut : entity work.mavg4
    port map (clk => clk, rst => rst, in_valid => in_valid, x => x, out_valid => out_valid, y => y);

  stim : process
    file     f                       : text;
    variable status                  : file_open_status;
    variable l, msg                  : line;
    variable v_rst, v_valid, v_x     : integer;
    variable e_valid, e_y            : integer;
    variable ok                      : boolean;
    variable line_no, vectors, errors : natural := 0;
  begin
    file_open(status, f, "mavg4_wektory.txt", read_mode);
    if status /= open_ok then
      write(msg, string'("FAIL: brak pliku mavg4_wektory.txt w katalogu roboczym"));
      writeline(output, msg);
      done <= true;
      std.env.finish;
    end if;
    wait until falling_edge(clk);
    while not endfile(f) loop
      readline(f, l);
      line_no := line_no + 1;
      next when l'length = 0 or l(l'left) = '#';               -- komentarze i puste wiersze
      read(l, v_rst, ok);
      if ok then read(l, v_valid, ok); end if;
      if ok then read(l, v_x, ok); end if;
      if ok then read(l, e_valid, ok); end if;
      if ok then read(l, e_y, ok); end if;
      next when not ok;
      rst      <= '1' when v_rst = 1 else '0';
      in_valid <= '1' when v_valid = 1 else '0';
      x        <= to_signed(v_x, 8);
      wait until falling_edge(clk);
      vectors := vectors + 1;
      if (out_valid = '1') /= (e_valid = 1) or to_integer(y) /= e_y then
        errors := errors + 1;
        report "wiersz " & integer'image(line_no) & ": y=" & integer'image(to_integer(y))
             & ", oczekiwano " & integer'image(e_y) severity warning;
      end if;
    end loop;
    file_close(f);

    write(msg, "wektorow: " & integer'image(vectors) & ", bledow: " & integer'image(errors));
    writeline(output, msg);
    if vectors < 400 then
      errors := errors + 1;
      report "za malo wektorow — plik niepelny?" severity warning;
    end if;
    if errors = 0 then
      write(msg, string'("PASS"));
    else
      write(msg, "FAIL: " & integer'image(errors) & " bledow");
    end if;
    writeline(output, msg);
    done <= true;
    std.env.finish;
    wait;
  end process stim;
end architecture sim;
