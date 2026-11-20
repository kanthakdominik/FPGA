-- Moduł nadrzędny DECA - VHDL. Rejestry kursu (21.02) w systemie Platform Designer (21.06):
-- JTAG to Avalon Master Bridge -> avmm_rejestry, dostęp z komputera skryptem System Console (konsola.tcl).
--   LED(6 downto 0) - STER(6 downto 0), LED(7) - irq; STAN = (SW, KEY); zdarzenie 0 - naciśnięcie KEY(1).
--   KEY(0) - reset systemu. Komponent system_rej musi zgadzać się z portami systemu z system.tcl (README.md).
library ieee;
use ieee.std_logic_1164.all;

entity deca_top is
  port (
    MAX10_CLK1_50 : in  std_logic;
    KEY           : in  std_logic_vector(1 downto 0);
    SW            : in  std_logic_vector(1 downto 0);
    LED           : out std_logic_vector(7 downto 0)   -- '0' = świeci
  );
end entity deca_top;

architecture rtl of deca_top is
  component system_rej
    port (
      clk_clk       : in  std_logic;
      reset_reset_n : in  std_logic;
      uklad_ster    : out std_logic_vector(31 downto 0);
      uklad_stan    : in  std_logic_vector(31 downto 0);
      uklad_zdarz   : in  std_logic_vector(7 downto 0);
      uklad_irq     : out std_logic
    );
  end component;

  signal clk, rst_n, nacisk, irq : std_logic;
  signal rs          : std_logic_vector(1 downto 0) := "00";
  signal s_we, s_we2 : std_logic_vector(3 downto 0) := "1111";
  signal ster, stan  : std_logic_vector(31 downto 0);
  signal zdarz       : std_logic_vector(7 downto 0);
  attribute altera_attribute : string;
  attribute altera_attribute of s_we : signal is "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS";
begin
  clk <= MAX10_CLK1_50;

  process (clk, KEY)
  begin
    if KEY(0) = '0' then
      rs <= "00";
    elsif rising_edge(clk) then
      rs <= rs(0) & '1';
    end if;
  end process;
  rst_n <= rs(1);

  process (clk)
  begin
    if rising_edge(clk) then
      s_we  <= SW & KEY;
      s_we2 <= s_we;
    end if;
  end process;
  nacisk <= s_we2(1) and not s_we(1);

  stan  <= (31 downto 4 => '0') & s_we;
  zdarz <= (7 downto 1 => '0') & nacisk;

  u_sys : system_rej
    port map (clk_clk => clk, reset_reset_n => rst_n, uklad_ster => ster, uklad_stan => stan,
              uklad_zdarz => zdarz, uklad_irq => irq);

  LED <= not (irq & ster(6 downto 0));
end architecture rtl;
