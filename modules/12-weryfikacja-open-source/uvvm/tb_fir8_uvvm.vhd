-- Testbench fir8 w stylu UVVM (biblioteka uvvm_util, uruchamiany przez VUnit): log z identyfikatorami
-- komunikatów, check_value z poziomem alarmu, await_value z oknem czasowym (opóźnienie potoku),
-- raport liczników alarmów na końcu. Impuls, nasycenie i 1000 próbek losowych z modelem w VHDL.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
use vunit_lib.run_pkg.all;
use vunit_lib.check_pkg.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

entity tb_fir8_uvvm is
  generic (
    runner_cfg : string
  );
end entity tb_fir8_uvvm;

architecture sim of tb_fir8_uvvm is
  type int_arr is array (natural range <>) of integer;
  constant H      : int_arr(0 to 7) := (-763, 0, 4499, 12648, 12648, 4499, 0, -763);
  constant PERIOD  : time   := 10 ns;
  constant C_SCOPE : string := "TB fir8";

  signal clk       : std_logic := '0';
  signal rst       : std_logic := '1';
  signal in_valid  : std_logic := '0';
  signal in_data   : signed(11 downto 0) := (others => '0');
  signal out_valid : std_logic;
  signal out_data  : signed(15 downto 0);

  -- kolejka oczekiwanych wyników (bufor cykliczny): zapisuje proces główny, czyta monitor
  signal expq : int_arr(0 to 4095) := (others => 0);
  signal tail : natural := 0;
  signal head : natural := 0;
begin
  clk <= not clk after PERIOD / 2;

  dut : entity work.fir8
    port map (clk => clk, rst => rst, in_valid => in_valid, in_data => in_data, out_valid => out_valid,
              out_data => out_data);

  main : process
    variable hist  : int_arr(0 to 7) := (others => 0);
    variable seed1 : positive := 7;
    variable seed2 : positive := 3;
    variable x     : integer;

    procedure send(v : integer) is
      variable acc : integer := 0;
    begin
      hist := v & hist(0 to 6);
      for i in 0 to 7 loop
        acc := acc + H(i) * hist(i);
      end loop;
      acc := (acc + 1024 - ((acc + 1024) mod 2048)) / 2048;
      expq(tail mod 4096) <= maximum(-32768, minimum(32767, acc));
      tail <= tail + 1;
      in_valid <= '1';
      in_data  <= to_signed(v, 12);
      wait until falling_edge(clk);
      in_valid <= '0';
    end procedure send;
  begin
    test_runner_setup(runner, runner_cfg);
    set_alert_stop_limit(ERROR, 0);                       -- zliczaj błędy zamiast przerywać
    log(ID_LOG_HDR, "Test fir8 z UVVM", C_SCOPE);
    wait until falling_edge(clk);
    wait until falling_edge(clk);
    rst <= '0';
    wait until falling_edge(clk);

    log(ID_SEQUENCER, "impuls i opoznienie potoku", C_SCOPE);
    send(2047);
    -- próbka przyjęta 5 ns przed powrotem z send(), wynik po trzech kolejnych zboczach: out_valid
    -- powinien wzrosnąć 25 ns od teraz — okno 20…30 ns
    await_value(out_valid, '1', 2 * PERIOD, 3 * PERIOD, ERROR, "out_valid po impulsie", C_SCOPE);
    wait until falling_edge(clk);                         -- await_value wraca tuż po zboczu narastającym:
                                                          -- powrót do rytmu „pobudzenia na zboczu opadającym”
    for i in 1 to 9 loop send(0); end loop;

    log(ID_SEQUENCER, "nasycenie", C_SCOPE);
    for r in 1 to 2 loop
      for i in 7 downto 0 loop
        if H(i) < 0 then send(-2048); else send(2047); end if;
      end loop;
      for i in 7 downto 0 loop
        if H(i) < 0 then send(2047); else send(-2048); end if;
      end loop;
    end loop;

    log(ID_SEQUENCER, "1000 probek losowych", C_SCOPE);
    for n in 1 to 1000 loop
      random(-2048, 2047, seed1, seed2, x);                -- procedura losująca z uvvm_util
      send(x);
    end loop;
    for i in 1 to 8 loop
      wait until falling_edge(clk);
    end loop;

    check_value(tail - head, 0, ERROR, "wszystkie wyniki odebrane", C_SCOPE);
    report_alert_counters(FINAL);
    check_equal(get_alert_counter(ERROR), 0, "bledy zgloszone przez UVVM");
    test_runner_cleanup(runner);
  end process main;

  monitor : process
  begin
    wait until rising_edge(clk);
    if out_valid = '1' then
      check_value(to_integer(out_data), expq(head mod 4096), ERROR, "wynik filtru", C_SCOPE, ID_NEVER);
      head <= head + 1;
    end if;
  end process monitor;
end architecture sim;
