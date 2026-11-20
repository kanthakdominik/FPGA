-- Dekoder enkodera kwadraturowego (20.04): synchronizator, filtr (stan stały przez FILTR taktów),
-- dekodowanie ×4 (A wyprzedza B — w przód), liczenie niedozwolonych przejść (zmiana A i B naraz).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity enkoder is
  generic (
    W     : positive := 16;
    FILTR : positive := 8
  );
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    a        : in  std_logic;
    b        : in  std_logic;
    pozycja  : out std_logic_vector(W - 1 downto 0) := (others => '0');
    kierunek : out std_logic := '0';
    bledy    : out std_logic_vector(7 downto 0) := (others => '0')
  );
end entity enkoder;

architecture rtl of enkoder is
  signal s_a, s_b : std_logic_vector(1 downto 0) := "00";
  attribute altera_attribute : string;
  attribute altera_attribute of s_a, s_b : signal is "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS";
  signal kandydat, stan, stan_d : std_logic_vector(1 downto 0) := "00";
  signal stabil   : natural range 0 to FILTR := 0;
  signal poz      : unsigned(W - 1 downto 0) := (others => '0');
  signal bl       : unsigned(7 downto 0) := (others => '0');
begin
  pozycja <= std_logic_vector(poz);
  bledy   <= std_logic_vector(bl);

  process (clk)
    variable przejscie : std_logic_vector(3 downto 0);
  begin
    if rising_edge(clk) then
      s_a <= s_a(0) & a;
      s_b <= s_b(0) & b;
      -- filtr
      if (s_a(1) & s_b(1)) /= kandydat then
        kandydat <= s_a(1) & s_b(1);
        stabil   <= 0;
      elsif stabil /= FILTR then
        stabil <= stabil + 1;
      else
        stan <= kandydat;
      end if;
      stan_d <= stan;
      -- dekodowanie: Gray 00 -> 10 -> 11 -> 01 -> 00 = w przód
      przejscie := stan_d & stan;
      if rst = '1' then
        poz <= (others => '0');
        bl  <= (others => '0');
      else
        case przejscie is
          when "0010" | "1011" | "1101" | "0100" => poz <= poz + 1; kierunek <= '1';
          when "0001" | "0111" | "1110" | "1000" => poz <= poz - 1; kierunek <= '0';
          when "0011" | "1100" | "0110" | "1001" => if bl /= 255 then bl <= bl + 1; end if;
          when others => null;
        end case;
      end if;
    end if;
  end process;
end architecture rtl;
