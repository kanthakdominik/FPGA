-- Odbiornik MAC dla MII (25.03): preambuła i SFD, składanie bajtów, bajty danych z opóźnieniem 4 bajtów (FCS nie
-- jest przekazywany), na końcu ramki impuls koniec z crc_ok (reszta CRC-32 = 0xDEBB20E3), dlugosc i blad.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mii_rx is
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    rxd     : in  std_logic_vector(3 downto 0);
    rx_dv   : in  std_logic;
    rx_er   : in  std_logic;
    m_dane  : out std_logic_vector(7 downto 0) := (others => '0');
    m_wazne : out std_logic := '0';
    koniec  : out std_logic := '0';
    crc_ok  : out std_logic := '0';
    dlugosc : out unsigned(10 downto 0) := (others => '0');
    blad    : out std_logic := '0'
  );
end entity mii_rx;

architecture rtl of mii_rx is
  function crc_bajt(c : std_logic_vector(31 downto 0); d : std_logic_vector(7 downto 0)) return std_logic_vector is
    variable r : std_logic_vector(31 downto 0);
  begin
    r := c xor (x"000000" & d);
    for i in 0 to 7 loop
      if r(0) = '1' then r := ('0' & r(31 downto 1)) xor x"EDB88320"; else r := '0' & r(31 downto 1); end if;
    end loop;
    return r;
  end function;

  type stan_t is (S_BEZCZ, S_PREAMB, S_DANE, S_POMIN);
  signal stan    : stan_t := S_BEZCZ;
  signal h, er   : std_logic := '0';
  signal mlodsza : std_logic_vector(3 downto 0) := "0000";
  signal opozn   : std_logic_vector(31 downto 0) := (others => '0');
  signal n       : natural range 0 to 2047 := 0;
  signal crc     : std_logic_vector(31 downto 0) := (others => '1');
begin
  process (clk)
    variable bajt : std_logic_vector(7 downto 0);
  begin
    if rising_edge(clk) then
      m_wazne <= '0';
      koniec  <= '0';
      bajt := rxd & mlodsza;
      if rst = '1' then
        stan <= S_BEZCZ; h <= '0'; mlodsza <= "0000"; opozn <= (others => '0'); n <= 0; crc <= (others => '1');
        er <= '0'; m_dane <= (others => '0'); crc_ok <= '0'; dlugosc <= (others => '0'); blad <= '0';
      else
        case stan is
          when S_BEZCZ =>
            if rx_dv = '1' then
              if rxd = x"5" then stan <= S_PREAMB; else stan <= S_POMIN; end if;
            end if;
          when S_PREAMB =>
            if rx_dv = '0' then stan <= S_BEZCZ;
            elsif rxd = x"D" then
              stan <= S_DANE; h <= '0'; n <= 0; crc <= (others => '1'); er <= rx_er;
            elsif rxd /= x"5" then stan <= S_POMIN;
            end if;
          when S_DANE =>
            if rx_dv = '0' then
              koniec <= '1';
              if crc = x"DEBB20E3" and h = '0' and er = '0' and n >= 4 then crc_ok <= '1'; else crc_ok <= '0'; end if;
              blad <= er or h;
              if n >= 4 then dlugosc <= to_unsigned(n - 4, 11); else dlugosc <= (others => '0'); end if;
              stan <= S_BEZCZ;
            else
              if rx_er = '1' then er <= '1'; end if;
              if h = '0' then
                mlodsza <= rxd; h <= '1';
              else
                h     <= '0';
                crc   <= crc_bajt(crc, bajt);
                opozn <= opozn(23 downto 0) & bajt;
                if n /= 2047 then n <= n + 1; end if;
                if n >= 4 then m_dane <= opozn(31 downto 24); m_wazne <= '1'; end if;
              end if;
            end if;
          when S_POMIN =>
            if rx_dv = '0' then stan <= S_BEZCZ; end if;
        end case;
      end if;
    end if;
  end process;
end architecture rtl;
