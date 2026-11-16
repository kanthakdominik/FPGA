#!/usr/bin/env python3
"""Lint kodu Verilog i SystemVerilog Verilatorem (--lint-only -Wall) — moduły z katalogów hdl/verilog/ i hdl/sv/.

Wszystkie moduły katalogu (pliki bez przedrostka tb_) są sprawdzane jednym wywołaniem; moduły, których nikt
nie instancjonuje, są dla Verilatora modułami nadrzędnymi (stąd -Wno-MULTITOP). Pliki .v są czytane jako Verilog-2005, pliki .sv jako SystemVerilog.
Testbenche są pomijane — w nich lint ma mniejsze znaczenie.

Ostrzeżenia, które świadomie dopuszczamy w kodzie, wyłącza się w pliku komentarzem
/* verilator lint_off <KOD> */ … /* verilator lint_on <KOD> */ z uzasadnieniem obok.

Użycie:
    python3 tools/lint_hdl.py [ścieżka ...] [--strict] [--strict-od NN]
    --strict        każde ostrzeżenie jest błędem
    --strict-od NN  ostrzeżenie jest błędem w modułach o numerze >= NN, w starszych tylko raport (CI: --strict-od 7)
Bez tych opcji skrypt tylko raportuje i kończy się kodem 0.
"""
import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OSTRZEZENIE = re.compile(r"^%Warning-\w+:", re.M)


def kolejnosc(pliki):
    """Pakiety (*_pkg) na początku — muszą być znane przed modułami, które je importują."""
    return sorted(pliki, key=lambda f: (not f.stem.endswith("_pkg"), f.name))


def main():
    p = argparse.ArgumentParser()
    p.add_argument("sciezki", nargs="*", default=[str(ROOT / "modules")])
    p.add_argument("--strict", action="store_true")
    p.add_argument("--strict-od", type=int, default=None)
    a = p.parse_args()

    if not shutil.which("verilator"):
        print("Brak programu verilator")
        return 1 if (a.strict or a.strict_od is not None) else 0

    katalogi = []
    for s in a.sciezki:
        for jezyk in ("verilog", "sv"):
            katalogi += sorted(Path(s).resolve().glob(f"**/hdl/{jezyk}"))

    problemy = 0
    bledy = 0
    for katalog in katalogi:
        rozsz = ".v" if katalog.name == "verilog" else ".sv"
        pliki = [f for f in kolejnosc(katalog.glob(f"*{rozsz}")) if not f.name.startswith("tb_")]
        if not pliki:
            continue
        print(f"\n{katalog.relative_to(ROOT)}")
        jezyk = ["--default-language", "1364-2005"] if rozsz == ".v" else ["--default-language", "1800-2017"]
        cmd = ["verilator", "--lint-only", "-Wall", "-Wno-MULTITOP", *jezyk, *map(str, pliki)]
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        log = (r.stdout + r.stderr).strip().replace(str(ROOT) + "/", "")
        n = len(OSTRZEZENIE.findall(log))
        if r.returncode == 0 and n == 0:
            print(f"  OK    {len(pliki)} plików bez ostrzeżeń")
        else:
            problemy += n or 1
            numer = re.match(r"(\d+)-", katalog.parent.parent.name)
            scisle = a.strict or (a.strict_od is not None and numer and int(numer.group(1)) >= a.strict_od)
            if scisle:
                bledy += n or 1
            print(f"  {'BŁĄD ' if scisle else 'UWAGA'} {n} komunikatów")
            print("        " + log[-4000:].replace("\n", "\n        "))

    print(f"\nKomunikatów lintu: {problemy}, w tym w trybie ścisłym: {bledy}")
    return 1 if bledy else 0


if __name__ == "__main__":
    sys.exit(main())
