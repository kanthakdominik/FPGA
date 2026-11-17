#!/usr/bin/env python3
"""Ograniczenia CDC w OpenSTA (15.07): synteza cdc_dobry do NanGate 45 nm i skrypt e07_cdc.tcl.

Parser raportów — ten sam co w module 14 (sprawdz_sta.sekcje). Zmienne: STA, LIB_DIR.
Użycie: python3 sprawdz_sta_cdc.py
"""
import os
import subprocess
import sys
from pathlib import Path

TU = Path(__file__).resolve().parent
sys.path.insert(0, str(TU.parent.parent / "14-analiza-czasowa" / "sta"))
from sprawdz_sta import sekcje  # noqa: E402

STA = os.environ.get("STA", "sta")
LIB_DIR = os.environ.get("LIB_DIR", "/opt/opensta/lib")
OCZEKIWANE = {"bez_ograniczen_setup": "*", "bez_ograniczen_hold": "*",
              "max_delay_setup": "MET", "max_delay_hold": None, "grupy_i_max_delay": None}


def main():
    (TU / "build").mkdir(exist_ok=True)
    p = subprocess.run(["yosys", "-q", "-c", "synteza_asic.tcl"], cwd=TU, capture_output=True, text=True,
                       env={**os.environ, "LIB": f"{LIB_DIR}/nangate45_typ.lib"})
    if p.returncode != 0:
        sys.exit(p.stdout + p.stderr)
    p = subprocess.run([STA, "-no_init", "-exit", "e07_cdc.tcl"], cwd=TU, capture_output=True, text=True,
                       env={**os.environ, "LIB_DIR": LIB_DIR})
    log = p.stdout + p.stderr
    (TU / "build" / "e07_cdc.log").write_text(log)
    w = sekcje(log)
    bledy = 0
    print("== e07_cdc: wskaźnik Graya wr_gray (clk_a 10 ns) -> synchronizator (clk_b 27,3 ns)")
    for et, oczek in OCZEKIWANE.items():
        d = w.get(et)
        if d is None:
            print(f"  {et:22s} BRAK SEKCJI")
            bledy += 1
            continue
        if d["stan"] is None:
            opis = "brak sciezek"
        elif "launch" in d:
            opis = (f"{d['launch_clk']:>10s} {d['launch']:7.2f} -> {d['capture_clk']:>10s} {d['capture']:7.2f}"
                    f"  relacja {d['capture'] - d['launch']:6.2f}  zapas {d['slack']:7.3f} {d['stan']}")
        else:
            opis = (f"max_delay {d.get('required_raw', 0):5.2f}  przybycie {d.get('arrival', 0):6.3f}"
                    f"  zapas {d['slack']:7.3f} {d['stan']}")
        ok = oczek == "*" and d["stan"] is not None or d["stan"] == oczek
        bledy += not ok
        print(f"  {et:22s} {opis}  {'OK' if ok else '<-- NIEZGODNE (oczekiwano ' + str(oczek) + ')'}")
    rel = w.get("bez_ograniczen_setup", {})
    if "launch" in rel:
        r = rel["capture"] - rel["launch"]
        ok = 0 < r < 10
        bledy += not ok
        print(f"  {'OK ' if ok else 'BLAD'} bez ograniczen: relacja zboczy {r:.2f} ns < okres clk_a (przypadkowa)")
    print("PASS" if bledy == 0 else f"FAIL: {bledy} niezgodnosci")
    return 1 if bledy else 0


if __name__ == "__main__":
    sys.exit(main())
