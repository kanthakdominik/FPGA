#!/usr/bin/env python3
"""Eksperymenty analizy czasowej modułu 14: OpenSTA na netliście ASIC i nextpnr-ecp5 dla FPGA.

1. Yosys syntetyzuje sta_demo (dzielnik_mc + spi_master) do komórek NanGate 45 nm (synteza_asic.tcl).
2. OpenSTA uruchamia skrypty e0*.tcl; każdy raport ścieżki jest otoczony znacznikami "### etykieta".
   Skrypt wyciąga z raportu: zbocze nadające i odbierające, czas przybycia i wymagany, zapas (slack).
3. Wyniki porównuje z oczekiwanymi (MET / VIOLATED) i z zależnościami liczbowymi
   (np. niepewność 0,3 ns zmniejsza zapas setup dokładnie o 0,3 ns).
4. nextpnr-ecp5: ten sam układ w FPGA ECP5 — maksymalna częstotliwość i skład ścieżki krytycznej.

Zmienne: STA (domyślnie sta), LIB_DIR (katalog z nangate45_{slow,typ,fast}.lib).
Użycie:  python3 sprawdz_sta.py [--bez-fpga]
"""
import json
import os
import re
import subprocess
import sys
from pathlib import Path

TU = Path(__file__).resolve().parent
BUILD = TU / "build"
STA = os.environ.get("STA", "sta")
LIB_DIR = os.environ.get("LIB_DIR", "/opt/opensta/lib")

# etykieta -> oczekiwany stan; None = brak ścieżek (np. po set_false_path)
OCZEKIWANE = {
    "e01_setup_hold": {"dzielnik_setup": "VIOLATED", "najkrotsza_hold": "MET", "spi_setup": "MET"},
    "e02_zegar": {"ref_setup": "MET", "ref_hold": "MET", "niep_setup": "MET", "niep_hold": "VIOLATED",
                  "skew_setup": "MET", "skew_hold": "VIOLATED"},
    "e02_narozniki": {"dzielnik_ss": "VIOLATED", "dzielnik_tt": "MET", "dzielnik_ff": "MET"},
    "e03_we_wy": {"wejscie_setup": "MET", "wejscie_hold": "MET", "wyjscie_setup": "MET",
                  "wyjscie_hold": "VIOLATED"},
    "e04_wyjatki": {"bez_mcp_setup": "VIOLATED", "bez_mcp_hold": "MET", "mcp4_setup": "MET",
                    "mcp4_hold": "VIOLATED", "mcp43_setup": "MET", "mcp43_hold": "MET",
                    "start_przed": "MET", "start_po": None, "b_okres": "MET", "b_max_delay": "MET"},
    "e06_spi": {"mosi_bez_setup": "MET", "mosi_bez_hold": "VIOLATED", "miso_bez_setup": "VIOLATED",
                "miso_bez_hold": "MET", "mosi_mcp_setup": "MET", "mosi_mcp_hold": "MET",
                "miso_mcp_setup": "MET", "miso_mcp_hold": "MET"},
}

# zależności liczbowe: (opis, funkcja wyników -> bool)
ZALEZNOSCI = [
    ("niepewność setup 0,3 ns: zapas mniejszy o 0,3",
     lambda w: abs(w["niep_setup"]["slack"] - (w["ref_setup"]["slack"] - 0.3)) < 0.002),
    ("niepewność hold 0,1 ns: zapas mniejszy o 0,1",
     lambda w: abs(w["niep_hold"]["slack"] - (w["ref_hold"]["slack"] - 0.1)) < 0.002),
    ("skew +1 ns na odbiorniku: setup +1",
     lambda w: abs(w["skew_setup"]["slack"] - (w["ref_setup"]["slack"] + 1.0)) < 0.002),
    ("skew +1 ns na odbiorniku: hold −1",
     lambda w: abs(w["skew_hold"]["slack"] - (w["ref_hold"]["slack"] - 1.0)) < 0.002),
    ("narożniki: opóźnienie SS > TT > FF",
     lambda w: w["dzielnik_ss"]["arrival"] > w["dzielnik_tt"]["arrival"] > w["dzielnik_ff"]["arrival"]),
    ("MCP -setup 4: wymagany czas o 3 okresy później",
     lambda w: abs(w["mcp4_setup"]["capture"] - w["bez_mcp_setup"]["capture"] - 24.0) < 0.002),
    ("MCP -setup 4 bez -hold: hold sprawdzany 3 okresy później",
     lambda w: abs(w["mcp4_hold"]["capture"] - w["bez_mcp_hold"]["capture"] - 24.0) < 0.002),
    ("MCP -setup 4 -hold 3: hold wraca do zbocza 0",
     lambda w: abs(w["mcp43_hold"]["capture"] - w["bez_mcp_hold"]["capture"]) < 0.002),
    ("max_delay 1,5 ns zastępuje okres 8 ns",
     lambda w: abs(w["b_max_delay"]["required_raw"] - 1.5) < 0.002),
    ("MOSI z MCP: setup na 2 okresy clk (16 ns)",
     lambda w: abs(w["mosi_mcp_setup"]["capture"] - w["mosi_mcp_setup"]["launch"] - 16.0) < 0.002),
    ("MISO z MCP: setup na 2 okresy clk (16 ns)",
     lambda w: abs(w["miso_mcp_setup"]["capture"] - w["miso_mcp_setup"]["launch"] - 16.0) < 0.002),
]


def uruchom(cmd, **kw):
    return subprocess.run(cmd, cwd=TU, capture_output=True, text=True, **kw)


def synteza():
    BUILD.mkdir(exist_ok=True)
    p = uruchom(["yosys", "-q", "-c", "synteza_asic.tcl"],
                env={**os.environ, "LIB": f"{LIB_DIR}/nangate45_typ.lib"})
    if p.returncode != 0:
        print(p.stdout + p.stderr)
        sys.exit("BLAD: synteza ASIC")
    stat = (BUILD / "synteza_stat.txt").read_text()
    m = re.search(r"Chip area for module .*?: ([\d.]+)", stat)
    komorki = re.search(r"(\d+)\s+\S+\s+cells", stat) or re.search(r"Number of cells:\s+(\d+)", stat)
    print(f"Synteza ASIC (NanGate 45 nm): {komorki.group(1) if komorki else '?'} komorek, "
          f"powierzchnia {m.group(1) if m else '?'} um^2")


def sekcje(tekst):
    """Słownik etykieta -> parametry ścieżki z raportu report_checks albo tekst check_setup."""
    wynik = {}
    for m in re.finditer(r"^### (\S+)\n(.*?)^### koniec", tekst, re.S | re.M):
        etykieta, tresc = m.group(1), m.group(2)
        d = {"tekst": tresc}
        zbocza = re.findall(r"^\s*(-?[\d.]+)\s+(-?[\d.]+)\s+clock (\S+) \((rise|fall) edge\)", tresc, re.M)
        if zbocza:
            d["launch"], d["launch_clk"] = float(zbocza[0][1]), f"{zbocza[0][2]} {zbocza[0][3]}"
            d["capture"], d["capture_clk"] = float(zbocza[-1][1]), f"{zbocza[-1][2]} {zbocza[-1][3]}"
        s = re.search(r"(-?[\d.]+)\s+slack \((MET|VIOLATED)\)", tresc)
        if s:
            d["slack"], d["stan"] = float(s.group(1)), s.group(2)
        else:
            d["stan"] = None
        a = re.search(r"(-?[\d.]+)\s+data arrival time", tresc)
        r = re.search(r"(-?[\d.]+)\s+data required time", tresc)
        if a:
            d["arrival"] = float(a.group(1))
        if r:
            d["required"] = float(r.group(1))
        mx = re.search(r"(-?[\d.]+)\s+(-?[\d.]+)\s+max_delay", tresc)
        if mx:
            d["required_raw"] = float(mx.group(1))
        d["ostrzezenia"] = len(re.findall(r"^Warning: There (are|is) \d+", tresc, re.M))
        wynik[etykieta] = d
    return wynik


def opensta():
    wszystkie, bledy = {}, 0
    for skrypt, oczekiwane in OCZEKIWANE.items():
        p = uruchom([STA, "-no_init", "-exit", f"{skrypt}.tcl"], env={**os.environ, "LIB_DIR": LIB_DIR})
        log = p.stdout + p.stderr
        (BUILD / f"{skrypt}.log").write_text(log)
        if re.search(r"^Error", log, re.M):
            print(f"BLAD w {skrypt}:\n" + "\n".join(l for l in log.splitlines() if l.startswith("Error")))
            bledy += 1
        w = sekcje(log)
        wszystkie.update(w)
        print(f"\n== {skrypt}")
        if skrypt == "e03_we_wy":
            for k in ("kontrola_bez_io", "kontrola_z_io"):
                if k in w:
                    print(f"  {k:18s} ostrzezen check_setup: {w[k]['ostrzezenia']}")
            if not (w.get("kontrola_bez_io", {}).get("ostrzezenia", 0) > 0 and
                    w.get("kontrola_z_io", {}).get("ostrzezenia", 1) == 0):
                print("  <-- NIEZGODNE: check_setup")
                bledy += 1
        for etykieta, stan in oczekiwane.items():
            d = w.get(etykieta)
            if d is None:
                print(f"  {etykieta:18s} BRAK SEKCJI")
                bledy += 1
                continue
            ok = d["stan"] == stan
            bledy += not ok
            if d["stan"] is None:
                opis = "brak sciezek"
            elif "launch" not in d:
                opis = (f"{'max_delay':>14s} {d.get('required_raw', 0):7.2f}" + " " * 27 +
                        f"  przybycie {d.get('arrival', 0):7.3f}  wymagany {d.get('required', 0):7.3f}"
                        f"  zapas {d['slack']:8.3f} {d['stan']}")
            else:
                opis = (f"{d['launch_clk']:>14s} {d['launch']:7.2f} -> {d['capture_clk']:>14s} {d['capture']:7.2f}"
                        f"  przybycie {d.get('arrival', 0):7.3f}  wymagany {d.get('required', 0):7.3f}"
                        f"  zapas {d['slack']:8.3f} {d['stan']}")
            print(f"  {etykieta:18s} {opis}  {'OK' if ok else '<-- NIEZGODNE (oczekiwano ' + str(stan) + ')'}")
    print("\n== zaleznosci")
    for opis, f in ZALEZNOSCI:
        try:
            ok = f(wszystkie)
        except (KeyError, TypeError):
            ok = False
        bledy += not ok
        print(f"  {'OK ' if ok else 'BLAD'} {opis}")
    return bledy


def fpga():
    """ECP5 (LFE5U-25F): synteza Yosysem, rozmieszczenie i trasowanie nextpnr, raport czasowy."""
    print("\n== FPGA: nextpnr-ecp5 (LFE5U-25F, CABGA381)")
    p = uruchom(["yosys", "-q", "-p", "synth_ecp5 -top sta_demo -json build/sta_demo_ecp5.json",
                 "../hdl/verilog/dzielnik_mc.v", "../hdl/verilog/spi_master.v", "sta_demo.v"])
    if p.returncode != 0:
        print(p.stderr)
        return 1
    wyniki = {}
    for predkosc in (6, 7, 8):
        raport = BUILD / f"ecp5_s{predkosc}.json"
        p = uruchom(["nextpnr-ecp5", "--25k", "--package", "CABGA381", "--speed", str(predkosc),
                     "--json", "build/sta_demo_ecp5.json", "--freq", "125", "--timing-allow-fail", "--seed", "1",
                     "--report", str(raport), "-l", f"build/ecp5_s{predkosc}.log"])
        if p.returncode != 0:
            print(p.stderr[-2000:])
            return 1
        r = json.loads(raport.read_text())
        fmax = list(r["fmax"].values())[0]["achieved"]
        wyniki[predkosc] = (fmax, r)
        print(f"  klasa szybkosci {predkosc}: Fmax {fmax:6.1f} MHz (wymaganie 125 MHz)")
    # skład ścieżki krytycznej dla klasy 6 (najwolniejszej)
    r = wyniki[6][1]
    sciezki = [c for c in r["critical_paths"] if c["from"] == c["to"]]
    if sciezki:
        suma = {}
        for el in sciezki[0]["path"]:
            suma[el["type"]] = suma.get(el["type"], 0.0) + el["delay"]
        n_logic = sum(1 for el in sciezki[0]["path"] if el["type"] == "logic")
        poczatek = sciezki[0]["path"][0]["from"]["cell"]
        print(f"  sciezka krytyczna (klasa 6) od {poczatek.split('_TRELLIS')[0]}: "
              + ", ".join(f"{k} {v:.2f} ns" for k, v in suma.items()) + f"; elementow logiki: {n_logic}")
        trasy = suma.get("routing", 0.0)
        cala = sum(suma.values())
        print(f"  udzial polaczen: {100 * trasy / cala:.0f} % z {cala:.2f} ns")
    ok = wyniki[6][0] < wyniki[7][0] < wyniki[8][0] and wyniki[8][0] < 125
    print(f"  {'OK ' if ok else 'BLAD'} Fmax rosnie z klasa szybkosci i jest ponizej 125 MHz (dzielnik bez MCP)")
    return 0 if ok else 1


def main():
    synteza()
    bledy = opensta()
    if "--bez-fpga" not in sys.argv:
        bledy += fpga()
    print("\nPASS" if bledy == 0 else f"\nFAIL: {bledy} niezgodnosci")
    return 1 if bledy else 0


if __name__ == "__main__":
    sys.exit(main())
