-- Sumator opisany behawioralnie: syntezator sam zbuduje go na łańcuchu przeniesień.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder is
  generic (W : positive := 8);
  port (
    a, b : in  std_logic_vector(W - 1 downto 0);
    cin  : in  std_logic;
    s    : out std_logic_vector(W - 1 downto 0);
    cout : out std_logic
  );
end entity adder;

architecture rtl of adder is
  signal sum : unsigned(W downto 0);         -- o jeden bit szerzej: miejsce na przeniesienie
begin
  sum  <= resize(unsigned(a), W + 1) + resize(unsigned(b), W + 1) + unsigned'(0 => cin);
  s    <= std_logic_vector(sum(W - 1 downto 0));
  cout <= sum(W);
end architecture rtl;
