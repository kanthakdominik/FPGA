#!/usr/bin/env python3
"""Zbiera z tematów modułów sekcje do plików zbiorczych.

- "## Reguły i liczby do zapamiętania" → modules/<moduł>/SCIAGA.md
- "## Pytania rekrutacyjne"             → rozmowa-kwalifikacyjna/pytania.md (sekcja modułu)

Uruchamiaj po wypełnieniu tematów: python3 tools/zbierz.py
Tematy w stanie szkieletu (pusta sekcja) są pomijane.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MODULY = sorted(p for p in (ROOT / "modules").iterdir() if p.is_dir())


def sekcja(tekst, naglowek):
    m = re.search(rf"^## {re.escape(naglowek)}\s*\n(.*?)(?=^## |\Z)", tekst, re.S | re.M)
    return m.group(1).strip() if m else ""


def tematy(modul):
    for plik in sorted(modul.glob("[0-9][0-9].[0-9][0-9]-*.md")):
        tekst = plik.read_text(encoding="utf-8")
        tytul = tekst.splitlines()[0].lstrip("# ").strip()
        yield plik, tytul, tekst


def sciagi():
    for modul in MODULY:
        readme = (modul / "README.md").read_text(encoding="utf-8").splitlines()[0].lstrip("# ").strip()
        czesci = [f"# Ściąga — {readme}", "", "[← moduł](README.md)", "",
                  "Reguły i liczby do zapamiętania ze wszystkich tematów modułu "
                  "(generowane przez `tools/zbierz.py` z sekcji tematów).", ""]
        for plik, tytul, tekst in tematy(modul):
            czesci += [f"## [{tytul}]({plik.name})", ""]
            tresc = sekcja(tekst, "Reguły i liczby do zapamiętania")
            czesci += [tresc if tresc else "_Temat jeszcze bez treści._", ""]
        (modul / "SCIAGA.md").write_text("\n".join(czesci).rstrip() + "\n", encoding="utf-8")


def pytania():
    wyjscie = ROOT / "rozmowa-kwalifikacyjna" / "pytania.md"
    czesci = ["# Pytania rekrutacyjne", "", "[← rozmowa kwalifikacyjna](README.md)", "",
              "Pytania ze wszystkich tematów, ułożone według modułów, z wzorcowymi odpowiedziami pod `<details>`. "
              "Generowane przez `tools/zbierz.py` z sekcji „Pytania rekrutacyjne” tematów — "
              "nie edytuj tego pliku ręcznie, zmieniaj pytania w tematach.", ""]
    for modul in MODULY:
        readme = (modul / "README.md").read_text(encoding="utf-8").splitlines()[0].lstrip("# ").strip()
        czesci += [f"## {readme}", ""]
        jest = False
        for plik, tytul, tekst in tematy(modul):
            tresc = sekcja(tekst, "Pytania rekrutacyjne")
            if not tresc:
                continue
            jest = True
            rel = f"../modules/{modul.name}/{plik.name}"
            tresc = re.sub(r"\]\((?!https?:|#|/)([^)]+)\)",
                           lambda m: f"]({(Path('../modules') / modul.name / m.group(1)).as_posix()})", tresc)
            tresc = re.sub(r"\(\.\./modules/[^/]+/\.\./\.\./", "(../", tresc)
            tresc = re.sub(r"\(\.\./modules/[^/]+/\.\./", "(../modules/", tresc)
            czesci += [f"### [{tytul}]({rel})", "", tresc, ""]
        if not jest:
            czesci += [f"_Pytania pojawią się razem z treścią modułu ([{modul.name}](../modules/{modul.name}/README.md))._", ""]
    wyjscie.write_text("\n".join(czesci).rstrip() + "\n", encoding="utf-8")


if __name__ == "__main__":
    sciagi()
    pytania()
    print("Zaktualizowano ściągi modułów i rozmowa-kwalifikacyjna/pytania.md")
