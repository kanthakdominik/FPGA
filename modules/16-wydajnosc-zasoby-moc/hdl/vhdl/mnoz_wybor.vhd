-- y = sel ? a*b : c*d (16.02). WSPOLNY = false: dwie mnożarki i multiplekser wyników;
-- WSPOLNY = true: multipleksery argumentów i jedna mnożarka.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mnoz_wybor is
  generic (
    W       : positive := 16;
    WSPOLNY : boolean  := false
  );
  port (
    clk : in  std_logic;
    sel : in  std_logic;
    a   : in  std_logic_vector(W - 1 downto 0);
    b   : in  std_logic_vector(W - 1 downto 0);
    c   : in  std_logic_vector(W - 1 downto 0);
    d   : in  std_logic_vector(W - 1 downto 0);
    y   : out std_logic_vector(2 * W - 1 downto 0)
  );
end entity mnoz_wybor;

architecture rtl of mnoz_wybor is
  signal x1, x2     : unsigned(W - 1 downto 0);
  signal p_ab, p_cd : unsigned(2 * W - 1 downto 0);
begin
  g_wsp : if WSPOLNY generate
    x1 <= unsigned(a) when sel = '1' else unsigned(c);
    x2 <= unsigned(b) when sel = '1' else unsigned(d);
    process (clk)
    begin
      if rising_edge(clk) then
        y <= std_logic_vector(x1 * x2);
      end if;
    end process;
  else generate
    p_ab <= unsigned(a) * unsigned(b);
    p_cd <= unsigned(c) * unsigned(d);
    process (clk)
    begin
      if rising_edge(clk) then
        if sel = '1' then
          y <= std_logic_vector(p_ab);
        else
          y <= std_logic_vector(p_cd);
        end if;
      end if;
    end process;
  end generate;
end architecture rtl;
