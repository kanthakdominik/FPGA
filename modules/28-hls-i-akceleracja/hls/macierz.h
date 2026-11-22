// Mnożenie macierzy 16 × 16 w stylu HLS (28.02, 28.03): ta sama funkcja, różne dyrektywy — różny sprzęt.
#pragma once
#include <cstdint>

constexpr int M = 16;

void mnoz_prosto(const int16_t a[M][M], const int16_t b[M][M], int64_t c[M][M]);      // 1 MAC na takt
void mnoz_rownolegle(const int16_t a[M][M], const int16_t b[M][M], int64_t c[M][M]);  // 16 MAC na takt
