-- Filtr FIR w strukturze transponowanej (26.01): y[n] = h0·x[n] + z1, z_k = h_k·x[n] + z_{k+1}. Każde mnożenie
-- ma swój rejestr sumy — długa ścieżka to jedno mnożenie i jedno dodawanie, niezależnie od N. Współczynniki
-- Q1.15 na wejściu wsp, wynik zaokrąglony i nasycony do 16 bitów; jedna próbka na takt, wynik takt później.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.dsp_pkg.all;

entity fir_transp is
  generic (N : positive := 31);
  port (
    clk, rst, we : in  std_logic;
    x            : in  signed(15 downto 0);
    wsp          : in  std_logic_vector(16 * N - 1 downto 0);
    y            : out signed(15 downto 0) := (others => '0');
    y_wazne      : out std_logic := '0'
  );
end entity fir_transp;

architecture rtl of fir_transp is
  type z_t is array (1 to N - 1) of signed(39 downto 0);
  signal z : z_t := (others => (others => '0'));
begin
  process (clk)
  begin
    if rising_edge(clk) then
      y_wazne <= '0';
      if rst = '1' then
        z <= (others => (others => '0'));
        y <= (others => '0');
      elsif we = '1' then
        for i in 1 to N - 2 loop
          z(i) <= resize(wsp_h(wsp, i) * x, 40) + z(i + 1);
        end loop;
        z(N - 1) <= resize(wsp_h(wsp, N - 1) * x, 40);
        y        <= nasyc(zaokr(resize(wsp_h(wsp, 0) * x, 40) + z(1), 15), 16);
        y_wazne  <= '1';
      end if;
    end if;
  end process;
end architecture rtl;
