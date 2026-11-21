-- Testbench 25.04: udp_nad (datagram 18 B porównany z ramką zbudowaną w testbenchu, niezależna kontrola sumy IPv4;
-- datagram 1000 B przez mii_tx/mii_rx) i arp_odp (odbiór 25 MHz, nadawanie ok. 24,9 MHz): odpowiedź na zapytanie
-- o nasz adres, nauczony adres pytającego, brak odpowiedzi na zapytanie o inny adres i na ramkę ze złym CRC.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_udp is
end entity tb_udp;

architecture sim of tb_udp is
  constant MAC_FPGA : std_logic_vector(47 downto 0) := x"020000000001";
  constant MAC_PC   : std_logic_vector(47 downto 0) := x"001B213C4D5E";
  constant IP_FPGA  : std_logic_vector(31 downto 0) := x"C0A801C8";        -- 192.168.1.200
  constant IP_PC    : std_logic_vector(31 downto 0) := x"C0A80164";        -- 192.168.1.100

  signal clk, clk_t : std_logic := '0';
  signal rst : std_logic := '1';
  signal fin : boolean := false;
  signal start : std_logic := '0';
  signal dl : unsigned(10 downto 0) := to_unsigned(18, 11);
  signal zajety, p_gotowy, m_wazne, m_ostatni, tx_gotowy, m_got : std_logic;
  signal m_dane : std_logic_vector(7 downto 0);
  signal p_dane : unsigned(7 downto 0) := (others => '0');
  signal m_gotowy, przez_mii : std_logic := '0';
  signal txd : std_logic_vector(3 downto 0);
  signal tx_en, przerwa, s_w : std_logic;
  signal r_dane : std_logic_vector(7 downto 0);
  signal r_wazne, r_koniec, r_crc_ok, r_blad : std_logic;
  signal r_dl : unsigned(10 downto 0);
  signal a_dane : std_logic_vector(7 downto 0) := x"00";
  signal a_wazne, a_koniec, a_crc : std_logic := '0';
  signal chce, o_wazne, o_ostatni, nauczony : std_logic;
  signal o_dane : std_logic_vector(7 downto 0);
  signal mac_pyt : std_logic_vector(47 downto 0);
  signal ip_pyt : std_logic_vector(31 downto 0);
  type bajty_t is array (0 to 2047) of std_logic_vector(7 downto 0);
  signal zebr, rx, arp : bajty_t := (others => x"00");
  signal nz, nr, na : natural := 0;

  function b48(v : std_logic_vector(47 downto 0); k : natural) return std_logic_vector is
  begin
    return v(8 * (6 - k) - 1 downto 8 * (5 - k));
  end function;
  function b32(v : std_logic_vector(31 downto 0); k : natural) return std_logic_vector is
  begin
    return v(8 * (4 - k) - 1 downto 8 * (3 - k));
  end function;
begin
  clk   <= not clk after 20 ns when not fin else clk;
  clk_t <= not clk_t after 20.1 ns when not fin else clk_t;

  m_got <= tx_gotowy when przez_mii = '1' else m_gotowy;
  s_w   <= m_wazne and przez_mii;

  u_udp : entity work.udp_nad
    port map (clk => clk, rst => rst, start => start, dlugosc => dl, mac_zr => MAC_FPGA, mac_cel => MAC_PC,
              ip_zr => IP_FPGA, ip_cel => IP_PC, port_zr => x"138D", port_cel => x"138E", zajety => zajety,
              p_dane => std_logic_vector(p_dane), p_wazne => '1', p_gotowy => p_gotowy,
              m_dane => m_dane, m_wazne => m_wazne, m_ostatni => m_ostatni, m_gotowy => m_got);
  u_tx : entity work.mii_tx
    port map (clk => clk, rst => rst, s_dane => m_dane, s_wazne => s_w, s_ostatni => m_ostatni,
              s_gotowy => tx_gotowy, txd => txd, tx_en => tx_en, przerwa => przerwa);
  u_rx : entity work.mii_rx
    port map (clk => clk, rst => rst, rxd => txd, rx_dv => tx_en, rx_er => '0', m_dane => r_dane, m_wazne => r_wazne,
              koniec => r_koniec, crc_ok => r_crc_ok, dlugosc => r_dl, blad => r_blad);
  u_arp : entity work.arp_odp
    port map (clk_rx => clk, rst_rx => rst, r_dane => a_dane, r_wazne => a_wazne, r_koniec => a_koniec,
              r_crc_ok => a_crc, mac_moj => MAC_FPGA, ip_moj => IP_FPGA, clk_tx => clk_t, rst_tx => rst,
              chce => chce, m_dane => o_dane, m_wazne => o_wazne, m_ostatni => o_ostatni, m_gotowy => '1',
              mac_pyt => mac_pyt, ip_pyt => ip_pyt, nauczony => nauczony);

  -- dane: 0, 1, 2, …; losowy odbiorca; zbieranie strumieni
  process (clk)
    variable s1, s2 : positive := 11;
    variable r : real;
    variable n_z, n_r : natural := 0;
  begin
    if rising_edge(clk) then
      if start = '1' then p_dane <= (others => '0'); elsif p_gotowy = '1' then p_dane <= p_dane + 1; end if;
      if przez_mii = '0' and m_wazne = '1' and m_gotowy = '1' then zebr(n_z) <= m_dane; n_z := n_z + 1; end if;
      if r_wazne = '1' then rx(n_r) <= r_dane; n_r := n_r + 1; end if;
      nz <= n_z; nr <= n_r;
    end if;
    if falling_edge(clk) then
      uniform(s1, s2, r);
      if r < 0.75 then m_gotowy <= '1'; else m_gotowy <= '0'; end if;
    end if;
  end process;
  process (clk_t)
    variable n_a : natural := 0;
  begin
    if rising_edge(clk_t) and o_wazne = '1' then arp(n_a) <= o_dane; n_a := n_a + 1; na <= n_a; end if;
  end process;

  process
    variable l : line;
    variable errors, bl, s : integer := 0;
    variable ocz : bajty_t;
    variable ramka : bajty_t;

    procedure zapytanie(szukany : std_logic_vector(31 downto 0); crc_dobry : std_logic) is
    begin
      ramka := (others => x"00");
      for q in 0 to 5 loop ramka(q) := x"FF"; ramka(6 + q) := b48(MAC_PC, q); ramka(22 + q) := b48(MAC_PC, q); end loop;
      ramka(12) := x"08"; ramka(13) := x"06"; ramka(14) := x"00"; ramka(15) := x"01"; ramka(16) := x"08";
      ramka(17) := x"00"; ramka(18) := x"06"; ramka(19) := x"04"; ramka(20) := x"00"; ramka(21) := x"01";
      for q in 0 to 3 loop ramka(28 + q) := b32(IP_PC, q); ramka(38 + q) := b32(szukany, q); end loop;
      for q in 0 to 59 loop
        wait until falling_edge(clk);
        a_dane <= ramka(q); a_wazne <= '1';
        wait until falling_edge(clk);
        a_wazne <= '0';
      end loop;
      wait until falling_edge(clk);
      a_koniec <= '1'; a_crc <= crc_dobry;
      wait until falling_edge(clk);
      a_koniec <= '0';
      for q in 1 to 200 loop wait until falling_edge(clk); end loop;
    end procedure;
  begin
    for q in 1 to 5 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    -- 1. datagram 18 B
    wait until falling_edge(clk); start <= '1';
    wait until falling_edge(clk); start <= '0';
    wait until zajety = '0';
    for q in 1 to 2 loop wait until falling_edge(clk); end loop;
    for q in 0 to 5 loop ocz(q) := b48(MAC_PC, q); ocz(6 + q) := b48(MAC_FPGA, q); end loop;
    ocz(12) := x"08"; ocz(13) := x"00"; ocz(14) := x"45"; ocz(15) := x"00"; ocz(16) := x"00"; ocz(17) := x"2E";
    ocz(18) := x"00"; ocz(19) := x"01"; ocz(20) := x"40"; ocz(21) := x"00"; ocz(22) := x"40"; ocz(23) := x"11";
    ocz(24) := x"00"; ocz(25) := x"00";
    for q in 0 to 3 loop ocz(26 + q) := b32(IP_FPGA, q); ocz(30 + q) := b32(IP_PC, q); end loop;
    ocz(34) := x"13"; ocz(35) := x"8D"; ocz(36) := x"13"; ocz(37) := x"8E"; ocz(38) := x"00"; ocz(39) := x"1A";
    ocz(40) := x"00"; ocz(41) := x"00";
    for q in 0 to 17 loop ocz(42 + q) := std_logic_vector(to_unsigned(q, 8)); end loop;
    s := 0;
    for q in 0 to 9 loop s := s + to_integer(unsigned(std_logic_vector'(ocz(14 + 2 * q) & ocz(15 + 2 * q)))); end loop;
    s := (s mod 65536) + s / 65536; s := (s mod 65536) + s / 65536;
    ocz(24) := not std_logic_vector(to_unsigned(s / 256, 8)); ocz(25) := not std_logic_vector(to_unsigned(s mod 256, 8));
    bl := 0;
    if nz /= 60 then bl := bl + 1; end if;
    for q in 0 to 59 loop if zebr(q) /= ocz(q) then bl := bl + 1; end if; end loop;
    s := 0;
    for q in 0 to 9 loop s := s + to_integer(unsigned(std_logic_vector'(zebr(14 + 2 * q) & zebr(15 + 2 * q)))); end loop;
    s := (s mod 65536) + s / 65536; s := (s mod 65536) + s / 65536;
    write(l, "datagram 18 B: " & integer'image(nz) & " bajtow ramki, niezgodnych " & integer'image(bl)
          & "; suma kontrolna IP " & to_hstring(std_logic_vector'(zebr(24) & zebr(25))) & ", suma naglowka " & integer'image(s));
    writeline(output, l);
    if bl /= 0 or s /= 65535 then errors := errors + 1; end if;
    -- 2. datagram 1000 B przez MII
    przez_mii <= '1'; dl <= to_unsigned(1000, 11);
    wait until falling_edge(clk); start <= '1';
    wait until falling_edge(clk); start <= '0';
    wait until r_koniec = '1';
    wait for 1 ns;
    bl := 0;
    for q in 0 to 999 loop if rx(nr - 1000 + q) /= std_logic_vector(to_unsigned(q mod 256, 8)) then bl := bl + 1; end if; end loop;
    write(l, "datagram 1000 B przez mii_tx/mii_rx: ramka " & integer'image(to_integer(r_dl)) & " B, crc_ok = "
          & std_logic'image(r_crc_ok) & ", bledow danych " & integer'image(bl));
    writeline(output, l);
    if bl /= 0 or r_crc_ok /= '1' or to_integer(r_dl) /= 1042 then errors := errors + 1; end if;
    -- 3. ARP
    zapytanie(IP_FPGA, '1');
    bl := 0;
    for q in 0 to 5 loop
      if arp(q) /= b48(MAC_PC, q) or arp(6 + q) /= b48(MAC_FPGA, q) or arp(22 + q) /= b48(MAC_FPGA, q)
         or arp(32 + q) /= b48(MAC_PC, q) then bl := bl + 1; end if;
    end loop;
    for q in 0 to 3 loop
      if arp(28 + q) /= b32(IP_FPGA, q) or arp(38 + q) /= b32(IP_PC, q) then bl := bl + 1; end if;
    end loop;
    if arp(12) /= x"08" or arp(13) /= x"06" or arp(20) /= x"00" or arp(21) /= x"02" then bl := bl + 1; end if;
    write(l, "ARP: odpowiedz " & integer'image(na) & " B, bledow " & integer'image(bl) & "; nauczony "
          & std_logic'image(nauczony) & ": MAC " & to_hstring(mac_pyt) & ", IP " & to_hstring(ip_pyt));
    writeline(output, l);
    if na /= 42 or bl /= 0 or nauczony /= '1' or mac_pyt /= MAC_PC or ip_pyt /= IP_PC then errors := errors + 1; end if;
    zapytanie(x"C0A801C9", '1');
    zapytanie(IP_FPGA, '0');
    write(l, "ARP: zapytanie o inny adres i ze zlym CRC -> odpowiedzi razem " & integer'image(na) & " B (oczekiwane 42)");
    writeline(output, l);
    if na /= 42 then errors := errors + 1; end if;
    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
