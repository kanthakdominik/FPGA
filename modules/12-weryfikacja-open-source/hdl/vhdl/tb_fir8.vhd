-- Testbench fir8: impuls, połówka LSB, skok, wzorzec nasycenia dodatni i ujemny, 2000 próbek losowych z przerwami
-- w in_valid. Model na liczbach całkowitych: suma iloczynów z historii próbek, floor((s + 1024) / 2048)
-- (zaokrąglenie w górę połówki), nasycenie do 16 bitów. Sprawdzane: każda próbka wyjściowa i opóźnienie
-- (wynik po 4. zboczu od wysłania = 3 takty potoku); pokrycie: nasycenie w obie strony, połówka LSB.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_fir8 is
end entity tb_fir8;

architecture sim of tb_fir8 is
  type int_arr is array (natural range <>) of integer;
  constant H : int_arr(0 to 7) := (-763, 0, 4499, 12648, 12648, 4499, 0, -763);

  signal clk       : std_logic := '0';
  signal done      : boolean   := false;
  signal rst       : std_logic := '1';
  signal in_valid  : std_logic := '0';
  signal in_data   : signed(11 downto 0) := (others => '0');
  signal out_valid : std_logic;
  signal out_data  : signed(15 downto 0);
  signal cycle     : natural := 0;

begin
  clk <= not clk after 5 ns when not done;

  dut : entity work.fir8
    port map (clk => clk, rst => rst, in_valid => in_valid, in_data => in_data, out_valid => out_valid,
              out_data => out_data);

  process (clk)
  begin
    if rising_edge(clk) then
      cycle <= cycle + 1;
    end if;
  end process;

  main : process
    variable hist                          : int_arr(0 to 7) := (others => 0);
    variable expq, lat                     : int_arr(0 to 4095);
    variable head, tail                    : natural := 0;
    variable errors, n_out                 : natural := 0;
    variable n_sat_pos, n_sat_neg, n_half  : natural := 0;
    variable seed1, seed2                  : positive := 12;
    variable v                             : integer;
    variable l                             : line;

    impure function rnd(n : positive) return natural is      -- liczba losowa 0 .. n - 1
      variable r : real;
    begin
      uniform(seed1, seed2, r);
      return integer(floor(r * real(n)));
    end function rnd;

    procedure fail(msg : string) is
    begin
      errors := errors + 1;
      if errors <= 10 then
        report msg severity warning;
      end if;
    end procedure fail;

    -- sprawdzenie wyjścia na zboczu opadającym (wołane w każdym takcie przez wait_fall)
    procedure check_output is
    begin
      if out_valid = '1' then
        if head = tail then
          fail("wyjscie bez wejscia");
        else
          n_out := n_out + 1;
          if to_integer(out_data) /= expq(head mod 4096) then
            fail("y = " & integer'image(to_integer(out_data)) & ", oczekiwano " &
                 integer'image(expq(head mod 4096)));
          end if;
          if cycle - lat(head mod 4096) /= 4 then
            fail("wynik po " & integer'image(cycle - lat(head mod 4096)) & " zboczach zamiast 4");
          end if;
          head := head + 1;
        end if;
      end if;
    end procedure check_output;

    procedure wait_fall is
    begin
      wait until falling_edge(clk);
      check_output;
    end procedure wait_fall;

    procedure send(value : integer) is
      variable s : integer := 0;
      variable y : integer;
    begin
      for i in 7 downto 1 loop
        hist(i) := hist(i - 1);
      end loop;
      hist(0) := value;
      for i in 0 to 7 loop
        s := s + H(i) * hist(i);
      end loop;
      if s mod 2048 = 1024 then                           -- mod w VHDL: wynik ze znakiem dzielnika
        n_half := n_half + 1;
      end if;
      y := (s + 1024 - ((s + 1024) mod 2048)) / 2048;     -- dzielenie z zaokrągleniem w dół
      if y > 32767 then
        y := 32767; n_sat_pos := n_sat_pos + 1;
      elsif y < -32768 then
        y := -32768; n_sat_neg := n_sat_neg + 1;
      end if;
      expq(tail mod 4096) := y;
      lat(tail mod 4096)  := cycle;
      tail := tail + 1;
      in_valid <= '1';
      in_data  <= to_signed(value, 12);
      wait_fall;
      in_valid <= '0';
    end procedure send;
  begin
    for k in 1 to 3 loop
      wait_fall;
    end loop;
    rst <= '0';
    wait_fall;
    send(2047);                                           -- impuls
    for k in 1 to 10 loop send(0); end loop;
    send(128);                                            -- połówka LSB: 12648 * 128 / 2048 = 790,5
    for k in 1 to 8 loop send(0); end loop;
    for k in 1 to 12 loop send(1000); end loop;           -- skok
    for k in 1 to 8 loop send(0); end loop;
    for r in 1 to 2 loop                                  -- nasycenie: znaki zgodne z h
      for i in 7 downto 0 loop
        if H(i) < 0 then send(-2048); else send(2047); end if;
      end loop;
      for i in 7 downto 0 loop
        if H(i) < 0 then send(2047); else send(-2048); end if;
      end loop;
    end loop;
    for k in 1 to 8 loop send(0); end loop;
    for n in 1 to 2000 loop                               -- losowe, z przerwami
      if rnd(4) = 0 then
        wait_fall;
      end if;
      if rnd(8) = 0 then
        if rnd(2) = 1 then v := 2047; else v := -2048; end if;
      else
        v := rnd(4096) - 2048;
      end if;
      send(v);
    end loop;
    for k in 1 to 8 loop
      wait_fall;
    end loop;

    if head /= tail then
      fail("brak " & integer'image(tail - head) & " wyjsc");
    end if;
    if n_sat_pos = 0 or n_sat_neg = 0 or n_half = 0 then
      fail("pokrycie: nasycenie +" & integer'image(n_sat_pos) & " -" & integer'image(n_sat_neg) &
           ", polowka LSB " & integer'image(n_half));
    end if;
    write(l, "probek: " & integer'image(n_out) & ", nasycen: +" & integer'image(n_sat_pos) & " -" &
             integer'image(n_sat_neg) & ", wynikow na polowce LSB: " & integer'image(n_half));
    writeline(output, l);
    if errors = 0 then
      write(l, string'("PASS"));
    else
      write(l, "FAIL: " & integer'image(errors) & " bledow");
    end if;
    writeline(output, l);
    done <= true;
    std.env.finish;
    wait;
  end process main;
end architecture sim;
