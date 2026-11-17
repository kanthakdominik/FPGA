-- Testbench fir8 w stylu OSVVM (uruchamiany przez VUnit): pokrycie „inteligentne” — kolejną próbkę
-- wejściową wybiera RandCovPoint spośród jeszcze niepokrytych koszy, aż model pokrycia będzie pełny;
-- scoreboard OSVVM (ScoreboardPkg_int) porównuje wyniki; AlertLogPkg zlicza błędy i drukuje raport.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
use vunit_lib.run_pkg.all;
use vunit_lib.check_pkg.all;

library osvvm;
use osvvm.AlertLogPkg.all;
use osvvm.RandomPkg.all;
use osvvm.CoveragePkg.all;
use osvvm.ScoreboardPkg_int.all;

entity tb_fir8_osvvm is
  generic (
    runner_cfg : string
  );
end entity tb_fir8_osvvm;

architecture sim of tb_fir8_osvvm is
  type int_arr is array (natural range <>) of integer;
  constant H : int_arr(0 to 7) := (-763, 0, 4499, 12648, 12648, 4499, 0, -763);

  signal clk       : std_logic := '0';
  signal rst       : std_logic := '1';
  signal in_valid  : std_logic := '0';
  signal in_data   : signed(11 downto 0) := (others => '0');
  signal out_valid : std_logic;
  signal out_data  : signed(15 downto 0);

  signal sb      : ScoreboardIDType;
  signal cov_in  : CoverageIDType;           -- wartości wejściowe
  signal cov_out : CoverageIDType;           -- klasy wyników
begin
  clk <= not clk after 5 ns;

  dut : entity work.fir8
    port map (clk => clk, rst => rst, in_valid => in_valid, in_data => in_data, out_valid => out_valid,
              out_data => out_data);

  main : process
    variable hist : int_arr(0 to 7) := (others => 0);
    variable n    : natural := 0;

    -- próbka na wejście, oczekiwany wynik do scoreboardu
    procedure send(x : integer) is
      variable acc : integer := 0;
    begin
      wait until falling_edge(clk);
      ICover(cov_in, x);
      hist := x & hist(0 to 6);
      for i in 0 to 7 loop
        acc := acc + H(i) * hist(i);
      end loop;
      acc := (acc + 1024 - ((acc + 1024) mod 2048)) / 2048;
      Push(sb, maximum(-32768, minimum(32767, acc)));
      in_valid <= '1';
      in_data  <= to_signed(x, 12);
      n := n + 1;
    end procedure send;
  begin
    test_runner_setup(runner, runner_cfg);
    SetAlertLogName("tb_fir8_osvvm");
    sb      <= NewID("SB");
    cov_in  <= NewID("wejscie");
    cov_out <= NewID("wyjscie");
    wait for 0 ns;
    -- kosze wejścia: skrajne wartości, zero, przedziały ujemne i dodatnie
    AddBins(cov_in, GenBin(-2048));
    AddBins(cov_in, GenBin(2047));
    AddBins(cov_in, GenBin(0));
    AddBins(cov_in, GenBin(-2047, -1, 8));
    AddBins(cov_in, GenBin(1, 2046, 8));
    -- kosze wyjścia: nasycenie w obie strony, wynik ujemny, dodatni
    AddBins(cov_out, GenBin(-32768));
    AddBins(cov_out, GenBin(32767));
    AddBins(cov_out, GenBin(-32767, -1, 1));
    AddBins(cov_out, GenBin(0, 32766, 1));

    wait until falling_edge(clk);
    wait until falling_edge(clk);
    rst <= '0';

    -- dopóki pokrycie niepełne: próbka z niepokrytego kosza wejścia (RandCovPoint);
    -- co 200 próbek wzorzec o znakach zgodnych ze współczynnikami (nasycenie w obie strony)
    while not (IsCovered(cov_in) and IsCovered(cov_out)) and n < 20000 loop
      if n mod 200 = 199 then
        for i in 7 downto 0 loop
          if H(i) < 0 then send(-2048); else send(2047); end if;
        end loop;
        for i in 7 downto 0 loop
          if H(i) < 0 then send(2047); else send(-2048); end if;
        end loop;
      end if;
      send(RandCovPoint(cov_in));
    end loop;
    wait until falling_edge(clk);
    in_valid <= '0';
    for i in 1 to 8 loop
      wait until falling_edge(clk);
    end loop;

    AffirmIf(IsCovered(cov_in) and IsCovered(cov_out), "pokrycie niepelne");
    AffirmIfEqual(GetPushCount(sb), GetCheckCount(sb), "liczba sprawdzonych wynikow");
    Log("probek: " & integer'image(n) & ", sprawdzonych: " & integer'image(GetCheckCount(sb)), ALWAYS);
    WriteBin(cov_out);
    ReportAlerts;
    check_equal(GetAlertCount, 0, "bledy zgloszone przez OSVVM");
    test_runner_cleanup(runner);
  end process main;

  monitor : process
  begin
    wait until rising_edge(clk);
    if out_valid = '1' then
      Check(sb, to_integer(out_data));
      ICover(cov_out, to_integer(out_data));
    end if;
  end process monitor;

  test_runner_watchdog(runner, 5 ms);
end architecture sim;
