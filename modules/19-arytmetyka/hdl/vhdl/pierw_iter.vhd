-- Pierwiastek całkowity iteracyjny (19.03): pierw = floor(sqrt(x)) dla x o 2W bitach, jeden bit
-- na takt (cyfra po cyfrze): do reszty dopisywane są dwa bity x, próbny odjemnik to 4·pierw + 1.
-- Wynik po W+2 taktach; reszta = x - pierw².
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pierw_iter is
  generic (W : positive := 8);
  port (
    clk    : in  std_logic;
    rst    : in  std_logic;
    start  : in  std_logic;
    x      : in  std_logic_vector(2 * W - 1 downto 0);
    busy   : out std_logic := '0';
    done   : out std_logic := '0';
    pierw  : out std_logic_vector(W - 1 downto 0);
    reszta : out std_logic_vector(W downto 0)
  );
end entity pierw_iter;

architecture rtl of pierw_iter is
  signal xs                     : unsigned(2 * W - 1 downto 0);
  signal p                      : unsigned(W - 1 downto 0);
  signal rr                     : unsigned(W + 1 downto 0);
  signal licz                   : natural range 0 to W;
  signal zajety                 : std_logic := '0';
  signal r_przes, proba, roznica : unsigned(W + 1 downto 0);
  signal bit_p                  : std_logic;
begin
  r_przes <= rr(W - 1 downto 0) & xs(2 * W - 1 downto 2 * W - 2);
  proba   <= p & "01";                                         -- 4·p + 1
  roznica <= r_przes - proba;
  bit_p   <= '1' when r_przes >= proba else '0';
  busy    <= zajety;

  process (clk)
  begin
    if rising_edge(clk) then
      done <= '0';
      if rst = '1' then
        zajety <= '0';
      elsif zajety = '0' then
        if start = '1' then
          xs     <= unsigned(x);
          p      <= (others => '0');
          rr     <= (others => '0');
          licz   <= W;
          zajety <= '1';
        end if;
      elsif licz /= 0 then
        xs   <= shift_left(xs, 2);
        rr   <= roznica when bit_p = '1' else r_przes;
        p    <= p(W - 2 downto 0) & bit_p;
        licz <= licz - 1;
      else
        zajety <= '0';
        done   <= '1';
        pierw  <= std_logic_vector(p);
        reszta <= std_logic_vector(rr(W downto 0));
      end if;
    end if;
  end process;
end architecture rtl;
