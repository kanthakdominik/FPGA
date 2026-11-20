#!/bin/sh
# Generowanie z rejestry.rdl (21.05): blok rejestrów SystemVerilog ze slave'em AXI4-Lite, nagłówek C
# i dokumentacja HTML; lint wygenerowanego kodu Verilatorem.
#   pip install systemrdl-compiler peakrdl peakrdl-regblock peakrdl-cheader peakrdl-html
set -e
cd "$(dirname "$0")"
mkdir -p build
python3 sprawdz.py
peakrdl regblock rejestry.rdl -o build/ --cpuif axi4-lite-flat
peakrdl c-header rejestry.rdl -o build/rejestry.h
peakrdl html rejestry.rdl -o build/html/
echo "--- wygenerowane pliki"
ls -l build
echo "--- definicje w nagłówku C"
grep -E "#define|typedef|struct" build/rejestry.h | head -30
echo "--- lint (verilator -Wall, ostrzeżenia nie przerywają)"
verilator --lint-only -Wall -Wno-fatal --top-module rejestry build/rejestry_pkg.sv build/rejestry.sv 2>&1 | grep -c "%Warning" || true
verilator --lint-only -Wno-MULTIDRIVEN --top-module rejestry build/rejestry_pkg.sv build/rejestry.sv
echo "--- porty bloku"
grep -nE "^\s*(input|output)" build/rejestry.sv | head -40
echo "lint bez błędów"
