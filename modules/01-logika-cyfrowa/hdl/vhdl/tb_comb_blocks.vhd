-- Testbench bloków kombinacyjnych: multiplekser, dekoder, enkoder priorytetowy, komparator.
-- Sprawdza wszystkie kombinacje wejść.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_comb_blocks is
end entity tb_comb_blocks;

architecture sim of tb_comb_blocks is
  signal d0, d1, d2, d3, my : std_logic_vector(3 downto 0);
  signal sel                : std_logic_vector(1 downto 0);
  signal da                 : std_logic_vector(2 downto 0);
  signal dy                 : std_logic_vector(7 downto 0);
  signal pa                 : std_logic_vector(7 downto 0);
  signal py                 : std_logic_vector(2 downto 0);
  signal pv                 : std_logic;
  signal ca, cb             : std_logic_vector(3 downto 0);
  signal eq, lt, gt         : std_logic;
begin
  u_mux : entity work.mux4
    generic map (W => 4)
    port map (d0 => d0, d1 => d1, d2 => d2, d3 => d3, sel => sel, y => my);
  u_dec : entity work.decoder
    generic map (N => 3)
    port map (a => da, y => dy);
  u_pe : entity work.prio_enc
    generic map (N => 8)
    port map (a => pa, y => py, valid => pv);
  u_cmp : entity work.comparator
    generic map (W => 4)
    port map (a => ca, b => cb, eq => eq, lt => lt, gt => gt);

  stim : process
    variable errors  : natural := 0;
    variable l       : line;
    variable v       : unsigned(7 downto 0);
    variable exp_idx : integer;

    procedure check(ok : boolean; msg : string) is
    begin
      if not ok then
        errors := errors + 1;
        report msg severity warning;
      end if;
    end procedure;
  begin
    -- multiplekser: każde wejście ma inną wartość, sprawdzamy wszystkie sel
    d0 <= x"1"; d1 <= x"2"; d2 <= x"4"; d3 <= x"8";
    for s in 0 to 3 loop
      sel <= std_logic_vector(to_unsigned(s, 2));
      wait for 1 ns;
      check(unsigned(my) = shift_left(to_unsigned(1, 4), s), "mux4: zle wyjscie dla sel=" & integer'image(s));
    end loop;

    -- dekoder: dokładnie jedna jedynka na pozycji a
    for i in 0 to 7 loop
      da <= std_logic_vector(to_unsigned(i, 3));
      wait for 1 ns;
      check(unsigned(dy) = shift_left(to_unsigned(1, 8), i), "decoder: zle wyjscie dla a=" & integer'image(i));
    end loop;

    -- enkoder priorytetowy: wszystkie 256 wartości, wzorzec liczony niezależnie
    for i in 0 to 255 loop
      v  := to_unsigned(i, 8);
      pa <= std_logic_vector(v);
      wait for 1 ns;
      exp_idx := -1;
      for b in 0 to 7 loop
        if v(b) = '1' then
          exp_idx := b;
        end if;
      end loop;
      if i = 0 then
        check(pv = '0', "prio_enc: valid=1 dla a=0");
      else
        check(pv = '1' and to_integer(unsigned(py)) = exp_idx,
              "prio_enc: zly wynik dla a=" & integer'image(i));
      end if;
    end loop;

    -- komparator: wszystkie pary liczb 4-bitowych
    for i in 0 to 15 loop
      for j in 0 to 15 loop
        ca <= std_logic_vector(to_unsigned(i, 4));
        cb <= std_logic_vector(to_unsigned(j, 4));
        wait for 1 ns;
        check((eq = '1') = (i = j) and (lt = '1') = (i < j) and (gt = '1') = (i > j),
              "comparator: zly wynik dla " & integer'image(i) & ", " & integer'image(j));
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
