-- Testbench pingpong: nadawca zapisuje bloki po 16 słów (blok · 256 + indeks) z losowymi przerwami;
-- odbiorca czeka losowo, czyta blok od końca i go zwalnia. Sprawdzane: bloki bez pominięć i powtórzeń,
-- nadawca bywa wstrzymywany.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_pingpong is
end entity tb_pingpong;

architecture sim of tb_pingpong is
  constant W  : positive := 16;
  constant AW : positive := 4;
  constant NB : positive := 40;
  signal clk, rst : std_logic := '1';
  signal wr_en, zwolnij : std_logic := '0';
  signal din, dout : std_logic_vector(W - 1 downto 0) := (others => '0');
  signal rd_addr : std_logic_vector(AW - 1 downto 0) := (others => '0');
  signal wr_ready, gotowy : std_logic;
  signal blok_w, slowo_w, wstrzymania : natural := 0;
  signal fin : boolean := false;
begin
  clk <= not clk after 5 ns when not fin else clk;
  dut : entity work.pingpong generic map (W => W, AW => AW)
    port map (clk => clk, rst => rst, wr_en => wr_en, din => din, wr_ready => wr_ready, rd_gotowy => gotowy,
              rd_addr => rd_addr, dout => dout, rd_zwolnij => zwolnij);

  -- nadawca: licznik przyjętych słów na zboczu, nowe słowo na opadającym zboczu
  process (clk)
  begin
    if rising_edge(clk) and rst = '0' then
      if wr_en = '1' and wr_ready = '1' then
        if slowo_w = 2 ** AW - 1 then
          slowo_w <= 0;
          blok_w  <= blok_w + 1;
        else
          slowo_w <= slowo_w + 1;
        end if;
      end if;
      if wr_en = '1' and wr_ready = '0' then
        wstrzymania <= wstrzymania + 1;
      end if;
    end if;
  end process;

  process
    variable s1, s2 : positive := 23;
    variable r : real;
  begin
    wait until falling_edge(clk);
    uniform(s1, s2, r);
    if rst = '0' and blok_w < NB and r < 0.75 then wr_en <= '1'; else wr_en <= '0'; end if;
    din <= std_logic_vector(to_unsigned(blok_w * 256 + slowo_w, W));
  end process;

  -- odbiorca
  process
    variable s1, s2 : positive := 29;
    variable r : real;
    variable l : line;
    variable blok_r, errors : integer := 0;
  begin
    wait for 23 ns;
    rst <= '0';
    while blok_r < NB loop
      wait until falling_edge(clk);
      if gotowy = '1' then
        uniform(s1, s2, r);
        for k in 1 to integer(floor(r * 40.0)) loop
          wait until falling_edge(clk);
        end loop;
        for i in 2 ** AW - 1 downto 0 loop
          rd_addr <= std_logic_vector(to_unsigned(i, AW));
          wait until falling_edge(clk);
          if to_integer(unsigned(dout)) /= blok_r * 256 + i then
            write(l, "blok " & integer'image(blok_r) & " slowo " & integer'image(i) & ": niezgodne");
            writeline(output, l);
            errors := errors + 1;
          end if;
        end loop;
        zwolnij <= '1';
        wait until falling_edge(clk);
        zwolnij <= '0';
        blok_r := blok_r + 1;
      end if;
    end loop;
    write(l, "blokow odczytanych: " & integer'image(blok_r) & ", takty wstrzymania nadawcy: " & integer'image(wstrzymania));
    writeline(output, l);
    if errors = 0 and wstrzymania > 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
