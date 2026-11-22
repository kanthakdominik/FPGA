-- Testbench 27.07: rv_jedno z idealną pamięcią 8 KB (odczyt kombinacyjny) i rejestrami we/wy przechowującymi
-- zapisane wartości. Program test.S; k-ty zapis rdzenia = k-ty zapis ISS (test_zapisy.hex), liczba
-- wycofanych instrukcji jak w ISS; koniec po zapisie pod TOHOST.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv_tb_pkg.all;

entity tb_rv_jedno is
end entity tb_rv_jedno;

architecture sim of tb_rv_jedno is
  constant WZOR   : zapisy_t := czytaj_zapisy("test_zapisy.hex", 1024);
  constant LICZBY : slowa_t  := czytaj_slowa("test_liczby.hex", 2);
  signal pam      : slowa_t(0 to 2047) := czytaj_slowa("test_prog.hex", 2048);
  signal io       : slowa_t(0 to 127) := (others => (others => '0'));
  signal clk      : std_logic := '0';
  signal fin      : boolean := false;
  signal rst      : std_logic := '1';
  signal i_adr, i_dane, d_adr, d_wdane, d_rdane : std_logic_vector(31 downto 0);
  signal d_wstrb  : std_logic_vector(3 downto 0);
  signal d_odczyt, wycofana : std_logic;
  signal koniec   : boolean := false;
  signal k, takty, instr, bl : integer := 0;
begin
  clk <= not clk after 5 ns when not fin else clk;
  i_dane  <= pam(to_integer(unsigned(i_adr(12 downto 2))));
  d_rdane <= pam(to_integer(unsigned(d_adr(12 downto 2)))) when d_adr(31 downto 28) = x"0"
             else io(to_integer(unsigned(d_adr(8 downto 2))));
  dut : entity work.rv_jedno port map (clk => clk, rst => rst, i_adr => i_adr, i_dane => i_dane, d_adr => d_adr,
    d_wdane => d_wdane, d_wstrb => d_wstrb, d_odczyt => d_odczyt, d_rdane => d_rdane, wycofana => wycofana);

  process (clk)
    variable maska : std_logic_vector(31 downto 0);
    variable jest  : std_logic_vector(67 downto 0);
  begin
    if rising_edge(clk) and rst = '0' and not koniec then
      takty <= takty + 1;
      if wycofana = '1' then instr <= instr + 1; end if;
      if d_wstrb /= "0000" then
        for b in 0 to 3 loop
          maska(8 * b + 7 downto 8 * b) := (others => d_wstrb(b));
        end loop;
        jest := d_adr & (d_wdane and maska) & d_wstrb;
        if jest /= WZOR(k) then
          if bl < 5 then
            pisz("zapis " & integer'image(k) & ": " & hex(jest) & ", ISS: " & hex(WZOR(k)));
          end if;
          bl <= bl + 1;
        end if;
        k <= k + 1;
        if d_adr(31 downto 28) = x"0" then
          for b in 0 to 3 loop
            if d_wstrb(b) = '1' then
              pam(to_integer(unsigned(d_adr(12 downto 2))))(8 * b + 7 downto 8 * b) <= d_wdane(8 * b + 7 downto 8 * b);
            end if;
          end loop;
        else
          io(to_integer(unsigned(d_adr(8 downto 2)))) <=
            (io(to_integer(unsigned(d_adr(8 downto 2)))) and not maska) or (d_wdane and maska);
          if d_adr = x"10000008" then koniec <= true; end if;
        end if;
      end if;
    end if;
  end process;

  process
    variable n : integer := 0;
  begin
    for i in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    while not koniec and n < 100000 loop
      wait until falling_edge(clk);
      n := n + 1;
    end loop;
    pisz("rv_jedno: zapisow " & integer'image(k) & " (ISS " & integer'image(to_integer(unsigned(LICZBY(0))))
         & "), niezgodnych " & integer'image(bl) & "; instrukcji " & integer'image(instr) & " (ISS "
         & integer'image(to_integer(unsigned(LICZBY(1)))) & "), taktow " & integer'image(takty));
    if koniec and k = to_integer(unsigned(LICZBY(0))) and bl = 0 and instr = to_integer(unsigned(LICZBY(1))) then
      pisz("PASS");
    else
      pisz("FAIL: niezgodnosc z ISS");
    end if;
    fin <= true;
    wait;
  end process;
end architecture sim;
