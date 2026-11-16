#!/usr/bin/env python3
"""Syntezuje w Yosysie każdy moduł Verilog z katalogów hdl/verilog/ i wypisuje zużycie zasobów.

Synteza ogólna na LUT o 4 wejściach (jak w MAX 10): `synth -flatten -top <moduł> -lut 4; check -assert; stat`.
Sprawdza, że kod jest syntezowalny (bez wielokrotnego sterowania, niepodłączonych wejść komórek itp.),
i daje orientacyjną liczbę LUT i przerzutników dla sekcji „Co powstaje po syntezie”.

Moduły są syntezowane z domyślnymi parametrami. Testbenche (tb_*.v) są pomijane.

Użycie:
    python3 tools/synteza_yosys.py [ścieżka ...] [--strict]
    --strict  brak Yosysa jest błędem (używane w CI)
"""
import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MODUL = re.compile(r"^\s*module\s+(\w+)", re.M)
KOMORKA = re.compile(r"^\s+(\$\S+)\s+(\d+)\s*$", re.M)


def podsumowanie(stat):
    """Zamienia wynik `stat` na krótki opis: LUT, przerzutniki, zatrzaski, inne komórki."""
    luty = przerzutniki = zatrzaski = 0
    inne = {}
    for nazwa, n in KOMORKA.findall(stat):
        n = int(n)
        if nazwa == "$lut":
            luty += n
        elif "DFF" in nazwa.upper():
            przerzutniki += n
        elif "DLATCH" in nazwa.upper():
            zatrzaski += n
        else:
            inne[nazwa] = inne.get(nazwa, 0) + n
    opis = f"LUT4: {luty:4d}   FF: {przerzutniki:4d}"
    if zatrzaski:
        opis += f"   zatrzaski: {zatrzaski}"
    if inne:
        opis += "   inne: " + ", ".join(f"{k} {v}" for k, v in sorted(inne.items()))
    return opis


def main():
    p = argparse.ArgumentParser()
    p.add_argument("sciezki", nargs="*", default=[str(ROOT / "modules")])
    p.add_argument("--strict", action="store_true")
    a = p.parse_args()

    if not shutil.which("yosys"):
        print("Brak programu yosys")
        return 1 if a.strict else 0

    katalogi = []
    for s in a.sciezki:
        katalogi += sorted(Path(s).resolve().glob("**/hdl/verilog"))

    bledy = 0
    for katalog in katalogi:
        pliki = [f for f in sorted(katalog.glob("*.v")) if not f.name.startswith("tb_")]
        if not pliki:
            continue
        print(f"\n{katalog.relative_to(ROOT)}")
        for plik in pliki:
            for top in MODUL.findall(plik.read_text(encoding="utf-8")):
                skrypt = (f"read_verilog {' '.join(str(f) for f in pliki)}; "
                          f"synth -flatten -top {top} -lut 4; check -assert; stat")
                r = subprocess.run(["yosys", "-p", skrypt], capture_output=True, text=True, timeout=300)
                if r.returncode != 0:
                    bledy += 1
                    print(f"  FAIL  {top}")
                    print("        " + (r.stdout + r.stderr).strip()[-2000:].replace("\n", "\n        "))
                else:
                    stat = r.stdout.rsplit("Printing statistics", 1)[-1]
                    print(f"  OK    {top:24s} {podsumowanie(stat)}")

    print(f"\nBłędów syntezy: {bledy}")
    return 1 if bledy else 0


if __name__ == "__main__":
    sys.exit(main())
