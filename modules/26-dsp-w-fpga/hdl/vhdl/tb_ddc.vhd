-- Testbench 26.06: ddc. 20000·cos(2π·0,105·n) z ddc_we.hex, nośna 0,1·fs, próbka w każdym takcie; I/Q po
-- decymacji przez 8 bit w bit z ddc_wy.hex i zakres |I + jQ| w stanie ustalonym.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.wektory_pkg.all;

entity tb_ddc is
end entity tb_ddc;

architecture sim of tb_ddc is
  constant XW  : wektor_t := czytaj_hex("ddc_we.hex", 4096, 16);
  constant YW  : wektor_t := czytaj_hex("ddc_wy.hex", 512, 32);
  signal clk     : std_logic := '0';
  signal fin     : boolean := false;
  signal rst     : std_logic := '1';
  signal we      : std_logic := '0';
  signal x       : signed(15 downto 0) := (others => '0');
  signal wi, wq  : signed(15 downto 0);
  signal v       : std_logic;
  signal n, bl   : integer := 0;
  signal amin    : real := 1.0e9;
  signal amax    : real := 0.0;
begin
  clk <= not clk after 5 ns when not fin else clk;
  dut : entity work.ddc port map (clk => clk, rst => rst, we => we, x => x, ftw => x"1999999A",
                                  i_wy => wi, q_wy => wq, wy_wazne => v);

  process (clk)
    variable a : real;
  begin
    if rising_edge(clk) and rst = '0' and v = '1' then
      if std_logic_vector(wi) & std_logic_vector(wq) /= YW(n) then
        if bl < 5 then
          pisz("probka " & integer'image(n) & ": (" & integer'image(to_integer(wi)) & ", "
               & integer'image(to_integer(wq)) & ")");
        end if;
        bl <= bl + 1;
      end if;
      if n >= 16 then
        a := sqrt(real(to_integer(wi)) ** 2 + real(to_integer(wq)) ** 2);
        if a > amax then amax <= a; end if;
        if a < amin then amin <= a; end if;
      end if;
      n <= n + 1;
    end if;
  end process;

  process
  begin
    for i in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    for i in 0 to 4095 loop
      wait until falling_edge(clk);
      x <= signed(XW(i)(15 downto 0)); we <= '1';
    end loop;
    wait until falling_edge(clk);
    we <= '0';
    for i in 1 to 20 loop wait until falling_edge(clk); end loop;
    pisz("ddc: " & integer'image(n) & " probek I/Q, niezgodnych z modelem " & integer'image(bl) & "; |I+jQ| od "
         & integer'image(integer(amin)) & " do " & integer'image(integer(amax)));
    if n = 512 and bl = 0 and amin > 9000.0 and amax < 11000.0 then pisz("PASS");
    else pisz("FAIL: niezgodnosci z modelem albo zla amplituda"); end if;
    fin <= true;
    wait;
  end process;
end architecture sim;
