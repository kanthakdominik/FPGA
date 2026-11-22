/* Sterownik peryferium pwm_avl (27.03) — implementacja. Bez zależności od HAL: adres bazowy podaje program
 * (w Nios V z system.h: PWM_0_BASE; w rv_soc: 0x10000100). */
#include "pwm.h"

void pwm_inicjuj(pwm_t *p, uintptr_t adres_bazowy, uint32_t okres, uint32_t wypelnienie)
{
    p->baza = (volatile uint32_t *)adres_bazowy;
    pwm_zapisz(p, PWM_STER, 0);                       /* wyłączony: nowe wartości obowiązują od razu */
    pwm_zapisz(p, PWM_OKRES, okres);
    pwm_zapisz(p, PWM_WYPELN, wypelnienie);
    pwm_zapisz(p, PWM_STATUS, PWM_STATUS_KONIEC);     /* skasuj starą flagę */
}

void pwm_ustaw_wypelnienie(const pwm_t *p, uint32_t wypelnienie)
{
    pwm_zapisz(p, PWM_WYPELN, wypelnienie);           /* zadziała od początku następnego okresu */
}

void pwm_wlacz(const pwm_t *p, int z_przerwaniem)
{
    pwm_zapisz(p, PWM_STER, PWM_STER_WL | (z_przerwaniem ? PWM_STER_PRZ : 0u));
}

void pwm_wylacz(const pwm_t *p)
{
    pwm_zapisz(p, PWM_STER, 0);
}

int pwm_koniec_okresu(const pwm_t *p)
{
    if (pwm_czytaj(p, PWM_STATUS) & PWM_STATUS_KONIEC) {
        pwm_zapisz(p, PWM_STATUS, PWM_STATUS_KONIEC); /* W1C: zapis 1 kasuje tylko ten bit */
        return 1;
    }
    return 0;
}

void pwm_czekaj_na_okres(const pwm_t *p)
{
    while (!pwm_koniec_okresu(p))
        ;
}
