-- Testbench projektu 3 (31.03), VHDL: te same bajty MIDI, pomiary i dekodowanie I2S co tb_projekt_syntezator.v.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_projekt_syntezator is
end entity tb_projekt_syntezator;

architecture sim of tb_projekt_syntezator is
  constant BIT_T : positive := 25;
  constant F_PROBK    : real := 12_500_000.0 / 256.0;
  signal clk     : std_logic := '0';
  signal fin     : boolean := false;
  signal rst     : std_logic := '1';
  signal rx      : std_logic := '1';
  signal bclk, wclk, dout, nowa, blad_ramki : std_logic;
  signal probka  : signed(23 downto 0);
  signal aktywne : std_logic_vector(3 downto 0);
  signal p_ost, p_przed : signed(23 downto 0) := (others => '0');
  signal i2s_zgodne, i2s_zle : natural := 0;

  procedure pisz(s : string) is
    variable l : line;
  begin
    write(l, s);
    writeline(output, l);
  end procedure;
begin
  clk <= not clk after 40 ns when not fin else clk;
  dut : entity work.projekt_syntezator
    generic map (CLK_HZ => 12_500_000, BAUD => 500_000, A_KROK => 8192, D_KROK => 1024, S_POZ => 32768,
                 R_KROK => 4096)
    port map (clk => clk, rst => rst, rx => rx, bclk => bclk, wclk => wclk, dout => dout, probka => probka,
              nowa => nowa, aktywne => aktywne, blad_ramki => blad_ramki);

  process (nowa)
  begin
    if rising_edge(nowa) then p_przed <= p_ost; p_ost <= probka; end if;
  end process;

  dekoder_i2s : process (bclk)
    variable wclk_d : std_logic := '1';
    variable kb : natural := 0;
    variable slowo : std_logic_vector(23 downto 0) := (others => '0');
  begin
    if rising_edge(bclk) then
      if wclk_d = '1' and wclk = '0' then kb := 0; else kb := kb + 1; end if;
      wclk_d := wclk;
      if wclk = '0' and kb >= 1 and kb <= 24 then slowo := slowo(22 downto 0) & dout; end if;
      if wclk = '0' and kb = 24 then
        if signed(slowo) = p_ost or signed(slowo) = p_przed then i2s_zgodne <= i2s_zgodne + 1;
        else i2s_zle <= i2s_zle + 1; end if;
      end if;
    end if;
  end process;

  process
    variable bledy : integer := 0;
    variable f_zm : real;
    variable p_max, p_min : integer;

    procedure wyslij(b : natural) is
      variable v : std_logic_vector(7 downto 0);
    begin
      v := std_logic_vector(to_unsigned(b, 8));
      rx <= '0';
      for i in 1 to BIT_T loop wait until rising_edge(clk); end loop;
      for k in 0 to 7 loop
        rx <= v(k);
        for i in 1 to BIT_T loop wait until rising_edge(clk); end loop;
      end loop;
      rx <= '1';
      for i in 1 to BIT_T loop wait until rising_edge(clk); end loop;
    end procedure;
    procedure probki(n : natural) is
    begin
      for i in 1 to n loop wait until rising_edge(nowa); end loop;
    end procedure;
    procedure oczekuj_glosy(wzor : std_logic_vector(3 downto 0); co : string) is
    begin
      if aktywne /= wzor then
        pisz("FAIL: " & co & ": aktywne glosy " & to_string(aktywne) & ", oczekiwane " & to_string(wzor));
        bledy := bledy + 1;
      else
        pisz(co & ": aktywne glosy " & to_string(aktywne));
      end if;
    end procedure;
    procedure mierz(n : natural) is
      variable nprz, t_pierw, t_ost : integer := 0;
      variable poprz : signed(23 downto 0);
    begin
      nprz := 0; t_pierw := 0; t_ost := 0; p_max := -(2 ** 23); p_min := 2 ** 23; poprz := probka;
      for i in 0 to n - 1 loop
        wait until rising_edge(nowa);
        wait for 1 ns;
        if poprz < 0 and probka >= 0 then
          if nprz = 0 then t_pierw := i; end if;
          t_ost := i;
          nprz := nprz + 1;
        end if;
        if to_integer(probka) > p_max then p_max := to_integer(probka); end if;
        if to_integer(probka) < p_min then p_min := to_integer(probka); end if;
        poprz := probka;
      end loop;
      if nprz > 1 then f_zm := real(nprz - 1) * F_PROBK / real(t_ost - t_pierw); else f_zm := 0.0; end if;
    end procedure;
    procedure sprawdz_f(f_ocz : real; co : string) is
    begin
      if f_zm < f_ocz * 0.998 or f_zm > f_ocz * 1.002 then
        pisz("FAIL: " & co & ": " & real'image(f_zm) & " Hz, oczekiwane " & real'image(f_ocz));
        bledy := bledy + 1;
      else
        pisz(co & ": " & real'image(f_zm) & " Hz (oczekiwane " & real'image(f_ocz) & "), szczyt "
             & integer'image(p_max) & " / " & integer'image(p_min));
      end if;
    end procedure;
  begin
    for i in 1 to 10 loop wait until rising_edge(clk); end loop;
    rst <= '0';
    probki(4);
    wyslij(16#C0#); wyslij(16#00#);
    wyslij(16#90#); wyslij(93); wyslij(127);
    probki(60);
    oczekuj_glosy("0001", "Note On 93");
    mierz(2048);
    sprawdz_f(1760.0, "prostokat, nuta 93");
    if p_max /= 1040320 or p_min /= -1040384 then
      pisz("FAIL: szczyt " & integer'image(p_max) & " / " & integer'image(p_min)); bledy := bledy + 1;
    end if;
    wyslij(97); wyslij(100);
    wyslij(81); wyslij(16#F8#); wyslij(64);
    probki(10);
    oczekuj_glosy("0111", "running status + F8");
    wyslij(93); wyslij(0);
    probki(30);
    oczekuj_glosy("0110", "93 vel 0 (Note Off)");
    wyslij(16#80#); wyslij(97); wyslij(64);
    probki(30);
    oczekuj_glosy("0100", "80 97 (Note Off)");
    wyslij(16#90#); wyslij(60); wyslij(127); wyslij(62); wyslij(127);
    wyslij(64); wyslij(127); wyslij(65); wyslij(127);
    probki(10);
    oczekuj_glosy("1111", "4 nuty + glos 81");
    wyslij(16#80#); wyslij(60); wyslij(0);
    probki(30);
    oczekuj_glosy("1111", "Note Off zabranej nuty 60");
    wyslij(16#B0#); wyslij(123); wyslij(0);
    probki(30);
    oczekuj_glosy("0000", "CC 123 (wszystkie wyl.)");
    wyslij(16#C0#); wyslij(16#03#);
    wyslij(16#90#); wyslij(69); wyslij(127);
    probki(60);
    mierz(4096);
    sprawdz_f(440.0, "sinus, nuta 69");
    if p_max < 1030000 or p_max > 1040320 then
      pisz("FAIL: szczyt sinusa " & integer'image(p_max)); bledy := bledy + 1;
    end if;
    pisz("I2S: slow lewego kanalu zgodnych z probkami " & integer'image(i2s_zgodne) & ", niezgodnych "
         & integer'image(i2s_zle));
    if i2s_zgodne < 5000 or i2s_zle /= 0 then pisz("FAIL: dane I2S"); bledy := bledy + 1; end if;
    if blad_ramki = '1' then pisz("FAIL: blad ramki UART"); bledy := bledy + 1; end if;
    if bledy = 0 then pisz("PASS"); else pisz("FAIL: " & integer'image(bledy) & " bledow"); end if;
    fin <= true;
    wait;
  end process;
end architecture sim;
