-- Testbench VUnit dla fir8: cztery przypadki testowe (impuls, skok, nasycenie, losowe), każdy w osobnej
-- symulacji. Oczekiwane wyjścia w kolejce VUnit (queue_t) liczone modelem w procesie głównym, porównanie
-- w procesie monitora. Generic BUG: dla układu z błędem test „losowe” wymaga wykrycia niezgodności.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.data_types_context;

library osvvm;
use osvvm.RandomPkg.all;

entity tb_fir8_vunit is
  generic (
    runner_cfg : string;
    BUG        : natural := 0
  );
end entity tb_fir8_vunit;

architecture sim of tb_fir8_vunit is
  type int_arr is array (natural range <>) of integer;
  constant H : int_arr(0 to 7) := (-763, 0, 4499, 12648, 12648, 4499, 0, -763);

  signal clk       : std_logic := '0';
  signal rst       : std_logic := '1';
  signal in_valid  : std_logic := '0';
  signal in_data   : signed(11 downto 0) := (others => '0');
  signal out_valid : std_logic;
  signal out_data  : signed(15 downto 0);
  signal n_bad     : natural := 0;            -- niezgodności wykryte przez monitor
  signal n_out     : natural := 0;

  constant expected : queue_t := new_queue;
begin
  clk <= not clk after 5 ns;

  dut : entity work.fir8
    generic map (BUG => BUG)
    port map (clk => clk, rst => rst, in_valid => in_valid, in_data => in_data, out_valid => out_valid,
              out_data => out_data);

  main : process
    variable hist : int_arr(0 to 7) := (others => 0);
    variable rv   : RandomPType;

    -- model: wynik dla nowej próbki (floor((s + 1024) / 2048), nasycenie)
    impure function model(x : integer) return integer is
      variable s : integer := 0;
    begin
      hist := x & hist(0 to 6);
      for i in 0 to 7 loop
        s := s + H(i) * hist(i);
      end loop;
      s := (s + 1024 - ((s + 1024) mod 2048)) / 2048;
      return maximum(-32768, minimum(32767, s));
    end function model;

    procedure send(x : integer) is
    begin
      push_integer(expected, model(x));
      in_valid <= '1';
      in_data  <= to_signed(x, 12);
      wait until falling_edge(clk);
      in_valid <= '0';
    end procedure send;

    procedure drain is
    begin
      for i in 1 to 8 loop
        wait until falling_edge(clk);
      end loop;
      check(is_empty(expected), "nie wszystkie wyniki odebrane");
    end procedure drain;
  begin
    test_runner_setup(runner, runner_cfg);
    rv.InitSeed(rv'instance_name);
    wait until falling_edge(clk);
    wait until falling_edge(clk);
    rst <= '0';
    wait until falling_edge(clk);

    while test_suite loop
      if run("impuls") then
        send(2047);
        for i in 1 to 9 loop send(0); end loop;
      elsif run("skok") then
        for i in 1 to 12 loop send(1000); end loop;
      elsif run("nasycenie") then
        for r in 1 to 2 loop
          for i in 7 downto 0 loop
            if H(i) < 0 then send(-2048); else send(2047); end if;
          end loop;
          for i in 7 downto 0 loop
            if H(i) < 0 then send(2047); else send(-2048); end if;
          end loop;
        end loop;
        for i in 1 to 8 loop send(0); end loop;
      elsif run("losowe") then
        for n in 1 to 3000 loop
          if rv.RandInt(0, 3) = 0 then
            wait until falling_edge(clk);
          end if;
          if rv.RandInt(0, 7) = 0 then
            send(rv.RandInt(0, 1) * 4095 - 2048);
          else
            send(rv.RandInt(-2048, 2047));
          end if;
        end loop;
      end if;
      drain;
      info("wynikow: " & integer'image(n_out) & ", niezgodnych: " & integer'image(n_bad));
      if BUG = 0 then
        check_equal(n_bad, 0, "wyniki niezgodne z modelem");
      else
        check(n_bad > 0, "blad ukladu (BUG=" & integer'image(BUG) & ") nie zostal wykryty");
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process main;

  -- monitor: każdy wynik porównany z czołem kolejki
  monitor : process
    variable exp : integer;
  begin
    wait until rising_edge(clk);
    if out_valid = '1' then
      n_out <= n_out + 1;
      if is_empty(expected) then
        n_bad <= n_bad + 1;
      else
        exp := pop_integer(expected);
        if to_integer(out_data) /= exp then
          if n_bad < 3 then
            info("y = " & integer'image(to_integer(out_data)) & ", oczekiwano " & integer'image(exp));
          end if;
          n_bad <= n_bad + 1;
        end if;
      end if;
    end if;
  end process monitor;

  test_runner_watchdog(runner, 1 ms);
end architecture sim;
