#!/usr/bin/env python3
"""Sprawdza linki względne w plikach .md: czy plik docelowy istnieje i czy istnieje kotwica (#nagłówek)."""
import re
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LINK = re.compile(r"(?<!!)\[[^\]]*\]\(([^)\s]+)\)|!\[[^\]]*\]\(([^)\s]+)\)")
NAGLOWEK = re.compile(r"^#{1,6}\s+(.*)$")
KOD = re.compile(r"```.*?```", re.S)


def kotwica(tekst):
    """Kotwica nagłówka w stylu GitHuba."""
    t = tekst.strip().lower()
    t = re.sub(r"[`*_]", "", t)
    t = "".join(c for c in t if c.isalnum() or c in " -" or unicodedata.category(c) == "Mn")
    return t.replace(" ", "-")


def kotwice(plik, cache={}):
    if plik not in cache:
        tekst = KOD.sub("", plik.read_text(encoding="utf-8"))
        cache[plik] = {kotwica(m.group(1)) for l in tekst.splitlines() if (m := NAGLOWEK.match(l))}
    return cache[plik]


def main():
    bledy = 0
    for md in sorted(ROOT.rglob("*.md")):
        if any(p.startswith(".") for p in md.relative_to(ROOT).parts):
            continue
        tekst = KOD.sub("", md.read_text(encoding="utf-8"))
        tekst = re.sub(r"`[^`\n]*`", "", tekst)
        for m in LINK.finditer(tekst):
            cel = m.group(1) or m.group(2)
            if re.match(r"^[a-z]+:", cel) or cel.startswith("//"):
                continue
            sciezka, _, kotw = cel.partition("#")
            docel = (md.parent / sciezka).resolve() if sciezka else md
            if not docel.exists():
                print(f"{md.relative_to(ROOT)}: brak pliku {cel}")
                bledy += 1
            elif kotw and docel.suffix == ".md" and kotw not in kotwice(docel):
                print(f"{md.relative_to(ROOT)}: brak kotwicy {cel}")
                bledy += 1
    print(f"Błędnych linków: {bledy}")
    return 1 if bledy else 0


if __name__ == "__main__":
    sys.exit(main())
