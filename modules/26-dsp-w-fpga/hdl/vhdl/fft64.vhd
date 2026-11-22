-- FFT 64 punktów, radix-2 z podziałem w czasie (26.05), jeden motyl na takt, obliczenia w miejscu.
-- Wczytanie 64 próbek pod adresy z odwróconą kolejnością bitów, 6 etapów po 32 motyle (192 takty), wypisanie
-- wyników w kolejności naturalnej. Motyl: t = W·b (zaokrąglenie, przesunięcie o 15), a' = (a + t)/2,
-- b' = (a - t)/2 — wynik = DFT/64. Współczynniki obrotu Q1.15 z tw_tab.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fft64 is
  port (
    clk, rst, we : in  std_logic;
    xr, xi       : in  signed(15 downto 0);
    gotowy       : out std_logic;
    yr, yi       : out signed(15 downto 0) := (others => '0');
    wy_wazne     : out std_logic := '0'
  );
end entity fft64;

architecture rtl of fft64 is
  type pam_t is array (0 to 63) of signed(15 downto 0);
  type stan_t is (S_WCZYT, S_LICZ, S_WYJ);
  signal mr, mi        : pam_t := (others => (others => '0'));
  signal stan          : stan_t := S_WCZYT;
  signal n             : unsigned(5 downto 0) := (others => '0');
  signal etap          : natural range 1 to 6 := 1;
  signal gora, dol     : natural range 0 to 63;
  signal kw            : unsigned(4 downto 0);
  signal wr, wi        : signed(15 downto 0);

  function odwr(a : unsigned(5 downto 0)) return unsigned is
    variable r : unsigned(5 downto 0);
  begin
    for i in 0 to 5 loop
      r(i) := a(5 - i);
    end loop;
    return r;
  end function;
begin
  gotowy <= '1' when stan = S_WCZYT else '0';

  -- indeksy motyla b (0..31) w etapie s: pol = 2^(s-1), górny = (b / pol)·2·pol + b mod pol, dolny = górny + pol,
  -- współczynnik W^k, k = (b mod pol)·32/pol
  process (all)
    variable b : natural range 0 to 31;
  begin
    b := to_integer(n(4 downto 0));
    gora <= 0; dol <= 0; kw <= (others => '0');
    for s in 1 to 6 loop
      if etap = s then
        gora <= (b / 2 ** (s - 1)) * 2 ** s + b mod 2 ** (s - 1);
        dol  <= (b / 2 ** (s - 1)) * 2 ** s + b mod 2 ** (s - 1) + 2 ** (s - 1);
        kw   <= to_unsigned((b mod 2 ** (s - 1)) * 2 ** (6 - s), 5);
      end if;
    end loop;
  end process;
  u_tw : entity work.tw_tab port map (k => kw, wr => wr, wi => wi);

  process (clk)
    variable pr, pq             : signed(32 downto 0);
    variable tr, ti             : signed(17 downto 0);
    variable s1r, s1i, s2r, s2i : signed(17 downto 0);
  begin
    if rising_edge(clk) then
      wy_wazne <= '0';
      if rst = '1' then
        stan <= S_WCZYT; n <= (others => '0'); etap <= 1; yr <= (others => '0'); yi <= (others => '0');
      else
        case stan is
          when S_WCZYT =>
            if we = '1' then
              mr(to_integer(odwr(n))) <= xr;
              mi(to_integer(odwr(n))) <= xi;
              n <= n + 1;
              if n = 63 then
                stan <= S_LICZ; n <= (others => '0'); etap <= 1;
              end if;
            end if;
          when S_LICZ =>
            pr  := resize(wr * mr(dol), 33) - resize(wi * mi(dol), 33) + 16384;
            pq  := resize(wr * mi(dol), 33) + resize(wi * mr(dol), 33) + 16384;
            tr  := pr(32 downto 15);
            ti  := pq(32 downto 15);
            s1r := resize(mr(gora), 18) + tr;
            s1i := resize(mi(gora), 18) + ti;
            s2r := resize(mr(gora), 18) - tr;
            s2i := resize(mi(gora), 18) - ti;
            mr(gora) <= s1r(16 downto 1); mi(gora) <= s1i(16 downto 1);
            mr(dol)  <= s2r(16 downto 1); mi(dol)  <= s2i(16 downto 1);
            if n(4 downto 0) = 31 then
              n <= (others => '0');
              if etap = 6 then
                stan <= S_WYJ;
              else
                etap <= etap + 1;
              end if;
            else
              n <= n + 1;
            end if;
          when S_WYJ =>
            yr <= mr(to_integer(n)); yi <= mi(to_integer(n)); wy_wazne <= '1';
            n  <= n + 1;
            if n = 63 then
              stan <= S_WCZYT; n <= (others => '0');
            end if;
        end case;
      end if;
    end if;
  end process;
end architecture rtl;
