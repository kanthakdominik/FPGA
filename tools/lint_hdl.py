#!/usr/bin/env python3
"""Lint kodu Verilog i SystemVerilog Verilatorem (--lint-only -Wall) — moduły z katalogów hdl/verilog/ i hdl/sv/.

Każdy moduł (plik bez przedrostka tb_) jest sprawdzany jako moduł nadrzędny, razem z pozostałymi plikami
z katalogu (pakiety, interfejsy, podmoduły). Pliki .v są czytane jako Verilog-2005, pliki .sv jako SystemVerilog.
Testbenche są pomijane — w nich lint ma mniejsze znaczenie.

Ostrzeżenia, które świadomie dopuszczamy w kodzie, wyłącza się w pliku komentarzem
/* verilator lint_off <KOD> */ … /* verilator lint_on <KOD> */ z uzasadnieniem obok.

Użycie:
    python3 tools/lint_hdl.py [ścieżka ...] [--strict]
    --strict  każde ostrzeżenie jest błędem (CI: moduły, których kod ma być „czysty”)
Bez --strict skrypt tylko raportuje i kończy się kodem 0.
"""
import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MODUL = re.compile(r"^\s*module\s+(\w+)", re.M)
OSTRZEZENIE = re.compile(r"^%(Warning|Error)(-\w+)?:", re.M)


def kolejnosc(pliki):
    """Pakiety (*_pkg) na początku — muszą być znane przed modułami, które je importują."""
    return sorted(pliki, key=lambda f: (not f.stem.endswith("_pkg"), f.name))


def main():
    p = argparse.ArgumentParser()
    p.add_argument("sciezki", nargs="*", default=[str(ROOT / "modules")])
    p.add_argument("--strict", action="store_true")
    a = p.parse_args()

    if not shutil.which("verilator"):
        print("Brak programu verilator")
        return 1 if a.strict else 0

    katalogi = []
    for s in a.sciezki:
        for jezyk in ("verilog", "sv"):
            katalogi += sorted(Path(s).resolve().glob(f"**/hdl/{jezyk}"))

    problemy = 0
    for katalog in katalogi:
        rozsz = ".v" if katalog.name == "verilog" else ".sv"
        pliki = [f for f in kolejnosc(katalog.glob(f"*{rozsz}")) if not f.name.startswith("tb_")]
        if not pliki:
            continue
        print(f"\n{katalog.relative_to(ROOT)}")
        jezyk = ["--default-language", "1364-2005"] if rozsz == ".v" else ["--default-language", "1800-2017"]
        for plik in pliki:
            for top in MODUL.findall(plik.read_text(encoding="utf-8")):
                cmd = ["verilator", "--lint-only", "-Wall", *jezyk, "--top-module", top, *map(str, pliki)]
                r = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
                log = (r.stdout + r.stderr).strip()
                n = len(OSTRZEZENIE.findall(log))
                if r.returncode == 0 and n == 0:
                    print(f"  OK    {top}")
                else:
                    problemy += 1
                    print(f"  UWAGA {top}: {n} komunikatów")
                    print("        " + log[-3000:].replace("\n", "\n        "))

    print(f"\nModułów z ostrzeżeniami: {problemy}")
    return 1 if (a.strict and problemy) else 0


if __name__ == "__main__":
    sys.exit(main())
