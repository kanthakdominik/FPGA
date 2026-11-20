#!/usr/bin/env python3
"""Tablice dla interp_lin (19.06) i porównanie metod aproksymacji f(x) = sin(πx/2) na [0, 1).

Wejście x: 16 bitów bez znaku (Q0.16), wyjście: 16 bitów bez znaku (Q0.16, nasycenie do 65535).
Interpolacja liniowa z 2^S odcinkami: x = [k (S bitów) | frac (16-S bitów)],
y = baza[k] + round(nachyl[k] · frac / 2^(16-S)).
baza i nachyl dobrane metodą minimax na odcinku (cięciwa przesunięta o połowę największego odchylenia),
co zmniejsza błąd mniej więcej o połowę w stosunku do zwykłej cięciwy.

Zapisuje interp_baza.hex i interp_nachyl.hex (S = 6) i wypisuje tabelę największych błędów
(w LSB wyjścia, po wszystkich 65 536 wejściach) dla tablicy bez interpolacji, cięciw i minimaksu.
"""
import math
from pathlib import Path

F = 16
SKALA = 1 << F


def f(x):                                   # x w [0, 1]
    return math.sin(math.pi * x / 2)


def wzorzec(xi):
    return f(xi / SKALA) * SKALA


def tablice(S, minimax=True):
    FR = F - S
    baza, nachyl = [], []
    for k in range(1 << S):
        x0, x1 = k / (1 << S), (k + 1) / (1 << S)
        y0, y1 = f(x0) * SKALA, f(x1) * SKALA
        przes = 0.0
        if minimax:                          # funkcja wklęsła: nad cięciwą; przesunięcie o połowę odchylenia
            odch = max(wzorzec((k << FR) + j) - (y0 + (y1 - y0) * j / (1 << FR)) for j in range(1 << FR))
            przes = odch / 2
        baza.append(min(round(y0 + przes), SKALA - 1))
        nachyl.append(round(y1 - y0))
    return baza, nachyl


def interp(xi, S, baza, nachyl):
    FR = F - S
    k, frac = xi >> FR, xi & ((1 << FR) - 1)
    y = baza[k] + ((nachyl[k] * frac + (1 << (FR - 1))) >> FR)
    return min(y, SKALA - 1)


def blad_max(fun):
    return max(abs(fun(xi) - min(wzorzec(xi), SKALA - 1)) for xi in range(SKALA))


def main():
    print(f"f(x) = sin(πx/2), x i y po {F} bitów; największy błąd w LSB wyjścia (wszystkie wejścia)")
    for S in (6, 8, 10, 12):                 # sama tablica: wartość w środku odcinka
        tab = [min(round(f((k + 0.5) / (1 << S)) * SKALA), SKALA - 1) for k in range(1 << S)]
        b = blad_max(lambda xi: tab[xi >> (F - S)])
        print(f"  tablica bez interpolacji, {1 << S:5d} słów:            {b:8.2f}")
    for S in (4, 5, 6, 7):
        for mm in (False, True):
            baza, nachyl = tablice(S, mm)
            b = blad_max(lambda xi: interp(xi, S, baza, nachyl))
            print(f"  interpolacja liniowa, {1 << S:3d} odcinków, {'minimax ' if mm else 'cięciwa '}: {b:8.2f}"
                  f"   (tablice {1 << S} × {max(baza).bit_length()} b + {1 << S} × {max(nachyl).bit_length()} b)")
    S = 6
    baza, nachyl = tablice(S)
    tu = Path(__file__).parent
    (tu / "interp_baza.hex").write_text("".join(f"{v:04x}\n" for v in baza))
    (tu / "interp_nachyl.hex").write_text("".join(f"{v:03x}\n" for v in nachyl))
    print(f"zapisano interp_baza.hex i interp_nachyl.hex (S = {S}); największy błąd {blad_max(lambda xi: interp(xi, S, baza, nachyl)):.2f} LSB")


if __name__ == "__main__":
    main()
