#!/usr/bin/env bash
# Wszystkie sprawdzenia modułu 30 (lokalnie i w CI): generatory, zgodność nagłówków, test mapy rejestrów
# w Icarusie i GHDL, rdzenie FuseSoC (jeśli zainstalowany: pip install -r narzedzia/requirements.txt).
set -euo pipefail
REPO=$(cd "$(dirname "$0")/../../.." && pwd)
M=$REPO/modules/30-warsztat-inzyniera
M27=$REPO/modules/27-procesory-i-soc
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

echo "== Generator mapy rejestrów"
python3 "$M/narzedzia/rejestry.py" --sprawdz
echo "== Diagramy czasowe"
python3 "$M/narzedzia/wavedrom_ascii.py" --sprawdz
echo "== Nagłówek C zgodny z ręcznym pwm.h"
gcc -std=c11 -Wall -Werror -fsyntax-only -I "$M/rejestry/wygenerowane" -I "$M27/program/c" "$M/rejestry/zgodnosc.c"
echo "OK  zgodnosc.c: 9 x _Static_assert"

echo "== tb_pwm_regs (Icarus)"
iverilog -g2005 -I "$M/rejestry/wygenerowane" -o "$T/tb.vvp" "$M27/hdl/verilog/pwm_avl.v" "$M/rejestry/tb_pwm_regs.v"
vvp -n "$T/tb.vvp" | grep -v "finish called" | tee "$T/v.txt"
grep -q '^PASS' "$T/v.txt"
echo "== tb_pwm_regs (GHDL)"
( cd "$T" && ghdl -i --std=08 "$M/rejestry/wygenerowane/pwm_avl_regs_pkg.vhd" "$M27/hdl/vhdl/pwm_avl.vhd" \
      "$M/rejestry/tb_pwm_regs.vhd" && ghdl -m --std=08 tb_pwm_regs > /dev/null && ghdl -r --std=08 tb_pwm_regs ) \
  | tee "$T/g.txt"
grep -q '^PASS' "$T/g.txt"

if command -v fusesoc > /dev/null; then
    echo "== FuseSoC $(fusesoc --version)"
    R=(--cores-root "$M27" --cores-root "$M")
    cd "$T"
    fusesoc "${R[@]}" core list 2>/dev/null | grep 'fpga-kurs:'
    fusesoc "${R[@]}" run --target sim fpga-kurs:peryferia:pwm_avl > f1.txt 2>&1 || { cat f1.txt; exit 1; }
    grep -E '^(PASS|FAIL)' f1.txt; grep -q '^PASS' f1.txt
    fusesoc "${R[@]}" run --target lint fpga-kurs:peryferia:pwm_avl > f2.txt 2>&1 || { cat f2.txt; exit 1; }
    if grep -E '%(Warning|Error)' f2.txt; then exit 1; fi
    echo "lint: 0 ostrzeżeń"
    fusesoc "${R[@]}" run --target sim fpga-kurs:peryferia:pwm_avl_regs > f3.txt 2>&1 || { cat f3.txt; exit 1; }
    grep -E '^(mapa|PASS|FAIL)' f3.txt; grep -q '^PASS' f3.txt
else
    echo "(FuseSoC niezainstalowany — pominięto rdzenie)"
fi
echo "Moduł 30: wszystkie sprawdzenia PASS"
