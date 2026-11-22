-- WYGENEROWANE przez narzedzia/rejestry.py z rejestry/pwm_avl.json — nie edytuj ręcznie
-- Peryferium PWM ze slave'em Avalon-MM (moduł 27, 27.03), wersja opisu 1.0.0.
library ieee;
use ieee.std_logic_1164.all;

package pwm_avl_regs_pkg is
  constant PWM_AVL_SZEROKOSC : natural := 32;
  constant PWM_AVL_BITY_ADRESU : natural := 2;
  -- STER — Sterowanie
  constant PWM_AVL_STER_OFF : natural := 0;
  constant PWM_AVL_STER_RESET : std_logic_vector(31 downto 0) := x"00000000";
  constant PWM_AVL_STER_WL_POZ : natural := 0;
  constant PWM_AVL_STER_WL_SZER : natural := 1;
  constant PWM_AVL_STER_PRZ_POZ : natural := 1;
  constant PWM_AVL_STER_PRZ_SZER : natural := 1;
  -- OKRES — Długość okresu w taktach (≥ 2), obowiązuje od następnego okresu
  constant PWM_AVL_OKRES_OFF : natural := 1;
  constant PWM_AVL_OKRES_RESET : std_logic_vector(31 downto 0) := x"00000000";
  -- WYPELN — Takty stanu wysokiego (0 — stale 0, ≥ OKRES — stale 1), od następnego okresu
  constant PWM_AVL_WYPELN_OFF : natural := 2;
  constant PWM_AVL_WYPELN_RESET : std_logic_vector(31 downto 0) := x"00000000";
  -- STATUS — Stan; przerwanie = KONIEC & PRZ
  constant PWM_AVL_STATUS_OFF : natural := 3;
  constant PWM_AVL_STATUS_RESET : std_logic_vector(31 downto 0) := x"00000000";
  constant PWM_AVL_STATUS_KONIEC_POZ : natural := 0;
  constant PWM_AVL_STATUS_KONIEC_SZER : natural := 1;
  constant PWM_AVL_STATUS_WYJSCIE_POZ : natural := 1;
  constant PWM_AVL_STATUS_WYJSCIE_SZER : natural := 1;
end package pwm_avl_regs_pkg;
