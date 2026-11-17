-- Testbench mini_ila: badany sygnał to licznik, więc poprawny zapis to kolejne liczby. Scenariusze:
-- poziom na wartość (pre = 10), zbocze warunku z maską (bit 4), pre = 0 i pre = 255, maska 0.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_mini_ila is
end entity tb_mini_ila;

architecture sim of tb_mini_ila is
  constant W  : positive := 16;
  constant AW : positive := 8;
  constant N  : positive := 2 ** AW;
  type probki_t is array (0 to N - 1) of unsigned(W - 1 downto 0);

  signal clk, rst    : std_logic := '1';
  signal licznik     : unsigned(W - 1 downto 0) := (others => '0');
  signal arm, zbocze : std_logic := '0';
  signal tval, tmask : std_logic_vector(W - 1 downto 0) := (others => '0');
  signal pre, rd_addr : std_logic_vector(AW - 1 downto 0) := (others => '0');
  signal rd_data     : std_logic_vector(W - 1 downto 0);
  signal armed, capturing, done, trig_out : std_logic;
  signal n_trig      : natural := 0;
  signal fin         : boolean := false;
begin
  clk <= not clk after 5 ns when not fin else clk;

  process (clk)
  begin
    if rising_edge(clk) then
      licznik <= licznik + 1;
      if trig_out = '1' then
        n_trig <= n_trig + 1;
      end if;
    end if;
  end process;

  dut : entity work.mini_ila
    generic map (W => W, AW => AW)
    port map (clk => clk, rst => rst, probe => std_logic_vector(licznik), arm => arm, trig_val => tval,
              trig_mask => tmask, trig_zbocze => zbocze, pre => pre, rd_addr => rd_addr, rd_data => rd_data,
              armed => armed, capturing => capturing, done => done, trig_out => trig_out);

  process
    variable l      : line;
    variable errors : integer := 0;
    variable probki : probki_t;

    procedure przebieg(v, m : std_logic_vector(W - 1 downto 0); z : std_logic; p : natural; czekaj : natural) is
      variable t0 : natural;
    begin
      wait until falling_edge(clk);
      tval <= v; tmask <= m; zbocze <= z; pre <= std_logic_vector(to_unsigned(p, AW));
      for i in 1 to czekaj loop
        wait until falling_edge(clk);
      end loop;
      t0 := n_trig;
      arm <= '1';
      wait until falling_edge(clk);
      arm <= '0';
      wait until falling_edge(clk);
      if armed /= '1' and capturing /= '1' and done /= '1' then
        write(l, string'("brak armed po uzbrojeniu")); writeline(output, l);
        errors := errors + 1;
      end if;
      if done /= '1' then
        wait until done = '1';
      end if;
      wait until rising_edge(clk);                 -- trig_out liczony na następnym zboczu
      wait until falling_edge(clk);
      if n_trig /= t0 + 1 then
        write(l, "trig_out " & integer'image(n_trig - t0) & " razy"); writeline(output, l);
        errors := errors + 1;
      end if;
      for i in 0 to N - 1 loop
        rd_addr <= std_logic_vector(to_unsigned(i, AW));
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        probki(i) := unsigned(rd_data);
      end loop;
      for i in 1 to N - 1 loop
        if probki(i) /= probki(i - 1) + 1 then
          write(l, "pre=" & integer'image(p) & ": nieciagla probka " & integer'image(i)); writeline(output, l);
          errors := errors + 1;
        end if;
      end loop;
    end procedure;
  begin
    wait for 23 ns;
    rst <= '0';
    przebieg(x"0400", x"FFFF", '0', 10, 3);
    if probki(10) /= x"0400" then
      write(l, string'("1: zla probka wyzwolenia")); writeline(output, l); errors := errors + 1;
    end if;
    przebieg(x"0010", x"0010", '1', 100, 0);
    if probki(100)(4) /= '1' or probki(99)(4) /= '0' then
      write(l, string'("2: brak zbocza bitu 4")); writeline(output, l); errors := errors + 1;
    end if;
    przebieg(x"0080", x"00FF", '0', 0, 0);
    if probki(0)(7 downto 0) /= x"80" then
      write(l, string'("3: zla probka wyzwolenia")); writeline(output, l); errors := errors + 1;
    end if;
    przebieg(x"0000", x"0003", '0', 255, 0);
    if probki(255)(1 downto 0) /= "00" then
      write(l, string'("4: zla probka wyzwolenia")); writeline(output, l); errors := errors + 1;
    end if;
    przebieg(x"0000", x"0000", '0', 50, 0);
    if done /= '1' or armed = '1' or capturing = '1' then
      write(l, string'("5: flagi stanu")); writeline(output, l); errors := errors + 1;
    end if;
    if errors = 0 then
      write(l, string'("PASS"));
    else
      write(l, "FAIL: " & integer'image(errors) & " bledow");
    end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
