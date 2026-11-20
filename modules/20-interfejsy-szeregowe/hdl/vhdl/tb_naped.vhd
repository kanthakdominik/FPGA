-- Testbench 20.04: pwm_mostek, serwo i enkoder.
--   pwm_mostek (OKRES = 100, MARTWY = 5): dla wypełnień 0, 1, 3, 10, 50, 99, 100 — czasy włączenia wyjść
--   górnego i dolnego w ustalonym okresie (2·wyp − MARTWY i 2·(OKRES − wyp) − MARTWY, ucięte w zerze), nigdy
--   oba naraz, przerwa między nimi >= MARTWY; zmiana wypełnienia w środku okresu działa od następnego okresu.
--   serwo (zegar 1 MHz): pozycje 0, 128, 255 -> impulsy 1000, 1502, 2000 µs, okres 20 000 µs.
--   enkoder (FILTR = 8): 300 kroków w przód i 120 w tył z drganiami styków krótszymi od filtra,
--   pozycja i kierunek; 5 skoków niedozwolonych (zmiana A i B naraz) -> bledy = 5.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_naped is
end entity tb_naped;

architecture sim of tb_naped is
  constant OKRES  : positive := 100;
  constant MARTWY : positive := 5;
  type tab_t is array (0 to 15) of integer;
  type czasy_t is array (0 to 5) of time;
  signal clk, clk1 : std_logic := '0';
  signal fin, zatrzymaj : boolean := false;
  signal rst      : std_logic := '1';
  -- PWM
  signal wyp      : std_logic_vector(9 downto 0) := (others => '0');
  signal gora, dol, poczatek : std_logic;
  signal okresy   : integer := 0;
  signal zeruj    : boolean := false;
  signal wg, wd   : tab_t := (others => 0);
  signal oba      : integer := 0;
  signal min_przerwa : integer := 1000;
  -- serwo
  signal poz      : std_logic_vector(7 downto 0) := x"00";
  signal imp      : std_logic;
  signal szer, okr : czasy_t := (others => 0 ns);
  -- enkoder
  signal ea, eb   : std_logic := '0';
  signal pozycja  : std_logic_vector(15 downto 0);
  signal kierunek : std_logic;
  signal bledy    : std_logic_vector(7 downto 0);

  function oczek(w : integer) return integer is                 -- bez przełączeń nie ma czasu martwego
  begin
    if w = 0 then return 0;
    elsif w = OKRES then return 2 * OKRES;
    elsif 2 * w - MARTWY > 0 then return 2 * w - MARTWY;
    else return 0;
    end if;
  end function;
begin
  clk  <= not clk after 10 ns when not fin and not zatrzymaj else clk;   -- 50 MHz, zatrzymywany na test serwa
  clk1 <= not clk1 after 500 ns when not fin else clk1;                  -- 1 MHz dla serwa

  u_pwm : entity work.pwm_mostek generic map (W => 10, OKRES => OKRES, MARTWY => MARTWY)
    port map (clk => clk, rst => rst, wyp => wyp, gora => gora, dol => dol, poczatek => poczatek);

  process (clk)
    variable n_g, n_d, przerwa : integer := 0;
  begin
    if rising_edge(clk) and rst = '0' then
      if gora = '1' and dol = '1' then oba <= oba + 1; end if;
      if gora = '0' and dol = '0' then
        przerwa := przerwa + 1;
      else
        if przerwa > 0 and przerwa < min_przerwa then min_przerwa <= przerwa; end if;
        przerwa := 0;
      end if;
      if gora = '1' then n_g := n_g + 1; end if;
      if dol = '1' then n_d := n_d + 1; end if;
      if zeruj then
        okresy <= 0;
      elsif poczatek = '1' then
        if okresy < 16 then
          wg(okresy) <= n_g;
          wd(okresy) <= n_d;
        end if;
        okresy <= okresy + 1;
        n_g := 0;
        n_d := 0;
      end if;
    end if;
  end process;

  u_serwo : entity work.serwo generic map (CLK_HZ => 1_000_000)
    port map (clk => clk1, rst => rst, pozycja => poz, impuls => imp);

  process (imp)
    variable t_nar, t_poprz : time := 0 ns;
    variable n : integer := 0;
  begin
    if rising_edge(imp) then
      if n > 0 and n <= 6 then okr(n - 1) <= now - t_poprz; end if;
      t_poprz := now;
      t_nar   := now;
    elsif falling_edge(imp) then
      if n < 6 then szer(n) <= now - t_nar; end if;
      n := n + 1;
    end if;
  end process;

  u_enk : entity work.enkoder generic map (W => 16, FILTR => 8)
    port map (clk => clk, rst => rst, a => ea, b => eb, pozycja => pozycja, kierunek => kierunek, bledy => bledy);

  process
    variable l      : line;
    variable errors : integer := 0;
    variable faza   : integer := 0;                             -- indeks w sekwencji Graya
    variable s1, s2 : positive := 9;
    variable r      : real;
    variable w      : integer;

    function gray(f : integer) return std_logic_vector is
    begin
      case f mod 4 is
        when 0 => return "00";
        when 1 => return "10";
        when 2 => return "11";
        when others => return "01";
      end case;
    end function;

    procedure ustaw(ab : std_logic_vector(1 downto 0)) is
    begin
      ea <= ab(1);
      eb <= ab(0);
    end procedure;

    -- jeden krok z drganiami: zmieniany sygnał przełącza się kilka razy po 60 ns (3 takty < FILTR)
    procedure krok(w_przod : boolean) is
      variable stary, nowy : std_logic_vector(1 downto 0);
    begin
      stary := gray(faza);
      if w_przod then faza := faza + 1; else faza := faza + 3; end if;
      nowy := gray(faza);
      for q in 1 to 3 loop
        ustaw(nowy);  wait for 60 ns;
        ustaw(stary); wait for 60 ns;
      end loop;
      ustaw(nowy);
      uniform(s1, s2, r);
      wait for 400 ns + integer(floor(r * 256.0)) * 1 ns;
    end procedure;

    procedure czekaj_okresy(n : integer) is
    begin
      zeruj <= true;
      wait until rising_edge(clk);
      zeruj <= false;
      wait until okresy = n;
    end procedure;
  begin
    for q in 1 to 5 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    -- PWM: kolejne wypełnienia, po 4 okresy każde
    for k in 0 to 6 loop
      case k is
        when 0 => w := 0;
        when 1 => w := 1;
        when 2 => w := 3;
        when 3 => w := 10;
        when 4 => w := 50;
        when 5 => w := 99;
        when others => w := 100;
      end case;
      wyp <= std_logic_vector(to_unsigned(w, 10));
      czekaj_okresy(4);
      -- okres nr 0 — niepełny; nr 1 zaczyna się od połowy impulsu górnego, którego czas martwy wypadł
      -- jeszcze przy starym wypełnieniu; nr 2 — w pełni ustalony
      if wg(2) /= oczek(w) or wd(2) /= oczek(OKRES - w) then
        write(l, "PWM wyp=" & integer'image(w) & ": gora " & integer'image(wg(2)) & " (oczekiwano "
              & integer'image(oczek(w)) & "), dol " & integer'image(wd(2)) & " (oczekiwano "
              & integer'image(oczek(OKRES - w)) & ")");
        writeline(output, l);
        errors := errors + 1;
      end if;
    end loop;
    -- zmiana wypełnienia w połowie okresu: okres bieżący bez zmian
    wyp <= std_logic_vector(to_unsigned(30, 10));
    czekaj_okresy(1);
    for q in 1 to OKRES loop wait until falling_edge(clk); end loop;
    wyp <= std_logic_vector(to_unsigned(70, 10));
    wait until okresy = 3;
    if wg(1) /= oczek(30) or wg(2) /= oczek(70) then
      write(l, "PWM: zmiana w trakcie okresu: " & integer'image(wg(1)) & ", " & integer'image(wg(2)));
      writeline(output, l);
      errors := errors + 1;
    end if;
    write(l, "PWM: najkrotsza przerwa miedzy wyjsciami " & integer'image(min_przerwa) & " taktow (MARTWY = "
          & integer'image(MARTWY) & ")");
    writeline(output, l);
    if min_przerwa < MARTWY or oba /= 0 then errors := errors + 1; end if;

    -- serwo (zegar 50 MHz zatrzymany)
    zatrzymaj <= true;
    poz <= x"00"; wait for 20 ms;
    poz <= x"80"; wait for 20 ms;
    poz <= x"FF"; wait for 40 ms;
    zatrzymaj <= false;
    -- impuls nr 1 zaczyna się tuż przed zmianą pozycji (pozycja pobierana na początku okresu)
    write(l, "serwo: impulsy " & integer'image(szer(1) / 1 us) & ", " & integer'image(szer(2) / 1 us) & ", "
          & integer'image(szer(3) / 1 us) & " us; okres " & integer'image(okr(1) / 1 us) & " us");
    writeline(output, l);
    if szer(1) /= 1000 us or szer(2) /= 1502 us or szer(3) /= 2000 us or okr(1) /= 20 ms then
      errors := errors + 1;
    end if;

    -- enkoder
    for i in 1 to 300 loop krok(true); end loop;
    wait for 2 us;
    if to_integer(signed(pozycja)) /= 300 or kierunek /= '1' then
      write(l, "enkoder: " & integer'image(to_integer(signed(pozycja))) & " po 300 w przod"); writeline(output, l);
      errors := errors + 1;
    end if;
    for i in 1 to 120 loop krok(false); end loop;
    wait for 2 us;
    if to_integer(signed(pozycja)) /= 180 or kierunek /= '0' then
      write(l, "enkoder: " & integer'image(to_integer(signed(pozycja))) & " po 120 w tyl"); writeline(output, l);
      errors := errors + 1;
    end if;
    for i in 1 to 5 loop                                        -- skok o dwie fazy: A i B naraz
      faza := faza + 2;
      ustaw(gray(faza));
      wait for 1 us;
    end loop;
    write(l, "enkoder: pozycja " & integer'image(to_integer(signed(pozycja))) & ", bledy "
          & integer'image(to_integer(unsigned(bledy))));
    writeline(output, l);
    if to_integer(unsigned(bledy)) /= 5 or to_integer(signed(pozycja)) /= 180 then errors := errors + 1; end if;

    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
