// Testbench C (28.02): obie wersje histogramu porównane z prostym wzorcem na trzech zbiorach danych:
// losowe bajty, długie serie tych samych wartości i naprzemienne A B A B (najgorszy przypadek dla przekazania).
#include <cstdio>
#include <vector>
#include "histogram.h"

static uint32_t lcg(uint32_t &s) { s = s * 1664525u + 1013904223u; return s >> 24; }

int main()
{
    int bledy = 0;
    const char *nazwy[3] = {"losowe", "serie", "naprzemienne"};
    for (int zestaw = 0; zestaw < 3; zestaw++) {
        std::vector<uint8_t> d(4096);
        uint32_t s = 2800 + zestaw;
        for (int i = 0; i < 4096; i++) {
            if (zestaw == 0) d[i] = static_cast<uint8_t>(lcg(s));
            else if (zestaw == 1) d[i] = static_cast<uint8_t>((i / 37) * 11);
            else d[i] = static_cast<uint8_t>((i & 1) ? 200 : 7 + (i % 5 == 0));
        }
        uint32_t wzor[KOSZYKI] = {0}, h1[KOSZYKI], h2[KOSZYKI];
        for (int i = 0; i < 4096; i++) wzor[d[i]]++;
        histogram_prosty(d.data(), 4096, h1);
        histogram_szybki(d.data(), 4096, h2);
        int b1 = 0, b2 = 0;
        for (int k = 0; k < KOSZYKI; k++) {
            b1 += h1[k] != wzor[k];
            b2 += h2[k] != wzor[k];
        }
        std::printf("%-13s: niezgodnych koszykow — prosty %d, szybki %d\n", nazwy[zestaw], b1, b2);
        bledy += b1 + b2;
    }
    std::printf(bledy ? "FAIL\n" : "PASS\n");
    return bledy ? 1 : 0;
}
