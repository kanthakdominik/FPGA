-- Testbench 29.04: SECDED (39,32) — 200 słów, wszystkie błędy pojedyncze i podwójne; pamiec_ecc — błędy
-- pojedyncze w 20 słowach i podwójne w 3, odczyt z korekcją, jedno przejście czyszczenia (20 zapisów
-- zwrotnych, 3 błędy podwójne), odczyty po czyszczeniu i pierwszeństwo zapisu użytkownika.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_ecc is
end entity tb_ecc;

architecture sim of tb_ecc is
  signal clk      : std_logic := '0';
  signal fin      : boolean := false;
  signal rst      : std_logic := '1';
  -- A
  signal d        : std_logic_vector(31 downto 0) := (others => '0');
  signal blad     : std_logic_vector(38 downto 0) := (others => '0');
  signal c, cb    : std_logic_vector(38 downto 0);
  signal dd       : std_logic_vector(31 downto 0);
  signal pop, podw : std_logic;
  -- B
  signal we, rd, czysc_en, wstrzyk : std_logic := '0';
  signal adr, wstrzyk_adr          : unsigned(5 downto 0) := (others => '0');
  signal wdane, rdane              : std_logic_vector(31 downto 0) := (others => '0');
  signal wstrzyk_maska             : std_logic_vector(38 downto 0) := (others => '0');
  signal r_pop, r_podw, r_wazne    : std_logic;
  signal czysc_adr                 : unsigned(5 downto 0);
  signal skorygowane, podwojne     : unsigned(15 downto 0);

  type wzor_t is array (0 to 63) of std_logic_vector(31 downto 0);

  procedure pisz(s : string) is
    variable l : line;
  begin
    write(l, s);
    writeline(output, l);
  end procedure;

  function bit_na(i : natural) return std_logic_vector is
    variable v : std_logic_vector(38 downto 0) := (others => '0');
  begin
    v(i) := '1';
    return v;
  end function;
begin
  clk <= not clk after 5 ns when not fin else clk;
  u_k : entity work.secded_koder port map (d => d, c => c);
  cb <= c xor blad;
  u_d : entity work.secded_dekoder port map (c => cb, d => dd, poprawiony => pop, podwojny => podw);
  u_p : entity work.pamiec_ecc generic map (SLOWA => 64, AW => 6)
    port map (clk => clk, rst => rst, we => we, rd => rd, adr => adr, wdane => wdane, rdane => rdane,
              r_poprawiony => r_pop, r_podwojny => r_podw, r_wazne => r_wazne, czysc_en => czysc_en,
              czysc_adr => czysc_adr, skorygowane => skorygowane, podwojne => podwojne, wstrzyk => wstrzyk,
              wstrzyk_adr => wstrzyk_adr, wstrzyk_maska => wstrzyk_maska);

  process
    variable s : unsigned(31 downto 0) := to_unsigned(29, 32);
    variable a_czyste, a_poj, a_podw, a_bl, bledy, b_flagi, b_dane : integer := 0;
    variable wzor : wzor_t;
    variable od : std_logic_vector(31 downto 0);
    variable op, opd : std_logic;

    procedure lcg is
    begin
      s := resize(s * to_unsigned(1664525, 32) + to_unsigned(1013904223, 32), 32);
    end procedure;
    procedure zapisz(a : natural; v : std_logic_vector(31 downto 0)) is
    begin
      wait until falling_edge(clk);
      we <= '1'; adr <= to_unsigned(a, 6); wdane <= v;
      wait until falling_edge(clk);
      we <= '0';
      wzor(a) := v;
    end procedure;
    procedure psuj(a : natural; m : std_logic_vector(38 downto 0)) is
    begin
      wait until falling_edge(clk);
      wstrzyk <= '1'; wstrzyk_adr <= to_unsigned(a, 6); wstrzyk_maska <= m;
      wait until falling_edge(clk);
      wstrzyk <= '0';
    end procedure;
    procedure czytaj(a : natural) is
    begin
      wait until falling_edge(clk);
      rd <= '1'; adr <= to_unsigned(a, 6);
      wait until falling_edge(clk);
      rd <= '0'; od := rdane; op := r_pop; opd := r_podw;
    end procedure;
  begin
    for n in 1 to 200 loop
      lcg;
      d <= std_logic_vector(s);
      blad <= (others => '0');
      wait for 1 ns;
      if dd /= std_logic_vector(s) or pop = '1' or podw = '1' then a_bl := a_bl + 1; else a_czyste := a_czyste + 1; end if;
      for i in 0 to 38 loop
        blad <= bit_na(i);
        wait for 1 ns;
        if dd /= std_logic_vector(s) or pop = '0' or podw = '1' then a_bl := a_bl + 1; else a_poj := a_poj + 1; end if;
      end loop;
      for i in 0 to 38 loop
        for j in i + 1 to 38 loop
          blad <= bit_na(i) or bit_na(j);
          wait for 1 ns;
          if podw = '0' or pop = '1' then a_bl := a_bl + 1; else a_podw := a_podw + 1; end if;
        end loop;
      end loop;
    end loop;
    pisz("A: slow 200 - bez bledu " & integer'image(a_czyste) & ", bledy pojedyncze poprawione "
         & integer'image(a_poj) & "/7800, podwojne wykryte " & integer'image(a_podw) & "/148200, niezgodnosci "
         & integer'image(a_bl));
    if a_bl /= 0 or a_poj /= 7800 or a_podw /= 148200 then bledy := bledy + 1; end if;

    wait until falling_edge(clk);
    wait until falling_edge(clk);
    rst <= '0';
    for i in 0 to 63 loop lcg; zapisz(i, std_logic_vector(s)); end loop;
    for i in 0 to 19 loop psuj(i, bit_na(i mod 39)); end loop;
    for i in 40 to 42 loop psuj(i, bit_na(i mod 39) or bit_na((i + 7) mod 39)); end loop;
    czytaj(5);
    if od /= wzor(5) or op = '0' or opd = '1' then pisz("FAIL: odczyt slowa z bledem pojedynczym"); bledy := bledy + 1; end if;
    czytaj(41);
    if opd = '0' then pisz("FAIL: brak flagi bledu podwojnego"); bledy := bledy + 1; end if;

    wait until falling_edge(clk); czysc_en <= '1';
    for i in 1 to 64 loop wait until falling_edge(clk); end loop;
    czysc_en <= '0';
    for i in 1 to 3 loop wait until falling_edge(clk); end loop;
    pisz("B: jedno przejscie czyszczenia - zapisow zwrotnych " & integer'image(to_integer(skorygowane))
         & " (oczekiwane 20), bledow podwojnych " & integer'image(to_integer(podwojne)) & " (oczekiwane 3)");
    if skorygowane /= 20 or podwojne /= 3 then bledy := bledy + 1; end if;
    for i in 0 to 63 loop
      czytaj(i);
      if i >= 40 and i < 43 then
        if opd = '0' then b_flagi := b_flagi + 1; end if;
      else
        if op = '1' or opd = '1' then b_flagi := b_flagi + 1; end if;
        if od /= wzor(i) then b_dane := b_dane + 1; end if;
      end if;
    end loop;
    pisz("B: po czyszczeniu - slow z flagami nieoczekiwanymi " & integer'image(b_flagi) & ", z blednymi danymi "
         & integer'image(b_dane));
    if b_flagi /= 0 or b_dane /= 0 then bledy := bledy + 1; end if;

    psuj(30, bit_na(3));
    psuj(31, bit_na(9));
    wait until falling_edge(clk); czysc_en <= '1';
    while czysc_adr /= 30 loop wait until falling_edge(clk); end loop;
    we <= '1'; adr <= to_unsigned(30, 6); wdane <= x"A5A50030";
    wait until falling_edge(clk);
    adr <= to_unsigned(31, 6); wdane <= x"A5A50031";
    wait until falling_edge(clk);
    we <= '0';
    for i in 1 to 70 loop wait until falling_edge(clk); end loop;
    czysc_en <= '0';
    for i in 1 to 3 loop wait until falling_edge(clk); end loop;
    czytaj(30);
    if od /= x"A5A50030" or op = '1' or opd = '1' then pisz("FAIL: czyszczenie nadpisalo zapis uzytkownika (30)"); bledy := bledy + 1; end if;
    czytaj(31);
    if od /= x"A5A50031" or op = '1' or opd = '1' then pisz("FAIL: czyszczenie nadpisalo zapis uzytkownika (31)"); bledy := bledy + 1; end if;
    pisz("B: zapisy uzytkownika w trakcie czyszczenia zachowane (adresy 30 i 31)");

    if bledy = 0 then pisz("PASS"); else pisz("FAIL: " & integer'image(bledy) & " bledow"); end if;
    fin <= true;
    wait;
  end process;
end architecture sim;
