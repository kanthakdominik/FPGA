// Mnożenie macierzy (28.02, 28.03).
//  mnoz_prosto:      najgłębsza pętla potokowana z II = 1 — jedna mnożarka, 16·16·16 = 4096 iteracji.
//  mnoz_rownolegle:  pętla k rozwinięta (16 mnożarek i drzewo sumatorów), pętla j potokowana z II = 1 —
//                    256 iteracji; żeby co takt odczytać 16 elementów wiersza a i 16 kolumny b, tablice są
//                    podzielone (ARRAY_PARTITION) na rejestry/banki — inaczej dwa porty bloku pamięci dają
//                    II = 8 (16 odczytów / 2 porty).
#include "macierz.h"

void mnoz_prosto(const int16_t a[M][M], const int16_t b[M][M], int64_t c[M][M])
{
wiersz:
    for (int i = 0; i < M; i++)
    kolumna:
        for (int j = 0; j < M; j++) {
            int64_t s = 0;            // 31 bitów iloczynu + log2(16) = 35 bitów: int32 za mały
        iloczyn:
            for (int k = 0; k < M; k++) {
#pragma HLS PIPELINE II=1
                s += static_cast<int32_t>(a[i][k]) * b[k][j];
            }
            c[i][j] = s;
        }
}

void mnoz_rownolegle(const int16_t a[M][M], const int16_t b[M][M], int64_t c[M][M])
{
#pragma HLS ARRAY_PARTITION variable=a dim=2 complete
#pragma HLS ARRAY_PARTITION variable=b dim=1 complete
wiersz:
    for (int i = 0; i < M; i++)
    kolumna:
        for (int j = 0; j < M; j++) {
#pragma HLS PIPELINE II=1
            int64_t s = 0;            // 31 bitów iloczynu + log2(16) = 35 bitów: int32 za mały
        iloczyn:
            for (int k = 0; k < M; k++)       // w pętli potokowanej pętle wewnętrzne są rozwijane całkowicie
                s += static_cast<int32_t>(a[i][k]) * b[k][j];
            c[i][j] = s;
        }
}
