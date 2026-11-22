// Testbench C (28.05): mlp() na 1000 punktach testowych z nn/mlp_model.py (mlp_wektory.txt: x, y, klasa
// prawdziwa, trzy logity i klasa modelu int8) — logity co do bitu i dokładność względem etykiet.
#include <cstdio>
#include "mlp.h"
#include "wektory.h"

int main(int argc, char **argv)
{
    const std::string d = katalog(argc, argv, ".");
    auto v = czytaj_liczby(d + "mlp_wektory.txt");
    if (v.size() != 7000) {
        std::printf("FAIL: zly plik %smlp_wektory.txt\n", d.c_str());
        return 1;
    }
    int niezgodne = 0, dobre = 0;
    for (int p = 0; p < 1000; p++) {
        const long *w = &v[7 * p];
        int32_t l[MLP_KLASY];
        int k = mlp(static_cast<int8_t>(w[0]), static_cast<int8_t>(w[1]), l);
        if (l[0] != w[3] || l[1] != w[4] || l[2] != w[5] || k != w[6]) niezgodne++;
        dobre += k == w[2];
    }
    std::printf("mlp 2-16-3 int8: 1000 punktow, niezgodnych z modelem %d, dokladnosc %.1f%%\n",
                niezgodne, dobre / 10.0);
    std::printf(niezgodne ? "FAIL\n" : "PASS\n");
    return niezgodne ? 1 : 0;
}
