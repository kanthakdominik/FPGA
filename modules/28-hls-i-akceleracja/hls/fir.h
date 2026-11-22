// Filtr FIR 31 współczynników w stylu HLS (28.01, 28.02) — ten sam filtr co fir_transp/fir_sym z modułu 26.
#pragma once
#include <cstdint>

constexpr int FIR_N = 31;

// jedna próbka na wywołanie: rejestr przesuwny w zmiennej static (pamięć między wywołaniami = rejestry)
int16_t fir(int16_t x, const int16_t h[FIR_N]);
// cały blok próbek: pętla potokowana z II = 1
void fir_blok(const int16_t *x, int16_t *y, int n, const int16_t h[FIR_N]);
