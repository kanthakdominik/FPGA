-- Mnożenie liczb zespolonych (ar + j·ai)(br + j·bi) ze znakiem, W bitów na składową (19.02).
--   TRZY = false: cztery mnożenia; TRZY = true: trzy (sztuczka Gaussa):
--   k1 = br·(ar + ai), k2 = ar·(bi - br), k3 = ai·(br + bi); pr = k1 - k3, pi = k1 + k2.
-- Potok 4 takty, wynik 2W+1 bitów, nowa para w każdym takcie.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mnoz_zesp is
  generic (
    W    : positive := 16;
    TRZY : boolean  := true
  );
  port (
    clk       : in  std_logic;
    in_valid  : in  std_logic;
    ar, ai    : in  std_logic_vector(W - 1 downto 0);
    br, bi    : in  std_logic_vector(W - 1 downto 0);
    out_valid : out std_logic := '0';
    pr, pi    : out std_logic_vector(2 * W downto 0)
  );
end entity mnoz_zesp;

architecture rtl of mnoz_zesp is
  signal ar1, ai1, br1, bi1 : signed(W - 1 downto 0);
  signal v                  : std_logic_vector(2 downto 0) := (others => '0');
begin
  process (clk)
  begin
    if rising_edge(clk) then
      ar1 <= signed(ar);
      ai1 <= signed(ai);
      br1 <= signed(br);
      bi1 <= signed(bi);
      v   <= v(1 downto 0) & in_valid;
      out_valid <= v(2);
    end if;
  end process;

  g_cztery : if not TRZY generate
    signal m1, m2, m3, m4 : signed(2 * W - 1 downto 0);
    signal sr, si         : signed(2 * W downto 0);
  begin
    process (clk)
    begin
      if rising_edge(clk) then
        m1 <= ar1 * br1;
        m2 <= ai1 * bi1;
        m3 <= ar1 * bi1;
        m4 <= ai1 * br1;
        sr <= resize(m1, 2 * W + 1) - m2;
        si <= resize(m3, 2 * W + 1) + m4;
        pr <= std_logic_vector(sr);
        pi <= std_logic_vector(si);
      end if;
    end process;
  end;
  else generate
    signal s1, s2, s3    : signed(W downto 0);              -- sumy przed mnożeniem
    signal ar2, ai2, br2 : signed(W - 1 downto 0);
    signal k1, k2, k3    : signed(2 * W downto 0);
  begin
    process (clk)
    begin
      if rising_edge(clk) then
        s1  <= resize(ar1, W + 1) + ai1;
        s2  <= resize(bi1, W + 1) - br1;
        s3  <= resize(br1, W + 1) + bi1;
        ar2 <= ar1;
        ai2 <= ai1;
        br2 <= br1;
        k1  <= br2 * s1;
        k2  <= ar2 * s2;
        k3  <= ai2 * s3;
        pr  <= std_logic_vector(k1 - k3);                     -- dokładnie ar·br - ai·bi
        pi  <= std_logic_vector(k1 + k2);
      end if;
    end process;
  end generate;
end architecture rtl;
