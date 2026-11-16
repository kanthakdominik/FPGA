-- Pierwszy testbench mavg4: generator zegara, reset, procedury podające pobudzenia
-- na opadającym zboczu i ręcznie policzone wartości oczekiwane. Przypadki: odpowiedź na skok,
-- zmiana znaku, zaokrąglenie w dół liczb ujemnych, wstrzymanie (in_valid = '0'), reset w trakcie pracy.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_mavg4_basic is
end entity tb_mavg4_basic;

architecture sim of tb_mavg4_basic is
  constant T : time := 10 ns;                                  -- okres zegara

  signal clk       : std_logic := '0';
  signal done      : boolean   := false;
  signal rst       : std_logic := '1';
  signal in_valid  : std_logic := '0';
  signal x         : signed(7 downto 0) := (others => '0');
  signal out_valid : std_logic;
  signal y         : signed(7 downto 0);
begin
  -- generator zegara: zmiana co pół okresu, zatrzymany po zakończeniu testu
  clk <= not clk after T / 2 when not done;

  dut : entity work.mavg4
    port map (clk => clk, rst => rst, in_valid => in_valid, x => x, out_valid => out_valid, y => y);

  stim : process
    variable errors : natural := 0;
    variable l      : line;

    -- reset przez n taktów; zmiany na opadającym zboczu — z dala od zbocza, na którym układ próbkuje
    procedure reset(n : positive) is
    begin
      wait until falling_edge(clk);
      rst      <= '1';
      in_valid <= '0';
      for i in 1 to n loop
        wait until falling_edge(clk);
      end loop;
      rst <= '0';
    end procedure reset;

    -- jedna próbka i sprawdzenie wyjścia po zboczu
    procedure send(value : integer; expected : integer) is
    begin
      in_valid <= '1';
      x        <= to_signed(value, 8);
      wait until falling_edge(clk);
      in_valid <= '0';
      if out_valid /= '1' or y /= to_signed(expected, 8) then
        errors := errors + 1;
        report "x=" & integer'image(value) & " -> y=" & integer'image(to_integer(y))
             & ", oczekiwano " & integer'image(expected) severity warning;
      end if;
    end procedure send;

    -- takt bez danych: out_valid = '0', y bez zmian
    procedure idle(expected : integer) is
    begin
      wait until falling_edge(clk);
      if out_valid /= '0' or y /= to_signed(expected, 8) then
        errors := errors + 1;
        report "bez danych: y=" & integer'image(to_integer(y)) & ", oczekiwano " & integer'image(expected)
          severity warning;
      end if;
    end procedure idle;
  begin
    reset(2);
    idle(0);                                                   -- po resecie: y = 0, out_valid = '0'

    send(40, 10);                                              -- skok: (40 + 0 + 0 + 0) / 4
    send(40, 20);
    send(40, 30);
    send(40, 40);                                              -- okno pełne
    send(-40, 20);                                             -- zmiana znaku: (-40 + 40 + 40 + 40) / 4
    send(-40, 0);
    send(-40, -20);
    send(-40, -40);
    send(-1, -31);                                             -- -121 / 4 = -30,25 -> floor = -31 (nie -30!)
    idle(-31);                                                 -- wstrzymanie: wyjście trzyma wartość
    idle(-31);
    send(127, 11);                                             -- okno {127, -1, -40, -40}: 46 / 4 = 11,5 -> 11
    reset(1);
    idle(0);                                                   -- reset w trakcie pracy zeruje okno
    send(-128, -32);                                           -- wartość skrajna

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
