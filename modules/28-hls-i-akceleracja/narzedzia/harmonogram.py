#!/usr/bin/env python3
"""Harmonogram pętli potokowanej i interwał inicjacji II (28.02) — to, co narzędzie HLS liczy przy
#pragma HLS PIPELINE, w miniaturze.

Ciało pętli to graf operacji: każda operacja ma typ zasobu i opóźnienie (w taktach); krawędź (źródło, cel,
odległość) — cel potrzebuje wyniku źródła z iteracji o „odległość” wcześniejszej (0 — ta sama iteracja,
≥ 1 — zależność przenoszona przez pętlę, np. akumulator albo pamięć).
  ResMII = max po zasobach ⌈liczba operacji / liczba jednostek⌉   (np. porty pamięci)
  RecMII = max po cyklach grafu ⌈Σ opóźnień / Σ odległości⌉       (pętle sprzężenia)
  II ≥ max(ResMII, RecMII); harmonogram modulo (tablica zajętości zasobów modulo II) szuka najmniejszego II,
  przy którym wszystkie operacje się mieszczą i zależności przenoszone są spełnione:
     t(cel) + odległość · II ≥ t(źródło) + opóźnienie(źródło).
  Czas pętli o N iteracjach = głębokość + (N − 1) · II.
Użycie: python3 harmonogram.py [--test]
"""
import math
import sys
from collections import defaultdict


class Petla:
    def __init__(self, nazwa, opis, zasoby):
        self.nazwa, self.opis, self.zasoby = nazwa, opis, zasoby      # zasoby: typ -> liczba jednostek
        self.op = {}                                                  # nazwa -> (typ, opóźnienie)
        self.kr = []                                                  # (źródło, cel, odległość)

    def dodaj(self, nazwa, typ, opozn, *zalezy):
        self.op[nazwa] = (typ, opozn)
        for z in zalezy:
            self.kr.append((z, nazwa, 0) if isinstance(z, str) else (z[0], nazwa, z[1]))
        return self

    def przez_petle(self, zrodlo, cel, odleglosc=1):
        self.kr.append((zrodlo, cel, odleglosc))
        return self

    # ------------------------------------------------------------ dolne granice
    def res_mii(self):
        ile = defaultdict(int)
        for typ, _ in self.op.values():
            ile[typ] += 1
        m = 1
        for typ, n in ile.items():
            jedn = self.zasoby.get(typ)
            if jedn:
                m = max(m, math.ceil(n / jedn))
        return m

    def rec_mii(self):
        nast = defaultdict(list)
        for s, c, d in self.kr:
            nast[s].append((c, d))
        najw = 1
        wezly = sorted(self.op)
        for start in wezly:                                  # cykle elementarne (DFS od najmniejszego węzła)
            stos = [(start, 0, 0, [start])]
            while stos:
                w, lat, odl, sciezka = stos.pop()
                for c, d in nast[w]:
                    l2, o2 = lat + self.op[w][1], odl + d
                    if c == start and o2 > 0:
                        najw = max(najw, math.ceil(l2 / o2))
                    elif c not in sciezka and wezly.index(c) > wezly.index(start):
                        stos.append((c, l2, o2, sciezka + [c]))
        return najw

    # ------------------------------------------------------------ harmonogram modulo
    def harmonogram(self, ii):
        lat = {o: self.op[o][1] for o in self.op}
        dolna = {o: 0 for o in self.op}
        for _ in range(4 * len(self.op) + 4):              # najdłuższe ścieżki z odległościami (bez zasobów)
            zmiana = False
            for s, c, d in self.kr:
                if dolna[c] < dolna[s] + lat[s] - d * ii:
                    dolna[c] = dolna[s] + lat[s] - d * ii
                    zmiana = True
            if not zmiana:
                break
        else:
            return None                                   # cykl dodatni: II < RecMII
        t = {}
        mrt = defaultdict(lambda: [0] * ii)
        kolejnosc = list(self.op)
        while len(t) < len(self.op):
            o = min((x for x in self.op if x not in t), key=lambda x: (dolna[x], kolejnosc.index(x)))
            typ = self.op[o][0]
            czas = max(dolna[o], 0)
            jedn = self.zasoby.get(typ)
            if jedn:
                for _ in range(ii):
                    if mrt[typ][czas % ii] < jedn:
                        break
                    czas += 1
                else:
                    return None
                mrt[typ][czas % ii] += 1
            t[o] = czas
            for s, c, d in self.kr:                        # propagacja do jeszcze nieumieszczonych operacji
                if s == o and c not in t:
                    dolna[c] = max(dolna[c], czas + lat[o] - d * ii)
                if s in t and c in t and t[c] + d * ii < t[s] + lat[s]:
                    return None                           # przesunięcie przez zasoby złamało zależność
        return t

    def rozwiaz(self):
        mii = max(self.res_mii(), self.rec_mii())
        for ii in range(mii, mii + 64):
            t = self.harmonogram(ii)
            if t is not None:
                glebokosc = max(t[o] + max(self.op[o][1], 1) for o in t)
                return ii, t, glebokosc
        raise RuntimeError("brak harmonogramu")


def przyklady():
    p = []
    # 1. FIR, jedna iteracja = jeden współczynnik (MAC): akumulator całkowity — dodawanie w 1 takcie
    p.append(Petla("fir_mac_int", "MAC całkowity: acc += h[i]·x[i], dodawanie 1 takt", {"pam": 2})
             .dodaj("odczyt_h", "pam", 1).dodaj("odczyt_x", "pam", 1)
             .dodaj("mnoz", "dsp", 3, "odczyt_h", "odczyt_x")
             .dodaj("dodaj", "alu", 1, "mnoz").przez_petle("dodaj", "dodaj"))
    # 2. to samo na liczbach zmiennoprzecinkowych: sumator float ma kilka taktów opóźnienia
    p.append(Petla("suma_float", "acc += a[i] (float), sumator 4 takty", {"pam": 2})
             .dodaj("odczyt", "pam", 1).dodaj("fadd", "fadd", 4, "odczyt").przez_petle("fadd", "fadd"))
    # 3. ta sama suma z 4 akumulatorami częściowymi (przeplot): zależność co 4 iteracje
    p.append(Petla("suma_float_4", "4 akumulatory częściowe: acc[i % 4] += a[i]", {"pam": 2})
             .dodaj("odczyt", "pam", 1).dodaj("fadd", "fadd", 4, "odczyt").przez_petle("fadd", "fadd", 4))
    # 4. histogram: odczyt–dodanie–zapis tej samej pamięci, zależność przez pamięć na odległość 1
    p.append(Petla("histogram", "hist[d]++ w pamięci blokowej (odczyt 1 takt)", {"pam_h": 2, "pam_d": 2})
             .dodaj("odczyt_d", "pam_d", 1).dodaj("odczyt_h", "pam_h", 1, "odczyt_d")
             .dodaj("plus1", "alu", 1, "odczyt_h").dodaj("zapis_h", "pam_h", 1, "plus1")
             .przez_petle("zapis_h", "odczyt_h"))
    # 5. histogram z licznikiem w rejestrze i przekazaniem: w pętli zostaje tylko porównanie i licznik
    p.append(Petla("histogram_szybki", "licznik serii w rejestrze, pamięć bez zależności (DEPENDENCE false)",
                   {"pam_h": 2, "pam_d": 2})
             .dodaj("odczyt_d", "pam_d", 1).dodaj("porownaj", "alu", 0, "odczyt_d")   # łańcuch w tym samym takcie
             .dodaj("odczyt_h", "pam_h", 1, "odczyt_d").dodaj("licznik", "alu", 1, "porownaj", "odczyt_h")
             .dodaj("zapis_h", "pam_h", 1, "licznik").przez_petle("licznik", "licznik")
             .przez_petle("licznik", "porownaj"))
    # 6. wiersz × kolumna 16 elementów na iterację: 32 odczyty z dwóch pamięci po 2 porty
    w = Petla("macierz_2porty", "16 iloczynów na iterację, a i b w pamięciach 2-portowych", {"pam_a": 2, "pam_b": 2})
    w6 = Petla("macierz_podzial", "to samo, tablice podzielone na rejestry (ARRAY_PARTITION)", {})
    for q in (w, w6):
        poprz = None
        for k in range(16):
            q.dodaj("a%d" % k, "pam_a", 1).dodaj("b%d" % k, "pam_b", 1)
            q.dodaj("m%d" % k, "dsp", 3, "a%d" % k, "b%d" % k)
        for k in range(16):
            q.dodaj("s%d" % k, "alu", 1, "m%d" % k, *(["s%d" % (k - 1)] if k else []))
        p.append(q)
    # 7. biquad (26.02): w zależy od w z poprzedniej próbki przez mnożenie i dwa dodawania
    p.append(Petla("biquad", "IIR: w = b0·x + s1; s1 = b1·x − a1·w + s2 (mnożarka 3 takty)", {})
             .dodaj("b0x", "dsp", 3).dodaj("w", "alu", 1, "b0x", ("s1", 1))
             .dodaj("a1w", "dsp", 3, "w").dodaj("a2w", "dsp", 3, "w").dodaj("b1x", "dsp", 3).dodaj("b2x", "dsp", 3)
             .dodaj("s2", "alu", 1, "b2x", "a2w").dodaj("s1", "alu", 1, "b1x", "a1w", ("s2", 1)))
    return p


OCZEKIWANE = {"fir_mac_int": 1, "suma_float": 4, "suma_float_4": 1, "histogram": 3, "histogram_szybki": 1,
              "macierz_2porty": 8, "macierz_podzial": 1, "biquad": 5}


def main():
    print("%-17s %6s %6s %3s %8s %12s  %s" % ("pętla", "ResMII", "RecMII", "II", "głębok.", "takty N=1024", "opis"))
    bledy = 0
    for p in przyklady():
        ii, t, gl = p.rozwiaz()
        print("%-17s %6d %6d %3d %8d %12d  %s" % (p.nazwa, p.res_mii(), p.rec_mii(), ii, gl, gl + 1023 * ii, p.opis))
        if "--test" in sys.argv and OCZEKIWANE[p.nazwa] != ii:
            print("  BŁĄD: oczekiwane II = %d" % OCZEKIWANE[p.nazwa])
            bledy += 1
    if "--test" in sys.argv:
        print("PASS" if bledy == 0 else "FAIL")
    return 1 if bledy else 0


if __name__ == "__main__":
    sys.exit(main())
