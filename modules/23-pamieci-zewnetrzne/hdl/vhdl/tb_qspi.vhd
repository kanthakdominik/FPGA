-- Testbench 23.03: qspi_master z modelem pamięci SPI NOR flash (64 KiB, ID C2 20 19; rozkazy 9F, 05, 06, 03,
-- 0B, 6B, 02, 20; programowanie 20 µs, kasowanie 50 µs). Opis testów jak w tb_qspi.v.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_qspi is
end entity tb_qspi;

architecture sim of tb_qspi is
  type pam_t is array (0 to 65535) of std_logic_vector(7 downto 0);
  type b256_t is array (0 to 255) of std_logic_vector(7 downto 0);
  signal clk : std_logic := '0';
  signal fin : boolean := false;
  signal rst : std_logic := '1';
  signal start, z_adresem, zapis, quad : std_logic := '0';
  signal rozkaz, wdane, rdane : std_logic_vector(7 downto 0) := x"00";
  signal adres : std_logic_vector(23 downto 0) := (others => '0');
  signal puste : std_logic_vector(3 downto 0) := "0000";
  signal dlugosc : std_logic_vector(8 downto 0) := (others => '0');
  signal wpobierz, rwazne, gotowy, sclk, cs_n : std_logic;
  signal m_o, m_oe, linia : std_logic_vector(3 downto 0);
  signal f_o, f_oe : std_logic_vector(3 downto 0) := "0000";
  signal wip, wel : std_logic := '0';
  signal konflikty : integer := 0;
  -- dane testu
  signal bufor, odczyt : b256_t := (others => x"00");
  signal n_odcz, n_zap : integer := 0;
  signal zeruj : boolean := false;
begin
  clk   <= not clk after 5 ns when not fin else clk;
  linia <= (m_oe and m_o) or (f_oe and f_o) or (not m_oe and not f_oe);   -- podciąganie

  dut : entity work.qspi_master generic map (DIV => 2)
    port map (clk => clk, rst => rst, start => start, rozkaz => rozkaz, adres => adres, z_adresem => z_adresem,
              puste => puste, dlugosc => dlugosc, zapis => zapis, quad => quad, wdane => wdane, wpobierz => wpobierz,
              rdane => rdane, rwazne => rwazne, gotowy => gotowy, sclk => sclk, cs_n => cs_n, dq_o => m_o,
              dq_oe => m_oe, dq_i => linia);

  process (m_oe, f_oe)
  begin
    if (m_oe and f_oe) /= "0000" then konflikty <= konflikty + 1; end if;
  end process;

  -- model pamięci flash
  model : process (cs_n, sclk)
    variable mem : pam_t;
    variable strona : b256_t;
    variable w_str : std_logic_vector(255 downto 0);
    variable roz, bt : std_logic_vector(7 downto 0) := x"00";
    variable adr : std_logic_vector(23 downto 0) := (others => '0');
    variable nb, np, k, poczatek : integer := 0;
    variable init : boolean := true;
    variable baza : integer;
  begin
    if init then
      for i in 0 to 65535 loop mem(i) := std_logic_vector(to_unsigned((i * 37 + i / 256) mod 256, 8)); end loop;
      init := false;
    end if;
    if falling_edge(cs_n) then
      nb := 0; np := 0; roz := x"00"; w_str := (others => '0');
    elsif rising_edge(cs_n) then
      f_oe <= "0000";
      if roz = x"06" and nb = 8 then wel <= '1'; end if;
      if roz = x"02" and wel = '1' and wip = '0' and nb >= 40 then
        baza := to_integer(unsigned(adr(15 downto 8))) * 256;
        for i in 0 to 255 loop
          if w_str(i) = '1' then mem(baza + i) := mem(baza + i) and strona(i); end if;
        end loop;
        wel <= '0'; wip <= '1', '0' after 20 us;
      end if;
      if roz = x"20" and wel = '1' and wip = '0' and nb = 32 then
        baza := to_integer(unsigned(adr(15 downto 12))) * 4096;
        for i in 0 to 4095 loop mem(baza + i) := x"FF"; end loop;
        wel <= '0'; wip <= '1', '0' after 50 us;
      end if;
    elsif rising_edge(sclk) and cs_n = '0' then
      if nb < 8 then
        roz := roz(6 downto 0) & linia(0);
      elsif nb < 32 and (roz = x"03" or roz = x"0B" or roz = x"6B" or roz = x"02" or roz = x"20") then
        adr := adr(22 downto 0) & linia(0);
      elsif roz = x"02" and wip = '0' then
        bt := bt(6 downto 0) & linia(0);
        if (nb - 32) mod 8 = 7 then
          k := (to_integer(unsigned(adr(7 downto 0))) + np) mod 256;
          strona(k) := bt;
          w_str(k) := '1';
          np := np + 1;
        end if;
      end if;
      nb := nb + 1;
    elsif falling_edge(sclk) and cs_n = '0' then
      if roz = x"03" or roz = x"02" then poczatek := 32;
      elsif roz = x"0B" or roz = x"6B" then poczatek := 40;
      else poczatek := 8; end if;
      if nb >= poczatek then
        k := nb - poczatek;
        if roz = x"9F" then
          if k / 8 = 0 then bt := x"C2"; elsif k / 8 = 1 then bt := x"20"; else bt := x"19"; end if;
          f_o <= "00" & bt(7 - k mod 8) & '0'; f_oe <= "0010";
        elsif roz = x"05" then
          bt := "000000" & wel & wip;
          f_o <= "00" & bt(7 - k mod 8) & '0'; f_oe <= "0010";
        elsif roz = x"03" or roz = x"0B" then
          bt := mem((to_integer(unsigned(adr)) + k / 8) mod 65536);
          f_o <= "00" & bt(7 - k mod 8) & '0'; f_oe <= "0010";
        elsif roz = x"6B" then
          bt := mem((to_integer(unsigned(adr)) + k / 2) mod 65536);
          if k mod 2 = 0 then f_o <= bt(7 downto 4); else f_o <= bt(3 downto 0); end if;
          f_oe <= "1111";
        else
          f_oe <= "0000";
        end if;
      end if;
    end if;
  end process;

  -- zbieranie odczytanych bajtów i podawanie bajtów zapisu
  process (clk)
  begin
    if rising_edge(clk) then
      if zeruj then
        n_odcz <= 0;
        n_zap  <= 0;
        wdane  <= bufor(0);
      else
        if rwazne = '1' then
          odczyt(n_odcz mod 256) <= rdane;
          n_odcz <= n_odcz + 1;
        end if;
        if wpobierz = '1' then
          n_zap <= n_zap + 1;
          wdane <= bufor((n_zap + 1) mod 256);
        end if;
      end if;
    end if;
  end process;

  process
    variable l : line;
    variable errors, t_tr, t_111, t_114 : integer := 0;
    variable t0 : time;
    variable s1, s2 : positive := 5;
    variable r : real;
    variable b : b256_t;

    procedure transakcja(ro : std_logic_vector(7 downto 0); a : natural; za : std_logic; p : natural; dl : natural;
                         zp : std_logic; q : std_logic) is
    begin
      zeruj <= true;
      wait until falling_edge(clk);
      zeruj <= false;
      rozkaz <= ro; adres <= std_logic_vector(to_unsigned(a, 24)); z_adresem <= za;
      puste <= std_logic_vector(to_unsigned(p, 4)); dlugosc <= std_logic_vector(to_unsigned(dl, 9));
      zapis <= zp; quad <= q; start <= '1';
      t0 := now;
      wait until falling_edge(clk);
      start <= '0';
      wait until gotowy = '1';
      t_tr := (now - t0) / 10 ns;
      wait until falling_edge(clk);
    end procedure;

    procedure czekaj_wip is
    begin
      transakcja(x"05", 0, '0', 0, 1, '0', '0');
      while odczyt(0)(0) = '1' loop
        transakcja(x"05", 0, '0', 0, 1, '0', '0');
      end loop;
    end procedure;

    impure function wzor(i : natural) return std_logic_vector is
    begin
      return std_logic_vector(to_unsigned((i * 37 + i / 256) mod 256, 8));
    end function;

    procedure sprawdz(a : natural; dl : natural; nazwa : string) is
      variable z : integer := 0;
    begin
      for i in 0 to dl - 1 loop
        if odczyt(i) /= wzor(a + i) then z := z + 1; end if;
      end loop;
      if z /= 0 or n_odcz /= dl then
        write(l, nazwa & ": " & integer'image(z) & " bledow"); writeline(output, l);
        errors := errors + 1;
      end if;
    end procedure;
  begin
    for q in 1 to 5 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    transakcja(x"9F", 0, '0', 0, 3, '0', '0');
    write(l, "JEDEC ID: " & to_hstring(odczyt(0)) & " " & to_hstring(odczyt(1)) & " " & to_hstring(odczyt(2)));
    writeline(output, l);
    if odczyt(0) /= x"C2" or odczyt(1) /= x"20" or odczyt(2) /= x"19" then errors := errors + 1; end if;
    transakcja(x"03", 16#1234#, '1', 0, 256, '0', '0'); sprawdz(16#1234#, 256, "READ 0x03");
    t_111 := t_tr;
    transakcja(x"0B", 16#ABCD#, '1', 8, 100, '0', '0'); sprawdz(16#ABCD#, 100, "FAST READ 0x0B");
    transakcja(x"6B", 16#1234#, '1', 8, 256, '0', '1'); sprawdz(16#1234#, 256, "QUAD OUTPUT READ 0x6B");
    t_114 := t_tr;
    write(l, "odczyt 256 B: 1-1-1 " & integer'image(t_111) & " taktow, 1-1-4 " & integer'image(t_114) & " taktow");
    writeline(output, l);
    if t_114 * 3 > t_111 then errors := errors + 1; end if;
    transakcja(x"06", 0, '0', 0, 0, '0', '0');
    transakcja(x"20", 16#3000#, '1', 0, 0, '0', '0');
    czekaj_wip;
    transakcja(x"03", 16#3000#, '1', 0, 256, '0', '0');
    for i in 0 to 255 loop
      if odczyt(i) /= x"FF" then errors := errors + 1; end if;
    end loop;
    for i in 0 to 255 loop
      uniform(s1, s2, r);
      b(i) := std_logic_vector(to_unsigned(integer(floor(r * 256.0)), 8));
    end loop;
    bufor <= b;
    transakcja(x"02", 16#3100#, '1', 0, 256, '1', '0');        -- bez WREN: ignorowane
    transakcja(x"03", 16#3100#, '1', 0, 4, '0', '0');
    if odczyt(0) /= x"FF" then errors := errors + 1; end if;
    transakcja(x"06", 0, '0', 0, 0, '0', '0');
    transakcja(x"05", 0, '0', 0, 1, '0', '0');
    if odczyt(0) /= x"02" then errors := errors + 1; end if;
    transakcja(x"02", 16#3100#, '1', 0, 256, '1', '0');
    czekaj_wip;
    transakcja(x"6B", 16#3100#, '1', 8, 256, '0', '1');
    for i in 0 to 255 loop
      if odczyt(i) /= b(i) then errors := errors + 1; end if;
    end loop;
    write(l, "kasowanie sektora, programowanie strony 256 B z WREN i WIP, odczyt 1-1-4: bledow " & integer'image(errors));
    writeline(output, l);
    if konflikty /= 0 then errors := errors + 1; end if;
    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
