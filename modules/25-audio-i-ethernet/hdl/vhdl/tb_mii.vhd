-- Testbench 25.03: mii_tx -> mii_rx w pętli (25 MHz). Ramki 1, 14, 59, 60, 61, 100, 1514 i 20 losowych: preambuła
-- i SFD na linii, FCS na linii równe CRC-32 policzonemu w testbenchu (sprawdzonemu wektorem "123456789"),
-- bajty odebrane = wysłane + uzupełnienie, crc_ok, długość, przerwa ≥ 24 takty; ramka z przekłamanym bitem -> crc_ok = 0.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_mii is
end entity tb_mii;

architecture sim of tb_mii is
  signal clk : std_logic := '0';
  signal rst : std_logic := '1';
  signal fin : boolean := false;
  signal s_dane : std_logic_vector(7 downto 0) := x"00";
  signal s_wazne, s_ostatni : std_logic := '0';
  signal s_gotowy, tx_en, przerwa : std_logic;
  signal txd, rxd : std_logic_vector(3 downto 0);
  signal psuj : std_logic := '0';
  signal m_dane : std_logic_vector(7 downto 0);
  signal m_wazne, koniec, crc_ok, blad : std_logic;
  signal dlugosc : unsigned(10 downto 0);
  type bajty_t is array (0 to 2100) of std_logic_vector(7 downto 0);
  signal linia, odeb : bajty_t := (others => x"00");
  signal nl, no : natural := 0;
  signal zeruj : std_logic := '0';
  signal min_cisza : natural := 999;
  signal n_ramek : natural := 0;

  function crc32(c : std_logic_vector(31 downto 0); d : std_logic_vector(7 downto 0)) return std_logic_vector is
    variable r : std_logic_vector(31 downto 0) := c;
    variable b : std_logic;
  begin
    for i in 0 to 7 loop
      b := r(0) xor d(i);
      r := '0' & r(31 downto 1);
      if b = '1' then r := r xor x"EDB88320"; end if;
    end loop;
    return r;
  end function;
begin
  clk <= not clk after 20 ns when not fin else clk;
  rxd <= txd xor ("000" & psuj);

  u_tx : entity work.mii_tx
    port map (clk => clk, rst => rst, s_dane => s_dane, s_wazne => s_wazne, s_ostatni => s_ostatni,
              s_gotowy => s_gotowy, txd => txd, tx_en => tx_en, przerwa => przerwa);
  u_rx : entity work.mii_rx
    port map (clk => clk, rst => rst, rxd => rxd, rx_dv => tx_en, rx_er => '0', m_dane => m_dane, m_wazne => m_wazne,
              koniec => koniec, crc_ok => crc_ok, dlugosc => dlugosc, blad => blad);

  -- linia i odbiór
  process (clk)
    variable h : boolean := false;
    variable ml : std_logic_vector(3 downto 0);
    variable n_l, n_o, cisza : natural := 0;
    variable en_d : std_logic := '0';
  begin
    if rising_edge(clk) then
      if zeruj = '1' then n_l := 0; n_o := 0; h := false; end if;
      if tx_en = '1' then
        if not h then ml := txd; h := true;
        else linia(n_l) <= txd & ml; n_l := n_l + 1; h := false; end if;
      end if;
      if tx_en = '0' and en_d = '1' then cisza := 0; end if;
      if tx_en = '0' then cisza := cisza + 1; end if;
      if tx_en = '1' and en_d = '0' and n_ramek > 0 and cisza < min_cisza then min_cisza <= cisza; end if;
      en_d := tx_en;
      if m_wazne = '1' then odeb(n_o) <= m_dane; n_o := n_o + 1; end if;
      nl <= n_l; no <= n_o;
    end if;
  end process;

  process
    variable l : line;
    variable errors, bl : natural := 0;
    variable s1, s2 : positive := 3;
    variable r : real;
    type dane_t is array (0 to 2047) of std_logic_vector(7 downto 0);
    variable dane : dane_t;
    variable c : std_logic_vector(31 downto 0);

    procedure ramka(len : natural; zepsuj : boolean) is
      variable j, oczl : natural;
      variable bd : std_logic_vector(7 downto 0);
    begin
      for q in 0 to len - 1 loop
        uniform(s1, s2, r);
        dane(q) := std_logic_vector(to_unsigned(integer(floor(r * 256.0)) mod 256, 8));
      end loop;
      wait until falling_edge(clk);
      zeruj <= '1';
      wait until falling_edge(clk);
      zeruj <= '0';
      s_wazne <= '1'; s_dane <= dane(0);
      if len = 1 then s_ostatni <= '1'; else s_ostatni <= '0'; end if;
      j := 0;
      while j < len loop
        wait until rising_edge(clk);
        if s_gotowy = '1' then
          j := j + 1;
          wait for 1 ns;
          if j < len then s_dane <= dane(j); end if;
          if j = len - 1 then s_ostatni <= '1'; else s_ostatni <= '0'; end if;
          if j = len then s_wazne <= '0'; end if;
          if zepsuj and j = 30 then psuj <= '1', '0' after 40 ns; end if;
        end if;
      end loop;
      wait until koniec = '1';
      wait for 1 ns;
      if len < 60 then oczl := 60; else oczl := len; end if;
      for q in 0 to 6 loop if linia(q) /= x"55" then bl := bl + 1; end if; end loop;
      if linia(7) /= x"D5" then bl := bl + 1; end if;
      c := (others => '1');
      for q in 0 to oczl - 1 loop
        if q < len then bd := dane(q); else bd := x"00"; end if;
        c := crc32(c, bd);
      end loop;
      c := not c;
      if not zepsuj and std_logic_vector'(linia(8 + oczl + 3) & linia(8 + oczl + 2) & linia(8 + oczl + 1) & linia(8 + oczl)) /= c then
        bl := bl + 1;
      end if;
      if nl /= 8 + oczl + 4 then bl := bl + 1; end if;
      if zepsuj then
        if crc_ok = '1' then bl := bl + 1; end if;
      else
        if crc_ok /= '1' or blad /= '0' or to_integer(dlugosc) /= oczl or no /= oczl then bl := bl + 1; end if;
        for q in 0 to oczl - 1 loop
          if q < len then bd := dane(q); else bd := x"00"; end if;
          if odeb(q) /= bd then bl := bl + 1; end if;
        end loop;
      end if;
      n_ramek <= n_ramek + 1;
    end procedure;

    variable wek : std_logic_vector(31 downto 0);
    constant TXT : string(1 to 9) := "123456789";
    variable len : natural;
  begin
    wek := (others => '1');
    for q in 1 to 9 loop wek := crc32(wek, std_logic_vector(to_unsigned(character'pos(TXT(q)), 8))); end loop;
    wek := not wek;
    write(l, "CRC-32 testbenchu dla ""123456789"": " & to_hstring(wek));
    writeline(output, l);
    if wek /= x"CBF43926" then errors := errors + 1; end if;
    for q in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    ramka(1, false); ramka(14, false); ramka(59, false); ramka(60, false); ramka(61, false); ramka(100, false);
    ramka(1514, false);
    for q in 1 to 20 loop
      uniform(s1, s2, r);
      len := 1 + integer(floor(r * 1514.0)) mod 1514;
      ramka(len, false);
    end loop;
    wait for 1 ns;
    write(l, "ramek poprawnych " & integer'image(n_ramek) & ": bledow " & integer'image(bl)
          & ", minimalna przerwa miedzyramkowa " & integer'image(min_cisza) & " taktow");
    writeline(output, l);
    if bl /= 0 or min_cisza < 24 then errors := errors + 1; end if;
    bl := 0;
    ramka(200, true);
    write(l, "ramka z przeklamanym bitem: crc_ok = " & std_logic'image(crc_ok) & " (oczekiwane '0'), bledow "
          & integer'image(bl));
    writeline(output, l);
    if bl /= 0 then errors := errors + 1; end if;
    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
