// Testbench C (28.01, 28.02): fir() i fir_blok() na wektorach modułu 26 (fir_wsp.hex, fir_we.hex, fir_wy.hex —
// model Pythona dsp_model.py). Ta sama odpowiedź co RTL fir_transp/fir_sym: 2048 próbek bit w bit.
// Uruchomienie: ./tb_fir [katalog z danymi]; zwraca 0 przy zgodności (wymóg csim_design w Vitis HLS).
#include "fir.h"
#include "wektory.h"

int main(int argc, char **argv)
{
    const std::string d = katalog(argc, argv, "../../26-dsp-w-fpga/hdl/dane");
    auto hv = czytaj_hex16(d + "fir_wsp.hex");
    auto xv = czytaj_hex16(d + "fir_we.hex");
    auto yv = czytaj_hex16(d + "fir_wy.hex");
    if (hv.size() != FIR_N || xv.size() != 2048 || yv.size() != 2048) {
        std::printf("FAIL: brak wektorow w %s\n", d.c_str());
        return 1;
    }
    int16_t h[FIR_N];
    for (int i = 0; i < FIR_N; i++) h[i] = static_cast<int16_t>(hv[i]);

    int bledy1 = 0, bledy2 = 0;
    for (int k = 0; k < 2048; k++)
        if (fir(static_cast<int16_t>(xv[k]), h) != yv[k]) bledy1++;

    std::vector<int16_t> x(2048), y(2048);
    for (int k = 0; k < 2048; k++) x[k] = static_cast<int16_t>(xv[k]);
    fir_blok(x.data(), y.data(), 2048, h);
    for (int k = 0; k < 2048; k++)
        if (y[k] != yv[k]) bledy2++;

    std::printf("fir (probka na wywolanie): 2048 probek, niezgodnych z modelem %d\n", bledy1);
    std::printf("fir_blok (petla II=1):     2048 probek, niezgodnych z modelem %d\n", bledy2);
    std::printf(bledy1 + bledy2 ? "FAIL\n" : "PASS\n");
    return bledy1 + bledy2 ? 1 : 0;
}
