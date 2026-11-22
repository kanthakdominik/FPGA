-- Pamięć z ECC SECDED (39,32) i czyszczeniem w tle (29.04): zapis koduje, odczyt (takt później) dekoduje
-- z flagami; czyszczenie czyta kolejne adresy drugim portem i zapisuje z powrotem słowa z błędem pojedynczym,
-- chyba że użytkownik zapisał ten adres w międzyczasie. wstrzyk — port testowy (XOR maski do słowa).
-- SLOWA — potęga dwójki.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.secded_pkg.all;

entity pamiec_ecc is
  generic (SLOWA : positive := 64; AW : positive := 6);
  port (
    clk, rst      : in  std_logic;
    we, rd        : in  std_logic;
    adr           : in  unsigned(AW - 1 downto 0);
    wdane         : in  std_logic_vector(31 downto 0);
    rdane         : out std_logic_vector(31 downto 0);
    r_poprawiony  : out std_logic;
    r_podwojny    : out std_logic;
    r_wazne       : out std_logic := '0';
    czysc_en      : in  std_logic;
    czysc_adr     : out unsigned(AW - 1 downto 0);
    skorygowane   : out unsigned(15 downto 0);
    podwojne      : out unsigned(15 downto 0);
    wstrzyk       : in  std_logic;
    wstrzyk_adr   : in  unsigned(AW - 1 downto 0);
    wstrzyk_maska : in  std_logic_vector(38 downto 0)
  );
end entity pamiec_ecc;

architecture rtl of pamiec_ecc is
  type pam_t is array (0 to SLOWA - 1) of slowo_kod;
  signal pam                 : pam_t := (others => (others => '0'));
  signal kw, kw_b            : slowo_kod;
  signal odcz_a, odcz_b      : slowo_kod := (others => '0');
  signal adr_b, cz_adr       : unsigned(AW - 1 downto 0) := (others => '0');
  signal v_b, kolizja_b      : std_logic := '0';
  signal d_b                 : std_logic_vector(31 downto 0);
  signal pop_b, podw_b       : std_logic;
  signal zwrot               : std_logic;
  signal l_kor, l_podw       : unsigned(15 downto 0) := (others => '0');
begin
  u_kod : entity work.secded_koder port map (d => wdane, c => kw);
  u_dek_a : entity work.secded_dekoder
    port map (c => odcz_a, d => rdane, poprawiony => r_poprawiony, podwojny => r_podwojny);
  u_dek_b : entity work.secded_dekoder port map (c => odcz_b, d => d_b, poprawiony => pop_b, podwojny => podw_b);
  u_kod_b : entity work.secded_koder port map (d => d_b, c => kw_b);

  zwrot <= '1' when v_b = '1' and pop_b = '1' and kolizja_b = '0' and not (we = '1' and adr = adr_b) else '0';

  process (clk)
  begin
    if rising_edge(clk) then
      -- zapis zwrotny, potem wstrzyknięcie, potem użytkownik (ostatni wygrywa)
      if zwrot = '1' then pam(to_integer(adr_b)) <= kw_b; end if;
      if wstrzyk = '1' then
        pam(to_integer(wstrzyk_adr)) <= pam(to_integer(wstrzyk_adr)) xor wstrzyk_maska;
      end if;
      if we = '1' then pam(to_integer(adr)) <= kw; end if;
      if rd = '1' then odcz_a <= pam(to_integer(adr)); end if;
      odcz_b <= pam(to_integer(cz_adr));
      adr_b  <= cz_adr;
    end if;
  end process;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        r_wazne <= '0'; v_b <= '0'; kolizja_b <= '0'; cz_adr <= (others => '0');
        l_kor <= (others => '0'); l_podw <= (others => '0');
      else
        r_wazne   <= rd;
        v_b       <= czysc_en;
        kolizja_b <= '1' when we = '1' and adr = cz_adr else '0';
        if czysc_en = '1' then cz_adr <= cz_adr + 1; end if;
        if zwrot = '1' then l_kor <= l_kor + 1; end if;
        if v_b = '1' and podw_b = '1' then l_podw <= l_podw + 1; end if;
      end if;
    end if;
  end process;

  czysc_adr   <= cz_adr;
  skorygowane <= l_kor;
  podwojne    <= l_podw;
end architecture rtl;
