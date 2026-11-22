// Histogram (28.02, 28.03). Wersja prosta: hist[d]++ — w pętli potokowanej każda iteracja czyta koszyk, który
// poprzednia mogła właśnie zapisywać; przy pamięci blokowej (odczyt 1–2 takty, zapis takt później) narzędzie
// musi rozsunąć iteracje (II = 2–3). Wersja szybka: kolejne takie same bajty liczone w rejestrze, a ostatnio
// zapisany koszyk pamiętany w rejestrze (przekazanie) — zależność przez pamięć znika z odległości 1, więc można
// zapewnić narzędzie dyrektywą DEPENDENCE, że jej nie ma, i dostać II = 1. Obie wersje dają ten sam wynik.
#include "histogram.h"

void histogram_prosty(const uint8_t *dane, int n, uint32_t hist[KOSZYKI])
{
#pragma HLS INTERFACE m_axi port=dane depth=4096 bundle=gmem
#pragma HLS INTERFACE s_axilite port=n
#pragma HLS INTERFACE s_axilite port=return
zeruj:
    for (int i = 0; i < KOSZYKI; i++) {
#pragma HLS PIPELINE II=1
        hist[i] = 0;
    }
zlicz:
    for (int i = 0; i < n; i++) {
#pragma HLS PIPELINE II=1
#pragma HLS LOOP_TRIPCOUNT min=4096 max=4096
        hist[dane[i]]++;                       // raport HLS: II naruszone przez zależność na hist
    }
}

void histogram_szybki(const uint8_t *dane, int n, uint32_t hist[KOSZYKI])
{
#pragma HLS INTERFACE m_axi port=dane depth=4096 bundle=gmem
#pragma HLS INTERFACE s_axilite port=n
#pragma HLS INTERFACE s_axilite port=return
zeruj:
    for (int i = 0; i < KOSZYKI; i++) {
#pragma HLS PIPELINE II=1
        hist[i] = 0;
    }
    if (n <= 0) return;
    int biezacy = dane[0];                     // koszyk zliczany w rejestrze
    uint32_t licznik = 0;
    int zapisany = -1;                         // ostatnio zapisany koszyk i jego wartość (przekazanie)
    uint32_t zapisana = 0;
zlicz:
    for (int i = 0; i < n; i++) {
#pragma HLS PIPELINE II=1
#pragma HLS LOOP_TRIPCOUNT min=4096 max=4096
#pragma HLS DEPENDENCE variable=hist type=inter direction=RAW false
        const int d = dane[i];
        if (d == biezacy) {
            licznik++;
        } else {
            hist[biezacy] = licznik;
            zapisany = biezacy;
            zapisana = licznik;
            const uint32_t stary = (d == zapisany) ? zapisana : hist[d];
            licznik = stary + 1;
            biezacy = d;
        }
    }
    hist[biezacy] = licznik;
}
