/* WYGENEROWANE przez narzedzia/rejestry.py z rejestry/pwm_avl.json — nie edytuj ręcznie
 * Peryferium PWM ze slave'em Avalon-MM (moduł 27, 27.03), wersja opisu 1.0.0.
 * _OFF — numer słowa (adresowanie słowami w komponencie), _BAJT — przesunięcie w bajtach od adresu
 * bazowego, _POZ — pozycja najmłodszego bitu pola, _MASKA — maska pola w słowie. */
#ifndef PWM_AVL_REGS_H
#define PWM_AVL_REGS_H

/* STER — Sterowanie */
#define PWM_AVL_STER_OFF 0u
#define PWM_AVL_STER_BAJT 0x0u
#define PWM_AVL_STER_RESET 0x00000000u
#define PWM_AVL_STER_WL_POZ 0u
#define PWM_AVL_STER_WL_MASKA 0x00000001u  /* RW: włączenie generatora */
#define PWM_AVL_STER_PRZ_POZ 1u
#define PWM_AVL_STER_PRZ_MASKA 0x00000002u  /* RW: zezwolenie na przerwanie */

/* OKRES — Długość okresu w taktach (≥ 2), obowiązuje od następnego okresu */
#define PWM_AVL_OKRES_OFF 1u
#define PWM_AVL_OKRES_BAJT 0x4u
#define PWM_AVL_OKRES_RESET 0x00000000u

/* WYPELN — Takty stanu wysokiego (0 — stale 0, ≥ OKRES — stale 1), od następnego okresu */
#define PWM_AVL_WYPELN_OFF 2u
#define PWM_AVL_WYPELN_BAJT 0x8u
#define PWM_AVL_WYPELN_RESET 0x00000000u

/* STATUS — Stan; przerwanie = KONIEC & PRZ */
#define PWM_AVL_STATUS_OFF 3u
#define PWM_AVL_STATUS_BAJT 0xCu
#define PWM_AVL_STATUS_RESET 0x00000000u
#define PWM_AVL_STATUS_KONIEC_POZ 0u
#define PWM_AVL_STATUS_KONIEC_MASKA 0x00000001u  /* W1C: koniec okresu, zapis 1 kasuje */
#define PWM_AVL_STATUS_WYJSCIE_POZ 1u
#define PWM_AVL_STATUS_WYJSCIE_MASKA 0x00000002u  /* RO: bieżący stan wyjścia PWM */

#endif /* PWM_AVL_REGS_H */
