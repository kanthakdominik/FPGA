-- Testbench 26.05: fft64. Trzy ramki po 64 próbki zespolone z fft_we.hex (impuls, ton w prążku 5, szum);
-- wyniki w kolejności naturalnej bit w bit z fft_wy.hex, opóźnienie i prążek o największym module.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wektory_pkg.all;

entity tb_fft is
end entity tb_fft;

architecture sim of tb_fft is
  constant XW  : wektor_t := czytaj_hex("fft_we.hex", 192, 32);
  constant YW  : wektor_t := czytaj_hex("fft_wy.hex", 192, 32);
  signal clk     : std_logic := '0';
  signal fin     : boolean := false;
  signal rst     : std_logic := '1';
  signal we      : std_logic := '0';
  signal xr, xi  : signed(15 downto 0) := (others => '0');
  signal yr, yi  : signed(15 downto 0);
  signal gotowy, v : std_logic;
  signal takt, t_kon, lat, n, bl, maks, prazek : integer := 0;
begin
  clk  <= not clk after 5 ns when not fin else clk;
  takt <= takt + 1 when rising_edge(clk);
  dut : entity work.fft64 port map (clk => clk, rst => rst, we => we, xr => xr, xi => xi, gotowy => gotowy,
                                    yr => yr, yi => yi, wy_wazne => v);

  process (clk)
    variable m : integer;
  begin
    if rising_edge(clk) and rst = '0' and v = '1' then
      if std_logic_vector(yr) & std_logic_vector(yi) /= YW(n) then
        if bl < 5 then
          pisz("wynik " & integer'image(n) & ": (" & integer'image(to_integer(yr)) & ", "
               & integer'image(to_integer(yi)) & ")");
        end if;
        bl <= bl + 1;
      end if;
      if n = 0 then lat <= takt - t_kon; end if;
      if n >= 64 and n < 128 then
        m := to_integer(yr) * to_integer(yr) + to_integer(yi) * to_integer(yi);
        if m > maks then maks <= m; prazek <= n - 64; end if;
      end if;
      n <= n + 1;
    end if;
  end process;

  process
  begin
    for i in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    for f in 0 to 2 loop
      while gotowy /= '1' loop wait until falling_edge(clk); end loop;
      for i in 0 to 63 loop
        wait until falling_edge(clk);
        xr <= signed(XW(64 * f + i)(31 downto 16)); xi <= signed(XW(64 * f + i)(15 downto 0)); we <= '1';
      end loop;
      wait until falling_edge(clk);
      we <= '0';
      if f = 0 then t_kon <= takt; end if;
      wait until falling_edge(clk);
    end loop;
    while n < 192 loop wait until falling_edge(clk); end loop;
    for i in 1 to 5 loop wait until falling_edge(clk); end loop;
    pisz("fft64: 3 ramki, " & integer'image(n) & " wynikow, niezgodnych z modelem " & integer'image(bl));
    pisz("od ostatniej probki do pierwszego wyniku: " & integer'image(lat) & " taktow; ton: najwiekszy prazek "
         & integer'image(prazek));
    if n = 192 and bl = 0 and prazek = 5 then pisz("PASS");
    else pisz("FAIL: niezgodnosci z modelem"); end if;
    fin <= true;
    wait;
  end process;
end architecture sim;
