-- Filtr FIR, 8 współczynników, stałoprzecinkowy — układ weryfikowany w module 12.
-- Wejście: 12 bitów ze znakiem, strumień z in_valid (bez wstrzymania). Współczynniki Q1.15, symetryczne,
-- dolnoprzepustowe, suma = 32768 (wzmocnienie 1 dla składowej stałej):
--   h = (-763, 0, 4499, 12648, 12648, 4499, 0, -763)
-- Wyjście: 16 bitów ze znakiem = nasycenie(zaokrąglenie(suma / 2^11)) - 4 bity ułamkowe więcej niż wejście.
-- Zaokrąglenie "połówka w górę": (suma + 1024) shift_right 11. Potok 3 takty: iloczyny, suma, zaokrąglenie.
--
-- Generic BUG wstrzykuje błąd do ćwiczeń weryfikacji (0 = układ poprawny):
--   1 - obcięcie zamiast zaokrąglenia (różnica najwyżej 1 LSB),
--   2 - brak nasycenia (przepełnienie zawija wynik).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fir8 is
  generic (
    BUG : natural := 0
  );
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    in_valid  : in  std_logic;
    in_data   : in  signed(11 downto 0);
    out_valid : out std_logic;
    out_data  : out signed(15 downto 0)
  );
end entity fir8;

architecture rtl of fir8 is
  type coef_t is array (0 to 7) of integer;
  constant H : coef_t := (-763, 0, 4499, 12648, 12648, 4499, 0, -763);

  type x_t is array (0 to 7) of signed(11 downto 0);
  type p_t is array (0 to 7) of signed(27 downto 0);

  signal x       : x_t := (others => (others => '0'));  -- x(0) - najnowsza próbka
  signal p       : p_t := (others => (others => '0'));  -- iloczyny
  signal acc     : signed(30 downto 0) := (others => '0');
  signal v       : std_logic_vector(2 downto 0) := "000";
  signal valid_q : std_logic := '0';
  signal sat     : signed(15 downto 0);
begin
  -- zaokrąglenie i nasycenie
  process (all)
    variable r : signed(30 downto 0);
    variable s : signed(19 downto 0);
  begin
    if BUG = 1 then
      r := acc;
    else
      r := acc + 1024;
    end if;
    s := resize(shift_right(r, 11), 20);
    if BUG = 2 then
      sat <= resize(s, 16);
    elsif s > 32767 then
      sat <= to_signed(32767, 16);
    elsif s < -32768 then
      sat <= to_signed(-32768, 16);
    else
      sat <= resize(s, 16);
    end if;
  end process;

  process (clk)
    variable sum : signed(30 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        x       <= (others => (others => '0'));
        v       <= "000";
        valid_q <= '0';
      else
        if in_valid = '1' then
          x <= in_data & x(0 to 6);
        end if;
        v       <= v(1 downto 0) & in_valid;
        valid_q <= v(2);
      end if;
      for i in 0 to 7 loop
        p(i) <= resize(x(i) * to_signed(H(i), 16), 28);
      end loop;
      sum := (others => '0');
      for i in 0 to 7 loop
        sum := sum + resize(p(i), 31);
      end loop;
      acc      <= sum;
      out_data <= sat;
    end if;
  end process;

  out_valid <= valid_q;
end architecture rtl;
