-- DECA — własny SoC RISC-V (27.07): rv_soc z rdzeniem potokowym, 8 KB pamięci z programem deca.S (w Quartusie
-- przez atrybut ram_init_file: deca_prog.mif), rejestry systemowe i pwm_avl. Zegar 50 MHz.
--   LED(6:0) — rejestr LED programu, LED(7) — PWM; SW(0) — tryb, SW(1) — stop, KEY(1) — zerowanie, KEY(0) — reset.
library ieee;
use ieee.std_logic_1164.all;

entity deca_top is
  port (
    MAX10_CLK1_50 : in  std_logic;
    KEY           : in  std_logic_vector(1 downto 0);
    SW            : in  std_logic_vector(1 downto 0);
    LED           : out std_logic_vector(7 downto 0)
  );
end entity deca_top;

architecture rtl of deca_top is
  signal rs     : std_logic_vector(1 downto 0) := "11";
  signal s1, s2 : std_logic_vector(3 downto 0) := x"F";
  signal led_r  : std_logic_vector(31 downto 0);
  signal pwm_wy : std_logic;
  signal wej    : std_logic_vector(31 downto 0);
begin
  process (MAX10_CLK1_50)
  begin
    if rising_edge(MAX10_CLK1_50) then
      rs <= rs(0) & not KEY(0);
      s1 <= SW & KEY;
      s2 <= s1;
    end if;
  end process;

  wej <= x"000000" & "0000" & s2;
  u_soc : entity work.rv_soc
    generic map (SLOWA => 2048, PLIK => "", PLIK_MIF => "deca_prog.mif")
    port map (clk => MAX10_CLK1_50, rst => rs(1), wej => wej, led => led_r, pwm_wy => pwm_wy, pwm_irq => open,
              koniec => open, znak => open, znak_wazny => open, wycofana => open,
              mon_adr => open, mon_dane => open, mon_strb => open);

  LED <= not (pwm_wy & led_r(6 downto 0));
end architecture rtl;
