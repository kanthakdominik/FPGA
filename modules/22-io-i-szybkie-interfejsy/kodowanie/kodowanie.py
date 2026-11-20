"""Kodowanie liniowe dla łączy szeregowych (22.04): 8b/10b i 64b/66b ze skramblerem — model i sprawdzenie
własności, o których mówi tekst. Bez bibliotek zewnętrznych.

    python3 kodowanie.py

8b/10b (Widmer, Franaszek 1983; IEEE 802.3 cl. 36): tablice 5b/6b i 3b/4b z dwoma wariantami (RD- i RD+),
wybór wariantu według bieżącej nierównowagi (running disparity). Sprawdzane:
  - każde słowo kodowe ma 4, 5 albo 6 jedynek (nierównowaga 0 albo ±2), RD zawsze ±1,
  - najdłuższy ciąg jednakowych bitów w strumieniu losowych danych i znaków K: 5,
  - przecinek (0011111 / 1100000) nie pojawia się w strumieniu samych danych, w K28.5 — tylko na granicy znaku,
  - kodowanie jest odwracalne (dekodowanie 100 000 losowych znaków).
64b/66b (IEEE 802.3 cl. 49): nagłówek 01/10 i skrambler samosynchronizujący x^58 + x^39 + 1. Sprawdzane:
  - długość ciągów jednakowych bitów dla danych samych zer z i bez skramblera,
  - pojedynczy błąd na łączu daje 3 błędy po deskramblerze (propagacja), deskrambler synchronizuje się sam.
"""
import random

# ---------------------------------------------------------------- 8b/10b
# 5b/6b: EDCBA -> abcdei, warianty (RD-, RD+); jeden wariant = słowo zrównoważone
T56 = {
    0: ("100111", "011000"), 1: ("011101", "100010"), 2: ("101101", "010010"), 3: ("110001",),
    4: ("110101", "001010"), 5: ("101001",), 6: ("011001",), 7: ("111000", "000111"),
    8: ("111001", "000110"), 9: ("100101",), 10: ("010101",), 11: ("110100",),
    12: ("001101",), 13: ("101100",), 14: ("011100",), 15: ("010111", "101000"),
    16: ("011011", "100100"), 17: ("100011",), 18: ("010011",), 19: ("110010",),
    20: ("001011",), 21: ("101010",), 22: ("011010",), 23: ("111010", "000101"),
    24: ("110011", "001100"), 25: ("100110",), 26: ("010110",), 27: ("110110", "001001"),
    28: ("001110",), 29: ("101110", "010001"), 30: ("011110", "100001"), 31: ("101011", "010100"),
}
K28_6 = ("001111", "110000")
# 3b/4b: HGF -> fghj; dla danych 7 ma wariant podstawowy P7 i zamienny A7
T34 = {0: ("1011", "0100"), 1: ("1001",), 2: ("0101",), 3: ("1100", "0011"),
       4: ("1101", "0010"), 5: ("1010",), 6: ("0110",), 7: ("1110", "0001")}
A7 = ("0111", "1000")
K34 = {0: ("1011", "0100"), 1: ("0110", "1001"), 2: ("1010", "0101"), 3: ("1100", "0011"),
       4: ("1101", "0010"), 5: ("0101", "1010"), 6: ("1001", "0110"), 7: ("0111", "1000")}
ZNAKI_K = [0x1C, 0x3C, 0x5C, 0x7C, 0x9C, 0xBC, 0xDC, 0xFC, 0xF7, 0xFB, 0xFD, 0xFE]   # K28.0-7, K23/27/29/30.7


def nier(s):
    return s.count("1") - s.count("0")


def wybierz(warianty, rd):
    if len(warianty) == 1:
        return warianty[0]
    return warianty[0] if rd < 0 else warianty[1]


def nowe_rd(blok, rd):
    d = nier(blok)
    return rd if d == 0 else (1 if d > 0 else -1)


def koduj(bajt, k, rd):
    x, y = bajt & 0x1F, bajt >> 5
    if k:
        if x == 28:
            b6 = wybierz(K28_6, rd)
        else:                                            # K23.7, K27.7, K29.7, K30.7: 6b jak dane
            b6 = wybierz(T56[x], rd)
        rd = nowe_rd(b6, rd)
        b4 = wybierz(K34[y], rd)
    else:
        b6 = wybierz(T56[x], rd)
        rd = nowe_rd(b6, rd)
        if y == 7 and ((rd < 0 and x in (17, 18, 20)) or (rd > 0 and x in (11, 13, 14))):
            b4 = wybierz(A7, rd)                         # unika pięciu jednakowych bitów na styku e,i,f,g,h
        else:
            b4 = wybierz(T34[y], rd)
    rd = nowe_rd(b4, rd)
    return b6 + b4, rd


def najdluzszy(s):
    m = n = 1
    for a, b in zip(s, s[1:]):
        n = n + 1 if a == b else 1
        m = max(m, n)
    return m


def test_8b10b():
    bledy = 0
    # tablica dekodowania ze wszystkich znaków w obu RD
    dek = {}
    for rd0 in (-1, 1):
        for b in range(256):
            c, _ = koduj(b, False, rd0)
            dek.setdefault(c, set()).add((b, False))
        for b in ZNAKI_K:
            c, _ = koduj(b, True, rd0)
            dek.setdefault(c, set()).add((b, True))
    niejedn = [c for c, v in dek.items() if len(v) > 1]
    jedynki = sorted({c.count("1") for c in dek})
    print(f"8b/10b: {len(dek)} różnych słów kodowych (256 danych i 12 znaków K w dwóch wariantach RD), "
          f"liczba jedynek w słowie: {jedynki}, słów niejednoznacznych: {len(niejedn)}")
    if niejedn or jedynki != [4, 5, 6]:
        bledy += 1

    random.seed(1)
    rd, strumien, dane, rds = -1, [], [], set()
    for i in range(100_000):
        k = random.random() < 0.05
        b = random.choice(ZNAKI_K) if k else random.randrange(256)
        c, rd = koduj(b, k, rd)
        rds.add(rd)
        strumien.append(c)
        dane.append((b, k))
    s = "".join(strumien)
    odz = [next(iter(dek[c])) for c in strumien]
    print(f"  100 000 znaków (5 % K): RD tylko {sorted(rds)}, najdłuższy ciąg jednakowych bitów {najdluzszy(s)}, "
          f"dekodowanie {'zgodne' if odz == dane else 'NIEZGODNE'}")
    if rds != {-1, 1} or najdluzszy(s) > 5 or odz != dane:
        bledy += 1

    # przecinek w strumieniu samych danych i w strumieniu z K28.5
    rd, d = -1, []
    for i in range(100_000):
        c, rd = koduj(random.randrange(256), False, rd)
        d.append(c)
    s = "".join(d)
    n_dane = s.count("0011111") + s.count("1100000")
    rd, d, pozycje = -1, [], set()
    for i in range(20_000):
        k = i % 10 == 0
        c, rd = koduj(0xBC if k else random.randrange(256), k, rd)
        d.append(c)
    s = "".join(d)
    for wz in ("0011111", "1100000"):
        p = s.find(wz)
        while p >= 0:
            pozycje.add(p % 10)
            p = s.find(wz, p + 1)
    print(f"  przecinek w 1 000 000 bitów samych danych: {n_dane} razy; w strumieniu z K28.5 tylko na pozycjach "
          f"{sorted(pozycje)} znaku (K28.5 RD-: {koduj(0xBC, True, -1)[0]}, RD+: {koduj(0xBC, True, 1)[0]})")
    if n_dane != 0 or pozycje != {0}:
        bledy += 1
    return bledy


# ---------------------------------------------------------------- 64b/66b
def skrambluj(bity, stan):
    wyj = []
    for b in bity:
        o = b ^ stan[38] ^ stan[57]                       # x^58 + x^39 + 1, stan[0] = bit ostatni
        wyj.append(o)
        stan = [o] + stan[:-1]
    return wyj, stan


def deskrambluj(bity, stan):
    wyj = []
    for b in bity:
        wyj.append(b ^ stan[38] ^ stan[57])
        stan = [b] + stan[:-1]
    return wyj, stan


def test_64b66b():
    bledy = 0
    random.seed(2)
    bloki = 2000
    zera = [0] * 64
    bez, z_skr = [], []
    stan = [random.randrange(2) for _ in range(58)]
    for _ in range(bloki):
        bez += [0, 1] + zera                             # nagłówek 01 = blok danych
        s, stan = skrambluj(zera, stan)
        z_skr += [0, 1] + s
    print(f"64b/66b: dane same zera, {bloki} bloków: najdłuższy ciąg bez skramblera "
          f"{najdluzszy(''.join(map(str, bez)))} bitów, ze skramblerem {najdluzszy(''.join(map(str, z_skr)))} bitów; "
          f"narzut {2 / 64 * 100:.3f} % (8b/10b: 25 %)")
    if najdluzszy("".join(map(str, z_skr))) > 66:
        bledy += 1

    dane = [random.randrange(2) for _ in range(64 * 200)]
    tx, _ = skrambluj(dane, [0] * 58)
    rx_st = [random.randrange(2) for _ in range(58)]     # deskrambler startuje z innym stanem
    rx = list(tx)
    rx[5000] ^= 1                                        # jeden błąd na łączu
    odz, _ = deskrambluj(rx, rx_st)
    zle = [i for i in range(len(dane)) if odz[i] != dane[i]]
    po_synchr = [i for i in zle if i >= 58]
    print(f"  deskrambler z innym stanem początkowym: błędy tylko w pierwszych 58 bitach "
          f"({len([i for i in zle if i < 58])}), potem samosynchronizacja; jeden błąd na łączu w bicie 5000 -> "
          f"błędy po deskramblerze w bitach {po_synchr} ({len(po_synchr)} = 1 + 2 odczepy)")
    if po_synchr != [5000, 5039, 5058]:
        bledy += 1
    return bledy


if __name__ == "__main__":
    b = test_8b10b() + test_64b66b()
    print("Wynik:", "OK" if b == 0 else f"BŁĘDY: {b}")
    raise SystemExit(1 if b else 0)
