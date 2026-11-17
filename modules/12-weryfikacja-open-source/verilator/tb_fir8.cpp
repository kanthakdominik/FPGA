// Testbench C++ dla fir8 przetłumaczonego Verilatorem: zegar i pobudzenia w pętli C++, model w C++
// (int64, dokładny co do bitu), pomiar szybkości. Argumenty: +n=<liczba próbek> (domyślnie 2 000 000),
// +trace — zapis przebiegów do fir8.fst (tylko pierwsze 10 000 taktów).
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <deque>
#include <memory>
#include <random>

#include "Vfir8.h"
#include "verilated.h"
#include "verilated_fst_c.h"

static const int64_t H[8] = {-763, 0, 4499, 12648, 12648, 4499, 0, -763};

// model: historia próbek, suma iloczynów, (s + 1024) >> 11, nasycenie
struct Fir8Model {
    int64_t hist[8] = {0};
    int64_t step(int64_t x) {
        for (int i = 7; i > 0; --i) hist[i] = hist[i - 1];
        hist[0] = x;
        int64_t s = 0;
        for (int i = 0; i < 8; ++i) s += H[i] * hist[i];
        int64_t y = (s + 1024) >> 11;              // przesunięcie arytmetyczne (C++20: zdefiniowane)
        return y > 32767 ? 32767 : (y < -32768 ? -32768 : y);
    }
};

int main(int argc, char** argv) {
    auto ctx = std::make_unique<VerilatedContext>();
    ctx->commandArgs(argc, argv);
    auto dut = std::make_unique<Vfir8>(ctx.get());

    const char* arg = ctx->commandArgsPlusMatch("n=");
    long n_samples = (arg && *arg) ? atol(arg + 3) : 2000000;
    std::unique_ptr<VerilatedFstC> tfp;
    if (*ctx->commandArgsPlusMatch("trace")) {
        ctx->traceEverOn(true);
        tfp = std::make_unique<VerilatedFstC>();
        dut->trace(tfp.get(), 99);
        tfp->open("fir8.fst");
    }

    std::mt19937 rng(12);
    std::uniform_int_distribution<int> sample(-2048, 2047), coin(0, 7);
    Fir8Model model;
    std::deque<int64_t> expected;
    long sent = 0, checked = 0, errors = 0, cycles = 0;

    auto tick = [&](int rst, int valid, int data) {
        dut->clk = 0;
        dut->rst = rst;
        dut->in_valid = valid;
        dut->in_data = data & 0xFFF;                // 12 bitów, kod U2
        dut->eval();
        if (tfp && cycles < 10000) tfp->dump(static_cast<uint64_t>(cycles) * 10);
        dut->clk = 1;                               // zbocze narastające: rejestry przyjmują wartości
        dut->eval();
        if (tfp && cycles < 10000) tfp->dump(static_cast<uint64_t>(cycles) * 10 + 5);
        ++cycles;
        if (dut->out_valid) {                       // wynik widoczny po zboczu
            int64_t got = static_cast<int16_t>(dut->out_data);
            if (expected.empty()) {
                ++errors;
            } else {
                if (got != expected.front() && ++errors <= 10)
                    printf("takt %ld: y = %lld, oczekiwano %lld\n", cycles, (long long)got,
                           (long long)expected.front());
                expected.pop_front();
                ++checked;
            }
        }
    };

    auto t0 = std::chrono::steady_clock::now();
    for (int i = 0; i < 3; ++i) tick(1, 0, 0);
    while (sent < n_samples) {
        if (coin(rng) == 0) {                       // co ósmy takt bez próbki
            tick(0, 0, 0);
            continue;
        }
        int x = coin(rng) == 0 ? (coin(rng) & 1 ? 2047 : -2048) : sample(rng);
        expected.push_back(model.step(x));
        tick(0, 1, x);
        ++sent;
    }
    for (int i = 0; i < 8; ++i) tick(0, 0, 0);
    double sec = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();

    if (!expected.empty()) errors += expected.size();
    if (checked != n_samples) ++errors;
    printf("probek: %ld, sprawdzonych: %ld, taktow: %ld, czas: %.2f s, %.1f mln taktow/s\n", sent, checked,
           cycles, sec, cycles / sec / 1e6);
    if (tfp) tfp->close();
    dut->final();
    if (errors == 0) printf("PASS\n");
    else             printf("FAIL: %ld bledow\n", errors);
    return errors ? 1 : 0;
}
