-- Moduł nadrzędny DECA — VHDL. Osiem diod z jasnością rosnącą wykładniczo:
-- LED(i) ma wypełnienie (2**(i+1) - 1) / 256, od 1/256 (LED(0)) do 255/256 (LED(7)).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deca_top is
  port (
    MAX10_CLK1_50 : in  std_logic;
    LED           : out std_logic_vector(7 downto 0)   -- '0' = świeci
  );
end entity deca_top;

architecture rtl of deca_top is
  constant N : positive := 8;
  constant W : positive := 8;
  signal duty : std_logic_vector(N * W - 1 downto 0);
  signal pwm  : std_logic_vector(N - 1 downto 0);
begin
  g_duty : for i in 0 to N - 1 generate
    duty((i + 1) * W - 1 downto i * W) <= std_logic_vector(to_unsigned(2 ** (i + 1) - 1, W));
  end generate g_duty;

  u_pwm : entity work.pwm_multi
    generic map (N => N, W => W)
    port map (clk => MAX10_CLK1_50, rst => '0', duty => duty, pwm => pwm);

  LED <= not pwm;
end architecture rtl;
