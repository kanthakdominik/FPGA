-- Izolacja argumentów mnożarki (16.06): ISO = false - argumenty zapisywane w każdym takcie,
-- ISO = true - tylko przy in_valid (clock enable), więc mnożarka nie przełącza się na śmieciach.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity izolacja_operandow is
  generic (
    W   : positive := 16;
    ISO : boolean  := true
  );
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    in_valid  : in  std_logic;
    a         : in  std_logic_vector(W - 1 downto 0);
    b         : in  std_logic_vector(W - 1 downto 0);
    out_valid : out std_logic;
    p         : out std_logic_vector(2 * W - 1 downto 0)
  );
end entity izolacja_operandow;

architecture rtl of izolacja_operandow is
  signal a_r, b_r : unsigned(W - 1 downto 0);
  signal v_r, v_o : std_logic := '0';
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if not ISO or in_valid = '1' then
        a_r <= unsigned(a);
        b_r <= unsigned(b);
      end if;
      p <= std_logic_vector(a_r * b_r);
      if rst = '1' then
        v_r <= '0';
        v_o <= '0';
      else
        v_r <= in_valid;
        v_o <= v_r;
      end if;
    end if;
  end process;
  out_valid <= v_o;
end architecture rtl;
