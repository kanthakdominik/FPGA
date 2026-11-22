-- Peryferium „UDP z pamięci” dla Nios V (31.04): rejestry (slave Avalon-MM), master Avalon-MM czytający bufor,
-- udp_nad, kolejka asynchroniczna całej ramki i mii_tx w domenie zegara nadawania. Mapa rejestrów i działanie
-- jak w wersjach Verilog i SystemVerilog.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity udp_dma is
  port (
    clk, rst        : in  std_logic;
    s_address       : in  unsigned(3 downto 0);
    s_read, s_write : in  std_logic;
    s_writedata     : in  std_logic_vector(31 downto 0);
    s_readdata      : out std_logic_vector(31 downto 0) := (others => '0');
    irq             : out std_logic;
    m_address       : out unsigned(31 downto 0) := (others => '0');
    m_read          : out std_logic := '0';
    m_waitrequest   : in  std_logic;
    m_readdata      : in  std_logic_vector(31 downto 0);
    m_readdatavalid : in  std_logic;
    tx_clk, tx_rst  : in  std_logic;
    txd             : out std_logic_vector(3 downto 0);
    tx_en           : out std_logic
  );
end entity udp_dma;

architecture rtl of udp_dma is
  signal prz, koniec, zajety : std_logic := '0';
  signal r_adres, r_ip_zr, r_ip_cel, r_porty, pakiety : std_logic_vector(31 downto 0) := (others => '0');
  signal r_dl : unsigned(10 downto 0) := (others => '0');
  signal r_mac_zr, r_mac_cel : std_logic_vector(47 downto 0) := (others => '0');
  signal start : std_logic;

  type bufor_t is array (0 to 7) of std_logic_vector(31 downto 0);
  signal bufor : bufor_t := (others => (others => '0'));
  signal wp, rp : unsigned(2 downto 0) := (others => '0');
  signal ile, w_locie : unsigned(3 downto 0) := (others => '0');
  signal slowa_do : unsigned(9 downto 0) := (others => '0');
  signal bajty_do : unsigned(10 downto 0) := (others => '0');
  signal bi : unsigned(1 downto 0) := "00";
  signal m_rd : std_logic := '0';
  signal m_adr : unsigned(31 downto 0) := (others => '0');
  signal slowo : std_logic_vector(31 downto 0);
  signal p_dane : std_logic_vector(7 downto 0);
  signal p_wazne, p_gotowy, bierz, zdejmij, przyjety : std_logic;

  signal f_dane : std_logic_vector(7 downto 0);
  signal f_wazne, f_ostatni, f_pelna, f_zapis, m_gotowy : std_logic;
  signal k_dane : std_logic_vector(8 downto 0);
  signal k_pusta, k_czyt : std_logic;

  signal ramka_t, wyslano_t, czeka_tx : std_logic := '0';
  signal s_wysl, s_ramka : std_logic_vector(1 downto 0) := "00";
  signal nadaje, t_gotowy, t_wazne : std_logic := '0';

  attribute altera_attribute : string;
  attribute altera_attribute of s_wysl  : signal is "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS";
  attribute altera_attribute of s_ramka : signal is "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS";
begin
  start <= '1' when s_write = '1' and s_address = 0 and s_writedata(0) = '1' and zajety = '0' and r_dl /= 0
           else '0';
  irq <= koniec and prz;
  m_read <= m_rd;
  m_address <= m_adr;

  process (clk)
  begin
    if rising_edge(clk) then
      if s_read = '1' then
        case to_integer(s_address) is
          when 0 => s_readdata <= (31 downto 2 => '0') & prz & '0';
          when 1 => s_readdata <= (31 downto 2 => '0') & koniec & zajety;
          when 2 => s_readdata <= r_adres;
          when 3 => s_readdata <= std_logic_vector(resize(r_dl, 32));
          when 4 => s_readdata <= r_ip_zr;
          when 5 => s_readdata <= r_ip_cel;
          when 6 => s_readdata <= r_porty;
          when 7 => s_readdata <= x"0000" & r_mac_zr(47 downto 32);
          when 8 => s_readdata <= r_mac_zr(31 downto 0);
          when 9 => s_readdata <= x"0000" & r_mac_cel(47 downto 32);
          when 10 => s_readdata <= r_mac_cel(31 downto 0);
          when 11 => s_readdata <= pakiety;
          when others => s_readdata <= (others => '0');
        end case;
      end if;
    end if;
  end process;

  -- odczyt bufora i serializacja
  slowo   <= bufor(to_integer(rp));
  p_dane  <= slowo(8 * to_integer(bi) + 7 downto 8 * to_integer(bi));
  p_wazne <= '0' when ile = 0 else '1';
  bierz   <= p_wazne and p_gotowy;
  zdejmij <= '1' when bierz = '1' and (bi = 3 or bajty_do = 1) else '0';
  przyjety <= m_rd and not m_waitrequest;

  process (clk)
    variable dw, dl : unsigned(3 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        m_rd <= '0'; wp <= (others => '0'); rp <= (others => '0'); ile <= (others => '0');
        w_locie <= (others => '0'); slowa_do <= (others => '0'); bajty_do <= (others => '0'); bi <= "00";
      else
        if start = '1' then
          m_adr <= unsigned(r_adres(31 downto 2)) & "00";
          if r_dl(1 downto 0) /= "00" then slowa_do <= ('0' & r_dl(10 downto 2)) + 1;
          else slowa_do <= '0' & r_dl(10 downto 2); end if;
          bajty_do <= r_dl;
          bi <= "00";
        else
          if przyjety = '1' then
            m_rd <= '0';
            m_adr <= m_adr + 4;
            slowa_do <= slowa_do - 1;
          elsif m_rd = '0' and slowa_do /= 0 and w_locie + ile < 8 then
            m_rd <= '1';
          end if;
        end if;
        if m_readdatavalid = '1' then
          bufor(to_integer(wp)) <= m_readdata;
          wp <= wp + 1;
        end if;
        dw := w_locie;
        if przyjety = '1' then dw := dw + 1; end if;
        if m_readdatavalid = '1' then dw := dw - 1; end if;
        w_locie <= dw;
        dl := ile;
        if m_readdatavalid = '1' then dl := dl + 1; end if;
        if zdejmij = '1' then dl := dl - 1; end if;
        ile <= dl;
        if bierz = '1' then
          bajty_do <= bajty_do - 1;
          if zdejmij = '1' then bi <= "00"; else bi <= bi + 1; end if;
        end if;
        if zdejmij = '1' then rp <= rp + 1; end if;
      end if;
    end if;
  end process;

  -- datagram i kolejka ramki
  m_gotowy <= not f_pelna;
  u_udp : entity work.udp_nad
    port map (clk => clk, rst => rst, start => start, dlugosc => r_dl, mac_zr => r_mac_zr, mac_cel => r_mac_cel,
              ip_zr => r_ip_zr, ip_cel => r_ip_cel, port_zr => r_porty(31 downto 16), port_cel => r_porty(15 downto 0),
              zajety => open, p_dane => p_dane, p_wazne => p_wazne, p_gotowy => p_gotowy, m_dane => f_dane,
              m_wazne => f_wazne, m_ostatni => f_ostatni, m_gotowy => m_gotowy);
  f_zapis <= f_wazne and not f_pelna;
  u_kol : entity work.async_fifo generic map (W => 9, AW => 11)
    port map (wr_clk => clk, wr_rst => rst, wr_en => f_zapis, wr_data => f_ostatni & f_dane, wr_full => f_pelna,
              rd_clk => tx_clk, rd_rst => tx_rst, rd_en => k_czyt, rd_data => k_dane, rd_empty => k_pusta);

  process (clk)
  begin
    if rising_edge(clk) then
      s_wysl <= s_wysl(0) & wyslano_t;
      if rst = '1' then
        zajety <= '0'; koniec <= '0'; ramka_t <= '0'; czeka_tx <= '0'; pakiety <= (others => '0'); prz <= '0';
      else
        if s_write = '1' then
          case to_integer(s_address) is
            when 0 => prz <= s_writedata(1);
            when 1 => if s_writedata(1) = '1' then koniec <= '0'; end if;
            when 2 => r_adres <= s_writedata(31 downto 2) & "00";
            when 3 => r_dl <= unsigned(s_writedata(10 downto 0));
            when 4 => r_ip_zr <= s_writedata;
            when 5 => r_ip_cel <= s_writedata;
            when 6 => r_porty <= s_writedata;
            when 7 => r_mac_zr(47 downto 32) <= s_writedata(15 downto 0);
            when 8 => r_mac_zr(31 downto 0) <= s_writedata;
            when 9 => r_mac_cel(47 downto 32) <= s_writedata(15 downto 0);
            when 10 => r_mac_cel(31 downto 0) <= s_writedata;
            when others => null;
          end case;
        end if;
        if start = '1' then zajety <= '1'; end if;
        if f_zapis = '1' and f_ostatni = '1' then
          ramka_t <= not ramka_t;
          czeka_tx <= '1';
        end if;
        if czeka_tx = '1' and s_wysl(1) = ramka_t then
          czeka_tx <= '0';
          zajety <= '0';
          koniec <= '1';
          pakiety <= std_logic_vector(unsigned(pakiety) + 1);
        end if;
      end if;
    end if;
  end process;

  -- domena nadawania MII
  t_wazne <= nadaje and not k_pusta;
  k_czyt  <= t_wazne and t_gotowy;
  process (tx_clk)
  begin
    if rising_edge(tx_clk) then
      s_ramka <= s_ramka(0) & ramka_t;
      if tx_rst = '1' then
        nadaje <= '0'; wyslano_t <= '0';
      elsif nadaje = '0' then
        if s_ramka(1) /= wyslano_t then nadaje <= '1'; end if;
      elsif k_czyt = '1' and k_dane(8) = '1' then
        nadaje <= '0';
        wyslano_t <= s_ramka(1);
      end if;
    end if;
  end process;
  u_mii : entity work.mii_tx
    port map (clk => tx_clk, rst => tx_rst, s_dane => k_dane(7 downto 0), s_wazne => t_wazne, s_ostatni => k_dane(8),
              s_gotowy => t_gotowy, txd => txd, tx_en => tx_en, przerwa => open);
end architecture rtl;
