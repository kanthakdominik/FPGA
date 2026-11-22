/* Sterownik peryferium pwm_avl (27.03) — wspólny dla własnego SoC (rv_soc) i systemu Nios V.
 * Rejestry 32-bitowe pod kolejnymi słowami od adresu bazowego (Avalon-MM, adresowanie słowami w komponencie,
 * bajtami po stronie procesora):
 *   0 STER    bit 0 WL (włączenie), bit 1 PRZ (zezwolenie na przerwanie)
 *   1 OKRES   długość okresu w taktach zegara peryferium (≥ 2)
 *   2 WYPELN  liczba taktów stanu wysokiego (0 — stale 0, ≥ OKRES — stale 1)
 *   3 STATUS  bit 0 KONIEC (zapis 1 kasuje), bit 1 bieżący stan wyjścia
 * Nowe OKRES i WYPELN działają od następnego okresu. Dostęp tylko 32-bitowy. */
#ifndef PWM_H
#define PWM_H

#include <stdint.h>

#define PWM_STER            0u
#define PWM_OKRES           1u
#define PWM_WYPELN          2u
#define PWM_STATUS          3u

#define PWM_STER_WL         (1u << 0)
#define PWM_STER_PRZ        (1u << 1)
#define PWM_STATUS_KONIEC   (1u << 0)
#define PWM_STATUS_WYJSCIE  (1u << 1)

typedef struct {
    volatile uint32_t *baza;     /* volatile: każdy dostęp to prawdziwy odczyt/zapis magistrali */
} pwm_t;

static inline void pwm_zapisz(const pwm_t *p, unsigned rej, uint32_t v) { p->baza[rej] = v; }
static inline uint32_t pwm_czytaj(const pwm_t *p, unsigned rej) { return p->baza[rej]; }

void pwm_inicjuj(pwm_t *p, uintptr_t adres_bazowy, uint32_t okres, uint32_t wypelnienie);
void pwm_ustaw_wypelnienie(const pwm_t *p, uint32_t wypelnienie);
void pwm_wlacz(const pwm_t *p, int z_przerwaniem);
void pwm_wylacz(const pwm_t *p);
int  pwm_koniec_okresu(const pwm_t *p);      /* 1, jeśli minął okres — flaga zostaje skasowana */
void pwm_czekaj_na_okres(const pwm_t *p);    /* aktywne czekanie na koniec okresu */

#endif
