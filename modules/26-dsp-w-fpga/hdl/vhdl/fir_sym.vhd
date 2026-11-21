-- Filtr FIR symetryczny (26.01), N nieparzyste: h_i = h_{N-1-i}, więc przed mnożeniem dodaje się pary próbek —
-- (N+1)/2 mnożeń zamiast N. Potok: linia opóźniająca -> sumy par -> mnożenia -> suma -> zaokrąglenie
-- i nasycenie; opóźnienie 4 takty, jedna próbka na takt. Używane współczynniki h_0..h_{(N-1)/2} z wsp.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.dsp_pkg.all;

entity fir_sym is
  generic (N : positive := 31);
  port (
    clk, rst, we : in  std_logic;
    x            : in  signed(15 downto 0);
    wsp          : in  std_logic_vector(16 * N - 1 downto 0);
    y            : out signed(15 downto 0) := (others => '0');
    y_wazne      : out std_logic := '0'
  );
end entity fir_sym;

architecture rtl of fir_sym is
  constant P : positive := (N + 1) / 2;
  type lin_t is array (0 to N - 1) of signed(15 downto 0);
  type p_t is array (0 to P - 1) of signed(16 downto 0);
  type m_t is array (0 to P - 1) of signed(32 downto 0);
  signal lin : lin_t := (others => (others => '0'));
  signal pp  : p_t := (others => (others => '0'));
  signal m   : m_t := (others => (others => '0'));
  signal s   : signed(39 downto 0) := (others => '0');
  signal v   : std_logic_vector(3 downto 0) := (others => '0');
begin
  process (clk)
    variable suma : signed(39 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        lin <= (others => (others => '0'));
        v   <= (others => '0');
      else
        v <= v(2 downto 0) & we;
        if we = '1' then
          lin(0) <= x;
          for i in 1 to N - 1 loop
            lin(i) <= lin(i - 1);
          end loop;
        end if;
      end if;
      for i in 0 to P - 2 loop                                        -- stopień 1: sumy par
        pp(i) <= resize(lin(i), 17) + resize(lin(N - 1 - i), 17);
      end loop;
      pp(P - 1) <= resize(lin(P - 1), 17);                            -- środkowy współczynnik
      for i in 0 to P - 1 loop                                        -- stopień 2: mnożenia
        m(i) <= wsp_h(wsp, i) * pp(i);
      end loop;
      suma := (others => '0');                                        -- stopień 3: suma
      for i in 0 to P - 1 loop
        suma := suma + resize(m(i), 40);
      end loop;
      s       <= suma;
      y       <= nasyc(zaokr(s, 15), 16);                             -- stopień 4
      y_wazne <= v(3);
    end if;
  end process;
end architecture rtl;
