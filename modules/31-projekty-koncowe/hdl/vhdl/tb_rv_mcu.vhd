-- Testbench projektu 6 (31.06), VHDL: te same sprawdzenia co tb_rv_mcu.v (powitanie, LED z licznika, PWM,
-- echo z zamianą liter, pożegnanie, TOHOST).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_rv_mcu is
end entity tb_rv_mcu;

architecture sim of tb_rv_mcu is
  constant BIT_T : positive := 20;
  signal clk : std_logic := '0';
  signal fin : boolean := false;
  signal rst : std_logic := '1';
  signal rx  : std_logic := '1';
  signal tx, pwm_wy, koniec, wycofana : std_logic;
  signal led : std_logic_vector(31 downto 0);
  signal takt, instr : natural := 0;
  signal ostatnia : string(1 to 32) := (others => ' ');
  signal dl_ost, nlinii : natural := 0;
  signal zmian, odstep_min, odstep_max : integer := 0;

  procedure pisz(s : string) is
    variable l : line;
  begin
    write(l, s);
    writeline(output, l);
  end procedure;
begin
  clk <= not clk after 5 ns when not fin else clk;
  process (clk)
  begin
    if rising_edge(clk) then
      takt <= takt + 1;
      if wycofana = '1' then instr <= instr + 1; end if;
    end if;
  end process;

  dut : entity work.rv_mcu
    generic map (SLOWA => 1024, PLIK => "mcu_sym.hex", PLIK_MIF => "", CLK_HZ => 1_000_000, BAUD => 50_000)
    port map (clk => clk, rst => rst, wej => x"0000000F", led => led, uart_rx => rx, uart_tx => tx,
              pwm_wy => pwm_wy, koniec => koniec, wycofana => wycofana);

  odbior : process
    variable b : std_logic_vector(7 downto 0);
    variable bufl : string(1 to 32) := (others => ' ');
    variable n : natural := 0;
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
    elsif b /= x"0D" and n < 32 then
      n := n + 1;
      bufl(n) := character'val(to_integer(unsigned(b)));
    end if;
  end process;

  zmiany_led : process (clk)
    variable led_p : std_logic_vector(31 downto 0) := (others => '0');
    variable t_led : integer := -1;
    variable mn : integer := integer'high;
    variable mx, z : integer := 0;
  begin
    if rising_edge(clk) then
      if led /= led_p and rst = '0' then
        if t_led >= 0 then
          if takt - t_led < mn then mn := takt - t_led; end if;
          if takt - t_led > mx then mx := takt - t_led; end if;
        end if;
        t_led := takt;
        z := z + 1;
      end if;
      led_p := led;
      zmian <= z; odstep_min <= mn; odstep_max <= mx;
    end if;
  end process;

  process
    variable bledy, wys, t : integer := 0;
    procedure czekaj(n : natural) is
    begin
      for i in 1 to n loop wait until rising_edge(clk); end loop;
    end procedure;
    procedure wyslij(c : character) is
      variable v : std_logic_vector(7 downto 0);
    begin
      v := std_logic_vector(to_unsigned(character'pos(c), 8));
      rx <= '0'; czekaj(BIT_T);
      for i in 0 to 7 loop rx <= v(i); czekaj(BIT_T); end loop;
      rx <= '1'; czekaj(BIT_T);
    end procedure;
    procedure oczekuj(wzor : string) is
      variable n0, tt : natural;
    begin
      n0 := nlinii; tt := 0;
      while nlinii = n0 and tt < 50_000 loop wait until rising_edge(clk); tt := tt + 1; end loop;
      wait for 0 ns;
      if nlinii = n0 then
        pisz("FAIL: brak linii """ & wzor & """"); bledy := bledy + 1;
      elsif dl_ost /= wzor'length or ostatnia(1 to dl_ost) /= wzor then
        pisz("FAIL: linia """ & ostatnia(1 to dl_ost) & """, oczekiwana """ & wzor & """"); bledy := bledy + 1;
      else
        pisz("UART: """ & wzor & """");
      end if;
    end procedure;
  begin
    czekaj(5);
    rst <= '0';
    oczekuj("RISC-V MCU (31.06)");
    wys := 0;
    for i in 1 to 400 loop
      wait until rising_edge(clk);
      if pwm_wy = '1' then wys := wys + 1; end if;
    end loop;
    pisz("PWM: " & integer'image(wys) & " taktow stanu wysokiego na 400 (oczekiwane 100)");
    if wys /= 100 then bledy := bledy + 1; end if;
    czekaj(12_000);
    pisz("LED: " & integer'image(zmian) & " zmian, odstepy " & integer'image(odstep_min) & ".."
         & integer'image(odstep_max) & " taktow (porownanie co 3000, odpytywanie flagi +- 40)");
    if zmian < 4 or odstep_min < 2960 or odstep_max > 3040 then bledy := bledy + 1; end if;
    wyslij('A'); wyslij('b'); wyslij('c'); wyslij(' '); wyslij('x'); wyslij('y'); wyslij('z'); wyslij('!');
    wyslij(character'val(13));
    oczekuj("ABC XYZ!");
    wyslij('q');
    oczekuj("");
    oczekuj("KONIEC");
    t := 0;
    while koniec /= '1' and t < 20_000 loop wait until rising_edge(clk); t := t + 1; end loop;
    if koniec /= '1' then pisz("FAIL: program nie zapisal TOHOST"); bledy := bledy + 1; end if;
    pisz("instrukcji wykonanych: " & integer'image(instr) & " w " & integer'image(takt) & " taktach");
    if bledy = 0 then pisz("PASS"); else pisz("FAIL: " & integer'image(bledy) & " bledow"); end if;
    fin <= true;
    wait;
  end process;
end architecture sim;
