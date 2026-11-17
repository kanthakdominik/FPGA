#!/usr/bin/env python3
"""MTBF synchronizatora — rachunek z 15.02. Każda liczba z tekstu policzona i sprawdzona.

Model: przerzutnik, którego wejście zmieni się w oknie T_w wokół zbocza, wchodzi w stan metastabilny;
prawdopodobieństwo, że po czasie t_r nadal nie zdecydował, maleje jak exp(−t_r / τ). Stąd:

    MTBF = exp(t_r / τ) / (T_w · f_clk · f_dane)

t_r — czas na ustalenie: od zbocza do chwili, w której wynik musi być stabilny na wejściu następnego
elementu = okres zegara − t_co − t_logika − t_su (dla każdego kolejnego stopnia synchronizatora dochodzi
prawie cały okres). τ i T_w zależą od technologii; poniżej wartości PRZYKŁADOWE, rzędu spotykanego
w FPGA 28–65 nm (prawdziwe liczby dla MAX 10 liczy Quartus: report_metastability, 15.07).
Użycie: python3 mtbf.py
"""
import math
import sys

TAU = 20e-12          # stała czasowa rozstrzygania [s] — przykładowa
T_W = 30e-12          # okno metastabilności [s] — przykładowe
T_CO, T_SU = 0.4e-9, 0.2e-9
ROK = 365.25 * 24 * 3600

BLEDY = []


def log10_mtbf(t_r, f_clk, f_dane, tau=TAU, t_w=T_W):
    """log10(MTBF [s]) — liczony w skali logarytmicznej, bo exp(t_r/τ) szybko przekracza zakres liczb."""
    return t_r / tau / math.log(10) - math.log10(t_w * f_clk * f_dane)


def mtbf(t_r, f_clk, f_dane, tau=TAU, t_w=T_W):
    return 10 ** log10_mtbf(t_r, f_clk, f_dane, tau, t_w)


def t_r(f_clk, stopnie, t_logika=0.0, t_pol=0.3e-9):
    """Czas na ustalenie: pierwszy stopień ma okres − t_co − t_pol − t_su − logika, każdy następny + (okres − t_co − t_su)."""
    T = 1 / f_clk
    return (T - T_CO - t_pol - T_SU - t_logika) + (stopnie - 1) * (T - T_CO - T_SU)


def opis(log10_sek):
    if log10_sek < 0 or math.isnan(log10_sek):
        return "< 1 s"
    if log10_sek > 12:
        return f"10^{log10_sek - math.log10(ROK):.0f} lat"
    sek = 10 ** log10_sek
    if sek > ROK:
        return f"{sek / ROK:.0f} lat"
    if sek > 3600:
        return f"{sek / 3600:.1f} h"
    return f"{sek:.2g} s"


def sprawdz(nazwa, wartosc, oczekiwana, tol=0.02):
    ok = abs(wartosc - oczekiwana) <= tol * abs(oczekiwana)
    if not ok:
        BLEDY.append(nazwa)
    print(f"  {'OK ' if ok else 'BLAD'} {nazwa:58s} {wartosc:.3g} (w tekście {oczekiwana:.3g})")


print(f"Parametry przykładowe: tau = {TAU*1e12:.0f} ps, T_w = {T_W*1e12:.0f} ps, t_co = {T_CO*1e9} ns, "
      f"t_su = {T_SU*1e9} ns, połączenie 0,3 ns\n")
print(f"{'f_clk':>8s} {'f_dane':>8s} {'wariant':38s} {'t_r [ns]':>9s} {'MTBF':>18s}")
for f_clk, f_dane in ((100e6, 10e6), (400e6, 40e6), (500e6, 50e6)):
    for nazwa, st, lg in (("1 przerzutnik + logika 1,2 ns", 1, 1.2e-9), ("1 przerzutnik, bez logiki", 1, 0.0),
                          ("2 przerzutniki", 2, 0.0), ("3 przerzutniki", 3, 0.0)):
        tr = t_r(f_clk, st, lg)
        lm = log10_mtbf(tr, f_clk, f_dane) if tr > 0 else float("nan")
        print(f"{f_clk/1e6:6.0f} MHz {f_dane/1e6:5.0f} MHz {nazwa:38s} {tr*1e9:9.2f} {opis(lm):>18s}")
    print()

print("Liczby z tekstu:")
# 400 MHz, dane 40 MHz: jeden przerzutnik, za nim 1,2 ns logiki -> t_r = 2,5 − 0,4 − 0,3 − 0,2 − 1,2 = 0,4 ns
sprawdz("t_r 400 MHz, 1 FF + logika 1,2 ns [ns]", t_r(400e6, 1, 1.2e-9) * 1e9, 0.4)
sprawdz("MTBF 400 MHz/40 MHz, 1 FF + logika [s]", mtbf(t_r(400e6, 1, 1.2e-9), 400e6, 40e6), 1011)
# ten sam zegar, dwa przerzutniki bez logiki: t_r = (2,5 − 0,9) + (2,5 − 0,6) = 3,5 ns
sprawdz("t_r 400 MHz, 2 FF [ns]", t_r(400e6, 2) * 1e9, 3.5)
sprawdz("log10 MTBF 400 MHz, 2 FF [lata]", log10_mtbf(t_r(400e6, 2), 400e6, 40e6) - math.log10(ROK), 62.8, tol=0.01)
# każde dodatkowe 100 ps czasu ustalenia mnoży MTBF przez e^(100/20) ≈ 148
sprawdz("mnożnik MTBF za +100 ps", math.exp(100e-12 / TAU), 148.4)
# dwukrotnie wyższa częstotliwość danych — MTBF dwukrotnie krótszy
sprawdz("stosunek MTBF przy 2× f_dane", mtbf(5e-9, 1e8, 1e7) / mtbf(5e-9, 1e8, 2e7), 2.0)

print("PASS" if not BLEDY else f"FAIL: {len(BLEDY)} niezgodnosci")
sys.exit(1 if BLEDY else 0)
