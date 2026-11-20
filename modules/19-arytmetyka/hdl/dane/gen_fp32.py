#!/usr/bin/env python3
"""Wektory testowe dla fp32_mnoz (19.05): mnożenie liczb IEEE 754 binary32, zaokrąglenie do najbliższej
(połówka do parzystej), liczby zdenormalizowane traktowane jak zero (DAZ na wejściu, FTZ na wyjściu),
jeden kanoniczny NaN (0x7FC00000).

Model `mnoz` liczy na liczbach całkowitych tak jak sprzęt; dla wyników w zakresie liczb normalnych jest
porównywany z mnożeniem w Pythonie (iloczyn dwóch binary32 jest dokładny w binary64, a struct.pack('f')
zaokrągla do najbliższej parzystej) — model jest więc sprawdzony względem prawdziwego IEEE 754.

Zapisuje fp32_mnoz.hex: w każdym wierszu  a  b  wynik  flagi  (flagi: bit 1 — nadmiar, bit 0 — niedomiar).
"""
import random
import struct
from pathlib import Path

NAN = 0x7FC00000


def rozbierz(x):
    return x >> 31, (x >> 23) & 0xFF, x & 0x7FFFFF


def mnoz(a, b):
    """Zwraca (wynik, nadmiar, niedomiar) — dokładnie jak fp32_mnoz."""
    sa, ea, fa = rozbierz(a)
    sb, eb, fb = rozbierz(b)
    s = sa ^ sb
    zero_a, zero_b = ea == 0, eb == 0                     # zero albo zdenormalizowana (DAZ)
    inf_a, inf_b = ea == 255 and fa == 0, eb == 255 and fb == 0
    nan_a, nan_b = ea == 255 and fa != 0, eb == 255 and fb != 0
    if nan_a or nan_b or (inf_a and zero_b) or (zero_a and inf_b):
        return NAN, 0, 0
    if inf_a or inf_b:
        return (s << 31) | 0x7F800000, 0, 0
    if zero_a or zero_b:
        return s << 31, 0, 0
    m = ((1 << 23) | fa) * ((1 << 23) | fb)               # 48 bitów, wartość w [2^46, 2^48)
    e = ea + eb - 127
    if m >> 47:
        mant, g, st, e = m >> 24, (m >> 23) & 1, int(m & ((1 << 23) - 1) != 0), e + 1
    else:
        mant, g, st = m >> 23, (m >> 22) & 1, int(m & ((1 << 22) - 1) != 0)
        mant &= (1 << 24) - 1
    mant += g & (st | (mant & 1))                         # połówka do parzystej
    if mant >> 24:
        mant >>= 1
        e += 1
    if e >= 255:
        return (s << 31) | 0x7F800000, 1, 0
    if e <= 0:
        return s << 31, 0, 1
    return (s << 31) | (e << 23) | (mant & 0x7FFFFF), 0, 0


def f32(x):
    return struct.unpack("<f", struct.pack("<I", x))[0]


def bity(v):
    return struct.unpack("<I", struct.pack("<f", v))[0]


def losowa(rnd, emin=1, emax=254):
    return (rnd.getrandbits(1) << 31) | (rnd.randint(emin, emax) << 23) | rnd.getrandbits(23)


def krotka_mantysa(rnd, bitow, e):
    """Liczba o mantysie z `bitow` znaczącymi bitami — iloczyny takich liczb często wypadają na połówce."""
    m = rnd.getrandbits(bitow - 1) | (1 << (bitow - 1))
    return (rnd.getrandbits(1) << 31) | (e << 23) | ((m << (24 - bitow)) & 0x7FFFFF)


def main():
    rnd = random.Random(19)
    pary = []
    spec = [0x00000000, 0x80000000, 0x3F800000, 0xBF800000, 0x7F800000, 0xFF800000, NAN, 0x7F800001,
            0xFFC00000, 0x00000001, 0x807FFFFF, 0x00800000, 0x7F7FFFFF, 0xFF7FFFFF, 0x40000000, 0x3F000000]
    pary += [(a, b) for a in spec for b in spec]                    # wszystkie pary specjalne
    pary += [(losowa(rnd), losowa(rnd)) for _ in range(1500)]      # cały zakres (z nadmiarem i niedomiarem)
    pary += [(losowa(rnd, 100, 154), losowa(rnd, 100, 154)) for _ in range(800)]
    for _ in range(600):                                             # remisy przy zaokrąglaniu
        pary.append((krotka_mantysa(rnd, 13, rnd.randint(110, 140)), krotka_mantysa(rnd, 13, rnd.randint(110, 140))))
    for _ in range(300):                                             # granica niedomiaru i nadmiaru
        ea = rnd.randint(1, 126)
        pary.append((losowa(rnd, ea, ea), losowa(rnd, 127 - ea - 1, 127 - ea + 1)))
        ea = rnd.randint(128, 254)
        pary.append((losowa(rnd, ea, ea), losowa(rnd, 381 - ea - 1, 381 - ea + 1)))
    pary += [(0x3F800001, 0x3F800001), (0x3FFFFFFF, 0x3FFFFFFF), (0x00800000, 0x3F000000),
             (0x00800000, 0x3F800000), (0x7F7FFFFF, 0x3F800001), (0x7F7FFFFF, 0x40000000)]

    sprawdzone = remisy = nadmiary = niedomiary = 0
    wiersze = []
    for a, b in pary:
        p, nad, nied = mnoz(a, b)
        e = (p >> 23) & 0xFF
        if 0 < e < 255 and not nad and not nied:                    # wynik normalny: porównanie z IEEE 754
            ieee = bity(f32(a) * f32(b))
            assert ieee == p, (hex(a), hex(b), hex(p), hex(ieee))
            sprawdzone += 1
        ma, mb = (1 << 23) | (a & 0x7FFFFF), (1 << 23) | (b & 0x7FFFFF)
        m = ma * mb
        reszta_bity = 24 if m >> 47 else 23
        if (m & ((1 << reszta_bity) - 1)) == 1 << (reszta_bity - 1):
            remisy += 1
        nadmiary += nad
        niedomiary += nied
        wiersze.append(f"{a:08x} {b:08x} {p:08x} {nad * 2 + nied:x}")
    Path(__file__).with_name("fp32_mnoz.hex").write_text("\n".join(wiersze) + "\n")
    print(f"wektorów {len(wiersze)}: porównanych z IEEE 754 {sprawdzone}, remisów {remisy}, "
          f"nadmiarów {nadmiary}, niedomiarów {niedomiary}")


if __name__ == "__main__":
    main()
