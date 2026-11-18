-- Testbench secded_koder + secded_dekoder (K = 32, 39 bitów): 300 słów bez błędu, wszystkie 39 błędów
-- pojedynczych dla każdego słowa, wszystkie 741 par błędów dla 20 słów.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_secded is
end entity tb_secded;

architecture sim of tb_secded is
  constant K : positive := 32;
  constant R : positive := 6;
  constant N : positive := K + R + 1;
  signal dane, odz : std_logic_vector(K - 1 downto 0) := (others => '0');
  signal kod, blad, kod_b : std_logic_vector(N - 1 downto 0) := (others => '0');
  signal poj, pod : std_logic;
  signal syn : std_logic_vector(R - 1 downto 0);
begin
  u_k : entity work.secded_koder generic map (K => K, R => R) port map (dane => dane, kod => kod);
  kod_b <= kod xor blad;
  u_d : entity work.secded_dekoder generic map (K => K, R => R)
    port map (kod => kod_b, dane => odz, pojedynczy => poj, podwojny => pod, syndrom => syn);

  process
    variable s1, s2 : positive := 37;
    variable r : real;
    variable l : line;
    variable errors, n_poj, n_pod : integer := 0;
    variable b : std_logic_vector(N - 1 downto 0);
  begin
    for s in 0 to 299 loop
      if s = 0 then
        dane <= (others => '0');
      elsif s = 1 then
        dane <= (others => '1');
      else
        for i in 0 to K - 1 loop
          uniform(s1, s2, r);
          if r < 0.5 then dane(i) <= '0'; else dane(i) <= '1'; end if;
        end loop;
      end if;
      blad <= (others => '0');
      wait for 1 ns;
      if odz /= dane or poj = '1' or pod = '1' then
        write(l, string'("bez bledu: niezgodne")); writeline(output, l); errors := errors + 1;
      end if;
      for i in 0 to N - 1 loop
        b := (others => '0'); b(i) := '1';
        blad <= b;
        wait for 1 ns;
        n_poj := n_poj + 1;
        if odz /= dane or poj /= '1' or pod /= '0' then
          write(l, "pojedynczy na pozycji " & integer'image(i)); writeline(output, l); errors := errors + 1;
        end if;
      end loop;
      if s < 20 then
        for i in 0 to N - 1 loop
          for j in i + 1 to N - 1 loop
            b := (others => '0'); b(i) := '1'; b(j) := '1';
            blad <= b;
            wait for 1 ns;
            n_pod := n_pod + 1;
            if pod /= '1' or poj /= '0' then
              write(l, "podwojny " & integer'image(i) & "," & integer'image(j)); writeline(output, l);
              errors := errors + 1;
            end if;
          end loop;
        end loop;
      end if;
    end loop;
    write(l, "bledy pojedyncze: " & integer'image(n_poj) & ", podwojne: " & integer'image(n_pod)); writeline(output, l);
    if errors = 0 and n_poj = 300 * N and n_pod = 20 * N * (N - 1) / 2 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    std.env.finish;
    wait;
  end process;
end architecture sim;
