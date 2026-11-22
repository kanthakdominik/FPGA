-- Test integracyjny (30.01), VHDL: te same sprawdzenia co tb_pwm_regs.v — wyłącznie stałe z wygenerowanego
-- pakietu pwm_avl_regs_pkg, sprzęt: pwm_avl z modułu 27.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.pwm_avl_regs_pkg.all;

entity tb_pwm_regs is
end entity tb_pwm_regs;

architecture sim of tb_pwm_regs is
  signal clk       : std_logic := '0';
  signal fin       : boolean := false;
  signal rst       : std_logic := '1';
  signal address   : std_logic_vector(1 downto 0) := "00";
  signal av_read   : std_logic := '0';
  signal av_write  : std_logic := '0';
  signal writedata : std_logic_vector(31 downto 0) := (others => '0');
  signal readdata  : std_logic_vector(31 downto 0);
  signal irq, pwm  : std_logic;

  procedure pisz(s : string) is
    variable l : line;
  begin
    write(l, s);
    writeline(output, l);
  end procedure;

  function adr(off : natural) return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned(off, PWM_AVL_BITY_ADRESU));
  end function;

  function bit_na(poz : natural) return std_logic_vector is
    variable v : std_logic_vector(31 downto 0) := (others => '0');
  begin
    v(poz) := '1';
    return v;
  end function;
begin
  clk <= not clk after 5 ns when not fin else clk;
  dut : entity work.pwm_avl
    port map (clk => clk, rst => rst, address => address, read => av_read, write => av_write, writedata => writedata,
              readdata => readdata, irq => irq, pwm => pwm);

  process
    variable bledy, wysokie : integer := 0;
    variable v : std_logic_vector(31 downto 0);

    procedure zapisz(off : natural; d : std_logic_vector(31 downto 0)) is
    begin
      wait until falling_edge(clk);
      address <= adr(off); writedata <= d; av_write <= '1';
      wait until falling_edge(clk);
      av_write <= '0';
    end procedure;
    procedure czytaj(off : natural) is
    begin
      wait until falling_edge(clk);
      address <= adr(off); av_read <= '1';
      wait until falling_edge(clk);
      av_read <= '0'; v := readdata;
    end procedure;
    procedure oczekuj(off : natural; wart : std_logic_vector(31 downto 0); co : string) is
    begin
      czytaj(off);
      if v /= wart then
        pisz("FAIL: " & co);
        bledy := bledy + 1;
      end if;
    end procedure;
  begin
    for i in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    oczekuj(PWM_AVL_STER_OFF, PWM_AVL_STER_RESET, "STER po resecie");
    oczekuj(PWM_AVL_OKRES_OFF, PWM_AVL_OKRES_RESET, "OKRES po resecie");
    oczekuj(PWM_AVL_WYPELN_OFF, PWM_AVL_WYPELN_RESET, "WYPELN po resecie");
    oczekuj(PWM_AVL_STATUS_OFF, PWM_AVL_STATUS_RESET, "STATUS po resecie");
    zapisz(PWM_AVL_OKRES_OFF, std_logic_vector(to_unsigned(10, 32)));
    zapisz(PWM_AVL_WYPELN_OFF, std_logic_vector(to_unsigned(3, 32)));
    oczekuj(PWM_AVL_OKRES_OFF, std_logic_vector(to_unsigned(10, 32)), "OKRES");
    oczekuj(PWM_AVL_WYPELN_OFF, std_logic_vector(to_unsigned(3, 32)), "WYPELN");
    zapisz(PWM_AVL_STER_OFF, bit_na(PWM_AVL_STER_WL_POZ));
    for i in 1 to 100 loop
      wait until rising_edge(clk);
      if pwm = '1' then wysokie := wysokie + 1; end if;
    end loop;
    if wysokie /= 30 then
      pisz("FAIL: " & integer'image(wysokie) & " taktow stanu wysokiego na 100 (oczekiwane 30)");
      bledy := bledy + 1;
    end if;
    czytaj(PWM_AVL_STATUS_OFF);
    if v(PWM_AVL_STATUS_KONIEC_POZ) /= '1' or irq = '1' then
      pisz("FAIL: KONIEC nie ustawiony albo przerwanie bez PRZ"); bledy := bledy + 1;
    end if;
    zapisz(PWM_AVL_STER_OFF, bit_na(PWM_AVL_STER_WL_POZ) or bit_na(PWM_AVL_STER_PRZ_POZ));
    wait until falling_edge(clk);
    if irq /= '1' then pisz("FAIL: brak przerwania przy KONIEC i PRZ"); bledy := bledy + 1; end if;
    zapisz(PWM_AVL_STER_OFF, bit_na(PWM_AVL_STER_PRZ_POZ));
    zapisz(PWM_AVL_STATUS_OFF, bit_na(PWM_AVL_STATUS_KONIEC_POZ));
    wait until falling_edge(clk);
    if irq = '1' then pisz("FAIL: zapis 1 do KONIEC nie skasowal przerwania"); bledy := bledy + 1; end if;
    czytaj(PWM_AVL_STATUS_OFF);
    if v(PWM_AVL_STATUS_KONIEC_POZ) = '1' or v(PWM_AVL_STATUS_WYJSCIE_POZ) = '1' then
      pisz("FAIL: STATUS po skasowaniu i wylaczeniu"); bledy := bledy + 1;
    end if;
    pisz("mapa rejestrow z opisu JSON zgodna z pwm_avl: reset 4/4, zapis/odczyt, " & integer'image(wysokie)
         & "/100 taktow wysokich, W1C i przerwanie");
    if bledy = 0 then pisz("PASS"); else pisz("FAIL: " & integer'image(bledy) & " bledow"); end if;
    fin <= true;
    wait;
  end process;
end architecture sim;
