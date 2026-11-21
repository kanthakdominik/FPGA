-- Odpowiadanie na zapytania ARP (25.04). Część odbiorcza (clk_rx) sprawdza ramkę z mii_rx (adres docelowy nasz
-- albo rozgłoszeniowy, typ 0x0806, Ethernet/IPv4, operacja 1, szukany IP = ip_moj, poprawne CRC) i zapamiętuje
-- adres pytającego; zgłoszenie przechodzi do części nadawczej (clk_tx) bitem przełączanym przez synchronizator.
-- Część nadawcza wystawia 42 bajty odpowiedzi (operacja 2) i podaje nauczony adres pytającego.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity arp_odp is
  port (
    clk_rx    : in  std_logic;
    rst_rx    : in  std_logic;
    r_dane    : in  std_logic_vector(7 downto 0);
    r_wazne   : in  std_logic;
    r_koniec  : in  std_logic;
    r_crc_ok  : in  std_logic;
    mac_moj   : in  std_logic_vector(47 downto 0);
    ip_moj    : in  std_logic_vector(31 downto 0);
    clk_tx    : in  std_logic;
    rst_tx    : in  std_logic;
    chce      : out std_logic;
    m_dane    : out std_logic_vector(7 downto 0);
    m_wazne   : out std_logic;
    m_ostatni : out std_logic;
    m_gotowy  : in  std_logic;
    mac_pyt   : out std_logic_vector(47 downto 0) := (others => '0');
    ip_pyt    : out std_logic_vector(31 downto 0) := (others => '0');
    nauczony  : out std_logic := '0'
  );
end entity arp_odp;

architecture rtl of arp_odp is
  -- odbiór
  signal k              : natural range 0 to 63 := 0;
  signal zgodne         : std_logic := '1';
  signal sha, sha_z     : std_logic_vector(47 downto 0) := (others => '0');
  signal spa, spa_z     : std_logic_vector(31 downto 0) := (others => '0');
  signal t_odp          : std_logic := '0';
  -- nadawanie
  signal s_odp          : std_logic_vector(2 downto 0) := "000";
  signal czeka          : std_logic := '0';
  signal i              : natural range 0 to 41 := 0;
  signal odp            : std_logic_vector(42 * 8 - 1 downto 0) := (others => '0');
begin
  process (clk_rx)
    variable oczek : std_logic_vector(7 downto 0);
    variable spr   : boolean;
  begin
    if rising_edge(clk_rx) then
      spr := true;
      case k is
        when 12 => oczek := x"08"; when 13 => oczek := x"06"; when 14 => oczek := x"00"; when 15 => oczek := x"01";
        when 16 => oczek := x"08"; when 17 => oczek := x"00"; when 18 => oczek := x"06"; when 19 => oczek := x"04";
        when 20 => oczek := x"00"; when 21 => oczek := x"01";
        when 38 => oczek := ip_moj(31 downto 24); when 39 => oczek := ip_moj(23 downto 16);
        when 40 => oczek := ip_moj(15 downto 8);  when 41 => oczek := ip_moj(7 downto 0);
        when others => oczek := x"00"; spr := false;
      end case;
      if rst_rx = '1' then
        k <= 0; zgodne <= '1'; sha <= (others => '0'); spa <= (others => '0'); t_odp <= '0';
      else
        if r_wazne = '1' then
          if k /= 63 then k <= k + 1; end if;
          if k < 6 and r_dane /= x"FF" and r_dane /= mac_moj(8 * (6 - k) - 1 downto 8 * (5 - k)) then zgodne <= '0'; end if;
          if spr and r_dane /= oczek then zgodne <= '0'; end if;
          if k >= 22 and k <= 27 then sha <= sha(39 downto 0) & r_dane; end if;
          if k >= 28 and k <= 31 then spa <= spa(23 downto 0) & r_dane; end if;
        end if;
        if r_koniec = '1' then
          if zgodne = '1' and r_crc_ok = '1' and k >= 42 then
            sha_z <= sha; spa_z <= spa; t_odp <= not t_odp;
          end if;
          k <= 0; zgodne <= '1';
        end if;
      end if;
    end if;
  end process;

  chce      <= czeka;
  m_wazne   <= czeka;
  m_dane    <= odp(8 * (42 - i) - 1 downto 8 * (41 - i));
  m_ostatni <= '1' when i = 41 else '0';

  process (clk_tx)
  begin
    if rising_edge(clk_tx) then
      s_odp <= s_odp(1 downto 0) & t_odp;
      if rst_tx = '1' then
        czeka <= '0'; i <= 0; nauczony <= '0';
      elsif s_odp(2) /= s_odp(1) and czeka = '0' then
        czeka <= '1'; i <= 0;
        odp <= sha_z & mac_moj & x"0806" & x"0001" & x"0800" & x"06" & x"04" & x"0002" & mac_moj & ip_moj & sha_z & spa_z;
        mac_pyt <= sha_z; ip_pyt <= spa_z; nauczony <= '1';
      elsif czeka = '1' and m_gotowy = '1' then
        if i = 41 then czeka <= '0'; else i <= i + 1; end if;
      end if;
    end if;
  end process;
end architecture rtl;
