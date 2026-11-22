-- Testbench 27.07: rv_soc z rdzeniem potokowym, pamięcią blokową, rejestrami systemowymi i pwm_avl. Ten sam
-- program i wzorzec co tb_rv_jedno (porty mon_*), CPI potoku, tekst z rejestru KONSOLA, LED = 0x55.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rv_tb_pkg.all;

entity tb_rv_soc is
end entity tb_rv_soc;

architecture sim of tb_rv_soc is
  constant WZOR   : zapisy_t := czytaj_zapisy("test_zapisy.hex", 1024);
  constant LICZBY : slowa_t  := czytaj_slowa("test_liczby.hex", 2);
  signal clk      : std_logic := '0';
  signal fin      : boolean := false;
  signal rst      : std_logic := '1';
  signal led, mon_adr, mon_dane : std_logic_vector(31 downto 0);
  signal mon_strb : std_logic_vector(3 downto 0);
  signal pwm_wy, pwm_irq, koniec, znak_wazny, wycofana : std_logic;
  signal znak     : std_logic_vector(7 downto 0);
  signal stop, stop2 : boolean := false;
  signal k, takty, instr, bl : integer := 0;
  signal konsola  : string(1 to 64) := (others => ' ');
  signal dl       : natural := 0;
begin
  clk <= not clk after 5 ns when not fin else clk;
  dut : entity work.rv_soc generic map (SLOWA => 2048, PLIK => "test_prog.hex")
    port map (clk => clk, rst => rst, wej => x"0000000F", led => led, pwm_wy => pwm_wy, pwm_irq => pwm_irq,
              koniec => koniec, znak => znak, znak_wazny => znak_wazny, wycofana => wycofana,
              mon_adr => mon_adr, mon_dane => mon_dane, mon_strb => mon_strb);

  process (clk)
    variable maska : std_logic_vector(31 downto 0);
    variable jest  : std_logic_vector(67 downto 0);
  begin
    if rising_edge(clk) and rst = '0' and not stop2 then
      if stop then stop2 <= true; end if;
      takty <= takty + 1;
      if wycofana = '1' then instr <= instr + 1; end if;
      if znak_wazny = '1' and dl < 64 then
        konsola(dl + 1) <= character'val(to_integer(unsigned(znak)));
        dl <= dl + 1;
      end if;
      if mon_strb /= "0000" then
        for b in 0 to 3 loop
          maska(8 * b + 7 downto 8 * b) := (others => mon_strb(b));
        end loop;
        jest := mon_adr & (mon_dane and maska) & mon_strb;
        if jest /= WZOR(k) then
          if bl < 5 then
            pisz("zapis " & integer'image(k) & ": " & hex(jest) & ", ISS: " & hex(WZOR(k)));
          end if;
          bl <= bl + 1;
        end if;
        k <= k + 1;
        if mon_adr = x"10000008" then stop <= true; end if;
      end if;
    end if;
  end process;

  process
    variable n : integer := 0;
  begin
    for i in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    while not stop and n < 100000 loop
      wait until falling_edge(clk);
      n := n + 1;
    end loop;
    for i in 1 to 4 loop wait until falling_edge(clk); end loop;
    pisz("konsola: " & konsola(1 to dl));
    pisz("LED = " & hex(led));
    pisz("rv_potok: zapisow " & integer'image(k) & " (ISS " & integer'image(to_integer(unsigned(LICZBY(0))))
         & "), niezgodnych " & integer'image(bl) & "; instrukcji " & integer'image(instr) & " (ISS "
         & integer'image(to_integer(unsigned(LICZBY(1)))) & "), taktow " & integer'image(takty));
    if stop and k = to_integer(unsigned(LICZBY(0))) and bl = 0 and instr = to_integer(unsigned(LICZBY(1)))
       and led = x"00000055" then
      pisz("PASS");
    else
      pisz("FAIL: niezgodnosc z ISS");
    end if;
    fin <= true;
    wait;
  end process;
end architecture sim;
