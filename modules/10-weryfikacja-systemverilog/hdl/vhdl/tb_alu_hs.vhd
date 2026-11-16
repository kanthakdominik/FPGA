-- Testbench alu_hs: losowe operacje z wartościami brzegowymi, losowe wstrzymanie po stronie wyjścia
-- (z okresem silnego przeciążenia), potem pełna przepustowość i opróżnianie. Model liczy na liczbach
-- całkowitych, niezależnie od kodu układu. Sprawdzane: wynik i flagi każdej operacji, stabilność wyjść
-- przy wstrzymaniu, brak przyjęcia przy zajętym rejestrze, in_ready = '1' przy pełnym przepływie,
-- pokrycie: każdy kod op, SUB z a = b, przeniesienie, pożyczka, wynik zero.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_alu_hs is
end entity tb_alu_hs;

architecture sim of tb_alu_hs is
  constant W : positive := 8;

  signal clk                     : std_logic := '0';
  signal done                    : boolean   := false;
  signal rst                     : std_logic := '1';
  signal in_valid, out_ready     : std_logic := '0';
  signal in_ready, out_valid     : std_logic;
  signal carry, zero, err        : std_logic;
  signal op                      : std_logic_vector(2 downto 0)     := "000";
  signal a, b                    : std_logic_vector(W - 1 downto 0) := (others => '0');
  signal res                     : std_logic_vector(W - 1 downto 0);

  -- model: err & zero & carry & res liczony na liczbach całkowitych
  function model(o, x, y : natural) return std_logic_vector is
    constant M     : natural := 2 ** W;
    constant SHIFT : natural := y mod W;
    variable r     : natural := 0;
    variable c, e  : std_logic := '0';
    variable z     : std_logic;
  begin
    case o is
      when 0 =>
        r := (x + y) mod M;
        c := '1' when x + y >= M else '0';
      when 1 =>
        r := (x + M - y) mod M;
        c := '1' when x < y else '0';
      when 2 => r := to_integer(to_unsigned(x, W) and to_unsigned(y, W));
      when 3 => r := to_integer(to_unsigned(x, W) or to_unsigned(y, W));
      when 4 => r := to_integer(to_unsigned(x, W) xor to_unsigned(y, W));
      when 5 => r := (x * 2 ** SHIFT) mod M;
      when 6 => r := x / 2 ** SHIFT;
      when others => e := '1';
    end case;
    z := '1' when r = 0 else '0';
    return e & z & c & std_logic_vector(to_unsigned(r, W));
  end function model;
begin
  clk <= not clk after 5 ns when not done;

  dut : entity work.alu_hs
    generic map (W => W)
    port map (clk => clk, rst => rst, in_valid => in_valid, in_ready => in_ready, op => op, a => a, b => b,
              out_valid => out_valid, out_ready => out_ready, res => res, carry => carry, zero => zero,
              err => err);

  stim : process
    type count_t is array (0 to 7) of natural;
    variable exp_q, held, got           : std_logic_vector(W + 2 downto 0);
    variable has_exp, stalled, pending  : boolean  := false;
    variable errors, nin, nout          : natural  := 0;
    variable backpressure               : natural  := 0;
    variable ops                        : count_t  := (others => 0);
    variable sub_eq, n_carry            : natural  := 0;
    variable n_borrow, n_zero           : natural  := 0;
    variable av                         : std_logic_vector(W - 1 downto 0);
    variable l                          : line;
    variable seed1, seed2               : positive := 101;

    impure function rnd(n : positive) return natural is      -- liczba losowa 0 .. n - 1
      variable r : real;
    begin
      uniform(seed1, seed2, r);
      return integer(floor(r * real(n)));
    end function rnd;

    impure function operand return std_logic_vector is
    begin
      case rnd(8) is
        when 0      => return std_logic_vector(to_unsigned(0, W));
        when 1      => return std_logic_vector(to_unsigned(2 ** W - 1, W));
        when 2      => return std_logic_vector(to_unsigned(1, W));
        when others => return std_logic_vector(to_unsigned(rnd(2 ** W), W));
      end case;
    end function operand;

    procedure blad(msg : string) is
    begin
      errors := errors + 1;
      report msg severity warning;
    end procedure blad;
  begin
    wait until falling_edge(clk);
    wait until falling_edge(clk);
    rst <= '0';
    for n in 0 to 2999 loop
      -- 1. stabilność: wynik niewzięty w poprzednim takcie stoi bez zmian
      got := err & zero & carry & res;
      if stalled and (out_valid /= '1' or got /= held) then
        blad("takt " & integer'image(n) & ": zmiana wyjsc podczas wstrzymania");
      end if;
      -- 2. pobudzenia
      if n < 1000 then
        out_ready <= '1' when rnd(2) = 1 else '0';
      elsif n < 1500 then
        out_ready <= '1' when rnd(8) = 0 else '0';              -- silne przeciążenie
      else
        out_ready <= '1';
      end if;
      if not pending then                                      -- poprzednia operacja przyjęta
        if n >= 2900 then
          in_valid <= '0';
        elsif n >= 1500 then
          in_valid <= '1';
        else
          in_valid <= '1' when rnd(4) /= 0 else '0';
        end if;
        op <= std_logic_vector(to_unsigned(rnd(8), 3));
        av := operand;
        a  <= av;
        if rnd(8) = 0 then                                     -- co ósma: a = b
          b <= av;
        else
          b <= operand;
        end if;
      end if;
      wait for 1 ns;
      -- 3. przesłania w tym takcie: najpierw wyjście (stary wynik), potem wejście (nowy)
      got := err & zero & carry & res;
      if (out_valid = '1') /= has_exp then
        blad("takt " & integer'image(n) & ": niezgodne out_valid");
      end if;
      if out_valid = '1' and out_ready = '1' then
        if got /= exp_q then
          blad("takt " & integer'image(n) & ": err/zero/carry/res = " & to_string(got) &
               ", oczekiwano " & to_string(exp_q));
        end if;
        has_exp := false;
        nout    := nout + 1;
      end if;
      if in_valid = '1' and in_ready = '1' then
        if has_exp then
          blad("takt " & integer'image(n) & ": przyjecie przy zajetym rejestrze wyjsciowym");
        end if;
        exp_q   := model(to_integer(unsigned(op)), to_integer(unsigned(a)), to_integer(unsigned(b)));
        has_exp := true;
        nin     := nin + 1;
        ops(to_integer(unsigned(op))) := ops(to_integer(unsigned(op))) + 1;
        if op = "001" and a = b then
          sub_eq := sub_eq + 1;
        end if;
        if op = "000" and exp_q(W) = '1' then
          n_carry := n_carry + 1;
        end if;
        if op = "001" and exp_q(W) = '1' then
          n_borrow := n_borrow + 1;
        end if;
        if exp_q(W + 1) = '1' then
          n_zero := n_zero + 1;
        end if;
      end if;
      if n >= 1500 and n < 2900 and in_ready = '0' then
        blad("takt " & integer'image(n) & ": in_ready = 0 przy pelnym przeplywie");
      end if;
      pending := in_valid = '1' and in_ready = '0';            -- źródło trzyma operację do przyjęcia
      if out_valid = '1' and out_ready = '0' then
        backpressure := backpressure + 1;
      end if;
      stalled := out_valid = '1' and out_ready = '0';
      held    := got;
      wait until falling_edge(clk);
    end loop;

    if has_exp or nout /= nin then
      blad("przyjeto " & integer'image(nin) & ", odebrano " & integer'image(nout));
    end if;
    for i in ops'range loop
      if ops(i) = 0 then
        blad("pokrycie: brak operacji op=" & integer'image(i));
      end if;
    end loop;
    if sub_eq = 0 or n_carry = 0 or n_borrow = 0 or n_zero = 0 or backpressure = 0 then
      blad("pokrycie: sub_eq=" & integer'image(sub_eq) & " carry=" & integer'image(n_carry) &
           " borrow=" & integer'image(n_borrow) & " zero=" & integer'image(n_zero) &
           " wstrzymania=" & integer'image(backpressure));
    end if;
    write(l, "operacji: " & integer'image(nout) & ", wstrzyman: " & integer'image(backpressure));
    writeline(output, l);
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
