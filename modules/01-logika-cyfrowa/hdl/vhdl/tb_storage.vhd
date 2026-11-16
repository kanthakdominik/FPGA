-- Testbench elementów pamiętających: rejestr z zezwoleniem, przerzutnik z resetem asynchronicznym, zatrzask.
-- Pobudzenia zmieniane na opadającym zboczu zegara.
library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

entity tb_storage is
end entity tb_storage;

architecture sim of tb_storage is
  constant T   : time := 10 ns;
  signal clk   : std_logic := '0';
  signal done  : boolean   := false;
  -- register_en
  signal rst   : std_logic := '1';
  signal en    : std_logic := '0';
  signal d, q  : std_logic_vector(7 downto 0);
  -- dff_arst
  signal arst  : std_logic := '1';
  signal fd    : std_logic := '0';
  signal fq    : std_logic;
  -- d_latch
  signal le    : std_logic := '0';
  signal ld    : std_logic := '0';
  signal lq    : std_logic;
begin
  clk <= not clk after T / 2 when not done;

  u_reg : entity work.register_en
    generic map (W => 8)
    port map (clk => clk, rst => rst, en => en, d => d, q => q);
  u_ff : entity work.dff_arst
    port map (clk => clk, arst => arst, d => fd, q => fq);
  u_lat : entity work.d_latch
    port map (en => le, d => ld, q => lq);

  stim : process
    variable errors : natural := 0;
    variable l      : line;

    procedure check(ok : boolean; msg : string) is
    begin
      if not ok then
        errors := errors + 1;
        report msg severity warning;
      end if;
    end procedure;
  begin
    d <= x"00";
    wait until falling_edge(clk);            -- pierwsze zbocze narastające wykonało reset
    check(q = x"00", "register_en: brak resetu synchronicznego");
    check(fq = '0', "dff_arst: brak resetu asynchronicznego");

    -- rejestr: zapis, pamiętanie przy en = 0, ponowny zapis
    rst <= '0'; en <= '1'; d <= x"A5";
    wait until falling_edge(clk);
    check(q = x"A5", "register_en: brak zapisu przy en=1");
    en <= '0'; d <= x"3C";
    wait until falling_edge(clk);
    check(q = x"A5", "register_en: zmiana wyjscia przy en=0");
    en <= '1';
    wait until falling_edge(clk);
    check(q = x"3C", "register_en: brak zapisu po ponownym en=1");
    -- reset synchroniczny działa dopiero na zboczu zegara
    rst <= '1';
    wait for 1 ns;
    check(q = x"3C", "register_en: reset zadzialal bez zbocza zegara");
    wait until falling_edge(clk);
    check(q = x"00", "register_en: brak resetu na zboczu zegara");
    rst <= '0';

    -- przerzutnik z resetem asynchronicznym
    arst <= '0'; fd <= '1';
    wait until falling_edge(clk);
    check(fq = '1', "dff_arst: brak zapisu na zboczu zegara");
    arst <= '1';
    wait for 1 ns;                           -- bez zbocza zegara
    check(fq = '0', "dff_arst: reset nie zadzialal natychmiast");
    arst <= '0';
    wait until falling_edge(clk);
    check(fq = '1', "dff_arst: brak zapisu po zwolnieniu resetu");

    -- zatrzask: przezroczysty przy en = 1, pamięta przy en = 0
    le <= '1'; ld <= '1';
    wait for 1 ns;
    check(lq = '1', "d_latch: brak przezroczystosci (1)");
    ld <= '0';
    wait for 1 ns;
    check(lq = '0', "d_latch: brak przezroczystosci (0)");
    le <= '0';
    wait for 1 ns;
    ld <= '1';
    wait for 1 ns;
    check(lq = '0', "d_latch: wyjscie zmienilo sie przy en=0");

    if errors = 0 then
      write(l, string'("PASS"));
    else
      write(l, "FAIL: " & integer'image(errors) & " bledow");
    end if;
    writeline(output, l);
    done <= true;
    std.env.finish;
    wait;
  end process stim;
end architecture sim;
