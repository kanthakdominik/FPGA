#!/usr/bin/env python3
"""Diagramy czasowe WaveDrom (WaveJSON) jako tekst (30.01) — żeby specyfikacja w Markdown była czytelna
także bez przeglądarki z JavaScriptem, w terminalu, w przeglądzie kodu i w diffie.

Obsługiwany podzbiór WaveJSON: "signal" (sygnały, odstępy {}, grupy ["nazwa", ...]), "wave" ze znakami
p n P N (zegar), 0 1 l h L H (poziomy), x, z, = i 2-9 (dane z listy "data"), . (ciąg dalszy), | (przerwa,
rysowana jak ciąg dalszy), "head": {"text", "tick"}, "foot": {"text"}, "config": {"hscale"}.
Pola "node"/"edge" są pomijane (strzałki zależności zostają w oryginalnym diagramie WaveDrom).

  python3 wavedrom_ascii.py diagram.json             # wydruk
  python3 wavedrom_ascii.py --sprawdz                # diagramy/*.json == diagramy/*.txt i wstawki w tematach
  python3 wavedrom_ascii.py --zapisz                 # odśwież diagramy/*.txt
"""
import argparse
import json
import re
import sys
from pathlib import Path

TU = Path(__file__).resolve().parent
MODUL = TU.parent
SZER = 4                                   # znaków na takt przy hscale = 1
WYSOKI, NISKI = "‾", "_"
ZEGAR = {"p": "/‾\\_", "P": "/‾\\_", "n": "\\_/‾", "N": "\\_/‾"}     # zbocze, poziom, zbocze, poziom
POZIOMY = {"0": 0, "l": 0, "L": 0, "1": 1, "h": 1, "H": 1}
DANE = set("=23456789")


class BladDiagramu(Exception):
    pass


def segmenty(fala):
    """Fala -> lista (znak, liczba taktów); '.' i '|' wydłużają poprzedni segment."""
    wynik = []
    for z in fala:
        if z in ".|":
            if not wynik:
                raise BladDiagramu(f"fala {fala!r} zaczyna się od '{z}'")
            wynik[-1][1] += 1
        elif z in ZEGAR or z in POZIOMY or z in DANE or z in "xz":
            wynik.append([z, 1])
        else:
            raise BladDiagramu(f"nieobsługiwany znak '{z}' w fali {fala!r}")
    return wynik


def rysuj_sygnal(sygnal, w):
    fala = sygnal.get("wave", "")
    dane = list(sygnal.get("data", []))
    if isinstance(sygnal.get("data"), str):
        dane = sygnal["data"].split()
    out, poprz = [], None
    for z, n in segmenty(fala):
        dl = n * w
        if z in ZEGAR:
            e1, p1, e2, p2 = ZEGAR[z]
            pol = w // 2
            okres = e1 + p1 * (pol - 1) + e2 + p2 * (w - pol - 1)
            out.append((okres * n)[:dl])
            poprz = "zegar"
        elif z in POZIOMY:
            poziom = POZIOMY[z]
            wypeln = WYSOKI if poziom else NISKI
            if poprz == ("poziom", poziom) or poprz is None:
                out.append(wypeln * dl)
            else:
                out.append(("/" if poziom else "\\") + wypeln * (dl - 1))
            poprz = ("poziom", poziom)
        elif z == "x":
            out.append(("x" if poprz in (None, "x") else "X") + "x" * (dl - 1))
            poprz = "x"
        elif z == "z":
            out.append("-" * dl)
            poprz = "z"
        else:
            if not dane:
                raise BladDiagramu(f"sygnał {sygnal.get('name')!r}: za mało etykiet w 'data'")
            etykieta = str(dane.pop(0))
            tresc = (" " + etykieta).ljust(dl - 1)[:dl - 1]
            out.append(("<" if poprz is None else "X") + tresc)
            poprz = "dane"
    if dane:
        raise BladDiagramu(f"sygnał {sygnal.get('name')!r}: nieużyte etykiety {dane}")
    return "".join(out)


def renderuj(diagram):
    hscale = int(diagram.get("config", {}).get("hscale", 1))
    w = SZER * hscale
    wiersze = []                                       # (nazwa, fala) albo (None, tekst)

    def zbierz(lista, wciecie):
        for e in lista:
            if isinstance(e, list):
                wiersze.append((None, " " * wciecie + f"[{e[0]}]"))
                zbierz(e[1:], wciecie + 2)
            elif isinstance(e, dict) and "wave" in e:
                wiersze.append((" " * wciecie + e.get("name", ""), rysuj_sygnal(e, w)))
            elif isinstance(e, dict):
                wiersze.append((None, ""))
            else:
                raise BladDiagramu(f"nieznany element {e!r}")

    zbierz(diagram["signal"], 0)
    szer_nazwy = max([len(n) for n, _ in wiersze if n is not None] + [4]) + 2
    takty = max([len(f) // w for n, f in wiersze if n is not None] + [0])
    linie = []
    glowa = diagram.get("head", {})
    if "text" in glowa:
        linie.append(glowa["text"])
    if "tick" in glowa:
        t0 = int(glowa["tick"])
        linie.append(" " * szer_nazwy + "".join(str(t0 + i).ljust(w) for i in range(takty)).rstrip())
    for n, f in wiersze:
        linie.append(f if n is None else n.ljust(szer_nazwy) + f)
    stopa = diagram.get("foot", {})
    if "text" in stopa:
        linie.append(stopa["text"])
    return "\n".join(l.rstrip() for l in linie) + "\n"


def wstawki_w_tematach():
    """Bloki tekstowe poprzedzone <!-- diagram: diagramy/x.txt --> w plikach tematów modułu."""
    for temat in sorted(MODUL.glob("*.md")):
        tekst = temat.read_text(encoding="utf-8")
        for m in re.finditer(r"<!-- diagram: (diagramy/[\w.-]+\.txt) -->\s*```text\n(.*?)```", tekst, re.S):
            yield temat.name, m.group(1), m.group(2)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("pliki", nargs="*", type=Path)
    ap.add_argument("--zapisz", action="store_true")
    ap.add_argument("--sprawdz", action="store_true")
    a = ap.parse_args()
    if a.pliki and not (a.zapisz or a.sprawdz):
        for p in a.pliki:
            print(renderuj(json.loads(p.read_text(encoding="utf-8"))), end="")
        return 0
    bledy = 0
    for zrodlo in a.pliki or sorted((MODUL / "diagramy").glob("*.json")):
        cel = zrodlo.with_suffix(".txt")
        try:
            tekst = renderuj(json.loads(zrodlo.read_text(encoding="utf-8")))
        except (BladDiagramu, KeyError, ValueError) as e:
            print(f"BŁĄD {zrodlo.name}: {e}")
            bledy += 1
            continue
        if a.zapisz:
            cel.write_text(tekst, encoding="utf-8")
            print(f"zapisano {cel.relative_to(MODUL)}")
        if a.sprawdz:
            zgodny = cel.exists() and cel.read_text(encoding="utf-8") == tekst
            print(f"{'OK ' if zgodny else 'NIEZGODNE'} {cel.relative_to(MODUL)}")
            bledy += 0 if zgodny else 1
    if a.sprawdz:
        n = 0
        for temat, sciezka, blok in wstawki_w_tematach():
            n += 1
            plik = MODUL / sciezka
            zgodny = plik.exists() and plik.read_text(encoding="utf-8") == blok
            print(f"{'OK ' if zgodny else 'NIEZGODNE'} wstawka {sciezka} w {temat}")
            bledy += 0 if zgodny else 1
        # nieobsługiwane konstrukcje muszą dawać błąd, nie cichy zły rysunek
        odrzucone = 0
        for zla in ({"signal": [{"name": "a", "wave": "0?1"}]},
                    {"signal": [{"name": "d", "wave": "x==", "data": ["A"]}]},
                    {"signal": [{"name": "d", "wave": "x=x", "data": ["A", "B"]}]},
                    {"signal": [{"name": "c", "wave": ".01"}]}):
            try:
                renderuj(zla)
                print(f"BŁĄD: przepuszczono {zla}")
                bledy += 1
            except BladDiagramu:
                odrzucone += 1
        print(f"wstawek w tematach: {n}; błędne diagramy odrzucone: {odrzucone}/4")
        print("PASS" if bledy == 0 else f"FAIL: {bledy} niezgodności")
    return 1 if bledy else 0


if __name__ == "__main__":
    sys.exit(main())
