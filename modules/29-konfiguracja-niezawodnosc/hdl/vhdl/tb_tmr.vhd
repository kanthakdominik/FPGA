-- Testbench 29.04: licznik_tmr z resynchronizacją i bez, te same wstrzyknięcia (kopia 0 bit 3, kopia 2 bit 12,
-- kopia 0 bit 5 i 64 takty później kopia 1 bit 5); wzorzec — zwykły licznik.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_tmr is
end entity tb_tmr;

architecture sim of tb_tmr is
  signal clk     : std_logic := '0';
  signal fin     : boolean := false;
  signal rst     : std_logic := '1';
  signal wstrzyk : std_logic_vector(2 downto 0) := "000";
  signal bit_w   : std_logic_vector(3 downto 0) := "0000";
  signal q1, q0  : std_logic_vector(15 downto 0);
  signal n1, n0  : std_logic;
  signal wzor    : unsigned(15 downto 0) := (others => '0');
  signal zle1, zle0, niez1, niez0, t : integer := 0;
  signal pierwszy0 : integer := -1;

  procedure pisz(s : string) is
    variable l : line;
  begin
    write(l, s);
    writeline(output, l);
  end procedure;
begin
  clk <= not clk after 5 ns when not fin else clk;
  u1 : entity work.licznik_tmr generic map (W => 16, SPRZEZENIE => 1)
    port map (clk => clk, rst => rst, en => '1', wstrzyk => wstrzyk, wstrzyk_bit => bit_w, q => q1, niezgodny => n1);
  u0 : entity work.licznik_tmr generic map (W => 16, SPRZEZENIE => 0)
    port map (clk => clk, rst => rst, en => '1', wstrzyk => wstrzyk, wstrzyk_bit => bit_w, q => q0, niezgodny => n0);

  process (clk)
  begin
    if rising_edge(clk) and rst = '0' then
      if unsigned(q1) /= wzor then zle1 <= zle1 + 1; end if;
      if unsigned(q0) /= wzor then
        zle0 <= zle0 + 1;
        if pierwszy0 < 0 then pierwszy0 <= t; end if;
      end if;
      if n1 = '1' then niez1 <= niez1 + 1; end if;
      if n0 = '1' then niez0 <= niez0 + 1; end if;
      wzor <= wzor + 1;
      t <= t + 1;
    end if;
  end process;

  process
    procedure wstrzyknij(k : std_logic_vector(2 downto 0); b : natural) is
    begin
      wait until falling_edge(clk);
      wstrzyk <= k; bit_w <= std_logic_vector(to_unsigned(b, 4));
      wait until falling_edge(clk);
      wstrzyk <= "000";
    end procedure;
    procedure czekaj(n : natural) is
    begin
      for i in 1 to n loop wait until falling_edge(clk); end loop;
    end procedure;
  begin
    czekaj(3);
    rst <= '0';
    czekaj(100);
    wstrzyknij("001", 3);
    czekaj(50);
    wstrzyknij("100", 12);
    czekaj(50);
    wstrzyknij("001", 5);
    czekaj(63);
    wstrzyknij("010", 5);
    czekaj(300);
    pisz("TMR z resynchronizacja: blednych wynikow " & integer'image(zle1) & ", taktow z niezgodnoscia kopii "
         & integer'image(niez1) & " (4 wstrzykniecia)");
    pisz("TMR bez resynchronizacji: blednych wynikow " & integer'image(zle0) & " (od taktu "
         & integer'image(pierwszy0) & "), taktow z niezgodnoscia " & integer'image(niez0));
    if zle1 = 0 and niez1 = 4 and zle0 > 0 then pisz("PASS");
    else pisz("FAIL: niezgodnosc z oczekiwaniami"); end if;
    fin <= true;
    wait;
  end process;
end architecture sim;
