-- Testbench mac: wektory losowej długości (1..8) z przerwami w in_valid, wartości skrajne (-256),
-- model — suma iloczynów liczb całkowitych, wyniki w kolejce porównane po 3 taktach.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_mac is
end entity tb_mac;

architecture sim of tb_mac is
  signal clk       : std_logic := '0';
  signal done      : boolean   := false;
  signal rst       : std_logic := '1';
  signal in_valid  : std_logic := '0';
  signal first     : std_logic := '0';
  signal a, b      : signed(8 downto 0) := (others => '0');
  signal acc       : signed(23 downto 0);
  signal acc_valid : std_logic;
begin
  clk <= not clk after 5 ns when not done;

  dut : entity work.mac generic map (W => 9, ACC_W => 24)
    port map (clk => clk, rst => rst, in_valid => in_valid, first => first, a => a, b => b,
              acc => acc, acc_valid => acc_valid);

  stim : process
    type queue_t is array (0 to 1023) of integer;
    variable exp_q                    : queue_t;
    variable wr, rd, extremes, errors : natural  := 0;
    variable sum, va, vb, len, s      : integer  := 0;
    variable l                        : line;
    variable seed1, seed2             : positive := 21;

    impure function rnd(n : positive) return natural is      -- liczba losowa 0 .. n - 1
      variable r : real;
    begin
      uniform(seed1, seed2, r);
      return integer(floor(r * real(n)));
    end function rnd;

    impure function sample return integer is                   -- -256 .. 255, częściej -256
    begin
      if rnd(8) = 0 then
        return -256;
      end if;
      return rnd(512) - 256;
    end function sample;

    procedure step is                                          -- jeden takt: sprawdzenie wyjścia
    begin
      wait until falling_edge(clk);
      if acc_valid = '1' then
        if rd >= wr then
          errors := errors + 1;
          report "acc_valid bez oczekiwanego wyniku" severity warning;
        elsif to_integer(acc) /= exp_q(rd) then
          errors := errors + 1;
          report "wynik " & integer'image(rd) & ": acc=" & integer'image(to_integer(acc))
               & ", oczekiwano " & integer'image(exp_q(rd)) severity warning;
        end if;
        rd := rd + 1;
      end if;
    end procedure step;
  begin
    step;
    step;
    rst <= '0';
    for v in 0 to 59 loop
      len := 1 + rnd(8);
      s   := 0;
      while s < len loop
        if rnd(4) /= 0 then
          va := sample;
          vb := sample;
          in_valid <= '1';
          first    <= '1' when s = 0 else '0';
          a        <= to_signed(va, 9);
          b        <= to_signed(vb, 9);
          if va = -256 and vb = -256 then
            extremes := extremes + 1;
          end if;
          if s = 0 then
            sum := va * vb;
          else
            sum := sum + va * vb;
          end if;
          exp_q(wr) := sum;
          wr        := wr + 1;
          s         := s + 1;
        else
          in_valid <= '0';
        end if;
        step;
      end loop;
    end loop;
    in_valid <= '0';
    for k in 1 to 5 loop
      step;
    end loop;

    if rd /= wr then
      errors := errors + 1;
      report "sprawdzono " & integer'image(rd) & " z " & integer'image(wr) & " wynikow" severity warning;
    end if;
    if extremes = 0 then
      errors := errors + 1;
      report "test nie sprawdzil iloczynu (-256) * (-256)" severity warning;
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
