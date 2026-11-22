/* Funkcje, które kompilator może wywołać sam, a których bez biblioteki C i libgcc nie ma (27.07):
 * memset/memcpy (zerowanie i kopiowanie struktur, pętle rozpoznane jako memset) i __mulsi3 (mnożenie
 * na RV32I bez rozszerzenia M). */
#include <stddef.h>
#include <stdint.h>

void *memset(void *d, int c, size_t n)
{
    uint8_t *p = d;
    while (n--)
        *p++ = (uint8_t)c;
    return d;
}

void *memcpy(void *d, const void *s, size_t n)
{
    uint8_t *p = d;
    const uint8_t *q = s;
    while (n--)
        *p++ = *q++;
    return d;
}

uint32_t __mulsi3(uint32_t a, uint32_t b)
{
    uint32_t w = 0;
    while (b) {
        if (b & 1u)
            w += a;
        a <<= 1;
        b >>= 1;
    }
    return w;
}
