-- Echo (25.02): y[n] = nasyc(x[n] + g·y[n-D]/256), linia opóźniająca D próbek w pamięci (16 starszych bitów y).
-- Dwa takty na próbkę: odczyt pamięci, potem suma i zapis.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity echo is
  generic (D : positive := 1024);
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    we      : in  std_logic;
    x       : in  signed(23 downto 0);
    g       : in  unsigned(7 downto 0);
    y       : out signed(23 downto 0) := (others => '0');
    y_wazne : out std_logic := '0'
  );
end entity echo;

architecture rtl of echo is
  type ram_t is array (0 to D - 1) of signed(15 downto 0);
  signal ram  : ram_t := (others => (others => '0'));
  signal ptr  : natural range 0 to D - 1 := 0;
  signal q    : signed(15 downto 0) := (others => '0');
  signal xr   : signed(23 downto 0) := (others => '0');
  signal faza : std_logic := '0';
begin
  process (clk)
    variable il   : signed(40 downto 0);
    variable suma : signed(32 downto 0);
    variable nas  : signed(23 downto 0);
  begin
    if rising_edge(clk) then
      y_wazne <= '0';
      q <= ram(ptr);
      il   := (q & x"00") * signed('0' & std_logic_vector(resize(g, 16)));   -- 24 × 17 bitów
      suma := resize(xr, 33) + resize(shift_right(il, 8), 33);
      if suma > 8388607 then nas := to_signed(8388607, 24);
      elsif suma < -8388608 then nas := to_signed(-8388608, 24);
      else nas := resize(suma, 24);
      end if;
      if rst = '1' then
        ptr <= 0; faza <= '0'; xr <= (others => '0'); y <= (others => '0');
      elsif faza = '0' then
        if we = '1' then xr <= x; faza <= '1'; end if;
      else
        y <= nas; y_wazne <= '1';
        ram(ptr) <= nas(23 downto 8);
        if ptr = D - 1 then ptr <= 0; else ptr <= ptr + 1; end if;
        faza <= '0';
      end if;
    end if;
  end process;
end architecture rtl;
