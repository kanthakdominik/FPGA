-- Testbench 27.03: pwm_avl przez procedury mastera Avalon-MM (zapis, odczyt z opóźnieniem 1 takt): wartości po
-- resecie, rejestry, wypełnienie, zmiana wypełnienia od następnego okresu, KONIEC/W1C, przerwanie, 0% i 100%.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_pwm is
end entity tb_pwm;

architecture sim of tb_pwm is
  signal clk       : std_logic := '0';
  signal fin       : boolean := false;
  signal rst       : std_logic := '1';
  signal address   : std_logic_vector(1 downto 0) := "00";
  signal rd, wr    : std_logic := '0';
  signal writedata : std_logic_vector(31 downto 0) := (others => '0');
  signal readdata  : std_logic_vector(31 downto 0);
  signal irq, pwm  : std_logic;

  procedure pisz(s : string) is
    variable l : line;
  begin
    write(l, s);
    writeline(output, l);
  end procedure;
begin
  clk <= not clk after 5 ns when not fin else clk;
  dut : entity work.pwm_avl port map (clk => clk, rst => rst, address => address, read => rd, write => wr,
                                      writedata => writedata, readdata => readdata, irq => irq, pwm => pwm);

  process
    variable bledy, wysokie : integer := 0;
    variable d : std_logic_vector(31 downto 0);

    procedure av_zapis(a : natural; v : natural) is
    begin
      wait until falling_edge(clk);
      address <= std_logic_vector(to_unsigned(a, 2)); writedata <= std_logic_vector(to_unsigned(v, 32)); wr <= '1';
      wait until falling_edge(clk);
      wr <= '0';
    end procedure;

    procedure av_odczyt(a : natural; v : out std_logic_vector(31 downto 0)) is
    begin
      wait until falling_edge(clk);
      address <= std_logic_vector(to_unsigned(a, 2)); rd <= '1';
      wait until falling_edge(clk);
      rd <= '0'; v := readdata;
    end procedure;

    procedure sprawdz(a : natural; oczek : natural; nazwa : string) is
      variable v : std_logic_vector(31 downto 0);
    begin
      av_odczyt(a, v);
      if to_integer(unsigned(v)) /= oczek then
        pisz("FAIL: " & nazwa & " = " & integer'image(to_integer(unsigned(v))) & ", oczekiwane " & integer'image(oczek));
        bledy := bledy + 1;
      end if;
    end procedure;

    procedure zmierz(n : natural) is
    begin
      wysokie := 0;
      for k in 1 to n loop
        wait until falling_edge(clk);
        if pwm = '1' then wysokie := wysokie + 1; end if;
      end loop;
    end procedure;

    procedure blad(s : string) is
    begin
      pisz("FAIL: " & s);
      bledy := bledy + 1;
    end procedure;
  begin
    for i in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    sprawdz(0, 0, "STER");
    sprawdz(1, 0, "OKRES");
    sprawdz(3, 0, "STATUS");
    av_zapis(1, 10);
    av_zapis(2, 3);
    sprawdz(1, 10, "OKRES");
    sprawdz(2, 3, "WYPELN");
    if pwm /= '0' then blad("PWM aktywne przed wlaczeniem"); end if;

    av_zapis(0, 1);
    zmierz(100);
    pisz("OKRES = 10, WYPELN = 3: " & integer'image(wysokie) & " taktow stanu wysokiego na 100 (oczekiwane 30)");
    if wysokie /= 30 then bledy := bledy + 1; end if;
    av_odczyt(3, d);
    if d(0) /= '1' then blad("brak flagi KONIEC"); end if;
    if irq /= '0' then blad("irq mimo PRZ = 0"); end if;
    av_zapis(0, 3);
    if irq /= '1' then blad("brak irq przy KONIEC i PRZ"); end if;
    av_zapis(0, 2);
    if irq /= '1' then blad("irq zniknelo bez kasowania"); end if;
    av_zapis(3, 1);
    if irq /= '0' then blad("irq po skasowaniu"); end if;
    sprawdz(3, 0, "STATUS");
    pisz("flaga KONIEC, przerwanie i kasowanie zapisem 1: sprawdzone");

    av_zapis(0, 1);
    wait until rising_edge(pwm);
    wait until falling_edge(clk);
    for i in 1 to 4 loop wait until falling_edge(clk); end loop;
    av_zapis(2, 9);
    wysokie := 0;
    while pwm = '0' loop
      wait until falling_edge(clk);
      wysokie := wysokie + 1;
    end loop;
    pisz("zmiana WYPELN 3 -> 9 w srodku okresu: do konca okresu wyjscie niskie przez " & integer'image(wysokie) & " taktow");
    if wysokie < 3 then bledy := bledy + 1; end if;
    zmierz(10);
    pisz("nastepny okres: " & integer'image(wysokie) & " taktow wysokich na 10 (oczekiwane 9)");
    if wysokie /= 9 then bledy := bledy + 1; end if;
    sprawdz(2, 9, "WYPELN");

    av_zapis(2, 0);
    for i in 1 to 12 loop wait until falling_edge(clk); end loop;
    zmierz(30);
    pisz("WYPELN = 0: " & integer'image(wysokie) & " taktow wysokich na 30");
    if wysokie /= 0 then bledy := bledy + 1; end if;
    av_zapis(2, 50);
    for i in 1 to 12 loop wait until falling_edge(clk); end loop;
    zmierz(30);
    pisz("WYPELN = 50 > OKRES: " & integer'image(wysokie) & " taktow wysokich na 30");
    if wysokie /= 30 then bledy := bledy + 1; end if;

    av_zapis(0, 0);
    for i in 1 to 2 loop wait until falling_edge(clk); end loop;
    if pwm /= '0' then blad("PWM po wylaczeniu"); end if;

    if bledy = 0 then pisz("PASS");
    else pisz("FAIL: " & integer'image(bledy) & " bledow"); end if;
    fin <= true;
    wait;
  end process;
end architecture sim;
