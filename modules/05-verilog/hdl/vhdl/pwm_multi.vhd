-- N kanałów PWM o rozdzielczości W bitów ze wspólnym licznikiem; wyjścia rejestrowane.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pwm_multi is
  generic (
    N : positive := 4;
    W : positive := 8
  );
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    duty : in  std_logic_vector(N * W - 1 downto 0);  -- kanał i: duty((i + 1) * W - 1 downto i * W)
    pwm  : out std_logic_vector(N - 1 downto 0)
  );
end entity pwm_multi;

architecture rtl of pwm_multi is
  signal cnt : unsigned(W - 1 downto 0) := (others => '0');
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cnt <= (others => '0');
      else
        cnt <= cnt + 1;                          -- unsigned zawija się sam: 2**W - 1 -> 0
      end if;
    end if;
  end process;

  g_ch : for i in 0 to N - 1 generate
    process (clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          pwm(i) <= '0';
        elsif cnt < unsigned(duty((i + 1) * W - 1 downto i * W)) then
          pwm(i) <= '1';
        else
          pwm(i) <= '0';
        end if;
      end if;
    end process;
  end generate g_ch;
end architecture rtl;
