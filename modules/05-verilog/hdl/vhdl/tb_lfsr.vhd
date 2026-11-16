-- Testbench LFSR (W = 8, x^8 + x^6 + x^5 + x^4 + 1): stan nigdy nie jest zerem,
-- nie powtarza się przed końcem okresu i wraca do stanu początkowego po 255 krokach.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_lfsr is
end entity tb_lfsr;

architecture sim of tb_lfsr is
  constant W : positive  := 8;
  signal clk : std_logic := '0';
  signal done : boolean  := false;
  signal rst : std_logic := '1';
  signal en  : std_logic := '0';
  signal q   : std_logic_vector(W - 1 downto 0);
begin
  clk <= not clk after 5 ns when not done;

  dut : entity work.lfsr
    generic map (W => W, TAPS => x"B8", SEED => x"01")
    port map (clk => clk, rst => rst, en => en, q => q);

  stim : process
    type seen_t is array (0 to 255) of boolean;
    variable seen   : seen_t := (others => false);
    variable errors : natural := 0;
    variable l      : line;
    variable model  : unsigned(W - 1 downto 0) := x"01";
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
    en  <= '1';
    for k in 0 to 254 loop
      check(unsigned(q) = model, "krok " & integer'image(k) & ": rozne od modelu");
      check(unsigned(q) /= 0 and not seen(to_integer(unsigned(q))), "krok " & integer'image(k) & ": zero lub powtorzenie");
      seen(to_integer(unsigned(q))) := true;
      -- model: przesunięcie w prawo, XOR z wielomianem, gdy wysunięty bit = 1
      if model(0) = '1' then
        model := shift_right(model, 1) xor x"B8";
      else
        model := shift_right(model, 1);
      end if;
      wait until falling_edge(clk);
    end loop;
    check(q = x"01", "po 255 krokach stan rozny od poczatkowego");
    en <= '0';
    wait until falling_edge(clk);
    wait until falling_edge(clk);
    check(q = x"01", "zmiana stanu przy en=0");

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
