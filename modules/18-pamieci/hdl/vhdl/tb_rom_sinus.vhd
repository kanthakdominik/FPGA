-- Testbench rom_sinus: 256 adresów porównanych z wartością liczoną w testbenchu (sin z ieee.math_real),
-- tolerancja ±1; en = '0' trzyma wyjście. Plik sinus.hex kopiuje do katalogu symulacji run_hdl_tests.py.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_rom_sinus is
end entity tb_rom_sinus;

architecture sim of tb_rom_sinus is
  signal clk  : std_logic := '0';
  signal en   : std_logic := '0';
  signal addr : std_logic_vector(7 downto 0) := (others => '0');
  signal dout : std_logic_vector(7 downto 0);
  signal fin  : boolean := false;
begin
  clk <= not clk after 5 ns when not fin else clk;
  dut : entity work.rom_sinus generic map (W => 8, AW => 8, PLIK => "sinus.hex", PLIK_MIF => "sinus.mif")
    port map (clk => clk, en => en, addr => addr, dout => dout);

  process
    variable l : line;
    variable oczek, v, errors : integer := 0;
  begin
    for k in 0 to 255 loop
      wait until falling_edge(clk);
      en <= '1'; addr <= std_logic_vector(to_unsigned(k, 8));
      wait until rising_edge(clk);
      wait for 1 ns;
      oczek := integer(floor(127.5 + 127.5 * sin(MATH_2_PI * real(k) / 256.0) + 0.5));
      v := to_integer(unsigned(dout));
      if v < oczek - 1 or v > oczek + 1 then
        write(l, "adres " & integer'image(k) & ": " & integer'image(v) & ", oczekiwano " & integer'image(oczek));
        writeline(output, l);
        errors := errors + 1;
      end if;
    end loop;
    wait until falling_edge(clk);
    en <= '0'; addr <= (others => '0');
    wait until rising_edge(clk);
    wait for 1 ns;
    if to_integer(unsigned(dout)) /= 124 then
      write(l, string'("en = '0' nie trzyma wyjscia")); writeline(output, l);
      errors := errors + 1;
    end if;
    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
