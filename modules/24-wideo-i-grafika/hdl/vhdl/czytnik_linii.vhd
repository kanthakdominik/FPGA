-- Czytnik linii obrazu (24.04): master Avalon-MM z odczytami burstowymi. Po impulsie start czyta SLOW słów od
-- adresu adr (bursty po maks. BURST słów, kolejne rozkazy bez czekania na dane) i zapisuje je do bufora linii
-- pod adresy bufor·SLOW + i. zajety = '1' do odebrania ostatniego słowa; gotowe — impuls na końcu.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity czytnik_linii is
  generic (
    SLOW  : positive := 40;
    BURST : positive := 8;                       -- ≤ 16
    AW    : positive := 16;
    LW    : positive := 7
  );
  port (
    clk          : in  std_logic;
    rst          : in  std_logic;
    start        : in  std_logic;
    adr          : in  unsigned(AW - 1 downto 0);
    bufor        : in  std_logic;
    zajety       : out std_logic := '0';
    gotowe       : out std_logic := '0';
    m_adr        : out unsigned(AW - 1 downto 0) := (others => '0');
    m_read       : out std_logic := '0';
    m_burstcount : out unsigned(4 downto 0) := (others => '0');
    m_wait       : in  std_logic;
    m_rvalid     : in  std_logic;
    m_rdata      : in  std_logic_vector(31 downto 0);
    lw_we        : out std_logic := '0';
    lw_adr       : out unsigned(LW - 1 downto 0) := (others => '0');
    lw_dane      : out std_logic_vector(31 downto 0) := (others => '0')
  );
end entity czytnik_linii;

architecture rtl of czytnik_linii is
  signal wyd, odb    : natural range 0 to SLOW := 0;
  signal nast_adr    : unsigned(AW - 1 downto 0) := (others => '0');
  signal baza_b      : natural range 0 to SLOW := 0;
  signal zaj, rd     : std_logic := '0';
begin
  zajety <= zaj;
  m_read <= rd;

  process (clk)
    variable dl : natural range 0 to SLOW;
  begin
    if rising_edge(clk) then
      if rst = '1' then
        zaj <= '0'; gotowe <= '0'; rd <= '0'; m_adr <= (others => '0'); m_burstcount <= (others => '0');
        lw_we <= '0'; lw_adr <= (others => '0'); lw_dane <= (others => '0');
        wyd <= 0; odb <= 0; nast_adr <= (others => '0'); baza_b <= 0;
      else
        gotowe <= '0';
        lw_we  <= '0';
        if zaj = '0' then
          if start = '1' then
            zaj <= '1'; wyd <= 0; odb <= 0; nast_adr <= adr;
            if bufor = '1' then baza_b <= SLOW; else baza_b <= 0; end if;
          end if;
        else
          if rd = '0' or m_wait = '0' then                  -- brak rozkazu albo właśnie przyjęty
            rd <= '0';
            if wyd /= SLOW then
              if SLOW - wyd > BURST then dl := BURST; else dl := SLOW - wyd; end if;
              rd           <= '1';
              m_adr        <= nast_adr;
              m_burstcount <= to_unsigned(dl, 5);
              nast_adr     <= nast_adr + dl;
              wyd          <= wyd + dl;
            end if;
          end if;
          if m_rvalid = '1' then
            lw_we   <= '1';
            lw_adr  <= to_unsigned(baza_b + odb, LW);
            lw_dane <= m_rdata;
            odb     <= odb + 1;
            if odb = SLOW - 1 then
              zaj <= '0'; gotowe <= '1';
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
