// Testbench C (28.02, 28.03): obie wersje mnożenia macierzy 16 × 16 porównane z wzorcem w int64, dla losowych
// liczb ze znakiem i dla wartości skrajnych (suma 16 iloczynów 16 × 16 bitów potrzebuje 35 bitów — int32 by się przepełnił).
#include <cstdio>
#include <cstdint>
#include "macierz.h"

static int16_t lcg(uint32_t &s) { s = s * 1664525u + 1013904223u; return static_cast<int16_t>(s >> 16); }

int main()
{
    int bledy = 0;
    for (int zestaw = 0; zestaw < 2; zestaw++) {
        int16_t a[M][M], b[M][M];
        int64_t c1[M][M], c2[M][M];
        uint32_t s = 28 + zestaw;
        for (int i = 0; i < M; i++)
            for (int j = 0; j < M; j++) {
                a[i][j] = zestaw ? static_cast<int16_t>(-32767 + (i + j) % 3) : lcg(s);
                b[i][j] = zestaw ? static_cast<int16_t>(32767 - (i * j) % 5) : lcg(s);
            }
        mnoz_prosto(a, b, c1);
        mnoz_rownolegle(a, b, c2);
        int b1 = 0, b2 = 0;
        for (int i = 0; i < M; i++)
            for (int j = 0; j < M; j++) {
                int64_t w = 0;
                for (int k = 0; k < M; k++) w += static_cast<int64_t>(a[i][k]) * b[k][j];
                b1 += c1[i][j] != w;
                b2 += c2[i][j] != w;
            }
        std::printf("zestaw %s: niezgodnych elementow — prosto %d, rownolegle %d\n",
                    zestaw ? "skrajny" : "losowy ", b1, b2);
        bledy += b1 + b2;
    }
    std::printf(bledy ? "FAIL\n" : "PASS\n");
    return bledy ? 1 : 0;
}
