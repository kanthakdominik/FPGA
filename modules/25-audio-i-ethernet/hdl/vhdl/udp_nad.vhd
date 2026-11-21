-- Nadawca ramek UDP/IPv4 (25.04): po starcie strumień bajtów ramki bez preambuły i FCS — nagłówek Ethernet (14 B),
-- IPv4 (20 B, z sumą kontrolną), UDP (8 B, suma 0), potem dlugosc bajtów danych ze strumienia p_*. Identyfikator
-- IP rośnie z każdym datagramem. Wyjście m_* podłącza się do s_* nadajnika mii_tx.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity udp_nad is
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    start     : in  std_logic;
    dlugosc   : in  unsigned(10 downto 0);
    mac_zr    : in  std_logic_vector(47 downto 0);
    mac_cel   : in  std_logic_vector(47 downto 0);
    ip_zr     : in  std_logic_vector(31 downto 0);
    ip_cel    : in  std_logic_vector(31 downto 0);
    port_zr   : in  std_logic_vector(15 downto 0);
    port_cel  : in  std_logic_vector(15 downto 0);
    zajety    : out std_logic := '0';
    p_dane    : in  std_logic_vector(7 downto 0);
    p_wazne   : in  std_logic;
    p_gotowy  : out std_logic;
    m_dane    : out std_logic_vector(7 downto 0);
    m_wazne   : out std_logic;
    m_ostatni : out std_logic;
    m_gotowy  : in  std_logic
  );
end entity udp_nad;

architecture rtl of udp_nad is
  signal nag      : std_logic_vector(42 * 8 - 1 downto 0) := (others => '0');   -- bajt 0 w najstarszych bitach
  signal r_dl     : natural range 0 to 2047 := 0;
  signal i        : natural range 0 to 2047 := 0;
  signal r_id     : unsigned(15 downto 0) := (others => '0');
  signal zaj, sum_ok, w_nagl, mw : std_logic := '0';

  function suma16(h : std_logic_vector(42 * 8 - 1 downto 0)) return std_logic_vector is
    variable s : natural := 0;
    variable k : natural;
  begin
    for w in 0 to 9 loop                                          -- słowa nagłówka IPv4 (bajty 14..33)
      k := 14 + 2 * w;
      s := s + to_integer(unsigned(h(8 * (42 - k) - 1 downto 8 * (40 - k))));
    end loop;
    s := (s mod 65536) + s / 65536;
    s := (s mod 65536) + s / 65536;
    return not std_logic_vector(to_unsigned(s, 16));
  end function;
begin
  w_nagl    <= '1' when i < 42 else '0';
  m_dane    <= nag(8 * (42 - i) - 1 downto 8 * (41 - i)) when i < 42 else p_dane;
  mw        <= zaj and sum_ok and (w_nagl or p_wazne);
  m_wazne   <= mw;
  m_ostatni <= '1' when w_nagl = '0' and i = r_dl + 41 else '0';
  p_gotowy  <= zaj and sum_ok and not w_nagl and m_gotowy;
  zajety    <= zaj;

  process (clk)
    variable dl_ip, dl_udp : unsigned(15 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        zaj <= '0'; sum_ok <= '0'; i <= 0; r_id <= (others => '0'); r_dl <= 0; nag <= (others => '0');
      elsif zaj = '0' then
        if start = '1' then
          dl_ip  := resize(dlugosc, 16) + 28;
          dl_udp := resize(dlugosc, 16) + 8;
          zaj <= '1'; sum_ok <= '0'; i <= 0;
          r_dl <= to_integer(dlugosc);
          r_id <= r_id + 1;
          nag <= mac_cel & mac_zr & x"0800" & x"4500" & std_logic_vector(dl_ip) & std_logic_vector(r_id + 1)
                 & x"4000" & x"4011" & x"0000" & ip_zr & ip_cel & port_zr & port_cel & std_logic_vector(dl_udp)
                 & x"0000";
        end if;
      elsif sum_ok = '0' then
        nag(8 * 18 - 1 downto 8 * 16) <= suma16(nag);            -- bajty 24..25
        sum_ok <= '1';
      elsif mw = '1' and m_gotowy = '1' then
        if i = r_dl + 41 and w_nagl = '0' then zaj <= '0'; else i <= i + 1; end if;
      end if;
    end if;
  end process;
end architecture rtl;
