-- Testbench 26.03: nco (4096 próbek dla czterech ftw z nco_ftw.hex, próbka co drugi takt; sin i cos bit w bit
-- z nco_sin.hex i nco_cos.hex) i sd_dac (liczba jedynek w 65 536 taktach = x + 32 768 ± 1 dla pięciu wartości).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wektory_pkg.all;

entity tb_nco is
end entity tb_nco;

architecture sim of tb_nco is
  constant FW  : wektor_t := czytaj_hex("nco_ftw.hex", 4096, 32);
  constant SW  : wektor_t := czytaj_hex("nco_sin.hex", 4096, 16);
  constant CWY : wektor_t := czytaj_hex("nco_cos.hex", 4096, 16);
  type wart_t is array (0 to 4) of integer;
  constant WART : wart_t := (-32768, -1000, 0, 12345, 32767);
  signal clk     : std_logic := '0';
  signal fin     : boolean := false;
  signal rst     : std_logic := '1';
  signal we      : std_logic := '0';
  signal ftw     : unsigned(31 downto 0) := (others => '0');
  signal s, c    : signed(15 downto 0);
  signal v       : std_logic;
  signal dx      : signed(15 downto 0) := (others => '0');
  signal dq      : std_logic;
  signal n, bsin, bcos, smax : integer := 0;
begin
  clk <= not clk after 5 ns when not fin else clk;
  u_nco : entity work.nco port map (clk => clk, rst => rst, we => we, ftw => ftw, sin_o => s, cos_o => c, wazne => v);
  u_dac : entity work.sd_dac port map (clk => clk, rst => rst, x => dx, q => dq);

  process (clk)
  begin
    if rising_edge(clk) and rst = '0' and v = '1' then
      if std_logic_vector(s) /= SW(n)(15 downto 0) then
        if bsin < 5 then pisz("sin: probka " & integer'image(n) & ": " & integer'image(to_integer(s))); end if;
        bsin <= bsin + 1;
      end if;
      if std_logic_vector(c) /= CWY(n)(15 downto 0) then
        if bcos < 5 then pisz("cos: probka " & integer'image(n) & ": " & integer'image(to_integer(c))); end if;
        bcos <= bcos + 1;
      end if;
      if to_integer(s) > smax then smax <= to_integer(s); end if;
      n <= n + 1;
    end if;
  end process;

  process
    variable jed, bledy : integer := 0;
  begin
    for i in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    for i in 0 to 4095 loop
      wait until falling_edge(clk);
      ftw <= unsigned(FW(i)); we <= '1';
      wait until falling_edge(clk);
      we <= '0';
    end loop;
    for i in 1 to 5 loop wait until falling_edge(clk); end loop;
    pisz("nco: " & integer'image(n) & " probek, niezgodnych sin " & integer'image(bsin) & ", cos "
         & integer'image(bcos) & ", max sin " & integer'image(smax));
    if n /= 4096 or bsin /= 0 or bcos /= 0 then bledy := bledy + 1; end if;
    for k in 0 to 4 loop
      wait until falling_edge(clk);
      dx <= to_signed(WART(k), 16);
      for i in 1 to 100 loop wait until falling_edge(clk); end loop;
      jed := 0;
      for i in 1 to 65536 loop
        wait until falling_edge(clk);
        if dq = '1' then jed := jed + 1; end if;
      end loop;
      pisz("sd_dac: x = " & integer'image(WART(k)) & ": jedynek " & integer'image(jed) & " z 65536 (oczekiwane "
           & integer'image(WART(k) + 32768) & ")");
      if abs(jed - (WART(k) + 32768)) > 1 then bledy := bledy + 1; end if;
    end loop;
    if bledy = 0 then pisz("PASS");
    else pisz("FAIL: " & integer'image(bledy) & " bledow"); end if;
    fin <= true;
    wait;
  end process;
end architecture sim;
