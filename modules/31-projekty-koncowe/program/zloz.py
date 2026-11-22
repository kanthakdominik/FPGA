#!/usr/bin/env python3
"""Składa program mcu.S (31.06) asemblerem z modułu 27 (rvasm.py) w dwóch wariantach stałych:
symulacja (krótkie okresy) i płytka DECA (50 MHz). Wyniki: hdl/dane/mcu_sym.hex (testbenche),
deca/rv_mcu/mcu_deca.hex i mcu_deca.mif (Quartus).

  python3 program/zloz.py            — zapisz pliki
  python3 program/zloz.py --sprawdz  — porównaj z plikami w repozytorium (CI)
"""
import importlib.util
import sys
from pathlib import Path

TU = Path(__file__).resolve().parent
MOD = TU.parent
spec = importlib.util.spec_from_file_location(
    "rvasm", MOD.parent / "27-procesory-i-soc" / "program" / "rvasm.py")
rvasm = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rvasm)

SLOWA = 1024
WARIANTY = {
    "sym":  {"OKRES_LED": 3000, "OKRES_PWM": 40, "WYPELN_PWM": 10},
    "deca": {"OKRES_LED": 12_500_000, "OKRES_PWM": 50_000, "WYPELN_PWM": 5_000},
}


def zloz(stale):
    zrodlo = "".join(".equ %s, %d\n" % kv for kv in stale.items())
    zrodlo += (TU / "mcu.S").read_text(encoding="utf-8")
    slowa = rvasm.Asembler().zloz(zrodlo)
    if len(slowa) > SLOWA:
        raise SystemExit("program za duży: %d słów" % len(slowa))
    return slowa


def pliki():
    sym = zloz(WARIANTY["sym"])
    deca = zloz(WARIANTY["deca"])
    return {
        MOD / "hdl" / "dane" / "mcu_sym.hex": rvasm.hex_slowa(sym),
        MOD / "deca" / "rv_mcu" / "mcu_deca.hex": rvasm.hex_slowa(deca),
        MOD / "deca" / "rv_mcu" / "mcu_deca.mif": rvasm.mif(deca, SLOWA),
    }, len(sym)


def main():
    p, n = pliki()
    if "--sprawdz" in sys.argv:
        zle = [k for k, v in p.items() if not k.exists() or k.read_text() != v]
        for k in zle:
            print("NIEZGODNY z mcu.S:", k.relative_to(MOD))
        print("mcu.S: %d słów; plików zgodnych %d/%d" % (n, len(p) - len(zle), len(p)))
        return 1 if zle else 0
    for k, v in p.items():
        k.parent.mkdir(parents=True, exist_ok=True)
        k.write_text(v)
        print("zapisano", k.relative_to(MOD))
    print("mcu.S: %d słów" % n)
    return 0


if __name__ == "__main__":
    sys.exit(main())
