// Filtr FIR w stylu HLS (28.01, 28.02): opis „jak w C”, a dyrektywy mówią narzędziu, jaki sprzęt z tego zrobić.
// Arytmetyka co do bitu jak w module 26: suma iloczynów 16 × 16 w 64 bitach, +2^14, przesunięcie o 15,
// nasycenie do 16 bitów. Dyrektywy (#pragma HLS) są dla Vitis HLS; g++ je pomija (-Wno-unknown-pragmas).
#include "fir.h"

static int16_t nasyc16(int64_t v)
{
    return static_cast<int16_t>(v > 32767 ? 32767 : v < -32768 ? -32768 : v);
}

int16_t fir(int16_t x, const int16_t h[FIR_N])
{
#pragma HLS PIPELINE II=1
#pragma HLS ARRAY_PARTITION variable=h complete
    static int16_t linia[FIR_N] = {0};
#pragma HLS ARRAY_PARTITION variable=linia complete
    int64_t acc = 0;
przesun:
    for (int i = FIR_N - 1; i > 0; i--)     // rozwinięta całkowicie (w funkcji potokowanej) -> rejestry przesuwne
        linia[i] = linia[i - 1];
    linia[0] = x;
mac:
    for (int i = 0; i < FIR_N; i++)         // rozwinięta -> 31 mnożarek i drzewo sumatorów
        acc += static_cast<int64_t>(h[i]) * linia[i];
    return nasyc16((acc + (1 << 14)) >> 15);
}

void fir_blok(const int16_t *x, int16_t *y, int n, const int16_t h[FIR_N])
{
#pragma HLS INTERFACE m_axi port=x depth=2048 bundle=gmem0
#pragma HLS INTERFACE m_axi port=y depth=2048 bundle=gmem1
#pragma HLS INTERFACE s_axilite port=n
#pragma HLS INTERFACE s_axilite port=h
#pragma HLS INTERFACE s_axilite port=return
    int16_t hl[FIR_N];
#pragma HLS ARRAY_PARTITION variable=hl complete
    for (int i = 0; i < FIR_N; i++) hl[i] = h[i];
    int16_t linia[FIR_N] = {0};
#pragma HLS ARRAY_PARTITION variable=linia complete
probki:
    for (int k = 0; k < n; k++) {
#pragma HLS PIPELINE II=1
#pragma HLS LOOP_TRIPCOUNT min=2048 max=2048
        for (int i = FIR_N - 1; i > 0; i--) linia[i] = linia[i - 1];
        linia[0] = x[k];
        int64_t acc = 0;
        for (int i = 0; i < FIR_N; i++) acc += static_cast<int64_t>(hl[i]) * linia[i];
        y[k] = nasyc16((acc + (1 << 14)) >> 15);
    }
}
