-- Testbench SPI (20.02): spi_master <-> spi_slave, cztery tryby (CPOL, CPHA), DIV = 4 i 7.
-- W każdym trybie 5 transakcji po 3 słowa (CS trzymane) i 5 jednosłowowych, dane losowe w obie strony.
-- Niezależny monitor próbkuje MOSI i MISO na zboczach wynikających z trybu; sprawdzane też 2N zboczy
-- na słowo i poziom SCLK = CPOL przy każdej zmianie CS.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_spi is
end entity tb_spi;

architecture sim of tb_spi is
  constant N  : positive := 8;
  constant LSL : positive := 40;
  type slowa_t is array (0 to LSL - 1) of std_logic_vector(N - 1 downto 0);
  type slowa2_t is array (0 to 1) of slowa_t;
  type w2_t is array (0 to 1) of std_logic_vector(N - 1 downto 0);
  type i2_t is array (0 to 1) of integer;
  signal clk  : std_logic := '0';
  signal fin  : boolean := false;
  signal rst  : std_logic := '1';
  signal cpol, cpha : std_logic := '0';
  signal start, dalej : std_logic_vector(0 to 1) := "00";
  signal tx_m, tx_s, rx_m, rx_s : w2_t := (others => (others => '0'));
  signal zajety, gotowe, sclk, mosi, miso, miso_oe, cs_n, pobrany, rx_wazne : std_logic_vector(0 to 1);
  signal slowa_m, slowa_s : slowa2_t;
  signal n_rm, n_rs, n_mon, zbocza, bl, bl_mon : i2_t := (others => 0);
begin
  clk <= not clk after 5 ns when not fin else clk;

  g_div : for g in 0 to 1 generate
    constant DIV : positive := 4 + 3 * g;
    signal miso_m : std_logic;
  begin
    miso_m <= miso(g) when miso_oe(g) = '1' else 'X';
    u_m : entity work.spi_master generic map (N => N, DIV => DIV)
      port map (clk => clk, rst => rst, cpol => cpol, cpha => cpha, start => start(g), dalej => dalej(g),
                tx_dane => tx_m(g), rx_dane => rx_m(g), zajety => zajety(g), gotowe => gotowe(g), sclk => sclk(g),
                mosi => mosi(g), miso => miso_m, cs_n => cs_n(g));
    u_s : entity work.spi_slave generic map (N => N)
      port map (clk => clk, rst => rst, cpol => cpol, cpha => cpha, sclk => sclk(g), mosi => mosi(g),
                miso => miso(g), miso_oe => miso_oe(g), cs_n => cs_n(g), tx_dane => tx_s(g),
                tx_pobrany => pobrany(g), rx_dane => rx_s(g), rx_wazne => rx_wazne(g));

    -- slave: kolejne słowo po każdym pobraniu; liczniki odebranych słów
    process (clk)
      variable n_pob : integer := 0;
    begin
      if rising_edge(clk) then
        if rst = '1' then
          n_pob := 0;
          tx_s(g) <= slowa_s(g)(0);
          n_rm(g) <= 0;
          n_rs(g) <= 0;
        else
          if pobrany(g) = '1' then
            n_pob := n_pob + 1;
            tx_s(g) <= slowa_s(g)(n_pob);
          end if;
          if gotowe(g) = '1' then
            if rx_m(g) /= slowa_s(g)(n_rm(g)) then bl(g) <= bl(g) + 1; end if;
            n_rm(g) <= n_rm(g) + 1;
          end if;
          if rx_wazne(g) = '1' then
            if rx_s(g) /= slowa_m(g)(n_rs(g)) then bl(g) <= bl(g) + 1; end if;
            n_rs(g) <= n_rs(g) + 1;
          end if;
        end if;
      end if;
    end process;

    -- monitor protokołu
    process (sclk(g), cs_n(g), rst)
      variable mo, mi : std_logic_vector(N - 1 downto 0);
      variable nb     : integer := 0;
    begin
      if rst = '1' then
        n_mon(g)  <= 0;
        zbocza(g) <= 0;
        nb := 0;
      elsif cs_n(g)'event then
        if sclk(g) /= cpol then bl_mon(g) <= bl_mon(g) + 1; end if;   -- SCLK w spoczynku = CPOL
      elsif sclk(g)'event and cs_n(g) = '0' then
        zbocza(g) <= zbocza(g) + 1;
        if (sclk(g) /= cpol) xor (cpha = '1') then             -- zbocze próbkujące tego trybu
          mo := mo(N - 2 downto 0) & mosi(g);
          mi := mi(N - 2 downto 0) & miso(g);
          nb := nb + 1;
          if nb = N then
            if mo /= slowa_m(g)(n_mon(g)) or mi /= slowa_s(g)(n_mon(g)) then bl_mon(g) <= bl_mon(g) + 1; end if;
            n_mon(g) <= n_mon(g) + 1;
            nb := 0;
          end if;
        end if;
      end if;
    end process;
  end generate;

  process
    variable l      : line;
    variable s1, s2 : positive := 3;
    variable r      : real;
    variable w, errors : integer := 0;

    impure function los return std_logic_vector is
    begin
      uniform(s1, s2, r);
      return std_logic_vector(to_unsigned(integer(floor(r * 256.0)), N));
    end function;

    procedure transakcja(ile : positive) is
    begin
      for q in 0 to ile - 1 loop
        wait until falling_edge(clk);
        tx_m(0) <= slowa_m(0)(w); tx_m(1) <= slowa_m(1)(w);
        if q /= ile - 1 then dalej <= "11"; else dalej <= "00"; end if;
        start <= "11";
        wait until falling_edge(clk);
        start <= "00";
        wait until zajety = "00";
        w := w + 1;
      end loop;
      for q in 1 to 20 loop wait until falling_edge(clk); end loop;
    end procedure;
  begin
    for m in 0 to 3 loop
      rst <= '1';
      cpol <= '1' when m >= 2 else '0';
      cpha <= '1' when m mod 2 = 1 else '0';
      for g in 0 to 1 loop
        for j in 0 to LSL - 1 loop
          slowa_m(g)(j) <= los;
          slowa_s(g)(j) <= los;
        end loop;
      end loop;
      for q in 1 to 20 loop wait until falling_edge(clk); end loop;
      rst <= '0';
      for q in 1 to 5 loop wait until falling_edge(clk); end loop;
      w := 0;
      for i in 1 to 5 loop transakcja(3); end loop;
      for i in 1 to 5 loop transakcja(1); end loop;
      for g in 0 to 1 loop
        if n_rm(g) /= 20 or n_rs(g) /= 20 or n_mon(g) /= 20 or zbocza(g) /= 20 * 2 * N then
          write(l, "tryb " & integer'image(m) & " DIV nr " & integer'image(g) & ": master " & integer'image(n_rm(g))
                & ", slave " & integer'image(n_rs(g)) & ", monitor " & integer'image(n_mon(g)) & ", zboczy "
                & integer'image(zbocza(g)));
          writeline(output, l);
          errors := errors + 1;
        end if;
      end loop;
      write(l, "tryb " & integer'image(m) & " (CPOL=" & std_logic'image(cpol) & " CPHA=" & std_logic'image(cpha)
            & "): 20 slow w obie strony, DIV 4 i 7, bledow " & integer'image(bl(0) + bl_mon(0)) & " / " & integer'image(bl(1) + bl_mon(1)));
      writeline(output, l);
    end loop;
    errors := errors + bl(0) + bl(1) + bl_mon(0) + bl_mon(1);
    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
