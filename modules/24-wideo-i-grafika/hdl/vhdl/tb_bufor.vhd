-- Testbench 24.04: takt_wideo + bufor_ramki z modelem pamięci Avalon-MM (bursty, opóźnienie ≥ 3 takty, losowy
-- waitrequest 30%, przerwy w readdatavalid 20%). Obraz 48×6 (6 słów na linię, bursty 4 + 2), SK = 1, zegary
-- 25 MHz i ok. 71 MHz. Klasyfikacja ramek (czarna, A, B, mieszana); przelacz w połowie ramek 2 i 4 ->
-- oczekiwany ciąg: czarna, A, A, B, B, A, A. Brak niedoborów (brak = '0').
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_bufor is
end entity tb_bufor;

architecture sim of tb_bufor is
  constant SZER : positive := 48;
  constant WYS  : positive := 6;
  constant SLOW : positive := 6;
  constant RAMKA : positive := SLOW * WYS;

  signal clk_p, clk_m : std_logic := '0';
  signal rst_p, rst_m : std_logic := '1';
  signal fin : boolean := false;
  signal hs, vs, de, nowa_ramka : std_logic;
  signal x, y : unsigned(11 downto 0);
  signal przelacz : std_logic := '0';
  signal aktywny, oczekuje, brak : std_logic;
  signal m_adr : unsigned(15 downto 0);
  signal m_read : std_logic;
  signal m_burstcount : unsigned(4 downto 0);
  signal m_wait, m_rvalid : std_logic := '0';
  signal m_rdata : std_logic_vector(31 downto 0) := (others => '0');
  signal o_de, o_hs, o_vs : std_logic;
  signal o_piks : std_logic_vector(3 downto 0);
  signal nr, oy : natural := 0;
  type klasy_t is array (0 to 9) of character;
  signal klasa : klasy_t := (others => '?');
  signal n_burst, n_slow, bl_linii : natural := 0;

  function wzor(f, px, py : natural) return natural is
  begin
    return (f * 7 + px * 3 + py * 5 + 1) mod 16;
  end function;
begin
  clk_p <= not clk_p after 20 ns when not fin else clk_p;
  clk_m <= not clk_m after 7 ns when not fin else clk_m;

  u_takt : entity work.takt_wideo
    generic map (H_AKT => 96, H_FP => 4, H_SYNC => 6, H_BP => 6, V_AKT => 12, V_FP => 1, V_SYNC => 2, V_BP => 2,
                 H_POL => '1', V_POL => '1')
    port map (clk => clk_p, rst => rst_p, hs => hs, vs => vs, de => de, x => x, y => y, nowa_ramka => nowa_ramka);

  dut : entity work.bufor_ramki
    generic map (SZER => SZER, WYS => WYS, SK => 1, BURST => 4, AW => 16, BAZA0 => 0, BAZA1 => RAMKA)
    port map (clk_m => clk_m, rst_m => rst_m, przelacz => przelacz, aktywny => aktywny, oczekuje => oczekuje,
              brak => brak, m_adr => m_adr, m_read => m_read, m_burstcount => m_burstcount, m_wait => m_wait,
              m_rvalid => m_rvalid, m_rdata => m_rdata,
              clk_p => clk_p, rst_p => rst_p, de => de, hs => hs, vs => vs, x => x, y => y,
              o_de => o_de, o_hs => o_hs, o_vs => o_vs, o_piks => o_piks);

  -- model pamięci Avalon-MM z burstami
  process (clk_m)
    type pam_t is array (0 to 2 * RAMKA - 1) of std_logic_vector(31 downto 0);
    type ka_t is array (0 to 15) of natural;
    variable pam : pam_t;
    variable k_adr, k_dl, k_t : ka_t := (others => 0);
    variable kz, ko, ile_w, takt : natural := 0;
    variable init : boolean := false;
    variable s1, s2 : positive := 77;
    variable r : real;
    variable w : natural;
  begin
    if not init then
      for f in 0 to 1 loop
        for wi in 0 to RAMKA - 1 loop
          for p in 0 to 7 loop
            pam(f * RAMKA + wi)(4 * p + 3 downto 4 * p) :=
              std_logic_vector(to_unsigned(wzor(f, (wi mod SLOW) * 8 + p, wi / SLOW), 4));
          end loop;
        end loop;
      end loop;
      init := true;
    end if;
    if falling_edge(clk_m) then
      uniform(s1, s2, r);
      if r < 0.3 then m_wait <= '1'; else m_wait <= '0'; end if;
    end if;
    if rising_edge(clk_m) then
      takt := takt + 1;
      if m_read = '1' and m_wait = '0' then
        k_adr(kz mod 16) := to_integer(m_adr); k_dl(kz mod 16) := to_integer(m_burstcount); k_t(kz mod 16) := takt;
        kz := kz + 1; n_burst <= n_burst + 1;
      end if;
      m_rvalid <= '0';
      uniform(s1, s2, r);
      if ko /= kz and takt - k_t(ko mod 16) >= 3 and r >= 0.2 then
        m_rvalid <= '1';
        w := k_adr(ko mod 16) + ile_w;
        m_rdata <= pam(w);
        n_slow <= n_slow + 1;
        if ile_w + 1 = k_dl(ko mod 16) then ile_w := 0; ko := ko + 1; else ile_w := ile_w + 1; end if;
      end if;
    end if;
  end process;

  -- klasyfikacja wyświetlonych ramek
  process (clk_p)
    variable ox, n_pix, zg0, zg1, czarne, yy, bl : natural := 0;
    variable vs_d, de_d : std_logic := '0';
    variable k : character;
    variable l : line;
  begin
    if rising_edge(clk_p) then
      if o_de = '1' then
        if to_integer(unsigned(o_piks)) = wzor(0, ox / 2, yy / 2) then zg0 := zg0 + 1; end if;
        if to_integer(unsigned(o_piks)) = wzor(1, ox / 2, yy / 2) then zg1 := zg1 + 1; end if;
        if o_piks = "0000" then czarne := czarne + 1; end if;
        ox := ox + 1; n_pix := n_pix + 1;
      end if;
      if de_d = '1' and o_de = '0' then
        if ox /= 96 then bl := bl + 1; end if;
        ox := 0; yy := yy + 1;
      end if;
      if o_vs = '1' and vs_d = '0' then
        if n_pix /= 96 * 12 then k := 'R';
        elsif czarne = n_pix then k := 'C';
        elsif zg0 = n_pix then k := 'A';
        elsif zg1 = n_pix then k := 'B';
        else k := 'M';
        end if;
        if nr < 10 then klasa(nr) <= k; end if;
        write(l, "ramka " & integer'image(nr) & ": " & k & " (pikseli " & integer'image(n_pix) & ", zgodnych z A "
              & integer'image(zg0) & ", z B " & integer'image(zg1) & "), aktywny = " & std_logic'image(aktywny));
        writeline(output, l);
        nr <= nr + 1; yy := 0; n_pix := 0; zg0 := 0; zg1 := 0; czarne := 0;
      end if;
      vs_d := o_vs; de_d := o_de;
      oy <= yy; bl_linii <= bl;
    end if;
  end process;

  process
    variable l : line;
    variable errors : natural := 0;
  begin
    for i in 1 to 4 loop wait until rising_edge(clk_m); end loop;
    rst_m <= '0';
    wait until rising_edge(clk_p);
    rst_p <= '0';
    for i in 0 to 6 loop
      if nr /= i then wait until nr = i; end if;
      if i = 2 or i = 4 then                                         -- połowa ramki: zgłoś zamianę
        wait until o_de = '1' and oy = 6;
        wait until falling_edge(clk_m);
        przelacz <= '1';
        wait until falling_edge(clk_m);
        przelacz <= '0';
      end if;
    end loop;
    if nr /= 7 then wait until nr = 7; end if;
    wait for 1 ns;
    if klasa(0) /= 'C' or klasa(1) /= 'A' or klasa(2) /= 'A' or klasa(3) /= 'B' or klasa(4) /= 'B'
       or klasa(5) /= 'A' or klasa(6) /= 'A' then errors := errors + 1; end if;
    write(l, "burstow " & integer'image(n_burst) & ", slow " & integer'image(n_slow) & " (" & integer'image(RAMKA)
          & " na ramke); klasy ramek (C - czarna): " & klasa(0) & klasa(1) & klasa(2) & klasa(3) & klasa(4)
          & klasa(5) & klasa(6));
    writeline(output, l);
    write(l, "brak = " & std_logic'image(brak) & ", oczekuje = " & std_logic'image(oczekuje) & ", bledne linie "
          & integer'image(bl_linii));
    writeline(output, l);
    if brak /= '0' or oczekuje /= '0' or bl_linii /= 0 then errors := errors + 1; end if;
    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
