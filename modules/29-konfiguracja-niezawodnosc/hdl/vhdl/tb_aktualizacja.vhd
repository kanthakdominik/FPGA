-- Testbench 29.02: crc32 (wartość kontrolna i 256 bajtów) i aktualizacja z modelem rdzenia Dual Configuration
-- (zajętość 531 taktów po zapisie offsetu 1, zapisy w czasie zajętości ignorowane poza watchdogiem).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_aktualizacja is
end entity tb_aktualizacja;

architecture sim of tb_aktualizacja is
  signal clk          : std_logic := '0';
  signal fin          : boolean := false;
  signal rst          : std_logic := '1';
  signal zeruj, cwe   : std_logic := '0';
  signal bajt         : std_logic_vector(7 downto 0) := (others => '0');
  signal crc          : std_logic_vector(31 downto 0);
  signal start, obraz, obraz_ok, pies : std_logic := '0';
  signal av_address   : std_logic_vector(2 downto 0);
  signal av_write, av_read, zajety, odmowa, wyzwolono : std_logic;
  signal av_writedata : std_logic_vector(31 downto 0);
  signal zapisy, ignorowane, rekonf, psy, odmowy, t_ovr, t_rek, takt : integer := 0;
  signal m_ovr, m_sel, obraz_rek : std_logic := '0';

  procedure pisz(s : string) is
    variable l : line;
  begin
    write(l, s);
    writeline(output, l);
  end procedure;

  function hex(v : std_logic_vector) return string is
    variable l : line;
  begin
    hwrite(l, v);
    return l.all;
  end function;

  function krok(c : std_logic_vector(31 downto 0); b : std_logic_vector(7 downto 0)) return std_logic_vector is
    variable t : std_logic_vector(31 downto 0);
  begin
    t := c xor (x"000000" & b);
    for i in 0 to 7 loop
      if t(0) = '1' then t := ('0' & t(31 downto 1)) xor x"EDB88320"; else t := '0' & t(31 downto 1); end if;
    end loop;
    return t;
  end function;
begin
  clk <= not clk after 5 ns when not fin else clk;
  u_crc : entity work.crc32 port map (clk => clk, zeruj => zeruj, we => cwe, bajt => bajt, crc => crc);
  dut : entity work.aktualizacja generic map (CZAS => 600)
    port map (clk => clk, rst => rst, start => start, obraz => obraz, obraz_ok => obraz_ok, pies => pies,
              av_address => av_address, av_write => av_write, av_writedata => av_writedata, av_read => av_read,
              zajety => zajety, odmowa => odmowa, wyzwolono => wyzwolono);

  model : process (clk)
    variable busy : integer := 0;
  begin
    if rising_edge(clk) then
      takt <= takt + 1;
      if busy > 0 then busy := busy - 1; end if;
      if odmowa = '1' then odmowy <= odmowy + 1; end if;
      if av_write = '1' then
        zapisy <= zapisy + 1;
        if av_address = "000" and av_writedata(1) = '1' then psy <= psy + 1; end if;
        if busy > 0 then
          ignorowane <= ignorowane + 1;
        elsif av_address = "001" then
          m_ovr <= av_writedata(0); m_sel <= av_writedata(1); busy := 531; t_ovr <= takt + 1;
        elsif av_address = "000" and av_writedata(0) = '1' then
          rekonf <= rekonf + 1; t_rek <= takt + 1;
          if m_ovr = '1' then obraz_rek <= m_sel; else obraz_rek <= '0'; end if;
        end if;
      end if;
    end if;
  end process;

  process
    constant NAPIS : string := "123456789";
    variable wz    : std_logic_vector(31 downto 0);
    variable b     : std_logic_vector(7 downto 0);
    variable bledy : integer := 0;
    procedure czekaj(n : natural) is
    begin
      for i in 1 to n loop wait until falling_edge(clk); end loop;
    end procedure;
  begin
    wait until falling_edge(clk); zeruj <= '1';
    wait until falling_edge(clk); zeruj <= '0';
    for i in NAPIS'range loop
      wait until falling_edge(clk);
      cwe <= '1'; bajt <= std_logic_vector(to_unsigned(character'pos(NAPIS(i)), 8));
    end loop;
    wait until falling_edge(clk); cwe <= '0';
    pisz("CRC-32(""123456789"") = 0x" & hex(crc) & " (oczekiwane 0xCBF43926)");
    if crc /= x"CBF43926" then bledy := bledy + 1; end if;
    wait until falling_edge(clk); zeruj <= '1';
    wait until falling_edge(clk); zeruj <= '0';
    wz := (others => '1');
    for i in 0 to 255 loop
      b := std_logic_vector(to_unsigned((i * 37 + 11) mod 256, 8));
      wait until falling_edge(clk);
      cwe <= '1'; bajt <= b;
      wz := krok(wz, b);
    end loop;
    wait until falling_edge(clk); cwe <= '0';
    pisz("CRC-32 256 bajtow: 0x" & hex(crc) & ", funkcja wzorcowa 0x" & hex(not wz));
    if crc /= not wz then bledy := bledy + 1; end if;

    czekaj(2);
    rst <= '0';
    wait until falling_edge(clk); start <= '1'; obraz <= '1'; obraz_ok <= '0';
    wait until falling_edge(clk); start <= '0';
    czekaj(5);
    if odmowy /= 1 or zapisy /= 0 then pisz("FAIL: brak odmowy albo zapis przy zlym CRC"); bledy := bledy + 1; end if;
    wait until falling_edge(clk); pies <= '1';
    wait until falling_edge(clk); pies <= '0';
    czekaj(3);
    if psy /= 1 then pisz("FAIL: brak zerowania licznika nadzorujacego"); bledy := bledy + 1; end if;
    wait until falling_edge(clk); start <= '1'; obraz <= '1'; obraz_ok <= '1';
    wait until falling_edge(clk); start <= '0';
    while wyzwolono /= '1' loop wait until falling_edge(clk); end loop;
    czekaj(3);
    pisz("zapis config_sel (obraz " & std_logic'image(m_sel) & ", nadpisanie " & std_logic'image(m_ovr)
         & ") w takcie " & integer'image(t_ovr) & ", wyzwolenie w takcie " & integer'image(t_rek)
         & " (odstep " & integer'image(t_rek - t_ovr) & " > 531)");
    pisz("zapisow " & integer'image(zapisy) & ", zignorowanych w czasie zajetosci " & integer'image(ignorowane)
         & ", rekonfiguracji " & integer'image(rekonf) & " z obrazu " & std_logic'image(obraz_rek));
    if rekonf /= 1 or obraz_rek /= '1' or ignorowane /= 0 or t_rek - t_ovr <= 531 or zajety /= '1' then
      bledy := bledy + 1;
    end if;
    if bledy = 0 then pisz("PASS"); else pisz("FAIL: " & integer'image(bledy) & " bledow"); end if;
    fin <= true;
    wait;
  end process;
end architecture sim;
