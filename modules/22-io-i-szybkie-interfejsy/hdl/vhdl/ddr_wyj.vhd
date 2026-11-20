-- Rejestr wyjściowy DDR - model behawioralny (22.02): d_h i d_l pobrane zboczem narastającym, na wyjściu
-- d_h w stanie wysokim zegara i d_l w stanie niskim. W układzie: blok I/O (ALTDDIO_OUT, ODDR, ODDRX1F).
library ieee;
use ieee.std_logic_1164.all;

entity ddr_wyj is
  port (
    clk : in  std_logic;
    d_h : in  std_logic;                                   -- bit w połowie wysokiej (pierwszy)
    d_l : in  std_logic;                                   -- bit w połowie niskiej (drugi)
    q   : out std_logic
  );
end entity ddr_wyj;

architecture beh of ddr_wyj is
  signal h, l, l_n : std_logic := '0';
begin
  process (clk)
  begin
    if rising_edge(clk) then
      h <= d_h;
      l <= d_l;
    end if;
    if falling_edge(clk) then
      l_n <= l;                                            -- bit drugi przejmuje wyjście przy zboczu opadającym
    end if;
  end process;
  q <= h when clk = '1' else l_n;
end architecture beh;
