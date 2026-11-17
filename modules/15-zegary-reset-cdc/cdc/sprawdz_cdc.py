#!/usr/bin/env python3
"""Uruchamia cdc_lint.py na przykładach modułu 15 i porównuje liczby przejść z oczekiwanymi.

cdc_dobry — same poprawne przejścia; cdc_zly — po jednym przykładzie każdego błędu; deca_top (Verilog) —
projekt DECA: przyciski i przełączniki asynchroniczne, domeny clk50 i clk10.
Użycie: python3 sprawdz_cdc.py
"""
import json
import subprocess
import sys
from pathlib import Path

TU = Path(__file__).resolve().parent
HDL = sorted(str(p) for p in (TU.parent / "hdl" / "verilog").glob("*.v")
             if not p.name.startswith("tb_") and p.name != "bramkowanie.v")
PRZYPADKI = [
    ("cdc_dobry", [str(TU / "cdc_przyklady.v")], "_a=clk_a,_b=clk_b",
     {"SYNC": 17, "WIELOBITOWE_GRAY": 3, "DANE_POD_KONTROLA": 16}),
    ("cdc_zly", [str(TU / "cdc_przyklady.v")], "_a=clk_a,_b=clk_b",
     {"BRAK_DRUGIEGO_STOPNIA": 1, "LOGIKA_PRZED_SYNC": 1, "SYNC": 4, "WIELOBITOWE_BEZ_GRAYA": 1,
      "BRAK_SYNCHRONIZACJI": 8}),
    ("deca_top", [str(TU.parent / "deca" / "cdc" / "deca_top.v")], "",
     None),                                         # wystarczy: brak błędów
]
BLEDY = {"BRAK_DRUGIEGO_STOPNIA", "METASTABILNE_DO_LOGIKI", "LOGIKA_PRZED_SYNC", "BRAK_SYNCHRONIZACJI",
         "WIELOBITOWE_BEZ_GRAYA"}


def main():
    zle = 0
    for top, pliki, porty, oczekiwane in PRZYPADKI:
        wynik = TU / f"{top}_cdc.json"
        p = subprocess.run([sys.executable, str(TU / "cdc_lint.py"), top, *HDL, *pliki, "--porty", porty,
                            "--json", str(wynik)], capture_output=True, text=True)
        print(p.stdout.rstrip())
        if p.stderr:
            print(p.stderr.rstrip())
        licz = json.loads(wynik.read_text()) if wynik.exists() else {}
        wynik.unlink(missing_ok=True)
        if oczekiwane is None:
            ok = sum(v for k, v in licz.items() if k in BLEDY) == 0 and licz.get("SYNC", 0) > 0
        else:
            ok = licz == oczekiwane
        print(f"  {'OK' if ok else '<-- NIEZGODNE, oczekiwano ' + str(oczekiwane)}\n")
        zle += not ok
    print("PASS" if zle == 0 else f"FAIL: {zle} niezgodnych")
    return 1 if zle else 0


if __name__ == "__main__":
    sys.exit(main())
