// Sieć neuronowa 2-16-3 int8 w stylu HLS (28.05). Arytmetyka co do bitu jak nn/mlp_model.py:
//   a1 = W1·x + B1 (int32), h = ReLU i powrót do int8: min(max((a1 + 2^(P1-1)) >> P1, 0), 127)
//   logity = W2·h + B2 (int32), klasa = pierwszy największy logit.
// Dyrektywy: PIPELINE II=1 na całej funkcji rozwija obie warstwy — 32 + 48 = 80 mnożeń int8 równolegle
// (reuse factor 1). Z ALLOCATION/limitem mnożarek albo PIPELINE II=R narzędzie dzieli mnożenia na R taktów.
#include "mlp.h"
#include "mlp_wagi.h"

int mlp(int8_t x, int8_t y, int32_t logity[MLP_KLASY])
{
#pragma HLS PIPELINE II=1
#pragma HLS ARRAY_PARTITION variable=logity complete
    const int8_t wej[MLP_WE] = {x, y};
    int8_t h[MLP_UKRYTE];
#pragma HLS ARRAY_PARTITION variable=h complete
warstwa1:
    for (int j = 0; j < MLP_UKRYTE; j++) {
        int32_t a = MLP_B1[j];
        for (int i = 0; i < MLP_WE; i++) a += MLP_W1[j][i] * wej[i];
        int32_t v = (a + (1 << (MLP_P1 - 1))) >> MLP_P1;      // >> na liczbie ujemnej: przesunięcie arytmetyczne
        h[j] = static_cast<int8_t>(v < 0 ? 0 : v > 127 ? 127 : v);
    }
    int klasa = 0;
warstwa2:
    for (int c = 0; c < MLP_WY; c++) {
        int32_t a = MLP_B2[c];
        for (int j = 0; j < MLP_UKRYTE; j++) a += MLP_W2[c][j] * h[j];
        logity[c] = a;
        if (a > logity[klasa]) klasa = c;
    }
    return klasa;
}
