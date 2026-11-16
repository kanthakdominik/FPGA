-- Testbench tiny_cpu: dwa programy (ciąg Fibonacciego i odliczanie z JNZ/HALT), losowe step.
-- Model: interpreter listy instrukcji napisany w testbenchu (bez automatu i sygnałów sterujących) liczy
-- oczekiwane wartości instrukcji OUT; każdy impuls out_valid jest z nimi porównywany.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_tiny_cpu is
end entity tb_tiny_cpu;

architecture sim of tb_tiny_cpu is
  constant FIB    : std_logic_vector(127 downto 0) := x"E0E0E0E0E0E0E0E0D25A466462C01100";
  constant COUNT  : std_logic_vector(127 downto 0) := x"E0E0E0E0E0E0E0E0E0E0C08245C0110A";
  constant MAXOUT : positive := 20;

  signal clk            : std_logic := '0';
  signal done           : boolean   := false;
  signal rst            : std_logic := '1';
  signal step           : std_logic := '0';
  signal out_f, out_c   : std_logic_vector(7 downto 0);
  signal v_f, v_c       : std_logic;
  signal halt_f, halt_c : std_logic;
  signal pc_f, pc_c     : std_logic_vector(3 downto 0);
begin
  clk <= not clk after 5 ns when not done;

  u_fib : entity work.tiny_cpu generic map (PROG => FIB)
    port map (clk => clk, rst => rst, step => step, out_data => out_f, out_valid => v_f, halted => halt_f, pc_o => pc_f);
  u_cnt : entity work.tiny_cpu generic map (PROG => COUNT)
    port map (clk => clk, rst => rst, step => step, out_data => out_c, out_valid => v_c, halted => halt_c, pc_o => pc_c);

  stim : process
    type outs_t is array (0 to MAXOUT - 1) of natural;
    variable exp_f, exp_c         : outs_t;
    variable nexp_f, nexp_c       : natural;
    variable stop_f, stop_c       : boolean;
    variable got_f, got_c, errors : natural  := 0;
    variable l                    : line;
    variable seed1, seed2         : positive := 61;
    variable r                    : real;

    -- interpreter: wykonuje program do HALT albo MAXOUT wartości OUT
    procedure interp(prog : std_logic_vector(127 downto 0); outs : out outs_t; nout : out natural;
                     stop : out boolean) is
      type regs_t is array (0 to 3) of natural;
      variable rr        : regs_t  := (others => 0);
      variable pc, n     : natural := 0;
      variable ins       : std_logic_vector(7 downto 0);
      variable d, s, imm : natural;
      variable halt      : boolean := false;
    begin
      outs := (others => 0);
      for guard in 1 to 1000 loop
        exit when halt or n = MAXOUT;
        ins := prog(8 * pc + 7 downto 8 * pc);
        d   := to_integer(unsigned(ins(5 downto 4)));
        s   := to_integer(unsigned(ins(3 downto 2)));
        imm := to_integer(unsigned(ins(3 downto 0)));
        pc  := (pc + 1) mod 16;
        case ins(7 downto 6) is
          when "00" => rr(d) := imm;
          when "01" =>
            case ins(1 downto 0) is
              when "00"   => rr(d) := (rr(d) + rr(s)) mod 256;
              when "01"   => rr(d) := (rr(d) - rr(s) + 256) mod 256;
              when "10"   => rr(d) := rr(s);
              when others => rr(d) := to_integer(to_unsigned(rr(d), 8) xor to_unsigned(rr(s), 8));
            end case;
          when "10" =>
            if rr(d) /= 0 then
              pc := imm;
            end if;
          when others =>
            case d is
              when 0      => outs(n) := rr(s);  n := n + 1;
              when 1      => pc := imm;
              when 2      => halt := true;
              when others => null;
            end case;
        end case;
      end loop;
      nout := n;
      stop := halt;
    end procedure interp;
  begin
    interp(FIB, exp_f, nexp_f, stop_f);
    interp(COUNT, exp_c, nexp_c, stop_c);

    wait until falling_edge(clk);
    wait until falling_edge(clk);
    rst <= '0';
    for n in 0 to 2999 loop
      uniform(seed1, seed2, r);
      step <= '1' when r < 0.5 else '0';
      wait until falling_edge(clk);
      if v_f = '1' and got_f < nexp_f then
        if to_integer(unsigned(out_f)) /= exp_f(got_f) then
          errors := errors + 1;
          report "Fibonacci " & integer'image(got_f) & ": " & integer'image(to_integer(unsigned(out_f)))
               & ", oczekiwano " & integer'image(exp_f(got_f)) severity warning;
        end if;
        got_f := got_f + 1;
      end if;
      if v_c = '1' then
        if got_c >= nexp_c then
          errors := errors + 1;
          report "odliczanie: nadmiarowe OUT" severity warning;
        elsif to_integer(unsigned(out_c)) /= exp_c(got_c) then
          errors := errors + 1;
          report "odliczanie " & integer'image(got_c) & ": " & integer'image(to_integer(unsigned(out_c)))
            severity warning;
        end if;
        got_c := got_c + 1;
      end if;
    end loop;

    if got_f < nexp_f or got_c /= nexp_c or (halt_c = '1') /= stop_c or halt_f /= '0' then
      errors := errors + 1;
      report "Fibonacci " & integer'image(got_f) & "/" & integer'image(nexp_f) & ", odliczanie "
           & integer'image(got_c) & "/" & integer'image(nexp_c) severity warning;
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
