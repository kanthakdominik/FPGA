-- Decymator CIC (26.04): N = 3 integratory przy częstotliwości wejściowej, decymacja przez R, 3 sekcje
-- grzebieniowe przy wyjściowej. Rejestry 25 bitów (16 + log2((R·M)^N) dla R = 8), arytmetyka modulo 2^25 —
-- przepełnienia integratorów znoszą się w grzebieniach. Wynik: 9 bitów w prawo. Bez mnożarek.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cic_dec is
  generic (R : positive := 8);
  port (
    clk, rst, we : in  std_logic;
    x            : in  signed(15 downto 0);
    y            : out signed(15 downto 0) := (others => '0');
    y_wazne      : out std_logic := '0'
  );
end entity cic_dec;

architecture rtl of cic_dec is
  signal i1, i2, i3, d1, d2, d3 : signed(24 downto 0) := (others => '0');
  signal n                      : natural range 0 to R - 1 := 0;
begin
  process (clk)
    variable i1n, i2n, i3n, c1, c2, c3 : signed(24 downto 0);
  begin
    if rising_edge(clk) then
      y_wazne <= '0';
      if rst = '1' then
        i1 <= (others => '0'); i2 <= (others => '0'); i3 <= (others => '0');
        d1 <= (others => '0'); d2 <= (others => '0'); d3 <= (others => '0');
        n  <= 0; y <= (others => '0');
      elsif we = '1' then
        i1n := i1 + resize(x, 25);
        i2n := i2 + i1n;
        i3n := i3 + i2n;
        i1 <= i1n; i2 <= i2n; i3 <= i3n;
        if n = R - 1 then                                            -- co R-ta próbka: grzebienie
          n  <= 0;
          c1 := i3n - d1;
          c2 := c1 - d2;
          c3 := c2 - d3;
          d1 <= i3n; d2 <= c1; d3 <= c2;
          y       <= c3(24 downto 9);
          y_wazne <= '1';
        else
          n <= n + 1;
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
