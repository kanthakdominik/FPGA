-- DECA — projekt 6 (31.06), VHDL: rv_mcu z programem mcu.S (RAM inicjowany przez atrybut ram_init_file:
-- mcu_deca.mif), UART na GPIO0_D, LED — licznik i PWM. Opis jak w deca_top.v.
library ieee;
use ieee.std_logic_1164.all;

entity deca_top is
  port (
    MAX10_CLK1_50 : in    std_logic;
    KEY           : in    std_logic_vector(1 downto 0);
    SW            : in    std_logic_vector(1 downto 0);
    LED           : out   std_logic_vector(7 downto 0);
    GPIO0_D       : inout std_logic_vector(1 downto 0)
  );
end entity deca_top;

architecture rtl of deca_top is
  signal rs     : std_logic_vector(1 downto 0) := "11";
  signal s1, s2 : std_logic_vector(3 downto 0) := x"F";
  signal led_r, wej : std_logic_vector(31 downto 0);
  signal tx_s, pwm_s : std_logic;
begin
  process (MAX10_CLK1_50)
  begin
    if rising_edge(MAX10_CLK1_50) then
      rs <= rs(0) & not KEY(0);
      s1 <= SW & KEY;
      s2 <= s1;
    end if;
  end process;
  wej <= x"0000000" & s2;
  u_mcu : entity work.rv_mcu
    generic map (SLOWA => 1024, PLIK => "", PLIK_MIF => "mcu_deca.mif", CLK_HZ => 50_000_000, BAUD => 115_200)
    port map (clk => MAX10_CLK1_50, rst => rs(1), wej => wej, led => led_r, uart_rx => GPIO0_D(1),
              uart_tx => tx_s, pwm_wy => pwm_s, koniec => open, wycofana => open);
  GPIO0_D(0) <= tx_s;
  GPIO0_D(1) <= 'Z';
  LED <= not (pwm_s & led_r(6 downto 0));
end architecture rtl;
