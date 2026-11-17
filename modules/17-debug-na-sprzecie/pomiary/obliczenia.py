#!/usr/bin/env python3
"""Liczby do pomiarów zewnętrznych (17.04): pasmo oscyloskopu a czas narastania, złożenie czasów
narastania, dzwonienie przewodu masy sondy, długość krytyczna ścieżki, częstotliwość próbkowania
analizatora. Każda liczba podana w tekście jest tu wyliczana i sprawdzana.

Model: układ pierwszego rzędu (BW = 0,35 / t_r), czasy narastania 10–90 % składane pierwiastkiem
z sumy kwadratów, przewód masy jako indukcyjność szeregowa z pojemnością wejściową sondy.
"""
import math
import sys

bledy = []


def sprawdz(warunek, opis):
    print(f"  {'OK  ' if warunek else 'BLAD'} {opis}")
    if not warunek:
        bledy.append(opis)


def pasmo(t_r):
    """Pasmo -3 dB [Hz] układu pierwszego rzędu o czasie narastania t_r [s]."""
    return 0.35 / t_r


def t_narastania(bw):
    return 0.35 / bw


def zlozenie(*t):
    return math.sqrt(sum(x * x for x in t))


def main():
    print("1. Pasmo i czas narastania (BW = 0,35 / t_r)")
    for bw in (50e6, 100e6, 200e6, 500e6):
        print(f"   oscyloskop {bw / 1e6:5.0f} MHz: własny czas narastania {t_narastania(bw) * 1e9:.2f} ns")
    sprawdz(abs(t_narastania(100e6) - 3.5e-9) < 1e-12, "100 MHz -> 3,5 ns")

    print("2. Zmierzony czas narastania = sqrt(t_sygnał² + t_oscyloskop² + t_sonda²)")
    t_sig = 1.0e-9                                     # zbocze wyjścia FPGA rzędu 1 ns
    for bw in (100e6, 200e6, 500e6):
        t_m = zlozenie(t_sig, t_narastania(bw))
        print(f"   sygnał 1,0 ns, oscyloskop {bw / 1e6:3.0f} MHz: widać {t_m * 1e9:.2f} ns "
              f"(błąd {100 * (t_m - t_sig) / t_sig:.0f} %)")
    t500 = zlozenie(t_sig, t_narastania(500e6))
    sprawdz(abs(t500 - 1.22e-9) < 0.01e-9, "1 ns na oscyloskopie 500 MHz -> ok. 1,22 ns")
    sprawdz(zlozenie(t_sig, t_narastania(100e6)) > 3.5e-9, "oscyloskop 100 MHz pokazuje własne zbocze, nie sygnału")
    # pasmo potrzebne do błędu <= 5 %: t_osc <= ok. 1/3 t_sig
    bw5 = pasmo(t_sig / 3)
    sprawdz(zlozenie(t_sig, t_sig / 3) / t_sig - 1 < 0.06, f"t_osc = t_sig / 3 -> błąd ok. 5 % (pasmo {bw5 / 1e9:.2f} GHz)")

    print("3. Dzwonienie przewodu masy sondy: f = 1 / (2π·sqrt(L·C))")
    C = 10e-12                                         # pojemność wejściowa sondy 10:1
    for opis, L in (("przewód 15 cm (ok. 1 nH/mm)", 150e-9), ("sprężynka masy (ok. 10 nH)", 10e-9)):
        f = 1 / (2 * math.pi * math.sqrt(L * C))
        print(f"   {opis}: {f / 1e6:.0f} MHz")
    f15 = 1 / (2 * math.pi * math.sqrt(150e-9 * C))
    f_spr = 1 / (2 * math.pi * math.sqrt(10e-9 * C))
    sprawdz(120e6 < f15 < 140e6, "15 cm przewodu masy i 10 pF -> ok. 130 MHz (w paśmie zbocza 1 ns)")
    sprawdz(f_spr > 450e6, "sprężynka masy -> ok. 500 MHz (powyżej pasma zbocza)")

    print("4. Długość krytyczna ścieżki (efekty linii długiej, gdy opóźnienie > t_r / 6)")
    v = 3e8 / math.sqrt(4.0)                           # FR4, εr ≈ 4 -> 15 cm/ns
    for t_r in (0.5e-9, 1e-9, 3e-9):
        l_kr = v * t_r / 6
        print(f"   t_r = {t_r * 1e9:.1f} ns: zbocze zajmuje {v * t_r * 100:.0f} cm, długość krytyczna {l_kr * 100:.1f} cm")
    sprawdz(abs(v * 1e-9 / 6 - 0.025) < 1e-4, "zbocze 1 ns w FR4 -> długość krytyczna 2,5 cm")

    print("5. Analizator logiczny w trybie czasowym: próbkowanie >= 4 x częstotliwość sygnału (lepiej 10 x)")
    for f in (1e6, 25e6):
        print(f"   sygnał {f / 1e6:4.0f} MHz: co najmniej {4 * f / 1e6:4.0f} MS/s, zalecane {10 * f / 1e6:4.0f} MS/s; "
              f"rozdzielczość czasu przy 4 x: {1e9 / (4 * f):.0f} ns")
    sprawdz(24e6 >= 4 * 1e6 and 24e6 < 4 * 25e6, "analizator 24 MS/s: wystarczy dla 1 MHz, nie dla 25 MHz")

    print("PASS" if not bledy else f"FAIL: {len(bledy)}")
    return 1 if bledy else 0


if __name__ == "__main__":
    sys.exit(main())
