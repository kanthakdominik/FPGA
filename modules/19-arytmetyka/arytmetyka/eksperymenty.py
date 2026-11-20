#!/usr/bin/env python3
"""Eksperymenty modułu 19: układy arytmetyczne z hdl/verilog po syntezie Yosysem (synth_ecp5)
i rozmieszczeniu nextpnr-ecp5 (LFE5U-25F, CABGA381, klasa szybkości 6). Dla każdego wariantu:
f_max (ścieżki rejestr–rejestr), LUT4, przerzutniki, bloki mnożarek MULT18X18D (18 × 18, jak w MAX 10).

  e1  mnożenie szerokie (19.02): 18 × 18 (LAT = 2 i 4) i 34 × 34 wprost (mnoz_potok) oraz 34 × 34 z potokiem
      za iloczynami częściowymi (mnoz_szeroki) — liczba bloków i f_max
  e2  mnożenie zespolone (19.02): cztery mnożenia i trzy (sztuczka Gaussa)
  e3  dzielenie (19.03): dziel_iter (bit na takt) i dziel_potok (wynik na takt), W = 16, oraz pierw_iter
  e4  CORDIC (19.04): N = 12 i 18 iteracji, W = 16 — bez mnożarek
  e5  liczby zmiennoprzecinkowe (19.05): fp32_mnoz i samo mnożenie mantys 24 × 24
  e6  aproksymacja (19.06): interp_lin — tablice i jedna mnożarka

Użycie: python3 eksperymenty.py [e1 … e6]   (bez argumentów — wszystkie)
Wymaga yosys i nextpnr-ecp5 w PATH (OSS CAD Suite). Wyniki: build/wyniki.json, tabela na stdout,
kod wyjścia 1, gdy któraś oczekiwana zależność nie zachodzi.
"""
import json
import subprocess
import sys
from pathlib import Path

TU = Path(__file__).resolve().parent
HDL = TU.parent / "hdl" / "verilog"
DANE = TU.parent / "hdl" / "dane"                   # katalog roboczy Yosysa: pliki $readmemh
BUILD = TU / "build"
URZADZENIE = ["--25k", "--package", "CABGA381", "--speed", "6"]
wyniki = {}
bledy = []


def uruchom(cmd):
    p = subprocess.run(cmd, cwd=DANE, capture_output=True, text=True)
    if p.returncode != 0:
        print(p.stdout[-3000:], p.stderr[-3000:])
        raise RuntimeError(" ".join(cmd[:3]))
    return p


def wariant(klucz, top, pliki, param=None, opis=""):
    nazwa = klucz.replace(" ", "_").replace("×", "x").replace("=", "")
    chparam = "".join(f"chparam -set {k} {v} {top}; " for k, v in (param or {}).items())
    plik = BUILD / f"{nazwa}.json"
    uruchom(["yosys", "-q", "-l", str(BUILD / f"{nazwa}_yosys.log"), "-p",
             f"read_verilog {' '.join(str(HDL / p) for p in pliki)}; {chparam}"
             f"synth_ecp5 -top {top} -json {plik}"])
    raport = BUILD / f"{nazwa}_pnr.json"
    uruchom(["nextpnr-ecp5", *URZADZENIE, "--json", str(plik), "--freq", "400", "--timing-allow-fail",
             "--seed", "1", "--report", str(raport), "-l", str(BUILD / f"{nazwa}_pnr.log")])
    r = json.loads(raport.read_text())
    fmax = min((v["achieved"] for v in r["fmax"].values()), default=0.0)
    u = r["utilization"]
    zas = {k: u[k]["used"] for k in ("TRELLIS_COMB", "TRELLIS_FF", "MULT18X18D", "DP16KD") if k in u}
    wyniki[klucz] = {"fmax": round(fmax, 1), **zas}
    print(f"  {klucz:30s} f_max {fmax:6.1f} MHz  LUT {zas.get('TRELLIS_COMB', 0):5d}  "
          f"FF {zas.get('TRELLIS_FF', 0):5d}  DSP {zas.get('MULT18X18D', 0):2d}  "
          f"BRAM {zas.get('DP16KD', 0):2d}  {opis}")
    return wyniki[klucz]


def oczekuj(warunek, opis):
    print(f"  {'OK  ' if warunek else 'BLAD'} {opis}")
    if not warunek:
        bledy.append(opis)


def e1():
    print("\n== e1: mnożenie szerokie (bloki 18 × 18)")
    r18 = wariant("18x18 mnoz_potok", "mnoz_potok", ["mnoz_potok.v"], {"WA": 18, "WB": 18, "LAT": 2})
    r18_4 = wariant("18x18 mnoz_potok LAT4", "mnoz_potok", ["mnoz_potok.v"], {"WA": 18, "WB": 18, "LAT": 4},
                    "dwa dodatkowe rejestry za blokiem")
    r34 = wariant("34x34 mnoz_potok", "mnoz_potok", ["mnoz_potok.v"], {"WA": 34, "WB": 34, "LAT": 2},
                  "iloczyny częściowe i ich suma w jednym takcie")
    rsz = wariant("34x34 mnoz_szeroki", "mnoz_szeroki", ["mnoz_szeroki.v"], {"H": 17},
                  "rejestr za iloczynami częściowymi")
    oczekuj(r18.get("MULT18X18D") == 1, "18 × 18 — jeden blok")
    oczekuj(abs(r18_4["fmax"] - r18["fmax"]) < 0.1 * r18["fmax"],
            "rejestry za blokiem bez wewnętrznego rejestru potoku nie podnoszą f_max (różnica < 10 %)")
    oczekuj(r34.get("MULT18X18D", 0) >= 4 and rsz.get("MULT18X18D") == 4, "34 × 34 — cztery bloki (lub więcej)")
    oczekuj(rsz["fmax"] > r34["fmax"], "rejestr przed sumą iloczynów częściowych podnosi f_max")


def e2():
    print("\n== e2: mnożenie zespolone 16-bitowe")
    r4 = wariant("zesp 4 mnozenia", "mnoz_zesp", ["mnoz_zesp.v"], {"TRZY": 0})
    r3 = wariant("zesp 3 mnozenia", "mnoz_zesp", ["mnoz_zesp.v"], {"TRZY": 1})
    oczekuj(r4.get("MULT18X18D") == 4 and r3.get("MULT18X18D") == 3, "4 i 3 bloki mnożarek")
    oczekuj(r3["TRELLIS_COMB"] > r4["TRELLIS_COMB"], "trzy mnożenia kosztują więcej logiki (sumatory)")


def e3():
    print("\n== e3: dzielenie i pierwiastek, W = 16")
    ri = wariant("dziel_iter W16", "dziel_iter", ["dziel_iter.v"], {"W": 16}, "wynik co 18 taktów")
    rp = wariant("dziel_potok W16", "dziel_potok", ["dziel_potok.v"], {"W": 16}, "wynik w każdym takcie")
    wariant("pierw_iter W16", "pierw_iter", ["pierw_iter.v"], {"W": 16}, "x 32-bitowe, wynik co 18 taktów")
    for k, r, n in (("dziel_iter W16", ri, 18), ("dziel_potok W16", rp, 1)):
        wyniki[k]["mln_wynikow_na_s"] = round(r["fmax"] / n, 1)
    print(f"  przepustowość: iteracyjnie {ri['fmax'] / 18:.1f} mln dzieleń/s, potok {rp['fmax']:.1f} mln/s")
    oczekuj(rp["TRELLIS_FF"] > 5 * ri["TRELLIS_FF"], "potok: wielokrotnie więcej przerzutników (3W² zamiast ok. 6W)")
    oczekuj(rp["fmax"] / 1 > 8 * ri["fmax"] / 18, "potok: wielokrotnie większa przepustowość")


def e4():
    print("\n== e4: CORDIC, W = 16, A = 24")
    r12 = wariant("cordic N12", "cordic", ["cordic.v"], {"N": 12})
    r18 = wariant("cordic N18", "cordic", ["cordic.v"], {"N": 18})
    oczekuj(r12.get("MULT18X18D", 0) == 0 and r18.get("MULT18X18D", 0) == 0, "CORDIC bez mnożarek")
    oczekuj(r18["TRELLIS_FF"] > r12["TRELLIS_FF"], "koszt rośnie z liczbą iteracji")


def e5():
    print("\n== e5: mnożenie zmiennoprzecinkowe binary32")
    rf = wariant("fp32_mnoz", "fp32_mnoz", ["fp32_mnoz.v"])
    rm = wariant("mantysy 24x24 bez znaku", "mnoz_potok", ["mnoz_potok.v"], {"WA": 24, "WB": 24, "ZNAK": 0, "LAT": 2})
    oczekuj(rf.get("MULT18X18D") == rm.get("MULT18X18D"), "te same bloki mnożarek co samo mnożenie mantys")
    oczekuj(rf["TRELLIS_COMB"] > rm["TRELLIS_COMB"], "obsługa wykładnika, zaokrąglenia i wartości specjalnych kosztuje logikę")


def e6():
    print("\n== e6: interpolacja liniowa z tablic (64 odcinki)")
    r = wariant("interp_lin S6", "interp_lin", ["interp_lin.v"])
    oczekuj(r.get("MULT18X18D") == 1, "jedna mnożarka")


def main():
    BUILD.mkdir(exist_ok=True)
    wybrane = sys.argv[1:] or ["e1", "e2", "e3", "e4", "e5", "e6"]
    for e in wybrane:
        globals()[e]()
    (BUILD / "wyniki.json").write_text(json.dumps(wyniki, indent=1, ensure_ascii=False))
    print("\nPASS" if not bledy else f"\nFAIL: {len(bledy)} niespełnionych zależności")
    return 1 if bledy else 0


if __name__ == "__main__":
    sys.exit(main())
