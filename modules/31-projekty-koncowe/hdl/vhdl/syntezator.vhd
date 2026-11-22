-- Syntezator 4-głosowy (31.03): akumulatory fazy, cztery kształty fali, obwiednia ADSR, przydział głosów,
-- przetwarzanie głosów po kolei (4 takty na głos) po każdym impulsie ramka. Jak w wersjach Verilog i SV.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity syntezator is
  generic (
    A_KROK : natural := 268; D_KROK : natural := 5; S_POZ : natural := 39321; R_KROK : natural := 4
  );
  port (
    clk, rst  : in  std_logic;
    ramka     : in  std_logic;
    ev_on, ev_off, ev_wszystkie, ev_prog : in std_logic;
    nuta, vel : in  unsigned(6 downto 0);
    prog      : in  unsigned(1 downto 0);
    probka    : out signed(23 downto 0) := (others => '0');
    nowa      : out std_logic := '0';
    aktywne   : out std_logic_vector(3 downto 0)
  );
end entity syntezator;

architecture rtl of syntezator is
  type stan_t is (CISZA, ATAK, OPAD, PODTRZ, WYBRZ);
  type stany_t is array (0 to 3) of stan_t;
  type u7_t is array (0 to 3) of unsigned(6 downto 0);
  type u24_t is array (0 to 3) of unsigned(23 downto 0);
  type u17_t is array (0 to 3) of unsigned(16 downto 0);
  signal stan   : stany_t := (others => CISZA);
  signal g_nuta, g_vel : u7_t := (others => (others => '0'));
  signal faza, krok : u24_t := (others => (others => '0'));
  signal env    : u17_t := (others => (others => '0'));
  signal fala   : unsigned(1 downto 0) := "00";
  signal kolejny : unsigned(1 downto 0) := "00";
  signal zd_on, zd_off, zd_wsz : std_logic := '0';
  signal zd_n, zd_v : unsigned(6 downto 0) := (others => '0');
  signal dziala : std_logic := '0';
  signal licz   : unsigned(3 downto 0) := (others => '0');
  signal fz     : unsigned(23 downto 0) := (others => '0');
  signal w      : signed(16 downto 0) := (others => '0');
  signal amp    : unsigned(15 downto 0) := (others => '0');
  signal wyj    : signed(15 downto 0) := (others => '0');
  signal acc    : signed(17 downto 0) := (others => '0');
  signal sin_a  : unsigned(7 downto 0);
  signal sin_q  : signed(15 downto 0);
  signal fg     : unsigned(23 downto 0);
  signal wyb    : natural range 0 to 3;
  signal znal   : boolean;

  function krok_nuty(n : unsigned(6 downto 0)) return unsigned is
    type tab_t is array (0 to 11) of natural;
    constant TAB : tab_t := (2876604, 3047655, 3228878, 3420877, 3624293, 3839805, 4068132, 4310035, 4566323,
                             4837851, 5125525, 5430304);
    variable okt, s : natural;
  begin
    okt := to_integer(n) / 12;
    s := to_integer(n) mod 12;
    return shift_right(to_unsigned(TAB(s), 24), 10 - okt);
  end function;
begin
  aktywne(0) <= '0' when stan(0) = CISZA else '1';
  aktywne(1) <= '0' when stan(1) = CISZA else '1';
  aktywne(2) <= '0' when stan(2) = CISZA else '1';
  aktywne(3) <= '0' when stan(3) = CISZA else '1';

  process (all)
    variable v_wyb : natural range 0 to 3;
    variable v_znal : boolean;
  begin
    v_wyb := to_integer(kolejny); v_znal := false;
    for j in 3 downto 0 loop
      if stan(j) = CISZA then v_wyb := j; v_znal := true; end if;
    end loop;
    for j in 3 downto 0 loop
      if stan(j) /= CISZA and g_nuta(j) = zd_n then v_wyb := j; v_znal := true; end if;
    end loop;
    wyb <= v_wyb; znal <= v_znal;
  end process;

  fg <= faza(to_integer(licz(3 downto 2)));
  sin_a <= not fg(21 downto 14) when fg(22) = '1' else fg(21 downto 14);
  u_sin : entity work.sin_tab port map (clk => clk, a => sin_a, q => sin_q);

  process (clk)
    variable g : natural range 0 to 3;
    variable env_vel : unsigned(22 downto 0);
    variable iloczyn : signed(33 downto 0);
    variable suma : signed(17 downto 0);
  begin
    if rising_edge(clk) then
      nowa <= '0';
      g := to_integer(licz(3 downto 2));
      if ev_on = '1' then zd_on <= '1'; zd_n <= nuta; zd_v <= vel; end if;
      if ev_off = '1' then zd_off <= '1'; zd_n <= nuta; end if;
      if ev_wszystkie = '1' then zd_wsz <= '1'; end if;
      if ev_prog = '1' then fala <= prog; end if;
      if rst = '1' then
        stan <= (others => CISZA); env <= (others => (others => '0'));
        dziala <= '0'; zd_on <= '0'; zd_off <= '0'; zd_wsz <= '0'; kolejny <= "00"; fala <= "00";
      elsif ramka = '1' then
        if zd_wsz = '1' then
          for i in 0 to 3 loop
            if stan(i) /= CISZA then stan(i) <= WYBRZ; end if;
          end loop;
        elsif zd_off = '1' then
          for i in 0 to 3 loop
            if stan(i) /= CISZA and stan(i) /= WYBRZ and g_nuta(i) = zd_n then stan(i) <= WYBRZ; end if;
          end loop;
        elsif zd_on = '1' then
          stan(wyb) <= ATAK;
          g_nuta(wyb) <= zd_n;
          g_vel(wyb) <= zd_v;
          krok(wyb) <= krok_nuty(zd_n);
          if not znal then kolejny <= kolejny + 1; end if;
        end if;
        zd_on <= ev_on; zd_off <= ev_off; zd_wsz <= ev_wszystkie;
        dziala <= '1'; licz <= (others => '0'); acc <= (others => '0');
      elsif dziala = '1' then
        licz <= licz + 1;
        case to_integer(licz(1 downto 0)) is
          when 0 =>
            fz <= faza(g);
            faza(g) <= faza(g) + krok(g);
            case stan(g) is
              when ATAK =>
                if env(g) + A_KROK >= 65535 then env(g) <= to_unsigned(65535, 17); stan(g) <= OPAD;
                else env(g) <= env(g) + A_KROK; end if;
              when OPAD =>
                if env(g) <= S_POZ + D_KROK then env(g) <= to_unsigned(S_POZ, 17); stan(g) <= PODTRZ;
                else env(g) <= env(g) - D_KROK; end if;
              when WYBRZ =>
                if env(g) <= R_KROK then env(g) <= (others => '0'); stan(g) <= CISZA;
                else env(g) <= env(g) - R_KROK; end if;
              when others => null;
            end case;
          when 1 =>
            case to_integer(fala) is
              when 0 =>
                if fz(23) = '1' then w <= to_signed(-32767, 17); else w <= to_signed(32767, 17); end if;
              when 1 =>
                w <= signed((not fz(23)) & (not fz(23)) & std_logic_vector(fz(22 downto 8)));
              when 2 =>
                if fz(23) = '1' then w <= to_signed(32767, 17) - signed('0' & fz(22 downto 7));
                else w <= signed('0' & fz(22 downto 7)) - to_signed(32768, 17); end if;
              when others =>
                if fz(23) = '1' then w <= -resize(sin_q, 17); else w <= resize(sin_q, 17); end if;
            end case;
            env_vel := env(g)(15 downto 0) * g_vel(g);
            amp <= env_vel(22 downto 7);
          when 2 =>
            iloczyn := w * signed('0' & amp);
            wyj <= iloczyn(31 downto 16);
          when others =>
            suma := acc + wyj;
            acc <= suma;
            if licz = 15 then
              dziala <= '0';
              probka <= suma & "000000";
              nowa <= '1';
            end if;
        end case;
      end if;
    end if;
  end process;
end architecture rtl;
