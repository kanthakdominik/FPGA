-- Dzielnik kombinacyjny ze ścieżką wielotaktową (14.04): q = a / b, r = a mod b.
-- start = '1' zapisuje argumenty do a_r, b_r; wynik trafia do q, r dokładnie N taktów później (done = '1').
-- Między a_r/b_r a q/r jest długa logika kombinacyjna, ale argumenty są stałe przez N taktów,
-- więc ścieżka ma N okresów zegara: set_multicycle_path -setup N, -hold N-1 (pliki .sdc modułu).
-- b = 0: q = same jedynki, r = a (jak w wielu procesorach RISC-V).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dzielnik_mc is
  generic (
    W : positive := 16;                      -- szerokość dzielnej
    V : positive := 8;                       -- szerokość dzielnika
    N : positive := 4                        -- liczba taktów na dzielenie (>= 2)
  );
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    start : in  std_logic;                   -- ignorowane, gdy busy
    a     : in  unsigned(W - 1 downto 0);
    b     : in  unsigned(V - 1 downto 0);
    busy  : out std_logic;
    done  : out std_logic;                   -- 1 takt, wynik ważny od tego taktu
    q     : out unsigned(W - 1 downto 0);
    r     : out unsigned(V - 1 downto 0)
  );
end entity dzielnik_mc;

architecture rtl of dzielnik_mc is
  signal a_r    : unsigned(W - 1 downto 0) := (others => '0');
  signal b_r    : unsigned(V - 1 downto 0) := (others => '0');
  signal b_safe : unsigned(W - 1 downto 0);
  signal cnt    : natural range 0 to N - 1 := 0;
  signal busy_r : std_logic := '0';
begin
  -- dzielnik nigdy nie jest zerem w wyrażeniu (symulacja VHDL zgłosiłaby błąd); b = 0 obsługuje warunek niżej
  b_safe <= resize(b_r, W) when b_r /= 0 else to_unsigned(1, W);

  process (clk)
  begin
    if rising_edge(clk) then
      done <= '0';
      if rst = '1' then
        busy_r <= '0';
        cnt    <= 0;
      elsif busy_r = '0' then
        if start = '1' then
          a_r    <= a;
          b_r    <= b;
          busy_r <= '1';
          cnt    <= 0;
        end if;
      elsif cnt = N - 1 then
        -- jedyny takt, w którym wynik jest zapisywany: N taktów po zapisie argumentów
        if b_r = 0 then
          q <= (others => '1');
          r <= a_r(V - 1 downto 0);
        else
          q <= a_r / b_safe;
          r <= resize(a_r mod b_safe, V);
        end if;
        busy_r <= '0';
        done   <= '1';
      else
        cnt <= cnt + 1;
      end if;
    end if;
  end process;

  busy <= busy_r;
end architecture rtl;
