-- Sumator z przeniesieniem szeregowym (ripple-carry) zbudowany z W sumatorów pełnych.
library ieee;
use ieee.std_logic_1164.all;

entity rca_adder is
  generic (W : positive := 8);
  port (
    a, b : in  std_logic_vector(W - 1 downto 0);
    cin  : in  std_logic;
    s    : out std_logic_vector(W - 1 downto 0);
    cout : out std_logic
  );
end entity rca_adder;

architecture structural of rca_adder is
  signal c : std_logic_vector(W downto 0);   -- c(i) = przeniesienie na wejście bitu i
begin
  c(0) <= cin;

  g_fa : for i in 0 to W - 1 generate
    u_fa : entity work.full_adder
      port map (a => a(i), b => b(i), cin => c(i), s => s(i), cout => c(i + 1));
  end generate g_fa;

  cout <= c(W);
end architecture structural;
