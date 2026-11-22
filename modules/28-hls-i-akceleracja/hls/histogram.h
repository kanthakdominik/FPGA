// Histogram bajtów w stylu HLS (28.02, 28.03): przykład zależności przenoszonej przez pamięć (odczyt-zmiana-
// zapis tego samego koszyka w kolejnych iteracjach), która ogranicza interwał inicjacji II.
#pragma once
#include <cstdint>

constexpr int KOSZYKI = 256;

void histogram_prosty(const uint8_t *dane, int n, uint32_t hist[KOSZYKI]);   // II ograniczone zależnością
void histogram_szybki(const uint8_t *dane, int n, uint32_t hist[KOSZYKI]);   // II = 1: przekazanie w rejestrach
