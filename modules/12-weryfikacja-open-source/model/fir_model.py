"""Model referencyjny filtru fir8 (moduł 12) — dokładny co do bitu oraz zmiennoprzecinkowy.

fir8_fixed()  — dokładnie to, co liczy układ: suma iloczynów na liczbach całkowitych, (s + 1024) >> 11,
                nasycenie do 16 bitów. Opcje rounding / saturate odtwarzają błędy BUG = 1 i BUG = 2.
fir8_float()  — ten sam filtr w liczbach zmiennoprzecinkowych (wzorzec „idealny”), w skali wyjścia
                (16 × wejście), do oceny błędu kwantyzacji.
"""
import numpy as np

H = np.array([-763, 0, 4499, 12648, 12648, 4499, 0, -763], dtype=np.int64)   # Q1.15
SHIFT = 11                                  # 15 bitów ułamka współczynników − 4 bity więcej na wyjściu
Y_MIN, Y_MAX = -(1 << 15), (1 << 15) - 1


def fir8_fixed(x, rounding=True, saturate=True):
    """Wyjście układu dla ciągu próbek x (liczby całkowite −2048…2047), historia zaczyna się od zer."""
    x = np.asarray(x, dtype=np.int64)
    s = np.convolve(x, H)[: len(x)]                       # suma iloczynów dla każdej próbki
    if rounding:
        s = s + (1 << (SHIFT - 1))
    y = s >> SHIFT                                        # przesunięcie arytmetyczne = dzielenie z floor
    if saturate:
        return np.clip(y, Y_MIN, Y_MAX)
    return ((y + (1 << 15)) % (1 << 16)) - (1 << 15)      # zawinięcie do 16 bitów ze znakiem


def fir8_float(x):
    """Filtr idealny: te same współczynniki bez zaokrągleń, wynik w skali wyjścia układu."""
    x = np.asarray(x, dtype=np.float64)
    return np.convolve(x, H / 32768.0)[: len(x)] * 16.0


def stats(x):
    """Liczba nasyceń w obie strony i wyników dokładnie na połówce LSB (przypadki brzegowe zaokrąglenia)."""
    s = np.convolve(np.asarray(x, dtype=np.int64), H)[: len(x)]
    y = (s + 1024) >> SHIFT
    return {
        "nasycenie+": int(np.sum(y > Y_MAX)),
        "nasycenie-": int(np.sum(y < Y_MIN)),
        "polowka": int(np.sum(s % 2048 == 1024)),
    }


def saturation_pattern():
    """Próbki o znakach zgodnych ze znakami współczynników — największa możliwa suma (dodatnia, ujemna)."""
    pos = [-2048 if h < 0 else 2047 for h in H[::-1]]
    neg = [2047 if h < 0 else -2048 for h in H[::-1]]
    return pos + neg


if __name__ == "__main__":
    rng = np.random.default_rng(1)
    x = np.concatenate([saturation_pattern(), rng.integers(-2048, 2048, 10000)])
    y = fir8_fixed(x)
    err = y - fir8_float(x)
    ok = np.abs(err[~((y == Y_MAX) | (y == Y_MIN))])
    print("odpowiedź impulsowa (2047):", fir8_fixed([2047] + [0] * 8).tolist())
    print("statystyki:", stats(x))
    print(f"błąd względem modelu zmiennoprzecinkowego (bez nasyceń): max {ok.max():.3f} LSB, "
          f"średni {ok.mean():.3f} LSB")
