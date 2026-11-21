-- Wyjście bufora ramki (24.04): obraz SZER × WYS, 4 bity na piksel (8 pikseli w słowie, piksel i w bitach
-- 4i+3..4i), dwie ramki w pamięci (BAZA0, BAZA1), powiększenie 2^SK.
--  - domena pamięci (clk_m): czytnik_linii ładuje linie do dwóch buforów linii z wyprzedzeniem jednej linii;
--    przelacz zamienia ramki na końcu wyświetlanej ramki;
--  - domena piksela (clk_p): odczyt bufora według (x, y); zdarzenia „linia zwolniona” i „koniec ramki” przechodzą
--    do domeny pamięci jako bity przełączane przez synchronizatory 3-przerzutnikowe. Opóźnienie: 2 takty clk_p.
-- Pierwsza ramka po resecie jest czarna. brak — linia nie zdążyła się załadować.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity bufor_ramki is
  generic (
    SZER  : positive := 320;
    WYS   : positive := 240;
    SK    : natural  := 1;
    BURST : positive := 8;
    AW    : positive := 16;
    BAZA0 : natural  := 0;
    BAZA1 : natural  := 9600
  );
  port (
    clk_m        : in  std_logic;
    rst_m        : in  std_logic;
    przelacz     : in  std_logic;
    aktywny      : out std_logic := '0';
    oczekuje     : out std_logic := '0';
    brak         : out std_logic := '0';
    m_adr        : out unsigned(AW - 1 downto 0);
    m_read       : out std_logic;
    m_burstcount : out unsigned(4 downto 0);
    m_wait       : in  std_logic;
    m_rvalid     : in  std_logic;
    m_rdata      : in  std_logic_vector(31 downto 0);
    clk_p        : in  std_logic;
    rst_p        : in  std_logic;
    de, hs, vs   : in  std_logic;
    x, y         : in  unsigned(11 downto 0);
    o_de         : out std_logic := '0';
    o_hs         : out std_logic := '0';
    o_vs         : out std_logic := '0';
    o_piks       : out std_logic_vector(3 downto 0) := "0000"
  );
end entity bufor_ramki;

architecture rtl of bufor_ramki is
  constant SLOW  : positive := SZER / 8;
  constant LW    : positive := integer(ceil(log2(real(2 * SLOW))));
  constant OST_Y : natural  := WYS * 2 ** SK - 1;
  constant MASKA : natural  := 2 ** SK - 1;

  type lram_t is array (0 to 2 * SLOW - 1) of std_logic_vector(31 downto 0);
  signal lram : lram_t;
  signal lw_we   : std_logic;
  signal lw_adr  : unsigned(LW - 1 downto 0);
  signal lw_dane : std_logic_vector(31 downto 0);

  -- domena piksela
  signal de_d, t_zw, t_kr, ok : std_logic := '0';
  signal y_d             : unsigned(11 downto 0) := (others => '0');
  signal q               : std_logic_vector(31 downto 0) := (others => '0');
  signal nib             : natural range 0 to 7 := 0;
  signal de1, hs1, vs1   : std_logic := '0';

  -- domena pamięci
  signal s_zw, s_kr      : std_logic_vector(2 downto 0) := "000";
  signal nast, zal, k    : natural range 0 to 2047 := 0;
  signal do_zal          : natural range 0 to 7 := 0;
  signal baza, adr_l     : unsigned(AW - 1 downto 0) := to_unsigned(BAZA0, AW);
  signal cz_start, bufor_l, ramka_m, akt, ocz : std_logic := '0';
  signal cz_zajety, cz_gotowe : std_logic;
begin
  aktywny  <= akt;
  oczekuje <= ocz;

  -- bufor linii: zapis w domenie pamięci, odczyt w domenie piksela
  process (clk_m)
  begin
    if rising_edge(clk_m) then
      if lw_we = '1' then lram(to_integer(lw_adr)) <= lw_dane; end if;
    end if;
  end process;

  -- ---------------------------------------------------------------- domena piksela
  process (clk_p)
  begin
    if rising_edge(clk_p) then
      if rst_p = '1' then
        de_d <= '0'; y_d <= (others => '0'); t_zw <= '0'; t_kr <= '0'; ok <= '0';
      else
        de_d <= de;
        y_d  <= y;
        if de_d = '1' and de = '0' then                              -- koniec linii aktywnej
          if to_integer(y_d) = OST_Y then
            t_kr <= not t_kr;
            ok   <= '1';
          elsif (to_integer(y_d) mod 2 ** SK) = MASKA then
            t_zw <= not t_zw;                                        -- ostatnie powtórzenie linii obrazu
          end if;
        end if;
      end if;
    end if;
  end process;

  process (clk_p)
    variable sx : unsigned(11 downto 0);
    variable a  : natural;
  begin
    if rising_edge(clk_p) then
      sx := shift_right(x, SK);
      a  := to_integer(sx(11 downto 3));
      if y(SK) = '1' then a := a + SLOW; end if;
      if a < 2 * SLOW then q <= lram(a); end if;
      nib <= to_integer(sx(2 downto 0));
      de1 <= de; hs1 <= hs; vs1 <= vs;
      o_de <= de1; o_hs <= hs1; o_vs <= vs1;
      if de1 = '1' and ok = '1' then
        o_piks <= q(4 * nib + 3 downto 4 * nib);
      else
        o_piks <= "0000";
      end if;
    end if;
  end process;

  -- ---------------------------------------------------------------- domena pamięci
  process (clk_m)
    variable e_zw, e_kr : boolean;
    variable z          : natural range 0 to 2047;
  begin
    if rising_edge(clk_m) then
      s_zw <= s_zw(1 downto 0) & t_zw;
      s_kr <= s_kr(1 downto 0) & t_kr;
      e_zw := s_zw(2) /= s_zw(1);
      e_kr := s_kr(2) /= s_kr(1);
      if rst_m = '1' then
        akt <= '0'; ocz <= '0'; brak <= '0'; nast <= 0; zal <= 0; k <= 0; do_zal <= 0; ramka_m <= '0';
        baza <= to_unsigned(BAZA0, AW); adr_l <= to_unsigned(BAZA0, AW); cz_start <= '0'; bufor_l <= '0';
      else
        cz_start <= '0';
        if przelacz = '1' then ocz <= '1'; end if;
        if cz_gotowe = '1' then zal <= zal + 1; end if;
        if e_kr then                                                 -- koniec ramki: zamiana i nowa ramka
          if ocz = '1' or przelacz = '1' then
            akt <= not akt;
            ocz <= '0';
            if akt = '1' then baza <= to_unsigned(BAZA0, AW); else baza <= to_unsigned(BAZA1, AW); end if;
          else
            if akt = '1' then baza <= to_unsigned(BAZA1, AW); else baza <= to_unsigned(BAZA0, AW); end if;
          end if;
          nast <= 0; zal <= 0; k <= 0; do_zal <= 2; ramka_m <= '1';
        else
          if e_zw then                                               -- zaczyna się linia k + 1
            k <= k + 1;
            z := zal;
            if cz_gotowe = '1' then z := z + 1; end if;
            if ramka_m = '1' and z < k + 2 then brak <= '1'; end if;
          end if;
          if cz_zajety = '0' and cz_start = '0' and do_zal /= 0 and nast /= WYS then
            cz_start <= '1';
            adr_l    <= baza;
            if nast mod 2 = 1 then bufor_l <= '1'; else bufor_l <= '0'; end if;
            baza     <= baza + SLOW;
            nast     <= nast + 1;
            if e_zw then do_zal <= do_zal; else do_zal <= do_zal - 1; end if;
          elsif e_zw then
            do_zal <= do_zal + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  u_cz : entity work.czytnik_linii
    generic map (SLOW => SLOW, BURST => BURST, AW => AW, LW => LW)
    port map (clk => clk_m, rst => rst_m, start => cz_start, adr => adr_l, bufor => bufor_l,
              zajety => cz_zajety, gotowe => cz_gotowe,
              m_adr => m_adr, m_read => m_read, m_burstcount => m_burstcount, m_wait => m_wait,
              m_rvalid => m_rvalid, m_rdata => m_rdata,
              lw_we => lw_we, lw_adr => lw_adr, lw_dane => lw_dane);
end architecture rtl;
