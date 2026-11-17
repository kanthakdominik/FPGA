-- Nadajnik-odbiornik SPI w trybie 0 (CPOL = 0, CPHA = 0), 8 bitów, najstarszy bit pierwszy (14.06).
-- Zegar SPI sclk powstaje w rejestrze sclk_r z zegara clk: pół okresu = DIV taktów, f_sclk = f_clk / (2*DIV).
-- MOSI zmienia się przy opadającym zboczu sclk, MISO jest próbkowane przy narastającym - oba sygnały
-- są wyrównane do zegara przesyłanego razem z danymi (interfejs źródłowo-synchroniczny dla wyjść).
-- Ograniczenia: zegar generowany na sclk_r i na porcie, opóźnienia wyjść i wejścia względem niego
-- oraz ścieżki wielotaktowe (DIV taktów clk między zmianą danych a zboczem próbkującym) - 14.06.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_master is
  generic (
    DIV : positive := 2                       -- pół okresu sclk w taktach clk, >= 2
  );
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    start : in  std_logic;                    -- ignorowane, gdy busy
    tx    : in  std_logic_vector(7 downto 0);
    busy  : out std_logic;
    done  : out std_logic;                    -- 1 takt po zakończeniu bajtu
    rx    : out std_logic_vector(7 downto 0);
    sclk  : out std_logic;
    mosi  : out std_logic;
    cs_n  : out std_logic;
    miso  : in  std_logic
  );
end entity spi_master;

architecture rtl of spi_master is
  signal busy_r : std_logic := '0';
  signal sclk_r : std_logic := '0';
  signal cnt    : natural range 0 to DIV - 1 := 0;
  signal nbit   : natural range 0 to 7 := 0;
  signal sh_tx  : std_logic_vector(6 downto 0) := (others => '0');  -- bity jeszcze do wysłania
  signal sh_rx  : std_logic_vector(7 downto 0) := (others => '0');
begin
  process (clk)
  begin
    if rising_edge(clk) then
      done <= '0';
      if rst = '1' then
        busy_r <= '0';
        sclk_r <= '0';
        cs_n   <= '1';
        mosi   <= '0';
      elsif busy_r = '0' then
        if start = '1' then
          busy_r <= '1';
          cs_n   <= '0';
          sh_tx  <= tx(6 downto 0);
          mosi   <= tx(7);                    -- pierwszy bit przed pierwszym narastającym zboczem
          cnt    <= 0;
          nbit   <= 0;
        end if;
      elsif cnt /= DIV - 1 then
        cnt <= cnt + 1;
      else
        cnt <= 0;
        if sclk_r = '0' then                  -- zbocze narastające: próbkowanie MISO
          sclk_r <= '1';
          sh_rx  <= sh_rx(6 downto 0) & miso;
        else                                  -- zbocze opadające: następny bit MOSI albo koniec
          sclk_r <= '0';
          if nbit = 7 then
            busy_r <= '0';
            cs_n   <= '1';
            done   <= '1';
            rx     <= sh_rx;
          else
            nbit  <= nbit + 1;
            sh_tx <= sh_tx(5 downto 0) & '0';
            mosi  <= sh_tx(6);
          end if;
        end if;
      end if;
    end if;
  end process;

  busy <= busy_r;
  sclk <= sclk_r;
end architecture rtl;
