-- Testbench 25.01: i2s_master z modelem kodeka (slave I2S): odbiór dout według formatu I2S i nadawanie din
-- (zmiana po opadającym BCLK). 200 ramek losowych próbek w obie strony, porównanie ciągów z wyrównaniem
-- opóźnienia potoku, pomiar BCLK, WCLK i liczby taktów BCLK na ramkę.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_i2s is
end entity tb_i2s;

architecture sim of tb_i2s is
  constant M : positive := 200;
  signal clk : std_logic := '0';
  signal rst : std_logic := '1';
  signal fin : boolean := false;
  signal tx_l, tx_p, rx_l, rx_p : std_logic_vector(23 downto 0) := (others => '0');
  signal ramka, bclk, wclk, dout : std_logic;
  signal din : std_logic := '0';
  type tab_t is array (0 to M + 9) of std_logic_vector(23 downto 0);
  signal wys_l, wys_p, mod_l, mod_p, odb_l, odb_p, fpg_l, fpg_p : tab_t := (others => (others => '0'));
  signal nf, no : natural := 0;
  signal okr_b, okr_w : time := 0 ns;
  signal nb_min : natural := 999;
  signal nb_max : natural := 0;

  procedure los24(variable s1, s2 : inout positive; variable v : out std_logic_vector(23 downto 0)) is
    variable r : real;
  begin
    uniform(s1, s2, r);
    v := std_logic_vector(to_unsigned(integer(floor(r * 16777216.0)) mod 16777216, 24));
  end procedure;
begin
  clk <= not clk after 40 ns when not fin else clk;

  dut : entity work.i2s_master
    port map (clk => clk, rst => rst, tx_l => tx_l, tx_p => tx_p, rx_l => rx_l, rx_p => rx_p, ramka => ramka,
              bclk => bclk, wclk => wclk, dout => dout, din => din);

  -- FPGA: nowe próbki po każdym impulsie ramka
  process (clk)
    variable s1, s2 : positive := 25;
    variable l, p : std_logic_vector(23 downto 0);
    variable n : natural := 0;
  begin
    if rising_edge(clk) and ramka = '1' then
      if n < M + 10 then fpg_l(n) <= rx_l; fpg_p(n) <= rx_p; end if;
      los24(s1, s2, l); los24(s1, s2, p);
      tx_l <= l; tx_p <= p;
      if n < M + 10 then wys_l(n) <= l; wys_p(n) <= p; end if;
      n := n + 1;
      nf <= n;
    end if;
  end process;

  -- model kodeka: odbiór (narastające BCLK) i nadawanie (opadające BCLK)
  process (bclk)
    variable w_pop : std_logic := '0';
    variable wn_pop : std_logic := '1';
    variable cnt, poz : natural := 99;
    variable sr, sl, sp : std_logic_vector(23 downto 0) := (others => '0');
    variable s1, s2 : positive := 77;
    variable n_o, n_m : natural := 0;
  begin
    if rising_edge(bclk) then
      if wclk /= w_pop then cnt := 0; else cnt := cnt + 1; end if;
      if cnt >= 1 and cnt <= 24 then sr := sr(22 downto 0) & dout; end if;
      if cnt = 24 and n_o < M + 10 then
        if wclk = '0' then odb_l(n_o) <= sr; else odb_p(n_o) <= sr; n_o := n_o + 1; no <= n_o; end if;
      end if;
      w_pop := wclk;
    end if;
    if falling_edge(bclk) then
      if wclk /= wn_pop then poz := 0; else poz := poz + 1; end if;
      if poz = 0 and wclk = '0' then
        los24(s1, s2, sl); los24(s1, s2, sp);
        if n_m < M + 10 then mod_l(n_m) <= sl; mod_p(n_m) <= sp; n_m := n_m + 1; end if;
      end if;
      if poz >= 1 and poz <= 24 then
        if wclk = '1' then din <= sp(24 - poz) after 10 ns; else din <= sl(24 - poz) after 10 ns; end if;
      else
        din <= '0' after 10 ns;
      end if;
      wn_pop := wclk;
    end if;
  end process;

  -- pomiar zegarów
  process (bclk, wclk)
    variable tb0, tw0 : time := 0 ns;
    variable nb, nb_w : natural := 0;
  begin
    if rising_edge(bclk) then
      if tb0 > 0 ns then okr_b <= now - tb0; end if;
      tb0 := now; nb := nb + 1;
    end if;
    if rising_edge(wclk) then
      if tw0 > 0 ns then
        okr_w <= now - tw0;
        if nb - nb_w < nb_min then nb_min <= nb - nb_w; end if;
        if nb - nb_w > nb_max then nb_max <= nb - nb_w; end if;
      end if;
      tw0 := now; nb_w := nb;
    end if;
  end process;

  process
    variable l : line;
    variable errors, z1, z2, zle, najl, op1, op2 : integer := 0;
  begin
    for i in 1 to 3 loop wait until rising_edge(clk); end loop;
    rst <= '0';
    wait until nf >= M + 2 and no >= M + 2;
    wait for 1 us;
    for kier in 0 to 1 loop
      najl := 999;
      for o in 0 to 7 loop
        zle := 0;
        for k in 8 to M - 6 loop
          if kier = 0 then
            if odb_l(k) /= wys_l(k - o + 3) or odb_p(k) /= wys_p(k - o + 3) then zle := zle + 1; end if;
          else
            if fpg_l(k) /= mod_l(k - o + 3) or fpg_p(k) /= mod_p(k - o + 3) then zle := zle + 1; end if;
          end if;
        end loop;
        if zle < najl then najl := zle; if kier = 0 then op1 := o - 3; else op2 := o - 3; end if; end if;
      end loop;
      if kier = 0 then z1 := najl; else z2 := najl; end if;
    end loop;
    write(l, "BCLK okres " & integer'image(okr_b / 1 ns) & " ns (3,125 MHz), WCLK okres " & integer'image(okr_w / 1 ns)
          & " ns (48,828 kHz), taktow BCLK na ramke " & integer'image(nb_min)
          & ".." & integer'image(nb_max));
    writeline(output, l);
    write(l, "ramek " & integer'image(M) & ": FPGA -> kodek bledow " & integer'image(z1) & " (opoznienie "
          & integer'image(op1) & "), kodek -> FPGA bledow " & integer'image(z2) & " (opoznienie " & integer'image(op2) & ")");
    writeline(output, l);
    if z1 /= 0 or z2 /= 0 or nb_min /= 64 or nb_max /= 64 or okr_b /= 320 ns or okr_w /= 20480 ns then
      errors := errors + 1;
    end if;
    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
