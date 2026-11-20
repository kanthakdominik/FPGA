-- SPI slave z nadpróbkowaniem (20.02): SCLK, MOSI, CS_N przez synchronizatory, zbocza wykrywane w logice
-- (f_clk >= ok. 10·f_SCLK). Nadawanie jak kolejka: tx_dane pobierane przy CS, jeśli nic nie czeka,
-- i zaraz po każdym słowie (impuls tx_pobrany). rx_wazne — impuls z odebranym słowem.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_slave is
  generic (N : positive := 8);
  port (
    clk        : in  std_logic;
    rst        : in  std_logic;
    cpol       : in  std_logic;
    cpha       : in  std_logic;
    sclk       : in  std_logic;
    mosi       : in  std_logic;
    miso       : out std_logic;
    miso_oe    : out std_logic;
    cs_n       : in  std_logic;
    tx_dane    : in  std_logic_vector(N - 1 downto 0);
    tx_pobrany : out std_logic := '0';
    rx_dane    : out std_logic_vector(N - 1 downto 0);
    rx_wazne   : out std_logic := '0'
  );
end entity spi_slave;

architecture rtl of spi_slave is
  signal s_sclk, s_mosi : std_logic_vector(1 downto 0) := "00";
  signal s_cs           : std_logic_vector(1 downto 0) := "11";
  attribute altera_attribute : string;
  attribute altera_attribute of s_sclk, s_mosi, s_cs : signal is "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS";
  signal sclk_d         : std_logic := '0';
  signal cs_d           : std_logic := '1';
  signal aktywny, cs_spad, zbocze, wiodace, koncowe, probkuj, wystaw : boolean;
  signal sr_tx, sr_rx   : std_logic_vector(N - 1 downto 0) := (others => '0');
  signal licz           : natural range 0 to N - 1 := 0;
  signal pierwsze       : boolean := true;
  signal czeka          : boolean := false;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      s_sclk <= s_sclk(0) & sclk;
      s_mosi <= s_mosi(0) & mosi;
      s_cs   <= s_cs(0) & cs_n;
      sclk_d <= s_sclk(1);
      cs_d   <= s_cs(1);
    end if;
  end process;

  aktywny <= s_cs(1) = '0';
  cs_spad <= cs_d = '1' and s_cs(1) = '0';
  zbocze  <= s_sclk(1) /= sclk_d and aktywny;
  wiodace <= zbocze and sclk_d = cpol;
  koncowe <= zbocze and sclk_d /= cpol;
  probkuj <= koncowe when cpha = '1' else wiodace;
  wystaw  <= wiodace when cpha = '1' else koncowe;
  miso    <= sr_tx(N - 1);
  miso_oe <= '1' when aktywny else '0';

  process (clk)
    variable nowe : std_logic_vector(N - 1 downto 0);
  begin
    if rising_edge(clk) then
      rx_wazne   <= '0';
      tx_pobrany <= '0';
      if rst = '1' then
        czeka <= false;
        licz  <= 0;
      elsif not aktywny then
        licz <= 0;
      elsif cs_spad then
        if not czeka then
          sr_tx      <= tx_dane;
          tx_pobrany <= '1';
          czeka      <= true;
        end if;
        licz     <= 0;
        pierwsze <= true;
      else
        if probkuj then
          nowe  := sr_rx(N - 2 downto 0) & s_mosi(1);
          sr_rx <= nowe;
          if licz = 0 then czeka <= false; end if;            -- słowo w drodze
          if licz = N - 1 then
            rx_dane  <= nowe;
            rx_wazne <= '1';
            licz     <= 0;
            if cpha = '1' then                                 -- CPHA = 1: następne słowo od razu
              sr_tx      <= tx_dane;
              tx_pobrany <= '1';
              czeka      <= true;
              pierwsze   <= true;
            end if;
          else
            licz <= licz + 1;
          end if;
        end if;
        if wystaw then
          if cpha = '0' and licz = 0 and not pierwsze then     -- CPHA = 0: po ostatnim bicie — nowe słowo
            sr_tx      <= tx_dane;
            tx_pobrany <= '1';
            czeka      <= true;
          elsif cpha = '1' and pierwsze then
            pierwsze <= false;                                 -- pierwszy bit słowa już wystawiony
          else
            sr_tx <= sr_tx(N - 2 downto 0) & '0';
          end if;
          if cpha = '0' then pierwsze <= false; end if;
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
