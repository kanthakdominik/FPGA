#!/usr/bin/env python3
"""Mała sieć neuronowa 2-16-3 i jej wersja całkowitoliczbowa (int8) dla akceleratora HLS (28.05).

Zbiór: punkty (x, y) z siatki int8 [-127, 127]^2 (deterministyczny generator LCG), trzy klasy:
  0 — wewnątrz koła o promieniu ok. 0,45 (x² + y² < 57²), 1 — poza kołem, x > 0, 2 — poza kołem, x ≤ 0.
Przepływ jak w hls4ml/FINN w miniaturze:
  --trenuj   trening w liczbach zmiennoprzecinkowych (SGD, softmax, czysty Python), kwantyzacja wag do int8
             ze skalami potęg dwójki, zapis nn/mlp_wagi.txt (wynik zależy od biblioteki matematycznej —
             dlatego trening nie jest powtarzany w CI);
  (domyślnie) wnioskowanie całkowitoliczbowe z mlp_wagi.txt -> hls/mlp_wagi.h (stałe dla C++) i
             hls/mlp_wektory.txt (wejścia, oczekiwane logity i klasy) + dokładność;
  --sprawdz  to samo do katalogu tymczasowego i porównanie z repozytorium (CI).
Arytmetyka całkowitoliczbowa (co do bitu jak hls/mlp.cpp):
  a1 = Σ w1·x + b1 (int32),  h = min(max((a1 + 2^(p1-1)) >> p1, 0), 127)  (ReLU i powrót do int8)
  a2 = Σ w2·h + b2 (int32) — logity; klasa = argmax (pierwszy największy).
"""
import math
import sys
import tempfile
from pathlib import Path

TU = Path(__file__).resolve().parent
MOD = TU.parent
WE, UKRYTE, WY = 2, 16, 3


class Lcg:
    def __init__(self, s):
        self.s = s & 0xFFFFFFFF

    def nast(self):
        self.s = (self.s * 1664525 + 1013904223) & 0xFFFFFFFF
        return self.s


def zbior(n, ziarno):
    g = Lcg(ziarno)
    dane = []
    for _ in range(n):
        x = (g.nast() >> 16) % 255 - 127
        y = (g.nast() >> 16) % 255 - 127
        if x * x + y * y < 57 * 57:
            k = 0
        elif x > 0:
            k = 1
        else:
            k = 2
        dane.append((x, y, k))
    return dane


# ---------------------------------------------------------------- trening (float)
def trenuj():
    g = Lcg(2805)
    los = lambda a: ((g.nast() >> 8) / float(1 << 24) * 2 - 1) * a
    w1 = [[los(1.0) for _ in range(WE)] for _ in range(UKRYTE)]
    b1 = [0.0] * UKRYTE
    w2 = [[los(0.5) for _ in range(UKRYTE)] for _ in range(WY)]
    b2 = [0.0] * WY
    uczace = [(x / 127.0, y / 127.0, k) for x, y, k in zbior(600, 1)]
    wsp = 0.1
    for epoka in range(300):
        for x, y, k in uczace:
            wej = (x, y)
            a1 = [sum(w1[j][i] * wej[i] for i in range(WE)) + b1[j] for j in range(UKRYTE)]
            h = [max(v, 0.0) for v in a1]
            a2 = [sum(w2[c][j] * h[j] for j in range(UKRYTE)) + b2[c] for c in range(WY)]
            m = max(a2)
            e = [math.exp(v - m) for v in a2]
            s = sum(e)
            d2 = [e[c] / s - (1.0 if c == k else 0.0) for c in range(WY)]
            d1 = [sum(d2[c] * w2[c][j] for c in range(WY)) * (1.0 if a1[j] > 0 else 0.0) for j in range(UKRYTE)]
            for c in range(WY):
                for j in range(UKRYTE):
                    w2[c][j] -= wsp * d2[c] * h[j]
                b2[c] -= wsp * d2[c]
            for j in range(UKRYTE):
                for i in range(WE):
                    w1[j][i] -= wsp * d1[j] * wej[i]
                b1[j] -= wsp * d1[j]
        if epoka == 200:
            wsp = 0.03
    test = [(x / 127.0, y / 127.0, k) for x, y, k in zbior(1000, 2)]
    dobre = 0
    for x, y, k in test:
        a1 = [max(sum(w1[j][i] * (x, y)[i] for i in range(WE)) + b1[j], 0.0) for j in range(UKRYTE)]
        a2 = [sum(w2[c][j] * a1[j] for j in range(UKRYTE)) + b2[c] for c in range(WY)]
        dobre += max(range(WY), key=lambda c: a2[c]) == k
    acc_float = dobre / len(test)

    # kwantyzacja: wagi int8 ze skalą 2^s, wejście x_q = x·127 ≈ x·2^7, aktywacje int8 ze skalą 2^sa
    def skala(macierz):
        m = max(abs(v) for wiersz in macierz for v in wiersz)
        return int(math.floor(math.log2(127.0 / m)))
    s1, s2 = skala(w1), skala(w2)
    maks_h = 0.0
    for x, y, k in uczace:
        for j in range(UKRYTE):
            maks_h = max(maks_h, sum(w1[j][i] * (x, y)[i] for i in range(WE)) + b1[j])
    sa = int(math.floor(math.log2(127.0 / maks_h)))
    q = lambda v, s: max(-127, min(127, int(round(v * (1 << s)))))
    w1q = [[q(v, s1) for v in w] for w in w1]
    w2q = [[q(v, s2) for v in w] for w in w2]
    b1q = [int(round(v * (1 << (7 + s1)))) for v in b1]
    b2q = [int(round(v * (1 << (sa + s2)))) for v in b2]
    p1 = 7 + s1 - sa
    linie = ["# Wagi sieci 2-16-3 po kwantyzacji (nn/mlp_model.py --trenuj); dokładność float na zbiorze testowym: %.4f"
             % acc_float, "P1 %d" % p1]
    linie += ["W1 " + " ".join(map(str, w)) for w in w1q]
    linie += ["B1 " + " ".join(map(str, b1q))]
    linie += ["W2 " + " ".join(map(str, w)) for w in w2q]
    linie += ["B2 " + " ".join(map(str, b2q))]
    (TU / "mlp_wagi.txt").write_text("\n".join(linie) + "\n")
    print("float: dokładność %.4f na 1000 punktach; skale 2^%d, 2^%d, aktywacje 2^%d, przesunięcie %d"
          % (acc_float, s1, s2, sa, p1))


# ---------------------------------------------------------------- wnioskowanie int8 i pliki
def wczytaj():
    w1, w2 = [], []
    for l in (TU / "mlp_wagi.txt").read_text().splitlines():
        if not l or l.startswith("#"):
            continue
        k, *v = l.split()
        v = list(map(int, v))
        if k == "P1":
            p1 = v[0]
        elif k == "W1":
            w1.append(v)
        elif k == "B1":
            b1 = v
        elif k == "W2":
            w2.append(v)
        elif k == "B2":
            b2 = v
    return p1, w1, b1, w2, b2


def wnioskuj(p, x, y):
    p1, w1, b1, w2, b2 = p
    h = []
    for j in range(UKRYTE):
        a = w1[j][0] * x + w1[j][1] * y + b1[j]
        h.append(min(max((a + (1 << (p1 - 1))) >> p1, 0), 127))
    logity = [sum(w2[c][j] * h[j] for j in range(UKRYTE)) + b2[c] for c in range(WY)]
    klasa = max(range(WY), key=lambda c: (logity[c], -c))
    return logity, klasa


def generuj(cel_hls):
    p = wczytaj()
    p1, w1, b1, w2, b2 = p
    test = zbior(1000, 2)
    wiersze, dobre = [], 0
    for x, y, k in test:
        logity, kl = wnioskuj(p, x, y)
        dobre += kl == k
        wiersze.append("%d %d %d %d %d %d %d" % (x, y, k, logity[0], logity[1], logity[2], kl))
    tab = lambda m: "{\n" + ",\n".join("    {" + ", ".join(map(str, w)) + "}" for w in m) + "\n}"
    h = ["// Wygenerowane przez nn/mlp_model.py z nn/mlp_wagi.txt — nie edytować ręcznie.",
         "#pragma once", "#include <cstdint>", "",
         "constexpr int MLP_WE = %d, MLP_UKRYTE = %d, MLP_WY = %d;" % (WE, UKRYTE, WY),
         "constexpr int MLP_P1 = %d;   // przesunięcie po pierwszej warstwie (skala aktywacji)" % p1,
         "static const int8_t MLP_W1[MLP_UKRYTE][MLP_WE] = %s;" % tab(w1),
         "static const int32_t MLP_B1[MLP_UKRYTE] = {%s};" % ", ".join(map(str, b1)),
         "static const int8_t MLP_W2[MLP_WY][MLP_UKRYTE] = %s;" % tab(w2),
         "static const int32_t MLP_B2[MLP_WY] = {%s};" % ", ".join(map(str, b2)), ""]
    pliki = {cel_hls / "mlp_wagi.h": "\n".join(h),
             cel_hls / "mlp_wektory.txt": "\n".join(wiersze) + "\n"}
    for pl, t in pliki.items():
        pl.write_text(t)
    return dobre / len(test), pliki


def main():
    if "--trenuj" in sys.argv:
        trenuj()
    if "--sprawdz" in sys.argv:
        with tempfile.TemporaryDirectory() as d:
            acc, pliki = generuj(Path(d))
            zle = [p.name for p in pliki if (MOD / "hls" / p.name).read_text() != p.read_text()]
            print("int8: dokładność %.4f na 1000 punktach" % acc)
            if zle:
                print("NIEZGODNE z modelem:", ", ".join(zle))
                return 1
            print("Pliki hls/mlp_wagi.h i hls/mlp_wektory.txt zgodne z modelem.")
            return 0
    acc, pliki = generuj(MOD / "hls")
    print("int8: dokładność %.4f na 1000 punktach; zapisano %s" % (acc, ", ".join(p.name for p in pliki)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
