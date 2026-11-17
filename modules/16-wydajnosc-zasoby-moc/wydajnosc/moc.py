#!/usr/bin/env python3
"""Szacowanie mocy dynamicznej na podstawie aktywności (16.06).

1. Yosys: izolacja_operandow (ISO = 0 i 1) -> netlista z bramek logicznych i przerzutników
   (synth -flatten), zapis do Veriloga (moduły izo0, izo1).
2. Icarus: tb_moc.v podaje ten sam strumień danych obu netlistom i zapisuje przebiegi (VCD).
3. Z VCD: liczba przełączeń każdej sieci; aktywność α = przełączenia (0→1 i 1→0) / takt.
   Każde przełączenie to ½·C·V² energii, więc moc dynamiczna P = Σ ½ · α_i · C_i · V² · f;
   przy równych pojemnościach sieci stosunek mocy dwóch
   wariantów = stosunek sum przełączeń. Symulacja bez opóźnień nie pokazuje szpilek (glitchy) —
   w rzeczywistości mnożarka bez izolacji przełącza się jeszcze częściej.
4. Przykładowe liczby z wzoru dla układu FPGA (pojemność sieci, napięcie rdzenia, zegar).

Wymaga yosys i iverilog. Kod wyjścia 1, gdy izolacja nie zmniejsza aktywności co najmniej 3 razy.
"""
import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

TU = Path(__file__).resolve().parent
HDL = TU.parent / "hdl" / "verilog"
BUILD = TU / "build"
TAKTY = 2000


def netlisty():
    skrypt = []
    for iso in (0, 1):
        skrypt.append(f"design -reset; read_verilog {HDL / 'izolacja_operandow.v'}; "
                      f"chparam -set ISO {iso} izolacja_operandow; synth -flatten -top izolacja_operandow; "
                      f"rename izolacja_operandow izo{iso}; tee -q -o build/izo{iso}_stat.json stat -json; "
                      f"write_verilog -noattr build/izo{iso}.v")
    p = subprocess.run(["yosys", "-p", "; ".join(skrypt)], cwd=TU, capture_output=True, text=True)
    if p.returncode != 0:
        print(p.stdout[-3000:], p.stderr)
        sys.exit(1)
    import json
    return [json.loads((BUILD / f"izo{iso}_stat.json").read_text())["design"]["num_cells"] for iso in (0, 1)]


def symulacja():
    for cmd in (["iverilog", "-g2005", "-o", "build/tb_moc", "tb_moc.v", "build/izo0.v", "build/izo1.v"],
                ["vvp", "-n", "build/tb_moc"]):
        p = subprocess.run(cmd, cwd=TU, capture_output=True, text=True)
        if p.returncode != 0:
            print(p.stdout, p.stderr)
            sys.exit(1)


def przelaczenia(vcd):
    """Zwraca {zakres: (liczba sieci-bitów, liczba przełączeń)} dla zakresów u0 i u1."""
    id_zakres, id_szer = {}, {}
    zakres = []
    poprzednie = {}
    licz = defaultdict(int)
    w_naglowku = True
    for linia in vcd.read_text().splitlines():
        t = linia.split()
        if not t:
            continue
        if w_naglowku:
            if t[0] == "$scope":
                zakres.append(t[2])
            elif t[0] == "$upscope":
                zakres.pop()
            elif t[0] == "$var":
                zz = next((z for z in zakres if z in ("u0", "u1")), None)
                if zz and t[3] not in id_zakres:
                    id_zakres[t[3]] = zz
                    id_szer[t[3]] = int(t[2])
            elif t[0] == "$enddefinitions":
                w_naglowku = False
            continue
        if t[0][0] == "#":
            continue
        if t[0][0] in "bB":
            wart, ident = t[0][1:], t[1]
        else:
            wart, ident = t[0][0], t[0][1:]
        if ident not in id_zakres:
            continue
        szer = id_szer[ident]
        wart = wart.rjust(szer, "0")[-szer:]
        stara = poprzednie.get(ident)
        if stara is not None:
            licz[ident] += sum(1 for x, y in zip(stara, wart) if x != y and x in "01" and y in "01")
        poprzednie[ident] = wart
    wynik = {}
    for z in ("u0", "u1"):
        ids = [i for i, zz in id_zakres.items() if zz == z]
        wynik[z] = (sum(id_szer[i] for i in ids), sum(licz[i] for i in ids))
    return wynik


def main():
    BUILD.mkdir(exist_ok=True)
    kom = netlisty()
    symulacja()
    w = przelaczenia(BUILD / "moc.vcd")
    (b0, t0), (b1, t1) = w["u0"], w["u1"]
    a0, a1 = t0 / (b0 * TAKTY), t1 / (b1 * TAKTY)
    print(f"netlisty: ISO=0 {kom[0]} komorek, ISO=1 {kom[1]} komorek")
    print(f"ISO=0: {b0} bitow sieci, {t0} przelaczen, srednia aktywnosc {a0:.3f} na takt")
    print(f"ISO=1: {b1} bitow sieci, {t1} przelaczen, srednia aktywnosc {a1:.3f} na takt")
    print(f"stosunek mocy dynamicznej (rowne pojemnosci): {t0 / t1:.2f}")
    # przykład liczbowy: P = 1/2 * alfa * C * V^2 * f * liczba sieci
    C, V, F = 20e-15, 1.2, 100e6       # 20 fF na sieć (rząd wielkości dla krótkiego połączenia w FPGA)
    for iso, b, a in ((0, b0, a0), (1, b1, a1)):
        print(f"przyklad: ISO={iso}: P = 0,5 x {a:.3f} x {b} x 20 fF x (1,2 V)^2 x 100 MHz = "
              f"{0.5 * a * b * C * V * V * F * 1e3:.3f} mW")
    ok = t1 * 3 < t0
    print("PASS" if ok else "FAIL: izolacja nie zmniejsza aktywnosci 3 razy")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
