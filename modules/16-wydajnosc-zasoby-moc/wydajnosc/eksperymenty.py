#!/usr/bin/env python3
"""Eksperymenty modułu 16: te same układy z hdl/verilog w kilku wariantach, synteza Yosysem
(synth_ecp5), rozmieszczenie i trasowanie nextpnr-ecp5 (LFE5U-25F, CABGA381, klasa szybkości 6).
Dla każdego wariantu: f_max zegara, zasoby po upakowaniu (LUT4, przerzutniki, mnożarki DSP)
i — gdzie ma to znaczenie — największy fanout sieci w netliście.

  e1  potokowanie (16.01): sumator_drzewo PIPE = 0, 1, 2
  e1r retiming (16.01): PIPE = 0 z dwoma rejestrami na wyjściu (RET = 2), bez i z synth_ecp5 -retime
  e2  współdzielenie (16.02): mnoz_wybor (dwie mnożarki / jedna), iloczyn_rown / iloczyn_szer,
      oraz synteza ogólna na LUT4 (bez DSP) obu wersji mnoz_wybor
  e3  głębokość logiki i fanout (16.03): max_n łańcuch / drzewo; rozgalezienie NDUP = 1, 8, 32
  e4  zamykanie timingu (16.04): ten sam układ z ośmioma ziarnami rozmieszczenia
  e5  floorplanning (16.05): floorplan_demo bez regionów, regiony blisko, regiony daleko

Użycie: python3 eksperymenty.py [e1 e1r e2 e3 e4 e5]   (bez argumentów — wszystkie)
Wymaga yosys i nextpnr-ecp5 w PATH (OSS CAD Suite). Wyniki: build/wyniki.json, tabela na stdout,
kod wyjścia 1, gdy któraś oczekiwana zależność nie zachodzi.
"""
import json
import os
import re
import subprocess
import sys
from pathlib import Path

TU = Path(__file__).resolve().parent
HDL = TU.parent / "hdl" / "verilog"
BUILD = TU / "build"
URZADZENIE = ["--25k", "--package", "CABGA381", "--speed", "6"]
wyniki = {}
bledy = []


def uruchom(cmd, env=None):
    p = subprocess.run(cmd, cwd=TU, capture_output=True, text=True, env=env)
    if p.returncode != 0:
        print(p.stdout[-3000:], p.stderr[-3000:])
        raise RuntimeError(" ".join(cmd[:3]))
    return p


def synteza(nazwa, top, pliki, param=None, opcje="", przed=""):
    """Yosys synth_ecp5 -> build/<nazwa>.json; zwraca maksymalny fanout sieci (bez zegara).
    przed — polecenia Yosysa wykonywane przed synth_ecp5 (np. ochrona rejestrów przed scaleniem)."""
    chparam = "".join(f"chparam -set {k} {v} {top}; " for k, v in (param or {}).items())
    plik = BUILD / f"{nazwa}.json"
    skrypt = (f"read_verilog {' '.join(str(p) for p in pliki)}; {chparam}{przed}"
              f"synth_ecp5 -top {top} {opcje} -json {plik}")
    uruchom(["yosys", "-q", "-l", str(BUILD / f"{nazwa}_yosys.log"), "-p", skrypt])
    return max_fanout(plik, top)


def max_fanout(plik, top):
    """Największa liczba wejść komórek zasilanych jednym bitem sieci (zegar pomijany)."""
    mod = json.loads(plik.read_text())["modules"][top]
    licz = {}
    for kom in mod["cells"].values():
        kier = kom.get("port_directions", {})
        for port, bity in kom["connections"].items():
            if kier.get(port) != "input" or port in ("CLK", "CK", "CLKI"):
                continue
            for b in bity:
                if isinstance(b, int):
                    licz[b] = licz.get(b, 0) + 1
    return max(licz.values()) if licz else 0


def pnr(nazwa, seed=1, extra=None, env=None):
    raport = BUILD / f"{nazwa}_s{seed}_pnr.json"
    uruchom(["nextpnr-ecp5", *URZADZENIE, "--json", str(BUILD / f"{nazwa}.json"), "--freq", "400",
             "--timing-allow-fail", "--seed", str(seed), "--report", str(raport),
             "-l", str(BUILD / f"{nazwa}_s{seed}_pnr.log"), *(extra or [])], env=env)
    r = json.loads(raport.read_text())
    fmax = min((v["achieved"] for v in r["fmax"].values()), default=0.0)
    u = r["utilization"]
    zas = {k: u[k]["used"] for k in ("TRELLIS_COMB", "TRELLIS_FF", "MULT18X18D") if k in u}
    return fmax, zas


def wariant(klucz, nazwa, top, pliki, param=None, opcje="", seed=1, extra=None, env=None, opis="", przed=""):
    fan = synteza(nazwa, top, pliki, param, opcje, przed)
    fmax, zas = pnr(nazwa, seed, extra, env)
    wyniki[klucz] = {"fmax": round(fmax, 1), "fanout": fan, **zas}
    print(f"  {klucz:28s} f_max {fmax:6.1f} MHz  LUT {zas.get('TRELLIS_COMB', 0):5d}  "
          f"FF {zas.get('TRELLIS_FF', 0):5d}  DSP {zas.get('MULT18X18D', 0):2d}  max fanout {fan:4d}  {opis}")
    return wyniki[klucz]


def oczekuj(warunek, opis):
    print(f"  {'OK  ' if warunek else 'BLAD'} {opis}")
    if not warunek:
        bledy.append(opis)


def e1():
    print("\n== e1: potokowanie drzewa sumatorów (8 x 16 bitów)")
    f = [HDL / "sumator_drzewo.v"]
    r = [wariant(f"sumator PIPE={p}", f"sum_p{p}", "sumator_drzewo", f, {"PIPE": p},
                 opis=f"opoznienie {2 + p} takty") for p in (0, 1, 2)]
    oczekuj(r[0]["fmax"] < r[1]["fmax"] < r[2]["fmax"], "f_max rośnie z liczbą stopni potoku")
    oczekuj(r[2]["TRELLIS_FF"] > r[0]["TRELLIS_FF"], "potok kosztuje przerzutniki")


def e1r():
    print("\n== e1r: retiming — PIPE = 0 i dwa rejestry na wyjściu (RET = 2)")
    f = [HDL / "sumator_drzewo.v"]
    bez = wariant("RET=2 bez retimingu", "sum_r2", "sumator_drzewo", f, {"RET": 2})
    najlepszy = 0.0
    for opcje in ("-retime", "-retime -noccu2"):
        nazwa = "sum_r2" + opcje.replace(" ", "").replace("-", "_")
        try:
            r = wariant(f"RET=2 {opcje}", nazwa, "sumator_drzewo", f, {"RET": 2}, opcje=opcje)
            najlepszy = max(najlepszy, r["fmax"])
        except RuntimeError as e:
            print(f"  {opcje}: niedostępne ({e})")
    wyniki["_retime_przyrost"] = round(najlepszy / bez["fmax"], 2)
    print(f"  dla porównania: PIPE=2 (te same 4 takty opóźnienia, rejestry wewnątrz drzewa) — "
          f"{wyniki.get('sumator PIPE=2', {}).get('fmax', '?')} MHz")


def e2():
    print("\n== e2: współdzielenie zasobów")
    f = [HDL / "mnoz_wybor.v", TU / "mnoz_wybor_rej.v"]
    r0 = wariant("mnoz_wybor dwie mnozarki", "mw0", "mnoz_wybor_rej", f, {"WSPOLNY": 0})
    r1 = wariant("mnoz_wybor jedna mnozarka", "mw1", "mnoz_wybor_rej", f, {"WSPOLNY": 1})
    # synteza ogólna na LUT4 (bez DSP): ten sam Yosys, inna kolejność przebiegów — mnożenia nie zostają
    # współdzielone; w synth_ecp5 przebieg share (log: "SAT-based resource sharing") łączy oba mnożenia
    # na podstawie wzorców aktywacji sel = 1 / sel = 0
    for wsp in (0, 1):
        plik = BUILD / f"mw_lut{wsp}.txt"
        uruchom(["yosys", "-q", "-p", f"read_verilog {HDL / 'mnoz_wybor.v'}; chparam -set WSPOLNY {wsp} mnoz_wybor; "
                 f"synth -flatten -top mnoz_wybor -lut 4; tee -q -o {plik} stat"])
        tekst = plik.read_text()
        n = sum(int(a or b) for a, b in re.findall(r"(\d+)\s+\$lut\b|\$lut\s+(\d+)", tekst))
        wyniki[f"mnoz_wybor LUT4 synth WSPOLNY={wsp}"] = n
        print(f"  Yosys synth -lut 4 (bez DSP) mnoz_wybor WSPOLNY={wsp}: {n} LUT4")
    oczekuj(wyniki["mnoz_wybor LUT4 synth WSPOLNY=0"] > 1.5 * wyniki["mnoz_wybor LUT4 synth WSPOLNY=1"],
            "synteza ogólna nie współdzieli mnożarek — ręczne współdzielenie oszczędza LUT")
    oczekuj(r0.get("MULT18X18D", 0) == r1.get("MULT18X18D", 0) == 1,
            "synth_ecp5 współdzieli mnożarki automatycznie (1 blok DSP w obu wersjach)")
    rr = wariant("iloczyn rownolegly", "il_rown", "iloczyn_rown", [HDL / "iloczyn_rown.v"], opis="1 wynik/takt")
    rs = wariant("iloczyn szeregowy", "il_szer", "iloczyn_szer", [HDL / "iloczyn_szer.v"], opis="1 wynik/4 takty")
    wyniki["_wydajnosc_rown_Mwynikow"] = rr["fmax"]
    wyniki["_wydajnosc_szer_Mwynikow"] = round(rs["fmax"] / 4, 1)
    print(f"  przepustowosc: rownolegly {rr['fmax']:.0f} mln wynikow/s, szeregowy {rs['fmax'] / 4:.0f} mln wynikow/s")
    oczekuj(rs.get("MULT18X18D", 0) < rr.get("MULT18X18D", 0) or rs["TRELLIS_COMB"] < rr["TRELLIS_COMB"],
            "wersja szeregowa jest mniejsza")
    oczekuj(rr["fmax"] > rs["fmax"] / 4, "wersja równoległa ma większą przepustowość")


def e3():
    print("\n== e3: głębokość logiki i fanout")
    f = [HDL / "max_n.v"]
    l = wariant("max_n lancuch", "max_l", "max_n", f, {"DRZEWO": 0}, opis="15 porównań szeregowo")
    d = wariant("max_n drzewo", "max_d", "max_n", f, {"DRZEWO": 1}, opis="4 poziomy porównań")
    oczekuj(d["fmax"] > 1.5 * l["fmax"], "drzewo co najmniej 1,5 raza szybsze od łańcucha")
    f = [HDL / "rozgalezienie.v"]
    r = {}
    for ndup in (1, 32):
        r[ndup] = wariant(f"rozgalezienie NDUP={ndup}", f"roz_{ndup}", "rozgalezienie", f,
                          {"N": 2048, "NDUP": ndup}, extra=["--no-promote-globals"], opis="bez sieci globalnych")
    wariant("rozgalezienie NDUP=1 global", "roz_1g", "rozgalezienie", f, {"N": 2048, "NDUP": 1},
            opis="z promocją sieci globalnych")
    # Yosys (opt_merge) scala identyczne przerzutniki — atrybuty keep/dont_merge na sygnale tego nie blokują;
    # w Quartusie dont_merge/preserve, w Vivado DONT_TOUCH/MAX_FANOUT zachowują kopie.
    oczekuj(r[32]["TRELLIS_FF"] == r[1]["TRELLIS_FF"] and r[32]["fanout"] == r[1]["fanout"],
            "Yosys scala kopie rejestru en_r (liczba przerzutników i fanout bez zmian)")


def e4():
    print("\n== e4: zmienność wyników — osiem ziaren rozmieszczenia (sumator PIPE = 0)")
    synteza("sum_ziarna", "sumator_drzewo", [HDL / "sumator_drzewo.v"], {"PIPE": 0})
    f = []
    for s in range(1, 9):
        fm, _ = pnr("sum_ziarna", seed=s)
        f.append(round(fm, 1))
    wyniki["ziarna"] = f
    srednia = sum(f) / len(f)
    print(f"  f_max: {', '.join(f'{x:.1f}' for x in f)} MHz; min {min(f):.1f}, max {max(f):.1f}, "
          f"średnio {srednia:.1f}, rozrzut {100 * (max(f) - min(f)) / srednia:.1f} %")
    oczekuj(max(f) > min(f), "ziarno zmienia wynik rozmieszczenia")


def e5():
    print("\n== e5: floorplanning — dwie instancje potoku, połączenie rejestr-rejestr między nimi")
    pliki = [HDL / "sumator_drzewo.v", TU / "floorplan_demo.v"]
    synteza("fp", "floorplan_demo", pliki)
    for tryb in ("brak", "blisko", "daleko"):
        extra, env = [], None
        if tryb != "brak":
            extra = ["--pre-place", str(TU / "region.py")]
            env = {**os.environ, "REGION": tryb}
        fm, zas = pnr("fp", extra=extra, env=env)
        log = (BUILD / "fp_s1_pnr.log").read_text()
        info = next((l.split("REGIONY ", 1)[1] for l in log.splitlines() if "REGIONY" in l), "")
        wyniki[f"floorplan {tryb}"] = {"fmax": round(fm, 1), **zas}
        print(f"  regiony: {tryb:7s} f_max {fm:6.1f} MHz  {info}")
    oczekuj(wyniki["floorplan daleko"]["fmax"] < 0.9 * wyniki["floorplan blisko"]["fmax"],
            "instancje na przeciwnych krańcach układu obniżają f_max")


def main():
    BUILD.mkdir(exist_ok=True)
    wybrane = sys.argv[1:] or ["e1", "e1r", "e2", "e3", "e4", "e5"]
    for e in wybrane:
        globals()[e]()
    (BUILD / "wyniki.json").write_text(json.dumps(wyniki, indent=1, ensure_ascii=False))
    print("\nPASS" if not bledy else f"\nFAIL: {len(bledy)} niespełnionych zależności")
    return 1 if bledy else 0


if __name__ == "__main__":
    sys.exit(main())
