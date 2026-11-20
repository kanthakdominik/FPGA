-- Odbiornik UART z nadpróbkowaniem (20.01): synchronizator, OVS próbek na bit, wykrycie startu,
-- decyzja większościowa z trzech próbek w środku bitu, odrzucanie fałszywego startu, powrót do
-- oczekiwania już w środku bitu stopu. PARZ: 0 — brak, 1 — nieparzysta, 2 — parzysta.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
  generic (
    CLK_HZ : positive := 50_000_000;
    BAUD   : positive := 115_200;
    PARZ   : natural  := 0;
    OVS    : positive := 16
  );
  port (
    clk        : in  std_logic;
    rst        : in  std_logic;
    rx         : in  std_logic;
    dane       : out std_logic_vector(7 downto 0);
    wazne      : out std_logic := '0';
    blad_ramki : out std_logic := '0';
    blad_parz  : out std_logic := '0'
  );
end entity uart_rx;

architecture rtl of uart_rx is
  function jako_bit(b : boolean) return std_logic is
  begin
    if b then return '1'; else return '0'; end if;
  end function;
  constant NIEP : std_logic := jako_bit(PARZ = 1);              -- parzystość nieparzysta: odwrócenie
  constant NDANE  : positive := 8 + minimum(PARZ, 1);
  constant SRODEK : natural  := OVS / 2;
  type stan_t is (S_CZEKA, S_START, S_BITY, S_STOP);

  signal syn    : std_logic_vector(1 downto 0) := "11";
  attribute altera_attribute : string;
  attribute altera_attribute of syn : signal is "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS";
  signal rx_s   : std_logic;
  signal acc    : unsigned(31 downto 0) := (others => '0');
  signal tick   : std_logic;
  signal stan   : stan_t := S_CZEKA;
  signal faza   : natural range 0 to OVS - 1 := 0;
  signal nbit   : natural range 0 to NDANE := 0;
  signal probki : std_logic_vector(2 downto 0) := "111";
  signal sr     : std_logic_vector(NDANE - 1 downto 0);
  signal wiek   : std_logic;
begin
  syn  <= syn(0) & rx when rising_edge(clk);
  rx_s <= syn(1);

  -- takt nadpróbkowania: OVS·BAUD na sekundę
  process (clk)
    variable suma : unsigned(32 downto 0);
  begin
    if rising_edge(clk) then
      suma := ('0' & acc) + OVS * BAUD;
      if suma >= CLK_HZ then
        acc  <= resize(suma - CLK_HZ, 32);
        tick <= '1';
      else
        acc  <= resize(suma, 32);
        tick <= '0';
      end if;
    end if;
  end process;

  wiek <= (probki(0) and probki(1)) or (probki(0) and probki(2)) or (probki(1) and probki(2));

  process (clk)
  begin
    if rising_edge(clk) then
      wazne <= '0';
      if rst = '1' then
        stan <= S_CZEKA;
      elsif tick = '1' then
        faza <= 0 when faza = OVS - 1 else faza + 1;
        if faza = SRODEK - 1 or faza = SRODEK or faza = SRODEK + 1 then
          probki <= probki(1 downto 0) & rx_s;
        end if;
        case stan is
          when S_CZEKA =>
            if rx_s = '0' then                                  -- początek bitu startu
              stan <= S_START;
              faza <= 1;
            end if;
          when S_START =>
            if faza = SRODEK + 2 then
              if wiek = '1' then stan <= S_CZEKA; end if;      -- zakłócenie — to nie był start
            elsif faza = OVS - 1 then
              stan <= S_BITY;
              nbit <= 0;
            end if;
          when S_BITY =>
            if faza = SRODEK + 2 then
              sr <= wiek & sr(NDANE - 1 downto 1);              -- od najmłodszego bitu
            elsif faza = OVS - 1 then
              if nbit = NDANE - 1 then stan <= S_STOP; end if;
              nbit <= nbit + 1;
            end if;
          when S_STOP =>
            if faza = SRODEK + 2 then
              dane       <= sr(7 downto 0);
              wazne      <= '1';
              blad_ramki <= not wiek;
              if PARZ /= 0 then
                blad_parz <= (xor sr) xor NIEP;
              else
                blad_parz <= '0';
              end if;
              stan <= S_CZEKA;
            end if;
        end case;
      end if;
    end if;
  end process;
end architecture rtl;
