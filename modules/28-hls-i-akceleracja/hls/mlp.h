// Sieć 2-16-3 int8 w stylu HLS (28.05): wnioskowanie jak w hls4ml — wagi jako stałe w logice, warstwy jako
// pętle rozwijane według „współczynnika ponownego użycia” (reuse factor).
#pragma once
#include <cstdint>

constexpr int MLP_KLASY = 3;

int mlp(int8_t x, int8_t y, int32_t logity[MLP_KLASY]);   // zwraca klasę (argmax)
