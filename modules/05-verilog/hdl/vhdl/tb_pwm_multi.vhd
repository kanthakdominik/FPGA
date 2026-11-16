-- Testbench PWM: 3 kanały, W = 4 (okres 16 taktów); w każdym okresie liczba taktów w stanie 1 = duty.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_pwm_multi is
end entity tb_pwm_multi;

architecture sim of tb_pwm_multi is
  constant N    : positive := 3;
  constant W    : positive := 4;
  constant P    : positive := 2 ** W;
  constant DUTY : std_logic_vector(N * W - 1 downto 0) := x"F" & x"5" & x"0";  -- kanały 2, 1, 0
  signal clk    : std_logic := '0';
  signal done   : boolean   := false;
  signal rst    : std_logic := '1';
  signal pwm    : std_logic_vector(N - 1 downto 0);
begin
  clk <= not clk after 5 ns when not done;

  dut : entity work.pwm_multi
    generic map (N => N, W => W)
    port map (clk => clk, rst => rst, duty => DUTY, pwm => pwm);

  stim : process
    type count_t is array (0 to N - 1) of natural;
    variable high   : count_t;
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
    wait until falling_edge(clk);
    rst <= '0';
    wait until falling_edge(clk);
    for period in 0 to 2 loop
      high := (others => 0);
      for k in 0 to P - 1 loop
        for ch in 0 to N - 1 loop
          if pwm(ch) = '1' then
            high(ch) := high(ch) + 1;
          end if;
        end loop;
        wait until falling_edge(clk);
      end loop;
      for ch in 0 to N - 1 loop
        check(high(ch) = to_integer(unsigned(DUTY((ch + 1) * W - 1 downto ch * W))),
              "okres " & integer'image(period) & ", kanal " & integer'image(ch) & ": " & integer'image(high(ch)));
      end loop;
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
