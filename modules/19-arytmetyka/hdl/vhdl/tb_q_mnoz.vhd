-- Testbench q_mnoz (19.01): Q1.15 × Q1.15 -> Q1.15, zbieżne z nasyceniem; 20 000 losowych par
-- i przypadki brzegowe ((-1)·(-1) — nasycenie z flagą, połówki LSB do parzystej). Dane w każdym takcie.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_q_mnoz is
end entity tb_q_mnoz;

architecture sim of tb_q_mnoz is
  constant N  : positive := 20000;
  constant NSP : positive := 8;
  type spec_t is array (0 to NSP - 1) of integer;
  constant SA : spec_t := (-32768, 16384, 1, -32768, 3, 5, 32767, -32768);
  constant SB : spec_t := (-32768, 16384, 1, 1, 16384, 16384, 32767, 32767);
  type int_t is array (0 to N + NSP - 1) of integer;
  signal clk       : std_logic := '0';
  signal fin       : boolean := false;
  signal in_valid  : std_logic := '0';
  signal a, b, p   : std_logic_vector(15 downto 0) := (others => '0');
  signal out_valid, przepel : std_logic;
  signal oczek, oczek_p : int_t := (others => 0);
  signal odebrane, errors, n_prz : integer := 0;
begin
  clk <= not clk after 5 ns when not fin else clk;
  dut : entity work.q_mnoz
    generic map (WA => 16, FA => 15, WB => 16, FB => 15, WO => 16, FO => 15, ZAOKR => 2, NASYC => true)
    port map (clk, in_valid, a, b, out_valid, p, przepel);

  process (clk)
    variable l : line;
  begin
    if rising_edge(clk) and out_valid = '1' then
      if to_integer(signed(p)) /= oczek(odebrane) or (przepel = '1') /= (oczek_p(odebrane) = 1) then
        if errors < 10 then
          write(l, "probka " & integer'image(odebrane) & ": " & integer'image(to_integer(signed(p)))
                & ", oczekiwano " & integer'image(oczek(odebrane)));
          writeline(output, l);
        end if;
        errors <= errors + 1;
      end if;
      if przepel = '1' then n_prz <= n_prz + 1; end if;
      odebrane <= odebrane + 1;
    end if;
  end process;

  process
    variable l : line;
    variable s1, s2 : positive := 7;
    variable r : real;
    variable xa, xb, il, podl, reszta, t, k : integer := 0;
  begin
    wait for 22 ns;
    for i in 0 to N + NSP - 1 loop
      wait until falling_edge(clk);
      if i < NSP then
        xa := SA(i); xb := SB(i);
      else
        uniform(s1, s2, r); xa := integer(floor(r * 65536.0)) - 32768;
        uniform(s1, s2, r); xb := integer(floor(r * 65536.0)) - 32768;
      end if;
      a <= std_logic_vector(to_signed(xa, 16));
      b <= std_logic_vector(to_signed(xb, 16));
      in_valid <= '1';
      -- model: Q2.30 -> Q1.15 (iloczyn do 2^30 mieści się w integer)
      il     := xa * xb;
      podl   := il / 32768;
      if il < 0 and podl * 32768 /= il then podl := podl - 1; end if;
      reszta := il - podl * 32768;
      t      := podl + 1 when reszta > 16384 or (reszta = 16384 and podl mod 2 /= 0) else podl;
      oczek_p(k) <= 1 when t > 32767 or t < -32768 else 0;
      oczek(k)   <= 32767 when t > 32767 else -32768 when t < -32768 else t;
      k := k + 1;
    end loop;
    wait until falling_edge(clk);
    in_valid <= '0';
    for i in 1 to 4 loop wait until falling_edge(clk); end loop;
    write(l, "probek " & integer'image(k) & ", odebranych " & integer'image(odebrane) & ", nasyconych "
          & integer'image(n_prz));
    writeline(output, l);
    if errors = 0 and odebrane = k and n_prz = 1 and oczek(0) = 32767 and oczek(4) = 2 and oczek(5) = 2 then
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
