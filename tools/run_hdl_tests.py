#!/usr/bin/env python3
"""Uruchamia wszystkie samosprawdzające się testbenche z katalogów hdl/ modułów.

Układ katalogów (docs/STYL-KODU.md):
    modules/<moduł>/hdl/vhdl/     tb_*.vhd  -> GHDL (VHDL-2008)
    modules/<moduł>/hdl/verilog/  tb_*.v    -> Icarus Verilog (Verilog-2005)
    modules/<moduł>/hdl/sv/       tb_*.sv   -> Verilator 5 (--binary --timing)

Testbench zalicza się, gdy wypisze linię zaczynającą się od "PASS" i żadnej od "FAIL".

Użycie:
    python3 tools/run_hdl_tests.py [ścieżka ...] [--strict]
    --strict  brak symulatora jest błędem (używane w CI)
"""
import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TIMEOUT = 180

JEZYKI = {
    "vhdl": (".vhd", "ghdl"),
    "verilog": (".v", "iverilog"),
    "sv": (".sv", "verilator"),
}


def uruchom(cmd, cwd):
    p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=TIMEOUT)
    return p.returncode, p.stdout + p.stderr


def test_vhdl(katalog, tb, tmp):
    zrodla = sorted(str(f) for f in katalog.glob("*.vhd"))
    kroki = [
        ["ghdl", "-i", "--std=08", f"--workdir={tmp}", *zrodla],
        ["ghdl", "-m", "--std=08", f"--workdir={tmp}", tb.stem],
        ["ghdl", "-r", "--std=08", f"--workdir={tmp}", tb.stem, "--assert-level=error"],
    ]
    log = ""
    for k in kroki:
        rc, out = uruchom(k, tmp)
        log += out
        if rc != 0 and k is not kroki[-1]:
            return False, log
    return wynik(log)


def test_verilog(katalog, tb, tmp):
    zrodla = [str(f) for f in sorted(katalog.glob("*.v")) if not f.name.startswith("tb_")]
    exe = os.path.join(tmp, "sim.vvp")
    rc, log = uruchom(["iverilog", "-g2005", "-Wall", "-s", tb.stem, "-o", exe, *zrodla, str(tb)], tmp)
    if rc != 0:
        return False, log
    rc, out = uruchom(["vvp", "-n", exe], tmp)
    return wynik(log + out)


def kolejnosc_sv(pliki):
    """Pakiety (*_pkg.sv) muszą być skompilowane przed modułami, które je importują."""
    return sorted(pliki, key=lambda f: (not f.stem.endswith("_pkg"), f.name))


def test_sv(katalog, tb, tmp):
    zrodla = [str(f) for f in kolejnosc_sv(katalog.glob("*.sv")) if not f.name.startswith("tb_")]
    rc, log = uruchom(["verilator", "--binary", "--timing", "--timescale", "1ns/1ps", "-Wno-fatal", "-Wno-lint", "-Wno-style",
                       "--top-module", tb.stem, "-Mdir", tmp, *zrodla, str(tb)], tmp)
    if rc != 0:
        return False, log
    rc, out = uruchom([os.path.join(tmp, f"V{tb.stem}")], tmp)
    return wynik(log + out)


WYNIK = re.compile(r"(?:^|\): )(PASS|FAIL)\b")


def wynik(log):
    znalezione = [m.group(1) for l in log.splitlines() if (m := WYNIK.search(l.strip()))]
    ok = "PASS" in znalezione and "FAIL" not in znalezione
    return ok, log


TESTY = {"vhdl": test_vhdl, "verilog": test_verilog, "sv": test_sv}

# Moduły nadrzędne dla DECA (deca/<projekt>/deca_top.*) nie mają testbenchy, bo Quartusa nie ma w CI.
# Sprawdzamy przynajmniej, czy kompilują się razem z kodem z hdl/ w otwartych narzędziach.
TOP_DECA = {".vhd": "vhdl", ".v": "verilog", ".sv": "sv"}


def sprawdz_top_deca(top, tmp):
    rozsz = top.suffix
    jezyk = TOP_DECA[rozsz]
    hdl = top.parent.parent.parent / "hdl" / jezyk
    zrodla = [str(f) for f in kolejnosc_sv(hdl.glob(f"*{rozsz}")) if not f.name.startswith("tb_")]
    zrodla += [str(f) for f in kolejnosc_sv(top.parent.glob(f"*{rozsz}")) if f != top] + [str(top)]
    if jezyk == "vhdl":
        rc, log = uruchom(["ghdl", "-i", "--std=08", f"--workdir={tmp}", *zrodla], tmp)
        if rc == 0:
            rc, out = uruchom(["ghdl", "-m", "--std=08", f"--workdir={tmp}", top.stem], tmp)
            log += out
    elif jezyk == "verilog":
        rc, log = uruchom(["iverilog", "-g2005", "-Wall", "-o", os.path.join(tmp, "a.out"),
                           "-s", top.stem, *zrodla], tmp)
    else:
        rc, log = uruchom(["verilator", "--lint-only", "-Wall", "-Wno-fatal", "--top-module", top.stem,
                           *zrodla], tmp)
    return rc == 0, log


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sciezki", nargs="*", default=[str(ROOT / "modules")])
    ap.add_argument("--strict", action="store_true")
    a = ap.parse_args()

    zadania, topy = [], []
    for s in a.sciezki:
        topy += sorted(Path(s).resolve().glob("**/deca/*/deca_top.*"))
        for jezyk, (rozsz, _) in JEZYKI.items():
            for katalog in sorted(Path(s).resolve().glob(f"**/hdl/{jezyk}")):
                for tb in sorted(katalog.glob(f"tb_*{rozsz}")):
                    zadania.append((jezyk, katalog, tb))

    if not zadania and not topy:
        print("Brak testbenchy do uruchomienia.")
        return 0

    bledy, pominiete = 0, 0
    for jezyk, katalog, tb in zadania:
        nazwa = tb.relative_to(ROOT) if tb.is_relative_to(ROOT) else tb
        if shutil.which(JEZYKI[jezyk][1]) is None:
            print(f"SKIP  {nazwa} (brak {JEZYKI[jezyk][1]})")
            pominiete += 1
            continue
        with tempfile.TemporaryDirectory() as tmp:
            try:
                ok, log = TESTY[jezyk](katalog, tb, tmp)
            except subprocess.TimeoutExpired:
                ok, log = False, f"przekroczony czas {TIMEOUT} s"
        print(f"{'PASS' if ok else 'FAIL'}  {nazwa}")
        if not ok:
            bledy += 1
            print("      " + "\n      ".join(log.strip().splitlines()[-30:]))

    for top in topy:
        nazwa = top.relative_to(ROOT) if top.is_relative_to(ROOT) else top
        narzedzie = JEZYKI[TOP_DECA[top.suffix]][1]
        if shutil.which(narzedzie) is None:
            print(f"SKIP  {nazwa} (brak {narzedzie})")
            pominiete += 1
            continue
        with tempfile.TemporaryDirectory() as tmp:
            ok, log = sprawdz_top_deca(top, tmp)
        print(f"{'OK  ' if ok else 'FAIL'}  {nazwa} (kompilacja)")
        if not ok:
            bledy += 1
            print("      " + "\n      ".join(log.strip().splitlines()[-30:]))

    print(f"\n{len(zadania)} testbenchy i {len(topy)} modułów DECA: {len(zadania) + len(topy) - bledy - pominiete} zaliczonych, "
          f"{bledy} błędów, {pominiete} pominiętych")
    if bledy or (a.strict and pominiete):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
