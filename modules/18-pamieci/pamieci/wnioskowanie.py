#!/usr/bin/env python3
"""Co synteza robi z kodu pamięci (18.01): Yosys synth_ecp5 dla wzorców z hdl/verilog (ram_sp w trzech
trybach, ram_sdp, rom_sinus, fifo_bram, pingpong, bufor_linii) i dla wzorców z zle_wzorce.v.
Dla każdego: liczba bloków pamięci DP16KD (18 Kb w ECP5; odpowiednik M9K w MAX 10), komórek pamięci
rozproszonej TRELLIS_DPR16X4, przerzutników i LUT4.
Oczekiwane: poprawne wzorce -> blok pamięci i kilka-kilkadziesiąt przerzutników; mała ROM 256 x 8 ->
LUT (taniej niż blok), z atrybutem rom_style = "block" -> blok; odczyt asynchroniczny ->
pamięć rozproszona; reset zawartości -> tysiące przerzutników; trzy porty odczytu -> kilka kopii pamięci.
Wymaga yosys (OSS CAD Suite). Kod wyjścia 1, gdy któreś oczekiwanie nie jest spełnione.
"""
import re
import subprocess
import sys
from pathlib import Path

TU = Path(__file__).resolve().parent
HDL = TU.parent / "hdl" / "verilog"
DANE = TU.parent / "hdl" / "dane"
KOMORKI = ("DP16KD", "TRELLIS_DPR16X4", "TRELLIS_FF", "LUT4")

PRZYPADKI = [
    # (opis, plik, top, parametry, oczekiwanie)
    ("ram_sp 256x8 READ_FIRST", HDL / "ram_sp.v", "ram_sp", {"TRYB": 0}, "blok"),
    ("ram_sp 256x8 WRITE_FIRST", HDL / "ram_sp.v", "ram_sp", {"TRYB": 1}, "blok"),
    ("ram_sp 256x8 NO_CHANGE", HDL / "ram_sp.v", "ram_sp", {"TRYB": 2}, "blok"),
    ("ram_sdp 1024x16", HDL / "ram_sdp.v", "ram_sdp", {"W": 16, "AW": 10}, "blok"),
    ("rom_sinus 256x8 z pliku", HDL / "rom_sinus.v", "rom_sinus", {}, "logika"),
    ("rom 256x8, rom_style=block", TU / "rom_blok.v", "rom_blok", {}, "blok"),
    ("fifo_bram 512x8 FWFT", HDL / "fifo_bram.v", "fifo_bram", {"AW": 9, "FWFT": 1, "AF": 500}, "blok"),
    ("pingpong 2x256x16", HDL / "pingpong.v", "pingpong", {"AW": 8}, "blok"),
    ("bufor_linii 640 x 2x8", HDL / "bufor_linii.v", "bufor_linii", {"SZER": 640}, "blok"),
    ("odczyt asynchroniczny 256x8", TU / "zle_wzorce.v", "ram_odczyt_async", {}, "rozproszona"),
    ("reset calej zawartosci 256x8", TU / "zle_wzorce.v", "ram_z_resetem", {}, "przerzutniki"),
    ("trzy porty odczytu 256x8", TU / "zle_wzorce.v", "ram_trzy_odczyty", {}, "kopie"),
]


def synteza(plik, top, param):
    chparam = "".join(f"chparam -set {k} {v} {top}; " for k, v in param.items())
    p = subprocess.run(["yosys", "-p", f"read_verilog {plik}; {chparam}synth_ecp5 -top {top}; stat"],
                       cwd=DANE, capture_output=True, text=True, timeout=600)
    if p.returncode != 0:
        print(p.stdout[-2000:], p.stderr[-2000:])
        raise RuntimeError(top)
    stat = p.stdout.rsplit("Printing statistics", 1)[-1]
    wynik = {}
    for k in KOMORKI:
        m = re.search(rf"^\s*(\d+)\s+{k}\s*$", stat, re.M) or re.search(rf"^\s*{k}\s+(\d+)\s*$", stat, re.M)
        wynik[k] = int(m.group(1)) if m else 0
    return wynik


def main():
    bledy = 0
    print(f"{'wzorzec':32s} {'DP16KD':>7s} {'DPR16X4':>8s} {'FF':>6s} {'LUT4':>6s}  oczekiwane")
    for opis, plik, top, param, oczek in PRZYPADKI:
        w = synteza(plik, top, param)
        if oczek == "blok":
            ok = w["DP16KD"] >= 1 and w["TRELLIS_FF"] < 200
        elif oczek == "logika":                     # mała ROM jako LUT: taniej niż blok 18 Kb
            ok = w["DP16KD"] == 0 and w["LUT4"] > 0
        elif oczek == "rozproszona":
            ok = w["DP16KD"] == 0 and w["TRELLIS_DPR16X4"] > 0
        elif oczek == "przerzutniki":
            ok = w["DP16KD"] == 0 and w["TRELLIS_FF"] >= 2048
        else:                                       # kopie
            ok = w["DP16KD"] >= 2 or w["TRELLIS_FF"] >= 2048
        bledy += 0 if ok else 1
        print(f"{opis:32s} {w['DP16KD']:7d} {w['TRELLIS_DPR16X4']:8d} {w['TRELLIS_FF']:6d} {w['LUT4']:6d}  "
              f"{oczek:12s} {'OK' if ok else 'BLAD'}")
    print("PASS" if bledy == 0 else f"FAIL: {bledy}")
    return 1 if bledy else 0


if __name__ == "__main__":
    sys.exit(main())
