-- DECA — Nios V (27.02, 27.03), VHDL: system_niosv z Platform Designer (make system): Nios V/m, 64 KB pamięci,
-- JTAG UART, PIO na LED(6:0), pwm_avl na LED(7). KEY(0) — reset. Komponent system_niosv musi zgadzać się
-- z portami systemu z system.tcl (README.md); w GHDL pozostaje niepowiązany (sprawdzana jest tylko składnia).
library ieee;
use ieee.std_logic_1164.all;

entity deca_top is
  port (
    MAX10_CLK1_50 : in  std_logic;
    KEY           : in  std_logic_vector(1 downto 0);
    LED           : out std_logic_vector(7 downto 0)
  );
end entity deca_top;

architecture rtl of deca_top is
  component system_niosv is
    port (
      clk_clk       : in  std_logic;
      reset_reset_n : in  std_logic;
      led_export    : out std_logic_vector(6 downto 0);
      pwm_pwm       : out std_logic
    );
  end component;

  signal rs    : std_logic_vector(1 downto 0) := "00";
  signal rst_n : std_logic;
  signal led_s : std_logic_vector(6 downto 0);     -- nazwy różne od portu LED (VHDL nie rozróżnia wielkości liter)
  signal pwm_s : std_logic;
begin
  process (MAX10_CLK1_50, KEY(0))
  begin
    if KEY(0) = '0' then
      rs <= "00";
    elsif rising_edge(MAX10_CLK1_50) then
      rs <= rs(0) & '1';
    end if;
  end process;
  rst_n <= rs(1);

  u_sys : system_niosv
    port map (clk_clk => MAX10_CLK1_50, reset_reset_n => rst_n, led_export => led_s, pwm_pwm => pwm_s);

  LED <= not (pwm_s & led_s);
end architecture rtl;
