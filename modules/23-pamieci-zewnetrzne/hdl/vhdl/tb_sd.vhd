-- Testbench 23.05: sd_spi z modelem karty SD w trybie SPI (CRC7 rozkazów, NCR, CMD8, ACMD41 zajęta 3 razy,
-- CMD58 z CCS, CMD16, CMD17 z tokenem i CRC16; kontrola ≥ 74 taktów przed CMD0 i SCLK ≤ 400 kHz).
-- Karty SDHC i SDSC, odczyt bloków 5 i 1000.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_sd is
end entity tb_sd;

architecture sim of tb_sd is
  type q_t is array (0 to 1023) of std_logic_vector(7 downto 0);
  type b_t is array (0 to 511) of std_logic_vector(7 downto 0);
  signal clk : std_logic := '0';
  signal fin : boolean := false;
  signal rst : std_logic := '1';
  signal odczyt : std_logic := '0';
  signal blok : std_logic_vector(31 downto 0) := (others => '0');
  signal gotowy, sdhc, blad, dane_wazne, koniec, crc_ok, sclk, mosi, cs_n : std_logic;
  signal kod_bledu : std_logic_vector(3 downto 0);
  signal dane : std_logic_vector(7 downto 0);
  signal miso : std_logic := '1';
  -- parametry i statystyki modelu
  signal m_hc, m_zeruj : boolean := false;
  signal n_cmd, acmd41_n, zle_crc, takty_przed, za_szybko : integer := 0;
  -- odbiór
  signal bufo : b_t;
  signal n_b : integer := 0;
  signal zeruj_b : boolean := false;

  function crc7(d : std_logic_vector(39 downto 0)) return std_logic_vector is
    variable c : std_logic_vector(6 downto 0) := (others => '0');
    variable fb : std_logic;
  begin
    for i in 39 downto 0 loop
      fb := d(i) xor c(6);
      c  := c(5 downto 0) & '0';
      if fb = '1' then c := c xor "0001001"; end if;
    end loop;
    return c;
  end function;
  function crc16(c0 : std_logic_vector(15 downto 0); d : std_logic_vector(7 downto 0)) return std_logic_vector is
    variable c : std_logic_vector(15 downto 0) := c0;
    variable fb : std_logic;
  begin
    for i in 7 downto 0 loop
      fb := d(i) xor c(15);
      c  := c(14 downto 0) & '0';
      if fb = '1' then c := c xor x"1021"; end if;
    end loop;
    return c;
  end function;
  function wzor(b : natural; i : natural) return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned((b * 7 + i * 13 + i / 256) mod 256, 8));
  end function;
begin
  clk <= not clk after 10 ns when not fin else clk;

  dut : entity work.sd_spi generic map (DIV_WOLNY => 63, DIV_SZYBKI => 2)
    port map (clk => clk, rst => rst, odczyt => odczyt, blok => blok, gotowy => gotowy, sdhc => sdhc, blad => blad,
              kod_bledu => kod_bledu, dane => dane, dane_wazne => dane_wazne, koniec => koniec, crc_ok => crc_ok,
              sclk => sclk, mosi => mosi, cs_n => cs_n, miso => miso);

  model : process (cs_n, sclk, m_zeruj)
    variable q : q_t;
    variable qh, qt, nb, acmd, i : integer := 0;
    variable rx, tx : std_logic_vector(7 downto 0) := x"FF";
    variable cmd : std_logic_vector(47 downto 0) := (others => '0');
    variable app, gotowa, pierwszy : boolean := false;
    variable t_ost : time := 0 ns;
    variable nr : natural;
    variable arg : std_logic_vector(31 downto 0);
    variable c : std_logic_vector(15 downto 0);
    variable bl : natural;
    variable ncmd, zcrc, tprz, zsz : integer := 0;

    procedure wstaw(b : std_logic_vector(7 downto 0)) is
    begin
      q(qt mod 1024) := b;
      qt := qt + 1;
    end procedure;
  begin
    if m_zeruj then
      qh := 0; qt := 0; nb := 0; acmd := 0; cmd := (others => '0'); app := false; gotowa := false;
      pierwszy := true; t_ost := 0 ns; ncmd := 0; zcrc := 0; tprz := 0; zsz := 0;
    end if;
    if falling_edge(cs_n) then
      nb := 0; tx := x"FF"; miso <= '1';
    elsif rising_edge(cs_n) then
      qh := qt; miso <= '1';
    elsif rising_edge(sclk) then
      if not gotowa or pierwszy then
        if t_ost > 0 ns and now - t_ost < 2490 ns then zsz := zsz + 1; end if;
        t_ost := now;
      end if;
      if cs_n = '1' and pierwszy then tprz := tprz + 1; end if;
      if cs_n = '0' then
        rx := rx(6 downto 0) & mosi;
        nb := nb + 1;
        if nb = 8 then
          nb := 0;
          if rx(7 downto 6) = "01" or unsigned(cmd) /= 0 then
            cmd := cmd(39 downto 0) & rx;
            if cmd(47 downto 46) = "01" then
              nr  := to_integer(unsigned(cmd(45 downto 40)));
              arg := cmd(39 downto 8);
              if cmd(7 downto 1) /= crc7(cmd(47 downto 8)) then zcrc := zcrc + 1; end if;
              if nr = 0 then pierwszy := false; end if;
              wstaw(x"FF");                                     -- NCR
              if app and nr = 41 then
                acmd := acmd + 1;
                if acmd > 3 then gotowa := true; end if;
                if gotowa then wstaw(x"00"); else wstaw(x"01"); end if;
              else
                case nr is
                  when 0 => gotowa := false; acmd := 0; wstaw(x"01");
                  when 8 => wstaw(x"01"); wstaw(x"00"); wstaw(x"00"); wstaw("0000" & arg(11 downto 8)); wstaw(arg(7 downto 0));
                  when 55 => if gotowa then wstaw(x"00"); else wstaw(x"01"); end if;
                  when 58 =>
                    if gotowa then wstaw(x"00"); else wstaw(x"01"); end if;
                    if m_hc then wstaw(x"C0"); else wstaw(x"80"); end if;
                    wstaw(x"FF"); wstaw(x"80"); wstaw(x"00");
                  when 16 => if unsigned(arg) = 512 then wstaw(x"00"); else wstaw(x"40"); end if;
                  when 17 =>
                    if m_hc then bl := to_integer(unsigned(arg)); else bl := to_integer(unsigned(arg)) / 512; end if;
                    if not m_hc and unsigned(arg(8 downto 0)) /= 0 then
                      wstaw(x"40");
                    else
                      wstaw(x"00"); wstaw(x"FF"); wstaw(x"FF"); wstaw(x"FE");
                      c := (others => '0');
                      for k in 0 to 511 loop
                        wstaw(wzor(bl, k));
                        c := crc16(c, wzor(bl, k));
                      end loop;
                      wstaw(c(15 downto 8)); wstaw(c(7 downto 0));
                    end if;
                  when others => wstaw(x"04");
                end case;
              end if;
              app  := (nr = 55);
              ncmd := ncmd + 1;
              cmd  := (others => '0');
            end if;
          end if;
        end if;
      end if;
    elsif falling_edge(sclk) and cs_n = '0' then
      if nb = 0 then
        if qh /= qt then tx := q(qh mod 1024); qh := qh + 1; else tx := x"FF"; end if;
      else
        tx := tx(6 downto 0) & '1';
      end if;
      miso <= tx(7);
    end if;
    n_cmd <= ncmd; acmd41_n <= acmd; zle_crc <= zcrc; takty_przed <= tprz; za_szybko <= zsz;
  end process;

  process (clk)
  begin
    if rising_edge(clk) then
      if zeruj_b then
        n_b <= 0;
      elsif dane_wazne = '1' then
        bufo(n_b mod 512) <= dane;
        n_b <= n_b + 1;
      end if;
    end if;
  end process;

  process
    variable l : line;
    variable errors : integer := 0;
    variable t0 : time;

    procedure czytaj(b : natural) is
      variable z : integer := 0;
    begin
      zeruj_b <= true;
      wait until rising_edge(clk);
      wait until falling_edge(clk);
      zeruj_b <= false;
      blok <= std_logic_vector(to_unsigned(b, 32)); odczyt <= '1';
      wait until falling_edge(clk);
      odczyt <= '0';
      wait until koniec = '1' or blad = '1';
      wait until falling_edge(clk);
      for i in 0 to 511 loop
        if bufo(i) /= wzor(b, i) then z := z + 1; end if;
      end loop;
      write(l, "  blok " & integer'image(b) & ": " & integer'image(n_b) & " bajtow, bledow " & integer'image(z));
      if crc_ok = '1' then write(l, string'(", CRC16 zgodne")); else write(l, string'(", CRC16 NIEZGODNE")); end if;
      writeline(output, l);
      if z /= 0 or n_b /= 512 or crc_ok /= '1' or blad = '1' then errors := errors + 1; end if;
    end procedure;
  begin
    for typ in 0 to 1 loop
      m_hc <= (typ = 0);
      rst <= '1';
      m_zeruj <= true;
      for q in 1 to 5 loop wait until falling_edge(clk); end loop;
      m_zeruj <= false;
      rst <= '0';
      t0 := now;
      wait until gotowy = '1' or blad = '1';
      if typ = 0 then write(l, string'("karta SDHC")); else write(l, string'("karta SDSC")); end if;
      write(l, ": inicjalizacja " & integer'image((now - t0) / 1 us) & " us, " & integer'image(n_cmd)
            & " rozkazow, ACMD41 " & integer'image(acmd41_n) & " razy, sdhc = " & std_logic'image(sdhc)
            & ", kod bledu " & integer'image(to_integer(unsigned(kod_bledu))));
      writeline(output, l);
      write(l, "  taktow SCLK z CS = 1 przed CMD0: " & integer'image(takty_przed) & ", za szybkich: "
            & integer'image(za_szybko) & ", zlych CRC7: " & integer'image(zle_crc));
      writeline(output, l);
      if blad = '1' or (sdhc = '1') /= (typ = 0) or takty_przed < 74 or za_szybko /= 0 or zle_crc /= 0 then
        errors := errors + 1;
      end if;
      czytaj(5);
      czytaj(1000);
    end loop;
    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
