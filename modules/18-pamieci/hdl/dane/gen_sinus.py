#!/usr/bin/env python3
"""Tablica sinusa dla rom_sinus (18.02): 256 próbek, 8 bitów, wartość = round(127,5 + 127,5 · sin(2πk/256)).
Zapisuje ten sam ciąg w trzech formatach:
  sinus.hex — $readmemh (Verilog/SV) i odczyt textio (VHDL w symulacji): jedna wartość szesnastkowa w wierszu,
  sinus.mem — format "mem" (Vivado, $readmemh): jak .hex, z adresem początkowym @0,
  sinus.mif — Memory Initialization File Quartusa (atrybut ram_init_file w VHDL, edytor pamięci).
Uruchomienie: python3 gen_sinus.py (w tym katalogu).
"""
import math
from pathlib import Path

N, W = 256, 8
TU = Path(__file__).resolve().parent
wartosci = [round(127.5 + 127.5 * math.sin(2 * math.pi * k / N)) for k in range(N)]
assert min(wartosci) >= 0 and max(wartosci) <= 255

(TU / "sinus.hex").write_text("".join(f"{v:02x}\n" for v in wartosci))
(TU / "sinus.mem").write_text("@0\n" + "".join(f"{v:02x}\n" for v in wartosci))
mif = [f"-- sinus: {N} slow po {W} bitow, wygenerowane przez gen_sinus.py",
       f"WIDTH={W};", f"DEPTH={N};", "ADDRESS_RADIX=HEX;", "DATA_RADIX=HEX;", "CONTENT BEGIN"]
mif += [f"    {k:02X} : {v:02X};" for k, v in enumerate(wartosci)]
mif += ["END;", ""]
(TU / "sinus.mif").write_text("\n".join(mif))
print(f"zapisano {N} wartosci: min {min(wartosci)}, max {max(wartosci)}, k=64 -> {wartosci[64]}")
