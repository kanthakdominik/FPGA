#!/usr/bin/env python3
"""Model bit w bit układów modułu 26 (26.07): współczynniki, tablice ROM, wektory testowe i miary jakości.

Każda funkcja modelu robi dokładnie te same operacje całkowitoliczbowe co RTL (mnożenia, sumy, zaokrąglenia,
nasycenia, zawijanie liczników), więc wyjście RTL ma się zgadzać z modelem co do bitu. Model:
  - projektuje filtry (okno Hamminga, wzory RBJ) i kwantuje współczynniki,
  - generuje moduły ROM (sin_tab, tw_tab) w Verilogu, SystemVerilogu i VHDL — te same wartości w trzech językach,
  - zapisuje wektory wejściowe i oczekiwane wyjścia do hdl/dane/*.hex (czytane przez testbenche),
  - liczy miary: charakterystykę FIR, cykle graniczne IIR, SFDR generatora NCO, błąd FFT względem liczb zmiennoprz.

Użycie:
  python3 dsp_model.py            — wygeneruj pliki i wypisz miary
  python3 dsp_model.py --sprawdz  — wygeneruj do katalogu tymczasowego i porównaj z plikami w repozytorium (CI)
Bez zewnętrznych bibliotek (tylko biblioteka standardowa).
"""
import cmath
import math
import os
import sys
import tempfile
from pathlib import Path

TU = Path(__file__).resolve().parent
HDL = TU.parent / "hdl"


# ---------------------------------------------------------------- arytmetyka stałoprzecinkowa
def nasyc(v, bity):
    lo, hi = -(1 << (bity - 1)), (1 << (bity - 1)) - 1
    return lo if v < lo else hi if v > hi else v


def zaokr(v, s):
    """Zaokrąglenie do najbliższej, połówki w górę: (v + 2^(s-1)) >> s (przesunięcie arytmetyczne = floor)."""
    return (v + (1 << (s - 1))) >> s


def zawin(v, bity):
    """Zawijanie do liczby ze znakiem o danej szerokości (jak rejestr w RTL)."""
    v &= (1 << bity) - 1
    return v - (1 << bity) if v >> (bity - 1) else v


def hx(v, bity):
    return format(v & ((1 << bity) - 1), "0%dX" % ((bity + 3) // 4))


class Lcg:
    """Własny generator liczb pseudolosowych — wynik niezależny od wersji Pythona."""
    def __init__(self, z):
        self.s = z & 0xFFFFFFFF

    def nast(self):
        self.s = (1664525 * self.s + 1013904223) & 0xFFFFFFFF
        return self.s

    def ze_znakiem(self, a):
        return (self.nast() >> 8) % (2 * a + 1) - a


# ---------------------------------------------------------------- 26.01 FIR
def projekt_fir(n, fc):
    """Filtr dolnoprzepustowy metodą okna (sinc · Hamming), fc względem fs, współczynniki Q1.15, suma ≈ 1."""
    m = (n - 1) / 2
    h = []
    for i in range(n):
        t = i - m
        s = 2 * fc if t == 0 else math.sin(2 * math.pi * fc * t) / (math.pi * t)
        h.append(s * (0.54 - 0.46 * math.cos(2 * math.pi * i / (n - 1))))
    k = sum(h)
    return [int(math.floor(v / k * 32768 + 0.5)) for v in h]


def fir(h, x):
    y, linia = [], [0] * len(h)
    for v in x:
        linia = [v] + linia[:-1]
        y.append(nasyc(zaokr(sum(a * b for a, b in zip(h, linia)), 15), 16))
    return y


def sygnal_fir(rng):
    x = [0] * 2048
    x[0] = 32767
    for n in range(64, 256):
        x[n] = 20000
    for n in range(256, 1024):
        x[n] = rng.ze_znakiem(32767)
    for n in range(1024, 2048):                     # świergot 0 … fs/2
        k = n - 1024
        x[n] = int(math.floor(30000 * math.sin(math.pi * k * k / 2048.0) + 0.5))
    return x


# ---------------------------------------------------------------- 26.02 IIR (DF-II transponowana)
def kwant(v, s, tryb):
    """Usunięcie s bitów ułamkowych: 0 — floor (obcięcie), 1 — zaokrąglenie, 2 — obcięcie w stronę zera."""
    if tryb == 0:
        return v >> s
    if tryb == 1:
        return zaokr(v, s)
    return -((-v) >> s) if v < 0 else v >> s


def projekt_iir():
    fs, f0, q = 1.0, 0.02, 5.0
    w0 = 2 * math.pi * f0 / fs
    al = math.sin(w0) / (2 * q)
    a0 = 1 + al
    k = lambda v: int(math.floor(v / a0 * 16384 + 0.5))
    b0 = k((1 - math.cos(w0)) / 2)
    return [b0, k(1 - math.cos(w0)), b0, k(-2 * math.cos(w0)), k(1 - al)]


def iir(c, x, tryb):
    b0, b1, b2, a1, a2 = c
    s1 = s2 = 0
    y = []
    for v in x:
        w = nasyc(kwant(b0 * v + s1, 14, tryb), 16)
        s1 = b1 * v - a1 * w + s2
        s2 = b2 * v - a2 * w
        y.append(w)
    return y


def sygnal_iir(rng):
    x = [0] * 2048
    x[0] = 16000
    for n in range(1024, 1536):
        x[n] = rng.ze_znakiem(2000)
    return x


# ---------------------------------------------------------------- 26.03 NCO
def tab_sin():
    return [int(math.floor(32767 * math.sin((i + 0.5) * math.pi / 512) + 0.5)) for i in range(256)]


def nco_probka(faza, t):
    """sin i cos dla 32-bitowej fazy: ćwiartka (2 bity) i adres (8 bitów) z najstarszych bitów."""
    def s(ph):
        q, a = (ph >> 30) & 3, (ph >> 22) & 255
        v = t[a] if q in (0, 2) else t[255 - a]
        return v if q < 2 else -v
    return s(faza), s((faza + (1 << 30)) & 0xFFFFFFFF)


def nco(ftw, t):
    faza, s, c = 0, [], []
    for f in ftw:
        a, b = nco_probka(faza, t)
        s.append(a)
        c.append(b)
        faza = (faza + f) & 0xFFFFFFFF
    return s, c


def sygnal_nco():
    return [0x0147AE14] * 1024 + [0x1999999A] * 1024 + [0x7FFFFFFF] * 1024 + [0x0A3D70A4] * 1024


def sfdr(x):
    """SFDR [dB]: okno Blackmana-Harrisa, DFT (prosta, N ≤ 1024), prążek główny ±4 binów pominięty."""
    n = len(x)
    w = [0.35875 - 0.48829 * math.cos(2 * math.pi * i / (n - 1)) + 0.14128 * math.cos(4 * math.pi * i / (n - 1))
         - 0.01168 * math.cos(6 * math.pi * i / (n - 1)) for i in range(n)]
    xw = [a * b for a, b in zip(x, w)]
    widmo = []
    for k in range(n // 2):
        s = sum(xw[i] * cmath.exp(-2j * math.pi * k * i / n) for i in range(n))
        widmo.append(abs(s))
    kmax = max(range(1, n // 2), key=lambda k: widmo[k])
    reszta = [widmo[k] for k in range(1, n // 2) if abs(k - kmax) > 4]
    return 20 * math.log10(widmo[kmax] / max(reszta))


# ---------------------------------------------------------------- 26.04 CIC i decymator wielofazowy
def cic(x, n=3, r=8, bity=25, przes=9):
    integ = [0] * n
    comb = [0] * n
    y = []
    for i, v in enumerate(x):
        a = v
        for k in range(n):
            integ[k] = zawin(integ[k] + a, bity)
            a = integ[k]
        if i % r == r - 1:
            for k in range(n):
                a, comb[k] = zawin(a - comb[k], bity), a
            y.append(a >> przes)
    return y


def pf_dec(h, x, m=4):
    pelne = fir(h, x)
    return [pelne[i] for i in range(len(x)) if i % m == m - 1]


def sygnal_dec(rng):
    x = [0] * 4096
    for n in range(0, 512):
        x[n] = 25000
    for n in range(512, 2048):
        x[n] = rng.ze_znakiem(32767)
    for n in range(2048, 4096):                     # dwa tony: 0,01 fs (przechodzi) i 0,3 fs (tłumiony)
        x[n] = int(math.floor(15000 * math.sin(2 * math.pi * 0.01 * n) + 15000 * math.sin(2 * math.pi * 0.3 * n) + 0.5))
    return x


# ---------------------------------------------------------------- 26.05 FFT 64
def tab_tw(n=64):
    return [(int(math.floor(32767 * math.cos(2 * math.pi * k / n) + 0.5)),
             int(math.floor(-32767 * math.sin(2 * math.pi * k / n) + 0.5))) for k in range(n // 2)]


def odwr(i, b=6):
    return int(format(i, "0%db" % b)[::-1], 2)


def fft64(x, tw):
    a = [x[odwr(i)] for i in range(64)]
    for s in range(1, 7):
        m, pol, krok = 1 << s, 1 << (s - 1), 64 >> s
        for k in range(0, 64, m):
            for j in range(pol):
                wr, wi = tw[j * krok]
                br, bi = a[k + j + pol]
                tr = (wr * br - wi * bi + (1 << 14)) >> 15
                ti = (wr * bi + wi * br + (1 << 14)) >> 15
                ar, ai = a[k + j]
                a[k + j] = ((ar + tr) >> 1, (ai + ti) >> 1)
                a[k + j + pol] = ((ar - tr) >> 1, (ai - ti) >> 1)
                for v in a[k + j] + a[k + j + pol]:
                    assert -32768 <= v <= 32767
    return a


def sygnal_fft(rng):
    ramki = [[(16384 if n == 0 else 0, 0) for n in range(64)]]
    ramki.append([(int(math.floor(16000 * math.cos(2 * math.pi * 5 * n / 64) + 0.5)),
                   int(math.floor(16000 * math.sin(2 * math.pi * 5 * n / 64) + 0.5))) for n in range(64)])
    ramki.append([(rng.ze_znakiem(20000), rng.ze_znakiem(20000)) for _ in range(64)])
    return ramki


# ---------------------------------------------------------------- 26.06 DDC
def ddc(x, ftw, t):
    s, c = nco([ftw] * len(x), t)
    i_ = [nasyc(zaokr(v * cc, 15), 16) for v, cc in zip(x, c)]
    q_ = [nasyc(zaokr(-v * ss, 15), 16) for v, ss in zip(x, s)]
    return cic(i_), cic(q_)


def sygnal_ddc():
    return [int(math.floor(20000 * math.cos(2 * math.pi * 0.105 * n) + 0.5)) for n in range(4096)]


# ---------------------------------------------------------------- generacja ROM w trzech językach
def rom_sin_v(t, sv):
    l, typ, ff = ("logic", "always_ff", "logic") if sv else ("reg", "always", "reg")
    w = ["// Plik wygenerowany przez model/dsp_model.py — nie edytować ręcznie.",
         "// Ćwiartka sinusa (26.03): 256 wartości 32767·sin((i + 0,5)·π/512), wyjście rejestrowane.",
         "`default_nettype none", "", "module sin_tab (",
         "    input  %s       clk," % ("logic" if sv else "wire "), "    input  %s [7:0] a," % ("logic" if sv else "wire "),
         "    output %s [15:0] q" % ff, ");", "    %s @(posedge clk)" % (typ if not sv else "always_ff"),
         "        case (a)"]
    for i, v in enumerate(t):
        w.append("            8'd%d: q <= 16'h%s;" % (i, hx(v, 16)))
    w += ["            default: q <= 16'h0000;" if not sv else "            default: q <= 16'h0000;",
          "        endcase", "endmodule", "", "`default_nettype wire", ""]
    return "\n".join(w)


def rom_sin_vhd(t):
    w = ["-- Plik wygenerowany przez model/dsp_model.py — nie edytować ręcznie.",
         "-- Ćwiartka sinusa (26.03): 256 wartości 32767·sin((i + 0,5)·π/512), wyjście rejestrowane.",
         "library ieee;", "use ieee.std_logic_1164.all;", "use ieee.numeric_std.all;", "",
         "entity sin_tab is", "  port (", "    clk : in  std_logic;", "    a   : in  unsigned(7 downto 0);",
         "    q   : out signed(15 downto 0) := (others => '0')", "  );", "end entity sin_tab;", "",
         "architecture rtl of sin_tab is", "  type tab_t is array (0 to 255) of signed(15 downto 0);",
         "  constant T : tab_t := ("]
    w += ["    x\"%s\"%s" % (hx(v, 16), "," if i < 255 else ");") for i, v in enumerate(t)]
    w += ["begin", "  process (clk)", "  begin", "    if rising_edge(clk) then", "      q <= T(to_integer(a));",
          "    end if;", "  end process;", "end architecture rtl;", ""]
    return "\n".join(w)


def rom_tw_v(tw, sv):
    w = ["// Plik wygenerowany przez model/dsp_model.py — nie edytować ręcznie.",
         "// Współczynniki obrotu FFT 64 (26.05): W_k = cos(2πk/64) - j·sin(2πk/64), k = 0..31, Q1.15 (32767).",
         "`default_nettype none", "", "module tw_tab (",
         "    input  %s [4:0]  k," % ("logic" if sv else "wire "),
         "    output %s [15:0] wr," % ("logic" if sv else "reg "),
         "    output %s [15:0] wi" % ("logic" if sv else "reg "), ");",
         "    %s" % ("always_comb" if sv else "always @(*)"), "        case (k)"]
    for k, (a, b) in enumerate(tw):
        w.append("            5'd%d: begin wr = 16'h%s; wi = 16'h%s; end" % (k, hx(a, 16), hx(b, 16)))
    w += ["            default: begin wr = 16'h0000; wi = 16'h0000; end", "        endcase", "endmodule", "",
          "`default_nettype wire", ""]
    return "\n".join(w)


def rom_tw_vhd(tw):
    w = ["-- Plik wygenerowany przez model/dsp_model.py — nie edytować ręcznie.",
         "-- Współczynniki obrotu FFT 64 (26.05): W_k = cos(2πk/64) - j·sin(2πk/64), k = 0..31, Q1.15 (32767).",
         "library ieee;", "use ieee.std_logic_1164.all;", "use ieee.numeric_std.all;", "",
         "entity tw_tab is", "  port (", "    k  : in  unsigned(4 downto 0);", "    wr : out signed(15 downto 0);",
         "    wi : out signed(15 downto 0)", "  );", "end entity tw_tab;", "",
         "architecture rtl of tw_tab is", "  type tab_t is array (0 to 31) of signed(15 downto 0);",
         "  constant TR : tab_t := (" + ", ".join("x\"%s\"" % hx(a, 16) for a, _ in tw[:8]) + ","]
    for g in range(1, 4):
        w.append("    " + ", ".join("x\"%s\"" % hx(a, 16) for a, _ in tw[8 * g:8 * g + 8]) + ("," if g < 3 else ");"))
    w.append("  constant TI : tab_t := (" + ", ".join("x\"%s\"" % hx(b, 16) for _, b in tw[:8]) + ",")
    for g in range(1, 4):
        w.append("    " + ", ".join("x\"%s\"" % hx(b, 16) for _, b in tw[8 * g:8 * g + 8]) + ("," if g < 3 else ");"))
    w += ["begin", "  wr <= TR(to_integer(k));", "  wi <= TI(to_integer(k));", "end architecture rtl;", ""]
    return "\n".join(w)


# ---------------------------------------------------------------- zapis wszystkiego
def generuj(cel):
    pliki = {}

    def wektor(nazwa, wartosci, bity):
        pliki["dane/" + nazwa] = "".join(hx(v, bity) + "\n" for v in wartosci)

    rng = Lcg(26)
    h = projekt_fir(31, 0.1)
    xf = sygnal_fir(rng)
    wektor("fir_wsp.hex", h, 16)
    wektor("fir_we.hex", xf, 16)
    wektor("fir_wy.hex", fir(h, xf), 16)

    c = projekt_iir()
    xi = sygnal_iir(rng)
    wektor("iir_wsp.hex", c, 16)
    wektor("iir_we.hex", xi, 16)
    for t in range(3):
        wektor("iir_wy%d.hex" % t, iir(c, xi, t), 16)

    t = tab_sin()
    ftw = sygnal_nco()
    s, co = nco(ftw, t)
    wektor("nco_ftw.hex", ftw, 32)
    wektor("nco_sin.hex", s, 16)
    wektor("nco_cos.hex", co, 16)

    xd = sygnal_dec(rng)
    hd = projekt_fir(32, 0.1)
    wektor("dec_we.hex", xd, 16)
    wektor("cic_wy.hex", cic(xd), 16)
    wektor("pfd_wsp.hex", hd, 16)
    wektor("pfd_wy.hex", pf_dec(hd, xd), 16)

    tw = tab_tw()
    ramki = sygnal_fft(rng)
    pliki["dane/fft_we.hex"] = "".join(hx(r, 16) + hx(i, 16) + "\n" for f in ramki for r, i in f)
    pliki["dane/fft_wy.hex"] = "".join(hx(r, 16) + hx(i, 16) + "\n" for f in ramki for r, i in fft64(f, tw))

    xdd = sygnal_ddc()
    wi, wq = ddc(xdd, 0x1999999A, t)
    wektor("ddc_we.hex", xdd, 16)
    pliki["dane/ddc_wy.hex"] = "".join(hx(a, 16) + hx(b, 16) + "\n" for a, b in zip(wi, wq))

    pliki["verilog/sin_tab.v"] = rom_sin_v(t, False)
    pliki["sv/sin_tab.sv"] = rom_sin_v(t, True)
    pliki["vhdl/sin_tab.vhd"] = rom_sin_vhd(t)
    pliki["verilog/tw_tab.v"] = rom_tw_v(tw, False)
    pliki["sv/tw_tab.sv"] = rom_tw_v(tw, True)
    pliki["vhdl/tw_tab.vhd"] = rom_tw_vhd(tw)

    for nazwa, tresc in pliki.items():
        p = Path(cel) / nazwa
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(tresc, encoding="utf-8")
    return pliki, dict(h=h, c=c, t=t, hd=hd, tw=tw, xf=xf, xi=xi, s=s, ramki=ramki, wi=wi, wq=wq)


def miary(d):
    h = d["h"]
    print("FIR 31 współczynników Q1.15 (fc = 0,1 fs):", h)
    for f in (0.0, 0.05, 0.1, 0.15, 0.2, 0.3):
        g = abs(sum(v * cmath.exp(-2j * math.pi * f * i) for i, v in enumerate(h))) / 32768
        print("  |H(%.2f fs)| = %7.2f dB" % (f, 20 * math.log10(max(g, 1e-12))))
    c = d["c"]
    print("IIR Q2.14 (dolnoprzepustowy f0 = 0,02 fs, Q = 5): b0 b1 b2 a1 a2 =", c)
    r = math.sqrt(c[4] / 16384)
    print("  promień biegunów |p| = %.5f" % r)
    for t, nazwa in enumerate(("obcięcie (floor)", "zaokrąglenie", "obcięcie w stronę zera")):
        y = iir(c, d["xi"], t)
        print("  %-24s cykl graniczny po impulsie: max|y[800..1023]| = %d, po szumie: max|y[1900..2047]| = %d"
              % (nazwa, max(abs(v) for v in y[800:1024]), max(abs(v) for v in y[1900:2048])))
    s = d["s"]
    print("NCO: SFDR (ftw = 0x0A3D70A4, 1024 próbek) = %.1f dB" % sfdr(s[3072:4096]))
    blad = 0.0
    for f in d["ramki"]:
        ref = [sum(complex(*f[n]) * cmath.exp(-2j * math.pi * k * n / 64) for n in range(64)) / 64 for k in range(64)]
        wyn = fft64(f, d["tw"])
        blad = max(blad, max(abs(complex(*wyn[k]) - ref[k]) for k in range(64)))
    print("FFT 64: maks. błąd względem DFT/64 (zmiennoprzecinkowej) = %.2f LSB" % blad)
    wi, wq = d["wi"], d["wq"]
    print("DDC: |I + jQ| w stanie ustalonym ≈ %d (wejście 20000, CIC: wzmocnienie 512, przesunięcie o 9)"
          % int(max(math.hypot(a, b) for a, b in zip(wi[100:], wq[100:]))))


def main():
    if "--sprawdz" in sys.argv:
        with tempfile.TemporaryDirectory() as tmp:
            pliki, d = generuj(tmp)
            rozne = [n for n, tresc in pliki.items() if not (HDL / n).is_file() or (HDL / n).read_text(encoding="utf-8") != tresc]
            miary(d)
            if rozne:
                print("Pliki niezgodne z modelem:", ", ".join(rozne))
                sys.exit(1)
            print("Wszystkie pliki zgodne z modelem (%d)." % len(pliki))
    else:
        _, d = generuj(HDL)
        miary(d)


if __name__ == "__main__":
    main()
