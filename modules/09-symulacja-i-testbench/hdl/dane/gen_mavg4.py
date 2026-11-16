#!/usr/bin/env python3
"""Generuje wektory testowe dla mavg4 (moduł 09) — model referencyjny w Pythonie („złoty model”).

Jeden wiersz = jeden takt zegara:   rst in_valid x   exp_out_valid exp_y
Pierwsze trzy liczby to wejścia podawane przed zboczem, dwie ostatnie — oczekiwane wyjścia po zboczu.
Wiersze zaczynające się od '#' to komentarze (testbenche je pomijają).

Użycie:
    python3 gen_mavg4.py              # zapisuje mavg4_wektory.txt obok skryptu
    python3 gen_mavg4.py --sprawdz    # sprawdza, czy plik w repozytorium jest aktualny (CI)
"""
import argparse
import random
import sys
from pathlib import Path

PLIK = Path(__file__).with_name("mavg4_wektory.txt")


class Mavg4:
    """Model zachowania mavg4 na poziomie taktów."""

    def __init__(self):
        self.okno = [0, 0, 0]          # x1, x2, x3
        self.out_valid = 0
        self.y = 0

    def zbocze(self, rst, in_valid, x):
        if rst:
            self.okno = [0, 0, 0]
            self.out_valid = 0
            self.y = 0
            return
        self.out_valid = in_valid
        if in_valid:
            self.y = (x + sum(self.okno)) // 4   # // w Pythonie zaokrągla w dół — także dla liczb ujemnych
            self.okno = [x] + self.okno[:2]


def scenariusz():
    """Lista (opis, [(rst, in_valid, x), ...])."""
    rng = random.Random(2026)
    s = []
    s.append(("reset", [(1, 0, 0)] * 2))
    s.append(("skok 0 -> 100", [(0, 1, 100)] * 5))
    s.append(("wartości skrajne", [(0, 1, -128)] * 4 + [(0, 1, 127)] * 4))
    s.append(("naprzemiennie -1, 0: zaokrąglenie w dół", [(0, 1, -1), (0, 1, 0)] * 4))
    s.append(("wstrzymanie (in_valid = 0)", [(0, 0, 55)] * 3))
    s.append(("reset w trakcie pracy", [(1, 1, 99), (0, 1, 8)]))
    los = []
    for i in range(400):
        if i == 200:
            los.append((1, 0, 0))
            continue
        x = rng.choice([-128, 127]) if rng.random() < 0.1 else rng.randint(-128, 127)
        los.append((0, int(rng.random() < 0.75), x))
    s.append(("400 taktów losowych (reset w takcie 200)", los))
    return s


def tekst():
    m = Mavg4()
    linie = [
        "# Wektory testowe mavg4 — wygenerowane przez gen_mavg4.py, nie edytować ręcznie.",
        "# rst in_valid x  exp_out_valid exp_y",
    ]
    for opis, takty in scenariusz():
        linie.append(f"# {opis}")
        for rst, v, x in takty:
            m.zbocze(rst, v, x)
            linie.append(f"{rst} {v} {x} {m.out_valid} {m.y}")
    return "\n".join(linie) + "\n"


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--sprawdz", action="store_true")
    a = p.parse_args()
    t = tekst()
    if a.sprawdz:
        if not PLIK.exists() or PLIK.read_text() != t:
            print(f"{PLIK.name} jest nieaktualny — uruchom gen_mavg4.py")
            return 1
        print(f"{PLIK.name} aktualny")
        return 0
    PLIK.write_text(t)
    print(f"Zapisano {PLIK} ({t.count(chr(10))} wierszy)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
