#!/usr/bin/env python3
"""Model CORDIC bit w bit zgodny z hdl/verilog/cordic.v (19.04) i analiza błędu.

Dla W = 16 bitów danych liczy największy błąd sin/cos (x_in = 32767/K), obrotu losowych wektorów
i wektorowania (moduł, kąt) w zależności od liczby iteracji N i szerokości kąta A.
Użycie: python3 cordic_model.py          — tabela błędów
        python3 cordic_model.py --test   — tylko konfiguracja z testbencha (W=16, A=24, N=18, G=4)
"""
import math
import random
import sys


def atan_a(i, A):
    t = round(math.atan(2.0 ** -i) / (2 * math.pi) * 2 ** 32)
    return (t + (1 << (31 - A))) >> (32 - A)


def ze_znakiem(v, bity):
    v &= (1 << bity) - 1
    return v - (1 << bity) if v >> (bity - 1) else v


def cordic(x_in, y_in, z_in, W=16, A=24, N=18, G=4, tryb=0):
    WI = W + 2 + G
    x, y = x_in << G, y_in << G
    z = ze_znakiem(z_in, A)
    cw = 1 << (A - 2)
    if tryb == 0:
        kw = (z_in >> (A - 2)) & 3
        if kw == 1:
            x, y, z = -y, x, z - cw
        elif kw == 2:
            x, y, z = y, -x, z + cw
    else:
        if x_in < 0 and y_in >= 0:
            x, y, z = y, -x, z + cw
        elif x_in < 0:
            x, y, z = -y, x, z - cw
    for k in range(N):
        kat = atan_a(k, A)
        d = (z >= 0) if tryb == 0 else (y < 0)
        xs, ys = x >> k, y >> k
        if d:
            x, y, z = x - ys, y + xs, z - kat
        else:
            x, y, z = x + ys, y - xs, z + kat
        x, y, z = ze_znakiem(x, WI), ze_znakiem(y, WI), ze_znakiem(z, A)
    pol = 1 << (G - 1)
    return (x + pol) >> G, (y + pol) >> G, z


def wzmocnienie(N):
    return math.prod(math.sqrt(1 + 2.0 ** (-2 * i)) for i in range(N))


def bledy(W=16, A=24, N=18, G=4, n=4000, ziarno=1):
    rnd = random.Random(ziarno)
    K = wzmocnienie(N)
    amp = 2 ** (W - 1) - 1
    m_sc = m_obr = m_mod = m_kat = 0.0
    x0 = round(amp / K)
    for i in range(4096):
        z = (i << (A - 12)) + rnd.randrange(1 << (A - 12))
        th = ze_znakiem(z, A) * 2 * math.pi / 2 ** A
        x, y, _ = cordic(x0, 0, z, W, A, N, G, 0)
        m_sc = max(m_sc, abs(x - K * x0 * math.cos(th)), abs(y - K * x0 * math.sin(th)))
    for _ in range(n):
        xi, yi = rnd.randrange(-2 ** (W - 1), 2 ** (W - 1)), rnd.randrange(-2 ** (W - 1), 2 ** (W - 1))
        z = rnd.randrange(1 << A)
        th = ze_znakiem(z, A) * 2 * math.pi / 2 ** A
        x, y, _ = cordic(xi, yi, z, W, A, N, G, 0)
        m_obr = max(m_obr, abs(x - K * (xi * math.cos(th) - yi * math.sin(th))),
                    abs(y - K * (xi * math.sin(th) + yi * math.cos(th))))
        x, y, zv = cordic(xi, yi, 0, W, A, N, G, 1)
        r = math.hypot(xi, yi)
        m_mod = max(m_mod, abs(x - K * r))
        if r >= 4096:
            ek = math.atan2(yi, xi) / (2 * math.pi) * 2 ** A
            dk = (zv - round(ek) + 2 ** (A - 1)) % 2 ** A - 2 ** (A - 1)
            m_kat = max(m_kat, abs(dk) * 2 * math.pi / 2 ** A)
    return K, m_sc, m_obr, m_mod, m_kat


def main():
    if "--test" in sys.argv:
        K, sc, obr, mod, kat = bledy()
        print(f"W=16 A=24 N=18 G=4: K={K:.6f} sin/cos {sc:.2f} LSB, obrót {obr:.2f} LSB, "
              f"moduł {mod:.2f} LSB, kąt {kat:.2e} rad")
        return
    print(f"{'N':>3} {'A':>3} {'G':>2} | {'sin/cos':>8} {'obrót':>8} {'moduł':>8} {'kąt [rad]':>10}   (W = 16, błąd w LSB)")
    for N, A, G in ((8, 24, 4), (10, 24, 4), (12, 24, 4), (14, 24, 4), (16, 24, 4), (18, 24, 4),
                    (20, 24, 4), (18, 18, 4), (18, 24, 0 + 2), (18, 24, 6)):
        K, sc, obr, mod, kat = bledy(N=N, A=A, G=G, n=1500)
        print(f"{N:3d} {A:3d} {G:2d} | {sc:8.2f} {obr:8.2f} {mod:8.2f} {kat:10.2e}")


if __name__ == "__main__":
    main()
