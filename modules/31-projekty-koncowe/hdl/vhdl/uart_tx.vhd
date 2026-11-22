-- Nadajnik UART (20.01): start (0), 8 bitów danych od najmłodszego, opcjonalna parzystość, STOP bitów stopu.
-- Takt bitowy z akumulatora fazy: średni okres dokładnie CLK_HZ/BAUD taktów.
--   PARZ: 0 — brak, 1 — nieparzysta, 2 — parzysta. start przy gotowy = '1' pobiera bajt.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
  generic (
    CLK_HZ : positive := 50_000_000;
    BAUD   : positive := 115_200;
    PARZ   : natural  := 0;
    STOP   : positive := 1
  );
  port (
    clk    : in  std_logic;
    rst    : in  std_logic;
    start  : in  std_logic;
    dane   : in  std_logic_vector(7 downto 0);
    gotowy : out std_logic;
    tx     : out std_logic := '1'
  );
end entity uart_tx;

architecture rtl of uart_tx is
  function jako_bit(b : boolean) return std_logic is
  begin
    if b then return '1'; else return '0'; end if;
  end function;
  constant NIEP : std_logic := jako_bit(PARZ = 1);              -- parzystość nieparzysta: odwrócenie
  constant NB : positive := 1 + 8 + minimum(PARZ, 1) + STOP;  -- bity ramki

  function ramka(d : std_logic_vector(7 downto 0)) return std_logic_vector is
    variable r : std_logic_vector(NB - 1 downto 0) := (others => '1');
  begin
    r(0)          := '0';
    r(8 downto 1) := d;
    if PARZ /= 0 then
      r(9) := (xor d) xor NIEP;      -- nieparzysta: dopełnienie do nieparzystej
    end if;
    return r;
  end function;

  signal sr     : std_logic_vector(NB - 1 downto 0);
  signal licz   : natural range 0 to NB;
  signal zajety : std_logic := '0';
  signal acc    : unsigned(31 downto 0);
begin
  gotowy <= not zajety;

  process (clk)
    variable suma : unsigned(32 downto 0);
  begin
    if rising_edge(clk) then
      suma := ('0' & acc) + BAUD;
      if rst = '1' then
        zajety <= '0';
        tx     <= '1';
      elsif zajety = '0' then
        if start = '1' then
          sr     <= ramka(dane);
          tx     <= '0';                                        -- bit startu
          licz   <= 0;
          acc    <= (others => '0');
          zajety <= '1';
        end if;
      else
        if suma >= CLK_HZ then
          acc <= resize(suma - CLK_HZ, 32);
          if licz = NB - 1 then                                 -- koniec ostatniego bitu stopu
            zajety <= '0';
            tx     <= '1';
          else
            sr   <= '1' & sr(NB - 1 downto 1);
            tx   <= sr(1);
            licz <= licz + 1;
          end if;
        else
          acc <= resize(suma, 32);
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
