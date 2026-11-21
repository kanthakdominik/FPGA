#!/usr/bin/env python3
"""Obrazek sprite'a 16×16 (24.03), 2 bity na piksel: '.' = przezroczysty, 'a' = kolor 1, 'b' = 2, 'c' = 3.
Generuje funkcję wiersza dla sprite16.v / .vhd i tablicę ASCII dla testbenchy.
Użycie: python3 sprite.py verilog|vhdl|tb_verilog|tb_vhdl"""
import sys

OBRAZ = [
    ".....aaaaaa.....",
    "...aabbbbbbaa...",
    "..abbbbbbbbbba..",
    ".abbbbbbbbbbbba.",
    ".abbcccbbcccbba.",
    "abbbcacbbcacbbba",
    "abbbcccbbcccbbba",
    "abbbbbbbbbbbbbba",
    "abbbbbbbbbbbbbba",
    "abbcbbbbbbbbcbba",
    "abbbcbbbbbbcbbba",
    ".abbbccccccbbba.",
    ".abbbbbbbbbbbba.",
    "..abbbbbbbbbba..",
    "...aabbbbbbaa...",
    ".....aaaaaa.....",
]
KOD = {'.': 0, 'a': 1, 'b': 2, 'c': 3}

def wiersz_bity(r):
    # piksel 0 (lewy) w bitach 31..30
    return "".join(format(KOD[ch], "02b") for ch in r)

def main():
    j = sys.argv[1] if len(sys.argv) > 1 else "verilog"
    for i, r in enumerate(OBRAZ):
        assert len(r) == 16
        b = int(wiersz_bity(r), 2)
        if j == "verilog":
            print(f"            4'd{i}:{' ' if i < 10 else ''} wiersz = 32'h{b:08X};   // {r}")
        elif j == "vhdl":
            print(f'      when {i:2d} => return x"{b:08X}";   -- {r}')
        elif j == "tb_verilog":
            print(f'        obraz[{i}] = "{r}";')
        else:
            print(f'    {i:2d} => "{r}"' + ("," if i < 15 else ""))

if __name__ == "__main__":
    main()
