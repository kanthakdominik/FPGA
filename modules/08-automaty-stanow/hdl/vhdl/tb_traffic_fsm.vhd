-- Testbench traffic_fsm dla trzech kodowań (binarne, one-hot, Graya): normalna praca porównana z modelem
-- oraz wstrzykiwane przekłamania pojedynczych bitów stanu. Model zna kody stanów z tabeli (zapis niezależny
-- od funkcji w układzie). Sprawdzane: wyjścia, err, powrót do R2 ze stanu nielegalnego, oraz to, że one-hot
-- wykrywa każde pojedyncze przekłamanie, a kodowania 3-bitowe — nie.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_traffic_fsm is
end entity tb_traffic_fsm;

architecture sim of tb_traffic_fsm is
  type slv3_arr is array (0 to 2) of std_logic_vector(2 downto 0);
  signal clk      : std_logic := '0';
  signal done     : boolean   := false;
  signal rst      : std_logic := '1';
  signal tick     : std_logic := '0';
  signal up0, up2 : std_logic_vector(2 downto 0) := "000";
  signal up1      : std_logic_vector(5 downto 0) := "000000";
  signal ns, ew   : slv3_arr;
  signal err      : std_logic_vector(0 to 2);
begin
  clk <= not clk after 5 ns when not done;

  u_bin  : entity work.traffic_fsm generic map (ENC => 0)
    port map (clk => clk, rst => rst, tick => tick, upset => up0, ns => ns(0), ew => ew(0), err => err(0));
  u_hot  : entity work.traffic_fsm generic map (ENC => 1)
    port map (clk => clk, rst => rst, tick => tick, upset => up1, ns => ns(1), ew => ew(1), err => err(1));
  u_gray : entity work.traffic_fsm generic map (ENC => 2)
    port map (clk => clk, rst => rst, tick => tick, upset => up2, ns => ns(2), ew => ew(2), err => err(2));

  stim : process
    type int_arr is array (0 to 2) of integer;
    variable idx              : int_arr := (5, 5, 5);          -- indeks stanu modelu, -1 = nielegalny
    variable tmr              : int_arr := (0, 0, 0);
    variable detected, missed : int_arr := (0, 0, 0);
    variable errors           : natural  := 0;
    variable l                : line;
    variable seed1, seed2     : positive := 29;
    variable v0, v2           : std_logic_vector(2 downto 0);
    variable v1               : std_logic_vector(5 downto 0);
    variable tk               : std_logic;

    impure function rnd(n : positive) return natural is      -- liczba losowa 0 .. n - 1
      variable r : real;
    begin
      uniform(seed1, seed2, r);
      return integer(floor(r * real(n)));
    end function rnd;

    -- kody stanów z tabeli: binarne 0..5, one-hot 1 << i, Graya 000 001 011 010 110 111
    function code_of(enc, i : natural) return std_logic_vector is
      type gray_t is array (0 to 5) of natural;
      constant GRAY : gray_t := (0, 1, 3, 2, 6, 7);
    begin
      if enc = 1 then
        return std_logic_vector(to_unsigned(2 ** i, 6));
      elsif enc = 2 then
        return std_logic_vector(to_unsigned(GRAY(i), 6));
      end if;
      return std_logic_vector(to_unsigned(i, 6));
    end function code_of;

    function decode(enc : natural; c : std_logic_vector(5 downto 0)) return integer is
    begin
      for i in 0 to 5 loop
        if code_of(enc, i) = c then
          return i;
        end if;
      end loop;
      return -1;
    end function decode;

    function last_of(i : integer) return natural is            -- czas trwania stanu - 1
    begin
      if i = 0 or i = 3 then
        return 3;
      elsif i = 1 or i = 4 then
        return 1;
      end if;
      return 0;
    end function last_of;

    function flip(width : positive; hit : boolean; bit_no : natural) return std_logic_vector is
      variable v : std_logic_vector(5 downto 0) := (others => '0');
    begin
      if hit then
        v(bit_no mod width) := '1';
      end if;
      return v;
    end function flip;

    procedure check(k : natural; n : natural) is
      variable e_ns, e_ew : std_logic_vector(2 downto 0) := "100";
    begin
      if idx(k) = 0 then e_ns := "001"; elsif idx(k) = 1 then e_ns := "010"; end if;
      if idx(k) = 3 then e_ew := "001"; elsif idx(k) = 4 then e_ew := "010"; end if;
      if ns(k) /= e_ns or ew(k) /= e_ew or (err(k) = '1') /= (idx(k) = -1) then
        errors := errors + 1;
        report "takt " & integer'image(n) & ", kodowanie " & integer'image(k) & ": ns=" & to_string(ns(k))
             & " ew=" & to_string(ew(k)) & ", model stan " & integer'image(idx(k)) severity warning;
      end if;
    end procedure check;

    procedure step_model(k : natural; upset : std_logic_vector(5 downto 0)) is
      variable nidx, ntmr, newidx : integer;
    begin
      if idx(k) = -1 then
        nidx := 5;  ntmr := 0;
      elsif tk = '1' and tmr(k) = last_of(idx(k)) then
        nidx := (idx(k) + 1) mod 6;  ntmr := 0;
      elsif tk = '1' then
        nidx := idx(k);  ntmr := tmr(k) + 1;
      else
        nidx := idx(k);  ntmr := tmr(k);
      end if;
      newidx := decode(k, code_of(k, nidx) xor upset);
      if upset /= "000000" then
        if newidx = -1 then
          detected(k) := detected(k) + 1;
        else
          missed(k) := missed(k) + 1;
        end if;
      end if;
      idx(k) := newidx;
      tmr(k) := ntmr;
    end procedure step_model;
  begin
    wait until falling_edge(clk);
    wait until falling_edge(clk);
    rst <= '0';
    for n in 0 to 2999 loop
      for k in 0 to 2 loop
        check(k, n);
      end loop;
      tk := '1' when rnd(2) = 1 else '0';
      v0 := flip(3, rnd(16) = 0, rnd(3))(2 downto 0);
      v1 := flip(6, rnd(16) = 0, rnd(6));
      v2 := flip(3, rnd(16) = 0, rnd(3))(2 downto 0);
      tick <= tk;
      up0  <= v0;
      up1  <= v1;
      up2  <= v2;
      wait until falling_edge(clk);
      step_model(0, "000" & v0);
      step_model(1, v1);
      step_model(2, "000" & v2);
    end loop;

    write(l, "przeklamania wykryte/niewykryte: binarne " & integer'image(detected(0)) & "/" & integer'image(missed(0))
           & ", one-hot " & integer'image(detected(1)) & "/" & integer'image(missed(1))
           & ", Graya " & integer'image(detected(2)) & "/" & integer'image(missed(2)));
    writeline(output, l);
    if missed(1) /= 0 or detected(1) = 0 then
      errors := errors + 1;
      report "one-hot powinien wykryc kazde pojedyncze przeklamanie" severity warning;
    end if;
    if detected(0) = 0 or missed(0) = 0 or detected(2) = 0 or missed(2) = 0 then
      errors := errors + 1;
      report "test nie pokazal obu przypadkow dla kodowan 3-bitowych" severity warning;
    end if;
    if errors = 0 then
      write(l, string'("PASS"));
    else
      write(l, "FAIL: " & integer'image(errors) & " bledow");
    end if;
    writeline(output, l);
    done <= true;
    std.env.finish;
    wait;
  end process stim;
end architecture sim;
