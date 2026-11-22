// Wygenerowane przez nn/mlp_model.py z nn/mlp_wagi.txt — nie edytować ręcznie.
#pragma once
#include <cstdint>

constexpr int MLP_WE = 2, MLP_UKRYTE = 16, MLP_WY = 3;
constexpr int MLP_P1 = 7;   // przesunięcie po pierwszej warstwie (skala aktywacji)
static const int8_t MLP_W1[MLP_UKRYTE][MLP_WE] = {
    {-26, 19},
    {-8, -15},
    {37, 27},
    {0, 0},
    {-19, 14},
    {4, 0},
    {35, 0},
    {8, 49},
    {-12, 14},
    {64, -29},
    {-29, -41},
    {-40, 1},
    {-52, 17},
    {-2, -1},
    {-19, -6},
    {9, -22}
};
static const int32_t MLP_B1[MLP_UKRYTE] = {-1089, -1413, -1723, -94, -785, 8, 77, -1738, -879, -2104, -1631, 137, -926, -224, -849, -871};
static const int8_t MLP_W2[MLP_WY][MLP_UKRYTE] = {
    {-21, -34, -35, 7, -18, 8, 25, -64, -6, 0, -59, 56, -9, 0, -13, -55},
    {-10, -2, 79, 7, -10, 8, 21, 47, -1, 63, 3, -64, -47, 5, -9, 32},
    {43, 38, -38, -7, 28, 0, -52, 26, 19, -71, 55, 15, 49, 0, 26, 18}
};
static const int32_t MLP_B2[MLP_WY] = {609, -354, -256};
