-- Testbench cdc_handshake: 200 słów w każdym kierunku (100 MHz -> 36,6 MHz i odwrotnie), wysyłane losowo,
-- gdy ready = '1'. Sprawdzane: kolejność i wartości słów po stronie docelowej, dst_data zmienia się tylko
-- razem z dst_valid.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_cdc_handshake is
end entity tb_cdc_handshake;

architecture sim of tb_cdc_handshake is
  constant W : positive := 8;
  subtype slowo is std_logic_vector(W - 1 downto 0);
  type kolejka_t is array (0 to 255) of slowo;

  signal clk_f, clk_s : std_logic := '0';
  signal fin          : boolean   := false;
  signal rst          : std_logic := '1';
  signal s1, s2       : std_logic := '0';
  signal d1, d2       : slowo := (others => '0');
  signal r1, v1, r2, v2 : std_logic;
  signal o1, o2       : slowo;
  -- kolejki oczekiwanych słów: zapis w domenie nadawcy, odczyt w domenie odbiorcy
  signal kol1, kol2   : kolejka_t;
  signal w1, w2, rd1, rd2, err1, err2 : natural := 0;
begin
  clk_f <= not clk_f after 5 ns when not fin;
  clk_s <= not clk_s after 13.65 ns when not fin;

  u1 : entity work.cdc_handshake
    generic map (W => W)
    port map (clk_src => clk_f, rst_src => rst, send => s1, src_data => d1, ready => r1,
              clk_dst => clk_s, rst_dst => rst, dst_valid => v1, dst_data => o1);
  u2 : entity work.cdc_handshake
    generic map (W => W)
    port map (clk_src => clk_s, rst_src => rst, send => s2, src_data => d2, ready => r2,
              clk_dst => clk_f, rst_dst => rst, dst_valid => v2, dst_data => o2);

  -- domena szybka: nadawca 1, odbiorca 2
  process (clk_f)
    variable sd1, sd2 : positive := 7;
    variable x        : real;
    variable o2_p     : slowo := (others => '0');
  begin
    if falling_edge(clk_f) then
      uniform(sd1, sd2, x);
      if rst = '0' and r1 = '1' and x < 0.33 then s1 <= '1'; else s1 <= '0'; end if;
      uniform(sd1, sd2, x);
      d1 <= std_logic_vector(to_unsigned(integer(floor(x * 256.0)), W));
      if rst = '0' then
        if v2 = '1' then
          if rd2 >= w2 or o2 /= kol2(rd2 mod 256) then err2 <= err2 + 1; end if;
          rd2 <= rd2 + 1;
        elsif rd2 > 0 and o2 /= o2_p then
          err2 <= err2 + 1;
        end if;
        o2_p := o2;
      end if;
    end if;
    if rising_edge(clk_f) and rst = '0' and s1 = '1' and r1 = '1' then
      kol1(w1 mod 256) <= d1;
      w1 <= w1 + 1;
    end if;
  end process;

  -- domena wolna: nadawca 2, odbiorca 1
  process (clk_s)
    variable sd1, sd2 : positive := 17;
    variable x        : real;
    variable o1_p     : slowo := (others => '0');
  begin
    if falling_edge(clk_s) then
      uniform(sd1, sd2, x);
      if rst = '0' and r2 = '1' and x < 0.5 then s2 <= '1'; else s2 <= '0'; end if;
      uniform(sd1, sd2, x);
      d2 <= std_logic_vector(to_unsigned(integer(floor(x * 256.0)), W));
      if rst = '0' then
        if v1 = '1' then
          if rd1 >= w1 or o1 /= kol1(rd1 mod 256) then err1 <= err1 + 1; end if;
          rd1 <= rd1 + 1;
        elsif rd1 > 0 and o1 /= o1_p then
          err1 <= err1 + 1;
        end if;
        o1_p := o1;
      end if;
    end if;
    if rising_edge(clk_s) and rst = '0' and s2 = '1' and r2 = '1' then
      kol2(w2 mod 256) <= d2;
      w2 <= w2 + 1;
    end if;
  end process;

  process
    variable l : line;
  begin
    wait for 100 ns;
    rst <= '0';
    wait until (rd1 >= 200 and rd2 >= 200) for 500 us;
    write(l, "slow odebranych: szybki->wolny " & integer'image(rd1) & ", wolny->szybki " & integer'image(rd2));
    writeline(output, l);
    if err1 + err2 = 0 and rd1 >= 200 and rd2 >= 200 then
      write(l, string'("PASS"));
    else
      write(l, "FAIL: " & integer'image(err1 + err2) & " bledow");
    end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
