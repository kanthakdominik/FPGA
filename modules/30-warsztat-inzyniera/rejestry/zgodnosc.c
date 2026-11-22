/* Zgodność wygenerowanego nagłówka z ręcznie napisanym sterownikiem modułu 27 (30.01) — sprawdzana przez
 * kompilator: gcc -std=c11 -Wall -Werror -fsyntax-only -I wygenerowane -I ../../27-procesory-i-soc/program/c */
#include "pwm_avl_regs.h"
#include "pwm.h"

_Static_assert(PWM_AVL_STER_OFF == PWM_STER, "STER");
_Static_assert(PWM_AVL_OKRES_OFF == PWM_OKRES, "OKRES");
_Static_assert(PWM_AVL_WYPELN_OFF == PWM_WYPELN, "WYPELN");
_Static_assert(PWM_AVL_STATUS_OFF == PWM_STATUS, "STATUS");
_Static_assert(PWM_AVL_STER_WL_MASKA == PWM_STER_WL, "STER.WL");
_Static_assert(PWM_AVL_STER_PRZ_MASKA == PWM_STER_PRZ, "STER.PRZ");
_Static_assert(PWM_AVL_STATUS_KONIEC_MASKA == PWM_STATUS_KONIEC, "STATUS.KONIEC");
_Static_assert(PWM_AVL_STATUS_WYJSCIE_MASKA == PWM_STATUS_WYJSCIE, "STATUS.WYJSCIE");
_Static_assert(PWM_AVL_STATUS_BAJT == 4u * PWM_STATUS, "adres bajtowy");
