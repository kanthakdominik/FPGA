#!/usr/bin/env python3
"""Obliczenia z przykładów w tekstach modułu 14 — każda liczba z tekstu policzona i sprawdzona.

Wzory (czasy w ns, skew = opóźnienie zegara do przerzutnika odbierającego minus do nadającego):
  zapas setup = (T·N_setup + skew − t_su − niepewność_setup) − (t_co + t_logika_max)
  zapas hold  = (t_co_min + t_logika_min) − (T·N_hold + skew + t_h + niepewność_hold)
  f_max       = 1 / (t_co + t_logika_max + t_su − skew)
Użycie: python3 obliczenia.py   (kończy się kodem 1, jeśli któraś liczba nie zgadza się z tekstem)
"""
import sys

BLEDY = []


def sprawdz(opis, wartosc, oczekiwana, tol=0.005):
    ok = abs(wartosc - oczekiwana) <= tol
    if not ok:
        BLEDY.append(opis)
    print(f"  {'OK ' if ok else 'BLAD'} {opis:62s} {wartosc:9.3f}  (w tekście {oczekiwana})")


def zapas_setup(T, t_co, t_log, t_su, skew=0.0, niep=0.0, n=1):
    return (n * T + skew - t_su - niep) - (t_co + t_log)


def zapas_hold(t_co, t_log, t_h, skew=0.0, niep=0.0, n=0, T=0.0):
    return (t_co + t_log) - (n * T + skew + t_h + niep)


def fmax_mhz(t_co, t_log, t_su, skew=0.0):
    return 1000.0 / (t_co + t_log + t_su - skew)


print("14.01 — ścieżka rejestr–rejestr, 100 MHz")
# t_co 0,8; logika 4,5 + połączenia 3,4; t_su 0,3; zegar dochodzi do odbiornika 0,2 ns później
sprawdz("zapas setup", zapas_setup(10, 0.8, 4.5 + 3.4, 0.3, skew=0.2), 1.2)
sprawdz("f_max [MHz]", fmax_mhz(0.8, 4.5 + 3.4, 0.3, skew=0.2), 113.64, tol=0.01)
# najkrótsza ścieżka: t_co_min 0,6; logika 0,2; t_h 0,1
sprawdz("zapas hold", zapas_hold(0.6, 0.2, 0.1, skew=0.2), 0.5)
sprawdz("zapas hold przy skew 1,0 ns (naruszenie)", zapas_hold(0.6, 0.2, 0.1, skew=1.0), -0.3)

print("14.02 — zegar: jitter, niepewność, skew, CRPR")
# niepewność setup = jitter cykl-do-cyklu 0,15 + zapas projektowy 0,1
sprawdz("zapas setup z niepewnością 0,25 ns", zapas_setup(10, 0.8, 7.9, 0.3, skew=0.2, niep=0.25), 0.95)
# opóźnienia drzewa zegara: do nadajnika 2,1 ns, do odbiornika 2,4 ns
sprawdz("skew z opóźnień drzewa zegara", 2.4 - 2.1, 0.3)
# OCV: część wspólna drzewa 1,8 ns, współczynniki 0,95 (wcześnie) i 1,05 (późno)
sprawdz("pesymizm części wspólnej (CRPR)", 1.8 * 1.05 - 1.8 * 0.95, 0.18)
# OpenSTA, e02_zegar: zapas setup 7,380 -> 7,080 (niepewność 0,3), hold 0,070 -> -0,030 (0,1)
sprawdz("OpenSTA: setup 7,380 − 0,3", 7.380 - 0.3, 7.080)
sprawdz("OpenSTA: hold 0,070 − 1,0 (skew)", 0.070 - 1.0, -0.930)

print("14.03 — wejścia i wyjścia względem zegara zewnętrznego, 100 MHz")
# wejście: układ zewnętrzny t_co_max 4,0, min 1,0; ścieżka na płytce 0,4…0,6
we_max, we_min = 4.0 + 0.6, 1.0 + 0.4
sprawdz("set_input_delay -max", we_max, 4.6)
sprawdz("set_input_delay -min", we_min, 1.4)
sprawdz("zapas setup wejścia (ścieżka w FPGA 3,1 + t_su 0,2)", 10 - we_max - 3.1 - 0.2, 2.1)
# wyjście: układ zewnętrzny t_su 2,0, t_h 0,8; płytka 0,5 (max), 0,3 (min)
wy_max, wy_min = 2.0 + 0.5, 0.3 - 0.8
sprawdz("set_output_delay -max", wy_max, 2.5)
sprawdz("set_output_delay -min", wy_min, -0.5)
sprawdz("zapas setup wyjścia (zegar->pin w FPGA 5,4)", 10 - wy_max - 5.4, 2.1)
sprawdz("zapas hold wyjścia (zegar->pin min 3,2; wymagany 0 − (−0,5))", 3.2 - (0 - wy_min), 2.7)

print("14.04 — ścieżka wielotaktowa N = 4 przy 100 MHz")
sprawdz("relacja setup bez MCP [ns]", 1 * 10, 10)
sprawdz("relacja setup z -setup 4 [ns]", 4 * 10, 40)
sprawdz("relacja hold z samym -setup 4 [ns]", (4 - 1) * 10, 30)
sprawdz("relacja hold z -setup 4 -hold 3 [ns]", (4 - 1 - 3) * 10, 0)
# OpenSTA, e04_wyjatki (8 ns): ścieżka dzielnika 21,896 ns w narożniku SS, t_su 0,166
sprawdz("OpenSTA: zapas bez MCP 8 − 0,166 − 21,896", 8 - 0.166 - 21.896, -14.062)
sprawdz("OpenSTA: zapas z MCP 32 − 0,166 − 21,896", 32 - 0.166 - 21.896, 9.938)

print("14.06 — SPI 25 MHz z clk_sys 100 MHz (DIV = 2), przykładowe opóźnienia FPGA")
T, DIV = 10.0, 2
t_sclk, t_mosi, t_in = 5.3, 5.5, 1.0              # zegar->pin SCLK, zegar->pin MOSI, pin MISO->rejestr
tsu, th, tco_max, tco_min, pl_max, pl_min, tsu_ff = 5.0, 5.0, 10.0, 2.0, 0.5, 0.2, 0.2
mosi_setup = DIV * T + t_sclk - t_mosi - tsu - pl_max
mosi_hold = DIV * T + t_mosi - t_sclk - (th - pl_min)
miso_setup = DIV * T - tsu_ff - (t_sclk + pl_max + tco_max + pl_max + t_in)
sprawdz("MOSI zapas setup", mosi_setup, 14.3)
sprawdz("MOSI zapas hold", mosi_hold, 15.4)
sprawdz("MISO zapas setup", miso_setup, 2.5)
# najwyższa częstotliwość SCLK, przy której MISO zdąży (pół okresu SCLK = DIV·T)
pol_okresu = t_sclk + pl_max + tco_max + pl_max + t_in + tsu_ff
sprawdz("MISO: minimalne pół okresu SCLK [ns]", pol_okresu, 17.5)
sprawdz("MISO: maksymalna f_SCLK [MHz]", 1000 / (2 * pol_okresu), 28.57, tol=0.01)
# źródłowo-synchroniczne DDR 125 MHz (bit co 4 ns), dane wyrównane do środka, rozrzut ±0,5 ns
okno = 8.0 / 2 - 2 * 0.5
sprawdz("DDR 125 MHz: okno ważności danych [ns]", okno, 3.0)
UI = 4.0
tsu_we = th_we = UI / 2 - 0.5                      # dane ważne 1,5 ns przed i po zboczu zegara przesyłanego
sprawdz("DDR: dane ważne przed zboczem (t_su na wejściu FPGA)", tsu_we, 1.5)
sprawdz("DDR wyrównane do środka: set_input_delay -max = UI − t_su", UI - tsu_we, 2.5)
sprawdz("DDR wyrównane do środka: set_input_delay -min = t_h", th_we, 1.5)

print("PASS" if not BLEDY else f"FAIL: {len(BLEDY)} niezgodnosci")
sys.exit(1 if BLEDY else 0)
