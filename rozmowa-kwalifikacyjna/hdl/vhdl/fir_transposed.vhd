-- Zadanie 12: filtr FIR 8 współczynników w strukturze transponowanej, h = 2, -10, 40, 96, 96, 40, -10, 2.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fir_transposed is
  port (
    clk : in  std_logic;
    rst : in  std_logic;
    en  : in  std_logic;
    x   : in  signed(11 downto 0);
    y   : out signed(23 downto 0)
  );
end entity;

architecture rtl of fir_transposed is
  type coef_t is array (0 to 7) of integer;
  constant H : coef_t := (2, -10, 40, 96, 96, 40, -10, 2);
  type sums_t is array (0 to 6) of signed(23 downto 0);
  signal s   : sums_t := (others => (others => '0'));
  signal y_q : signed(23 downto 0) := (others => '0');

  function mul(v : signed(11 downto 0); c : integer) return signed is
  begin
    return resize(v * to_signed(c, 12), 24);
  end function;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        y_q <= (others => '0');
        s   <= (others => (others => '0'));
      elsif en = '1' then
        y_q <= mul(x, H(0)) + s(0);
        for k in 0 to 5 loop
          s(k) <= mul(x, H(k + 1)) + s(k + 1);
        end loop;
        s(6) <= mul(x, H(7));
      end if;
    end if;
  end process;

  y <= y_q;
end architecture;
