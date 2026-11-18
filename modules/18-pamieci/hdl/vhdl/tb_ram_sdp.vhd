-- Testbench ram_sdp: (1) jeden zegar, zapis i odczyt w tym samym takcie, także pod ten sam adres
-- (oczekiwana stara zawartość); (2) blok zapisany zegarem 100 MHz, odczytany zegarem 37 MHz.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_ram_sdp is
end entity tb_ram_sdp;

architecture sim of tb_ram_sdp is
  constant W  : positive := 16;
  constant AW : positive := 6;
  type mem_t is array (0 to 2 ** AW - 1) of std_logic_vector(W - 1 downto 0);
  signal clk, clk_r2 : std_logic := '0';
  signal we, re, we2, re2 : std_logic := '0';
  signal adr_w, adr_r, aw2, ar2 : std_logic_vector(AW - 1 downto 0) := (others => '0');
  signal din, din2, dout, dout2 : std_logic_vector(W - 1 downto 0) := (others => '0');
  signal fin : boolean := false;
begin
  clk <= not clk after 5 ns when not fin else clk;
  process
  begin
    wait for 2.1 ns;
    while not fin loop
      clk_r2 <= not clk_r2;
      wait for 13.5 ns;
    end loop;
    wait;
  end process;

  u1 : entity work.ram_sdp generic map (W => W, AW => AW)
    port map (clk_w => clk, we => we, addr_w => adr_w, din => din, clk_r => clk, re => re, addr_r => adr_r, dout => dout);
  u2 : entity work.ram_sdp generic map (W => W, AW => AW)
    port map (clk_w => clk, we => we2, addr_w => aw2, din => din2, clk_r => clk_r2, re => re2, addr_r => ar2, dout => dout2);

  process
    variable s1, s2 : positive := 5;
    variable r : real;
    variable l : line;
    variable model : mem_t;
    variable oczek, dv : std_logic_vector(W - 1 downto 0);
    variable a, b : natural;
    variable wv : std_logic;
    variable errors, rdw : integer := 0;
    impure function los(n : positive) return natural is
    begin
      uniform(s1, s2, r);
      return integer(floor(r * real(n))) mod n;
    end function;
  begin
    for i in 0 to 2 ** AW - 1 loop
      wait until falling_edge(clk);
      dv := std_logic_vector(to_unsigned(los(65536), W));
      we <= '1'; adr_w <= std_logic_vector(to_unsigned(i, AW)); din <= dv; model(i) := dv;
    end loop;
    for n in 0 to 999 loop
      wait until falling_edge(clk);
      if los(2) = 1 then wv := '1'; else wv := '0'; end if;
      a := los(2 ** AW);
      if n mod 4 = 0 then b := a; else b := los(2 ** AW); end if;
      dv := std_logic_vector(to_unsigned(los(65536), W));
      we <= wv; re <= '1'; adr_w <= std_logic_vector(to_unsigned(a, AW)); adr_r <= std_logic_vector(to_unsigned(b, AW));
      din <= dv;
      oczek := model(b);
      if wv = '1' and a = b then rdw := rdw + 1; end if;
      if wv = '1' then model(a) := dv; end if;
      wait until rising_edge(clk);
      wait for 1 ns;
      if dout /= oczek then
        write(l, "jeden zegar, adres " & integer'image(b) & ": niezgodny odczyt"); writeline(output, l);
        errors := errors + 1;
      end if;
    end loop;
    we <= '0';
    for i in 0 to 2 ** AW - 1 loop
      wait until falling_edge(clk);
      we2 <= '1'; aw2 <= std_logic_vector(to_unsigned(i, AW));
      din2 <= std_logic_vector(to_unsigned(16#A000# + i * 3, W));
    end loop;
    wait until falling_edge(clk);
    we2 <= '0';
    for k in 1 to 3 loop
      wait until rising_edge(clk_r2);
    end loop;
    for i in 0 to 2 ** AW - 1 loop
      wait until falling_edge(clk_r2);
      re2 <= '1'; ar2 <= std_logic_vector(to_unsigned(i, AW));
      wait until rising_edge(clk_r2);
      wait for 1 ns;
      if to_integer(unsigned(dout2)) /= 16#A000# + i * 3 then
        write(l, "dwa zegary, adres " & integer'image(i) & ": niezgodny odczyt"); writeline(output, l);
        errors := errors + 1;
      end if;
    end loop;
    write(l, "odczytow pod adres zapisywany w tym samym takcie: " & integer'image(rdw)); writeline(output, l);
    if errors = 0 and rdw > 50 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
