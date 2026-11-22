/* Program dla systemu Nios V na DECA (27.02, 27.03): printf przez JTAG UART, licznik na diodach przez PIO
 * (HAL: IOWR_ALTERA_AVALON_PIO_DATA) i „oddychanie” LED[7] przez własne peryferium pwm_avl ze sterownikiem
 * pwm.h (ten sam kod co w rv_soc) — wypełnienie zmieniane w procedurze obsługi przerwania końca okresu.
 * Nazwy z system.h (generowanego do BSP z pliku .sopcinfo): PWM_BASE, PWM_IRQ, LED_BASE, ALT_CPU_FREQ. */
#include <stdio.h>
#include <stdint.h>
#include "system.h"
#include "sys/alt_irq.h"
#include "altera_avalon_pio_regs.h"
#include "pwm.h"

#define OKRES    50000u              /* 1 kHz przy 50 MHz */
#define KROK     50u                 /* zmiana wypełnienia co okres: pełny cykl jasności 2 s */

static pwm_t pwm;
static volatile uint32_t okresy;     /* volatile: zmieniane w przerwaniu, czytane w pętli głównej */

static void pwm_przerwanie(void *kontekst)
{
    static uint32_t wyp = 0;
    static int kierunek = 1;
    (void)kontekst;
    pwm_koniec_okresu(&pwm);         /* skasuj flagę — inaczej przerwanie (poziomem) wraca od razu */
    if (kierunek > 0) {
        wyp += KROK;
        if (wyp >= OKRES) kierunek = -1;
    } else {
        wyp -= KROK;
        if (wyp == 0) kierunek = 1;
    }
    pwm_ustaw_wypelnienie(&pwm, wyp);
    okresy++;
}

int main(void)
{
    printf("Nios V na DECA: zegar %u Hz, PWM pod 0x%08X, przerwanie %d\n",
           (unsigned)ALT_CPU_FREQ, (unsigned)PWM_BASE, PWM_IRQ);

    pwm_inicjuj(&pwm, PWM_BASE, OKRES, 0);
    alt_ic_isr_register(PWM_IRQ_INTERRUPT_CONTROLLER_ID, PWM_IRQ, pwm_przerwanie, NULL, NULL);
    pwm_wlacz(&pwm, 1);

    uint32_t licznik = 0, ostatnio = 0;
    for (;;) {
        if (okresy - ostatnio >= 500u) {               /* 500 okresów po 1 ms = 0,5 s */
            ostatnio += 500u;
            licznik++;
            IOWR_ALTERA_AVALON_PIO_DATA(LED_BASE, licznik & 0x7Fu);
            if ((licznik & 7u) == 0)
                printf("licznik %lu, okresow PWM %lu\n", (unsigned long)licznik, (unsigned long)okresy);
        }
    }
}
