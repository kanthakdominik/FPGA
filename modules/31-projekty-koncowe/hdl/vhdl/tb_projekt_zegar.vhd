-- Testbench projektu 1 (31.01), VHDL: te same komendy i sprawdzenia co tb_projekt_zegar.v.
-- 1 s = 10 000 taktów (CS_DZIEL = 100), bit UART = 20 taktów.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_projekt_zegar is
end entity tb_projekt_zegar;

architecture sim of tb_projekt_zegar is
  constant BIT_T : positive := 20;
  constant CS    : positive := 100;
  constant SEK   : positive := 100 * CS;
  signal clk     : std_logic := '0';
  signal fin     : boolean := false;
  signal rst     : std_logic := '1';
  signal rx      : std_logic := '1';
  signal tx, biegnie, pominieto, blad_ramki : std_logic;
  signal czas, stoper : std_logic_vector(23 downto 0);
  signal takt    : natural := 0;
  signal ostatnia : string(1 to 16) := (others => ' ');
  signal dl_ost  : natural := 0;
  signal nlinii  : natural := 0;

  procedure pisz(s : string) is
    variable l : line;
  begin
    write(l, s);
    writeline(output, l);
  end procedure;
begin
  clk <= not clk after 5 ns when not fin else clk;
  process (clk) begin if rising_edge(clk) then takt <= takt + 1; end if; end process;

  dut : entity work.projekt_zegar generic map (CLK_HZ => 1_000_000, BAUD => 50_000, CS_DZIEL => CS)
    port map (clk => clk, rst => rst, rx => rx, tx => tx, czas => czas, stoper => stoper, biegnie => biegnie,
              pominieto => pominieto, blad_ramki => blad_ramki);

  -- odbiornik testbencha: linie zakończone LF, CR pomijany
  odbior : process
    variable b    : std_logic_vector(7 downto 0);
    variable bufl : string(1 to 16) := (others => ' ');
    variable n    : natural := 0;
  begin
    wait until falling_edge(tx);
    for i in 1 to BIT_T + BIT_T / 2 loop wait until rising_edge(clk); end loop;
    for k in 0 to 7 loop
      b(k) := tx;
      for i in 1 to BIT_T loop wait until rising_edge(clk); end loop;
    end loop;
    if b = x"0A" then
      ostatnia <= bufl; dl_ost <= n; nlinii <= nlinii + 1;
      bufl := (others => ' '); n := 0;
    elsif b /= x"0D" and n < 16 then
      n := n + 1;
      bufl(n) := character'val(to_integer(unsigned(b)));
    end if;
  end process;

  process
    variable bledy, t_s, t_l, t_p, n0 : integer := 0;

    procedure czekaj(n : natural) is
    begin
      for i in 1 to n loop wait until rising_edge(clk); end loop;
    end procedure;
    procedure wyslij(c : character) is
      variable b : std_logic_vector(7 downto 0);
    begin
      b := std_logic_vector(to_unsigned(character'pos(c), 8));
      rx <= '0'; czekaj(BIT_T);
      for i in 0 to 7 loop rx <= b(i); czekaj(BIT_T); end loop;
      rx <= '1'; czekaj(BIT_T);
    end procedure;
    procedure komenda(s : string) is
    begin
      for i in s'range loop wyslij(s(i)); end loop;
    end procedure;
    procedure czekaj_linie is
      variable n0, t : natural := 0;
    begin
      n0 := nlinii; t := 0;
      while nlinii = n0 and t < 20_000 loop wait until rising_edge(clk); t := t + 1; end loop;
      wait for 0 ns;
      if nlinii = n0 then pisz("FAIL: brak odpowiedzi"); bledy := bledy + 1; end if;
    end procedure;
    procedure oczekuj(wzor : string; co : string) is
    begin
      czekaj_linie;
      if dl_ost /= wzor'length or ostatnia(1 to dl_ost) /= wzor then
        pisz("FAIL: " & co & ": odpowiedz """ & ostatnia(1 to dl_ost) & """, oczekiwane """ & wzor & """");
        bledy := bledy + 1;
      else
        pisz(co & " -> " & wzor);
      end if;
    end procedure;
    -- setne z ostatnich 8 znaków "mm:ss.cc"
    impure function setne return integer is
      variable s : string(1 to 8);
      function d(c : character) return integer is
      begin
        return character'pos(c) - character'pos('0');
      end function;
    begin
      s := ostatnia(dl_ost - 7 to dl_ost);
      return (d(s(1)) * 10 + d(s(2))) * 6000 + (d(s(4)) * 10 + d(s(5))) * 100 + d(s(7)) * 10 + d(s(8));
    end function;
    procedure sprawdz_setne(zm : integer; takty : integer; co : string) is
      variable ocz : integer;
    begin
      ocz := takty / CS;
      if zm < ocz - 1 or zm > ocz + 1 then
        pisz("FAIL: " & co & ": " & integer'image(zm) & " setnych, oczekiwane " & integer'image(ocz) & " +- 1");
        bledy := bledy + 1;
      else
        pisz(co & ": " & integer'image(zm) & " setnych (z czasu testbencha " & integer'image(ocz) & ")");
      end if;
    end procedure;
  begin
    czekaj(10); rst <= '0'; czekaj(10);
    komenda("?");        oczekuj("00:00:00", "?");
    komenda("T235958");  oczekuj("OK", "T235958");
    czekaj(3 * SEK);
    komenda("?");        oczekuj("00:00:01", "? po 3 s");
    komenda("t010203");  oczekuj("OK", "t010203");
    komenda("?");        oczekuj("01:02:03", "?");
    komenda("T240000");  oczekuj("ERR", "T240000");
    komenda("T125960");  oczekuj("ERR", "T125960");
    komenda("T1a");      oczekuj("ERR", "T1a");
    komenda("X");        oczekuj("ERR", "X");
    komenda("?");        oczekuj("01:02:03", "? bez zmian");

    t_s := takt; komenda("S"); oczekuj("OK", "S");
    if biegnie /= '1' then pisz("FAIL: stoper nie biegnie"); bledy := bledy + 1; end if;
    czekaj(12_000);
    t_l := takt; komenda("L"); czekaj_linie;
    if dl_ost /= 10 or ostatnia(1 to 2) /= "L " then
      pisz("FAIL: L: """ & ostatnia(1 to dl_ost) & """"); bledy := bledy + 1;
    end if;
    sprawdz_setne(setne, t_l - t_s, "L");
    czekaj(5000);
    t_p := takt; komenda("P"); oczekuj("OK", "P");
    czekaj(2 * SEK);
    komenda("W"); czekaj_linie;
    sprawdz_setne(setne, t_p - t_s, "W po pauzie");
    if biegnie = '1' then pisz("FAIL: stoper biegnie po P"); bledy := bledy + 1; end if;
    komenda("R");        oczekuj("OK", "R");
    komenda("W");        oczekuj("00:00.00", "W po R");

    n0 := nlinii;
    komenda("??");
    czekaj(6000);
    if nlinii - n0 /= 1 or pominieto /= '1' then
      pisz("FAIL: " & integer'image(nlinii - n0) & " odpowiedzi na dwie komendy naraz");
      bledy := bledy + 1;
    else
      pisz("?? naraz -> 1 odpowiedz, flaga pominieto = 1");
    end if;
    if blad_ramki = '1' then pisz("FAIL: blad ramki"); bledy := bledy + 1; end if;
    if bledy = 0 then pisz("PASS"); else pisz("FAIL: " & integer'image(bledy) & " bledow"); end if;
    fin <= true;
    wait;
  end process;
end architecture sim;
