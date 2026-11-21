-- DECA — strumień UDP do komputera (moduł 25, 25.03–25.05): PHY przez MII, mii_tx/mii_rx, arp_odp, udp_nad.
-- 1024 B danych: numer pakietu (4 B) + bajty (numer + i) mod 256. FPGA: 02:00:00:00:00:01, 192.168.1.200,
-- porty 5005 -> 5006; przed nauczeniem adresu komputera z ARP — adres rozgłoszeniowy. SW(1) — nadawanie,
-- SW(0) — pakiet co 1 ms albo jeden za drugim. MDIO: wyszukanie adresu PHY, potem odczyt stanu łącza.
-- Diody (0 = świeci): LED(0) PHY znaleziony, LED(1) łącze, LED(2) adres nauczony, LED(3) nadawanie, LED(7:4) licznik.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deca_top is
  port (
    MAX10_CLK1_50 : in    std_logic;
    KEY           : in    std_logic_vector(1 downto 0);
    SW            : in    std_logic_vector(1 downto 0);
    LED           : out   std_logic_vector(7 downto 0);
    NET_TX_CLK    : in    std_logic;
    NET_TXD       : out   std_logic_vector(3 downto 0);
    NET_TX_EN     : out   std_logic;
    NET_RX_CLK    : in    std_logic;
    NET_RXD       : in    std_logic_vector(3 downto 0);
    NET_RX_DV     : in    std_logic;
    NET_RX_ER     : in    std_logic;
    NET_COL       : in    std_logic;
    NET_CRS       : in    std_logic;
    NET_RESET_n   : out   std_logic;
    NET_MDC       : out   std_logic;
    NET_MDIO      : inout std_logic;
    NET_PCF_EN    : out   std_logic
  );
end entity deca_top;

architecture rtl of deca_top is
  constant MAC_FPGA : std_logic_vector(47 downto 0) := x"020000000001";
  constant IP_FPGA  : std_logic_vector(31 downto 0) := x"C0A801C8";

  signal clk, rst, phy_gotowy : std_logic;
  signal rs : std_logic_vector(1 downto 0) := "00";
  signal lr : natural range 0 to 1000000 := 0;
  signal m_start : std_logic := '0';
  signal m_phy : unsigned(4 downto 0) := (others => '0');
  signal m_rej : std_logic_vector(4 downto 0) := "00010";
  signal m_rdane : std_logic_vector(15 downto 0);
  signal m_got, m_zaj, mdio_o, mdio_oe, mdio_rst : std_logic;
  signal znaleziony, lacze : std_logic := '0';
  signal okres : unsigned(22 downto 0) := (others => '0');

  signal rrs, trs : std_logic_vector(1 downto 0) := "00";
  signal rst_rx, rst_tx : std_logic;
  signal r_dane : std_logic_vector(7 downto 0);
  signal r_wazne, r_koniec, r_crc_ok, r_blad : std_logic;
  signal r_dl : unsigned(10 downto 0);

  signal sw_t : std_logic_vector(1 downto 0) := "00";
  signal a_chce, a_wazne, a_ost, nauczony, tx_gotowy, a_got, u_got : std_logic;
  signal a_dane, u_dane, p_dane, s_dane : std_logic_vector(7 downto 0);
  signal mac_pc, mac_cel : std_logic_vector(47 downto 0);
  signal ip_pc, ip_cel : std_logic_vector(31 downto 0);
  signal wyb : natural range 0 to 2 := 0;
  signal u_start : std_logic := '0';
  signal nr : unsigned(31 downto 0) := (others => '0');
  signal u_zaj, p_got, u_wazne, u_ost, s_wazne, s_ostatni, przerwa : std_logic;
  signal pidx : unsigned(10 downto 0) := (others => '0');
  signal odstep : natural range 0 to 65535 := 0;
  signal s1, s2 : std_logic_vector(5 downto 0) := (others => '0');
begin
  NET_PCF_EN <= '0';
  clk <= MAX10_CLK1_50;

  -- domena 50 MHz: reset PHY i MDIO
  process (clk, KEY(0))
  begin
    if KEY(0) = '0' then rs <= "00"; elsif rising_edge(clk) then rs <= rs(0) & '1'; end if;
  end process;
  rst <= not rs(1);
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then lr <= 0; elsif lr /= 1000000 then lr <= lr + 1; end if;
    end if;
  end process;
  NET_RESET_n <= '1' when lr >= 500000 else '0';
  phy_gotowy  <= '1' when lr = 1000000 else '0';
  mdio_rst    <= not phy_gotowy;

  u_mdio : entity work.mdio
    generic map (DIV => 10)
    port map (clk => clk, rst => mdio_rst, start => m_start, zapis => '0', phy => std_logic_vector(m_phy), rej => m_rej,
              wdane => x"0000", rdane => m_rdane, gotowe => m_got, zajety => m_zaj, mdc => NET_MDC,
              mdio_o => mdio_o, mdio_oe => mdio_oe, mdio_i => NET_MDIO);
  NET_MDIO <= mdio_o when mdio_oe = '1' else 'Z';

  process (clk)
  begin
    if rising_edge(clk) then
      m_start <= '0';
      if phy_gotowy = '0' then
        znaleziony <= '0'; lacze <= '0'; m_phy <= (others => '0'); m_rej <= "00010"; okres <= (others => '0');
      else
        okres <= okres + 1;
        if m_zaj = '0' and m_start = '0' and okres = 0 and znaleziony = '1' then m_rej <= "00001"; m_start <= '1'; end if;
        if m_zaj = '0' and m_start = '0' and znaleziony = '0' and okres(9 downto 0) = 0 then m_start <= '1'; end if;
        if m_got = '1' then
          if znaleziony = '0' then
            if m_rdane /= x"FFFF" and m_rdane /= x"0000" then znaleziony <= '1'; else m_phy <= m_phy + 1; end if;
          else
            lacze <= m_rdane(2);
          end if;
        end if;
      end if;
    end if;
  end process;

  -- domena odbioru
  process (NET_RX_CLK, rst)
  begin
    if rst = '1' then rrs <= "00"; elsif rising_edge(NET_RX_CLK) then rrs <= rrs(0) & '1'; end if;
  end process;
  rst_rx <= not rrs(1);
  u_rx : entity work.mii_rx
    port map (clk => NET_RX_CLK, rst => rst_rx, rxd => NET_RXD, rx_dv => NET_RX_DV, rx_er => NET_RX_ER,
              m_dane => r_dane, m_wazne => r_wazne, koniec => r_koniec, crc_ok => r_crc_ok, dlugosc => r_dl,
              blad => r_blad);

  -- domena nadawania
  process (NET_TX_CLK, rst)
  begin
    if rst = '1' then trs <= "00"; elsif rising_edge(NET_TX_CLK) then trs <= trs(0) & '1'; end if;
  end process;
  rst_tx <= not trs(1);

  a_got <= '1' when tx_gotowy = '1' and wyb = 1 else '0';
  u_got <= '1' when tx_gotowy = '1' and wyb = 2 else '0';
  u_arp : entity work.arp_odp
    port map (clk_rx => NET_RX_CLK, rst_rx => rst_rx, r_dane => r_dane, r_wazne => r_wazne, r_koniec => r_koniec,
              r_crc_ok => r_crc_ok, mac_moj => MAC_FPGA, ip_moj => IP_FPGA,
              clk_tx => NET_TX_CLK, rst_tx => rst_tx, chce => a_chce, m_dane => a_dane, m_wazne => a_wazne,
              m_ostatni => a_ost, m_gotowy => a_got, mac_pyt => mac_pc, ip_pyt => ip_pc, nauczony => nauczony);

  mac_cel <= mac_pc when nauczony = '1' else x"FFFFFFFFFFFF";
  ip_cel  <= ip_pc  when nauczony = '1' else x"FFFFFFFF";
  p_dane  <= std_logic_vector(nr(31 downto 24)) when pidx = 0 else
             std_logic_vector(nr(23 downto 16)) when pidx = 1 else
             std_logic_vector(nr(15 downto 8))  when pidx = 2 else
             std_logic_vector(nr(7 downto 0))   when pidx = 3 else
             std_logic_vector(pidx(7 downto 0) + nr(7 downto 0));
  u_udp : entity work.udp_nad
    port map (clk => NET_TX_CLK, rst => rst_tx, start => u_start, dlugosc => to_unsigned(1024, 11),
              mac_zr => MAC_FPGA, mac_cel => mac_cel, ip_zr => IP_FPGA, ip_cel => ip_cel,
              port_zr => x"138D", port_cel => x"138E", zajety => u_zaj, p_dane => p_dane, p_wazne => '1',
              p_gotowy => p_got, m_dane => u_dane, m_wazne => u_wazne, m_ostatni => u_ost, m_gotowy => u_got);

  process (NET_TX_CLK)
  begin
    if rising_edge(NET_TX_CLK) then
      sw_t <= SW;
      u_start <= '0';
      if u_start = '1' then pidx <= (others => '0'); elsif p_got = '1' then pidx <= pidx + 1; end if;
      if odstep /= 0 then odstep <= odstep - 1; end if;
      if rst_tx = '1' then
        wyb <= 0; nr <= (others => '0'); odstep <= 0;
      else
        case wyb is
          when 0 =>
            if a_chce = '1' then wyb <= 1;
            elsif sw_t(1) = '1' and odstep = 0 and u_zaj = '0' then
              u_start <= '1'; wyb <= 2;
              if sw_t(0) = '1' then odstep <= 0; else odstep <= 25000; end if;
            end if;
          when 1 =>
            if a_wazne = '1' and a_ost = '1' and tx_gotowy = '1' then wyb <= 0; end if;
          when others =>
            if u_wazne = '1' and u_ost = '1' and tx_gotowy = '1' then wyb <= 0; nr <= nr + 1; end if;
        end case;
      end if;
    end if;
  end process;
  s_dane    <= a_dane when wyb = 1 else u_dane;
  s_wazne   <= a_wazne when wyb = 1 else u_wazne when wyb = 2 else '0';
  s_ostatni <= a_ost when wyb = 1 else u_ost;
  u_tx : entity work.mii_tx
    port map (clk => NET_TX_CLK, rst => rst_tx, s_dane => s_dane, s_wazne => s_wazne, s_ostatni => s_ostatni,
              s_gotowy => tx_gotowy, txd => NET_TXD, tx_en => NET_TX_EN, przerwa => przerwa);

  process (clk)
  begin
    if rising_edge(clk) then
      s1 <= nauczony & sw_t(1) & std_logic_vector(nr(13 downto 10));
      s2 <= s1;
    end if;
  end process;
  LED <= not (s2(3 downto 0) & s2(4) & s2(5) & lacze & znaleziony);
end architecture rtl;
