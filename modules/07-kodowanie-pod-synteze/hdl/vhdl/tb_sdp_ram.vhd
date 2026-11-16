-- Testbench sdp_ram: wypełnienie całej pamięci, potem losowe zapisy i odczyty z modelem.
-- Co ósmy takt odczyt spod adresu zapisywanego w tym samym takcie — oczekiwane stare dane.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_sdp_ram is
end entity tb_sdp_ram;

architecture sim of tb_sdp_ram is
  signal clk          : std_logic := '0';
  signal done         : boolean   := false;
  signal we           : std_logic := '0';
  signal waddr, raddr : std_logic_vector(4 downto 0) := (others => '0');
  signal wdata        : std_logic_vector(7 downto 0) := x"00";
  signal rdata        : std_logic_vector(7 downto 0);
begin
  clk <= not clk after 5 ns when not done;

  dut : entity work.sdp_ram generic map (W => 8, AW => 5)
    port map (clk => clk, we => we, waddr => waddr, wdata => wdata, raddr => raddr, rdata => rdata);

  stim : process
    type mem_t is array (0 to 31) of std_logic_vector(7 downto 0);
    variable model        : mem_t;
    variable e, wd        : std_logic_vector(7 downto 0);
    variable wa, ra       : natural;
    variable w            : boolean;
    variable errors       : natural  := 0;
    variable collisions   : natural  := 0;
    variable l            : line;
    variable seed1, seed2 : positive := 9;

    impure function rnd(n : positive) return natural is      -- liczba losowa 0 .. n - 1
      variable r : real;
    begin
      uniform(seed1, seed2, r);
      return integer(floor(r * real(n)));
    end function rnd;
  begin
    for n in 0 to 31 loop                                      -- wypełnienie
      wait until falling_edge(clk);
      wd       := std_logic_vector(to_unsigned(rnd(256), 8));
      we       <= '1';
      waddr    <= std_logic_vector(to_unsigned(n, 5));
      wdata    <= wd;
      model(n) := wd;
    end loop;
    wait until falling_edge(clk);
    we <= '0';

    for n in 0 to 399 loop
      w  := rnd(2) = 1 or n mod 8 = 0;
      wa := rnd(32);
      wd := std_logic_vector(to_unsigned(rnd(256), 8));
      if n mod 8 = 0 then
        ra := wa;
      else
        ra := rnd(32);
      end if;
      we    <= '1' when w else '0';
      waddr <= std_logic_vector(to_unsigned(wa, 5));
      wdata <= wd;
      raddr <= std_logic_vector(to_unsigned(ra, 5));
      if w and ra = wa then
        collisions := collisions + 1;
      end if;
      e := model(ra);                                          -- stan sprzed zapisu w tym takcie
      if w then
        model(wa) := wd;
      end if;
      wait until falling_edge(clk);
      if rdata /= e then
        errors := errors + 1;
        report "takt " & integer'image(n) & ": rdata=" & to_hstring(rdata) & ", oczekiwano " & to_hstring(e)
          severity warning;
      end if;
    end loop;

    if collisions = 0 then
      errors := errors + 1;
      report "test nie sprawdzil odczytu podczas zapisu" severity warning;
    end if;
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
