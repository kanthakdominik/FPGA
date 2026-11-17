#!/usr/bin/env python3
"""Działa w symulacji, nie działa na płytce (17.05): symulacja RTL kontra symulacja netlisty po syntezie.

Dla każdej pułapki: Yosys syntetyzuje wersję "zle" i "dobrze" (synth -flatten), zapisuje netlistę jako
moduł <nazwa>_net, a Icarus symuluje RTL i netlistę tym samym pobudzeniem i liczy takty, w których
wyjścia się różnią (porównanie !==, więc X też jest różnicą). Netlista to model tego, co trafi do
układu — różnica oznacza, że symulacja RTL nie mówi prawdy o sprzęcie.
Oczekiwane: wersja "zle" — różnice > 0, wersja "dobrze" — 0 różnic.
Wymaga yosys i iverilog. Kod wyjścia 1, gdy któreś oczekiwanie nie jest spełnione.
"""
import re
import subprocess
import sys
from pathlib import Path

TU = Path(__file__).resolve().parent
BUILD = TU / "build"
PULAPKI = {
    "lista_czulosci": "niepełna lista czułości",
    "opoznienia": "opóźnienia # w kodzie syntezowalnym",
    "x_optymizm": "X-optymizm (rejestr bez resetu)",
    "full_case": "dyrektywa full_case",
    "blokujace": "przypisania blokujące w blokach taktowanych",
}


def uruchom(cmd):
    p = subprocess.run(cmd, cwd=TU, capture_output=True, text=True)
    if p.returncode != 0:
        print(p.stdout[-2000:], p.stderr[-2000:])
        sys.exit(1)
    return p


def main():
    BUILD.mkdir(exist_ok=True)
    bledy = 0
    print(f"{'pułapka':48s} {'różnice zle':>12s} {'różnice dobrze':>15s}")
    for nazwa, opis in PULAPKI.items():
        nety = []
        for wersja in ("zle", "dobrze"):
            top = f"{nazwa}_{wersja}"
            net = BUILD / f"{top}_net.v"
            uruchom(["yosys", "-q", "-p", f"read_verilog {nazwa}.v; synth -flatten -top {top}; "
                     f"rename {top} {top}_net; write_verilog -noattr {net}"])
            nety.append(str(net))
        uruchom(["iverilog", "-g2005", "-o", str(BUILD / f"tb_{nazwa}"), f"tb_{nazwa}.v", f"{nazwa}.v", *nety])
        wynik = uruchom(["vvp", "-n", str(BUILD / f"tb_{nazwa}")]).stdout
        m = re.search(r"ROZNICE zle=(\d+) dobrze=(\d+)", wynik)
        if not m:
            print(wynik)
            sys.exit(1)
        rz, rd = int(m.group(1)), int(m.group(2))
        ok = rz > 0 and rd == 0
        bledy += 0 if ok else 1
        print(f"{nazwa + ' (' + opis + ')':48s} {rz:12d} {rd:15d}  {'OK' if ok else 'BLAD'}")
    print("PASS" if bledy == 0 else f"FAIL: {bledy}")
    return 1 if bledy else 0


if __name__ == "__main__":
    sys.exit(main())
