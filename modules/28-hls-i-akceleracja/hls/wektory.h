// Pomocnicze funkcje testbenchy C++ (28.x): odczyt plików .hex z modułu 26 i plików tekstowych z liczbami.
// Tylko biblioteka standardowa — testbenche kompilują się g++ (symulacja C w CI) i w Vitis HLS (csim_design).
#pragma once
#include <cstdint>
#include <cstdio>
#include <fstream>
#include <string>
#include <vector>

inline std::vector<int32_t> czytaj_hex16(const std::string &nazwa)
{
    std::vector<int32_t> v;
    std::ifstream f(nazwa);
    std::string l;
    while (std::getline(f, l)) {
        if (l.empty()) continue;
        uint32_t u = std::stoul(l, nullptr, 16);
        v.push_back(static_cast<int16_t>(u & 0xFFFFu));   // 16 bitów w kodzie uzupełnień do dwóch
    }
    return v;
}

inline std::vector<long> czytaj_liczby(const std::string &nazwa)
{
    std::vector<long> v;
    std::ifstream f(nazwa);
    long x;
    while (f >> x) v.push_back(x);
    return v;
}

// katalog z danymi: argument wywołania albo domyślny (względem katalogu hls/)
inline std::string katalog(int argc, char **argv, const char *domyslny)
{
    std::string k = argc > 1 ? argv[1] : domyslny;
    if (!k.empty() && k.back() != '/') k += '/';
    return k;
}
