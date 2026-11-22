#!/usr/bin/env python3
"""Syntezuje w Yosysie każdy moduł Verilog z katalogów hdl/verilog/ i wypisuje zużycie zasobów.

Synteza ogólna na LUT o 4 wejściach (jak w MAX 10): `synth -flatten -top <moduł> -lut 4; check -assert; stat; ltp -noff`.
Sprawdza, że kod jest syntezowalny (bez wielokrotnego sterowania, niepodłączonych wejść komórek itp.),
i daje orientacyjną liczbę LUT i przerzutników dla sekcji „Co powstaje po syntezie”. `ltp -noff` podaje
najdłuższą ścieżkę kombinacyjną (liczbę komórek między przerzutnikami lub portami) — miarę głębokości logiki.

Moduły są syntezowane z domyślnymi parametrami. Testbenche (tb_*.v) są pomijane.
Dodatkowe zestawy parametrów można podać w pliku modułu komentarzem (każdy wariant to osobna synteza):
    // yosys-warianty: ENC=1; ENC=2

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
WARIANTY = re.compile(r"^\s*//\s*yosys-warianty:\s*(.+)$", re.M)
LTP = re.compile(r"Longest topological path in \S+ \(length=(\d+)\)")


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
    p.add_argument("sciezki", nargs="*", default=[str(ROOT / "modules"), str(ROOT / "rozmowa-kwalifikacyjna")])
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
            tekst = plik.read_text(encoding="utf-8")
            warianty = [""]
            for linia in WARIANTY.findall(tekst):
                warianty += [w.strip() for w in linia.split(";") if w.strip()]
            for top, wariant in [(t, w) for t in MODUL.findall(tekst) for w in warianty]:
                chparam = "".join(f"chparam -set {k} {v} {top}; "
                                  for k, v in (x.split("=", 1) for x in wariant.split()))
                skrypt = (f"read_verilog {' '.join(str(f) for f in pliki)}; {chparam}"
                          f"synth -flatten -top {top} -lut 4; check -assert; stat; ltp -noff")
                nazwa = f"{top}[{wariant}]" if wariant else top
                # pliki zawartości pamięci ($readmemh) leżą w hdl/dane — Yosys szuka ich względem katalogu roboczego
                dane = katalog.parent / "dane"
                r = subprocess.run(["yosys", "-p", skrypt], capture_output=True, text=True, timeout=300,
                                   cwd=dane if dane.is_dir() else None)
                if r.returncode != 0:
                    bledy += 1
                    print(f"  FAIL  {nazwa}")
                    print("        " + (r.stdout + r.stderr).strip()[-2000:].replace("\n", "\n        "))
                else:
                    stat = r.stdout.rsplit("Printing statistics", 1)[-1]
                    ltp = LTP.findall(r.stdout)
                    glebokosc = f"   głębokość: {ltp[-1]}" if ltp else ""
                    print(f"  OK    {nazwa:24s} {podsumowanie(stat.split('Longest topological')[0])}{glebokosc}")

    print(f"\nBłędów syntezy: {bledy}")
    return 1 if bledy else 0


if __name__ == "__main__":
    sys.exit(main())
