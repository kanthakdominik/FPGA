/* Program w C dla własnego SoC rv_soc (27.03, 27.07): konsola (rejestr KONSOLA), CRC-32 z wartością
 * kontrolną "123456789" -> 0xCBF43926 i sterownik pwm.h — trzy okresy PWM mierzone licznikiem taktów.
 * Kompilacja: make (gcc RISC-V, -march=rv32i -mabi=ilp32), symulacja: make sym. Wynik main() trafia pod TOHOST. */
#include <stdint.h>
#include "pwm.h"

#define IO_BAZA   0x10000000u
#define LED       (*(volatile uint32_t *)(IO_BAZA + 0x00u))
#define TAKTY     (*(volatile uint32_t *)(IO_BAZA + 0x04u))
#define KONSOLA   (*(volatile uint32_t *)(IO_BAZA + 0x0Cu))
#define PWM_BAZA  (IO_BAZA + 0x100u)

static void pisz_znak(char c) { KONSOLA = (uint8_t)c; }

static void pisz(const char *s)
{
    while (*s)
        pisz_znak(*s++);
}

static void pisz_hex(uint32_t v)
{
    for (int i = 28; i >= 0; i -= 4) {
        uint32_t c = (v >> i) & 0xFu;
        pisz_znak((char)(c < 10u ? '0' + c : 'A' + c - 10u));
    }
}

static uint32_t crc32(const uint8_t *d, uint32_t n)
{
    uint32_t c = 0xFFFFFFFFu;
    while (n--) {
        c ^= *d++;
        for (int k = 0; k < 8; k++)
            c = (c >> 1) ^ (0xEDB88320u & (0u - (c & 1u)));
    }
    return ~c;
}

int main(void)
{
    static const char wzor[] = "123456789";
    int bledy = 0;

    pisz("C na rv_soc\n");
    uint32_t c = crc32((const uint8_t *)wzor, 9);
    pisz("CRC32 = ");
    pisz_hex(c);
    if (c == 0xCBF43926u) {
        pisz(" OK\n");
    } else {
        pisz(" BLAD\n");
        bledy++;
    }

    pwm_t pwm;
    pwm_inicjuj(&pwm, PWM_BAZA, 100, 25);
    pwm_wlacz(&pwm, 0);
    uint32_t t0 = TAKTY;
    for (int i = 0; i < 3; i++)
        pwm_czekaj_na_okres(&pwm);
    uint32_t dt = TAKTY - t0;
    pwm_wylacz(&pwm);
    pisz("3 okresy PWM (OKRES = 100): 0x");
    pisz_hex(dt);
    pisz(" taktow\n");
    if (dt < 250u || dt > 350u)
        bledy++;

    LED = 0x0Fu;
    pisz(bledy ? "PWM BLAD\n" : "PWM OK\n");
    return bledy;
}
