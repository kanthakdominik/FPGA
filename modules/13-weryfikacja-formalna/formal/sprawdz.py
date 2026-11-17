#!/usr/bin/env python3
"""Uruchamia wszystkie zadania formalne modułu 13 i porównuje wyniki z oczekiwanymi.

SymbiYosys zapisuje wynik zadania w <plik>_<zadanie>/status (PASS, FAIL, UNKNOWN, ERROR).
Skrypty Yosysa (*.ys) kończą się kodem 0, gdy dowód równoważności przeszedł, i błędem, gdy nie.
Wynik inny niż oczekiwany — także niespodziewany PASS — kończy skrypt kodem 1.

Użycie:  python3 sprawdz.py [nazwa ...]      (bez argumentów — wszystko)
"""
import re
import subprocess
import sys
import time
from pathlib import Path

TU = Path(__file__).resolve().parent

# plik .sby -> {zadanie: oczekiwany wynik}
SBY = {
    "cnt10": {"bmc": "PASS", "prove_fail": "UNKNOWN", "prove": "PASS", "prove_pdr": "PASS", "cover": "PASS",
              "cover_unreach": "FAIL"},
    "cnt10_vhdl": {"prove": "PASS", "cover": "PASS"},
    "alu_hs": {"prove": "PASS", "bug1": "FAIL", "bug2": "FAIL", "cover": "PASS"},
    "fifo_sync": {"prove": "PASS", "prove_weak": "UNKNOWN", "prove_pdr": "PASS", "cover": "PASS"},
}
# skrypt Yosysa -> oczekiwany wynik (PASS = kod 0)
YS = {
    "rownowaznosc_max": "PASS",
    "rownowaznosc_synteza": "PASS",
    "rownowaznosc_bug": "FAIL",
}

# linie dziennika warte pokazania: gdzie padła asercja, w którym kroku osiągnięto cover, ile kroków indukcji
CIEKAWE = re.compile(r"(Assert failed in|Reached cover statement|Unreached cover statement|"
                     r"Trying induction in step|summary: engine_0|failed assertion|"
                     r"Proved \d+ previously|unproven|SAT proof finished|SAT model found|ABC RESULTS|Of those cells)")


def wybrane(argumenty):
    return [n for n in [*SBY, *YS] if not argumenty or n in argumenty]


def uruchom_sby(nazwa):
    t0 = time.time()
    subprocess.run(["sby", "-f", f"{nazwa}.sby"], cwd=TU, capture_output=True, text=True)
    czas = time.time() - t0
    wyniki = []
    for zadanie, oczekiwany in SBY[nazwa].items():
        katalog = TU / f"{nazwa}_{zadanie}"
        status = katalog / "status"
        wynik = status.read_text().split()[0] if status.exists() else "BRAK"
        log = katalog / "logfile.txt"
        szczegoly = []
        if log.exists():
            linie = [l.split("] ", 1)[-1] if "] " in l else l for l in log.read_text().splitlines()]
            szczegoly = [l for l in linie if CIEKAWE.search(l)]
            if "Trying induction" in "\n".join(szczegoly):        # z indukcji tylko ostatni krok
                ind = [l for l in szczegoly if "Trying induction" in l]
                szczegoly = [l for l in szczegoly if "Trying induction" not in l] + ind[-1:]
        wyniki.append((f"{nazwa}:{zadanie}", oczekiwany, wynik, szczegoly))
    return wyniki, czas


def uruchom_ys(nazwa):
    t0 = time.time()
    p = subprocess.run(["yosys", "-q", "-l", f"{nazwa}.log", "-s", f"{nazwa}.ys"], cwd=TU,
                       capture_output=True, text=True)
    czas = time.time() - t0
    wynik = "PASS" if p.returncode == 0 else "FAIL"
    log = (TU / f"{nazwa}.log").read_text() if (TU / f"{nazwa}.log").exists() else p.stdout + p.stderr
    szczegoly = [l.strip() for l in log.splitlines() if CIEKAWE.search(l)]
    # dla kontrprzykładu: tabela wartości wejść z sat -show-inputs
    if wynik == "FAIL":
        tabela = [l.rstrip() for l in log.splitlines() if re.match(r"\s+\d+\s+\\in_", l)]
        szczegoly += tabela[:24]
    return [(nazwa, YS[nazwa], wynik, szczegoly)], czas


def main():
    nazwy = wybrane(sys.argv[1:])
    bledy = 0
    for nazwa in nazwy:
        wyniki, czas = uruchom_sby(nazwa) if nazwa in SBY else uruchom_ys(nazwa)
        print(f"== {nazwa} ({czas:.1f} s)")
        for zadanie, oczekiwany, wynik, szczegoly in wyniki:
            ok = wynik == oczekiwany
            bledy += not ok
            print(f"  {zadanie:28s} {wynik:8s} oczekiwano {oczekiwany:8s} {'OK' if ok else '<-- NIEZGODNE'}")
            for l in szczegoly:
                print(f"      {l}")
    print("PASS" if bledy == 0 else f"FAIL: {bledy} niezgodnych wynikow")
    return 1 if bledy else 0


if __name__ == "__main__":
    sys.exit(main())
