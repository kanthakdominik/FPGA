#!/usr/bin/env python3
"""Przygotowuje stronę GitHub Pages (MkDocs Material) z plików .md repozytorium.

Pliki źródłowe się nie zmieniają. Skrypt kopiuje je do _site/src, zamienia README.md na index.md,
poprawia odnośniki (katalogi → index.md, pliki spoza strony → GitHub), włącza Markdown wewnątrz <details>,
rozwija znaczniki kodu i zapisuje _site/mkdocs.yml z menu ułożonym jak mapa modułów w README.

Znaczniki kodu w plikach .md (na GitHubie niewidoczne — tam zostaje zwykły odnośnik pod znacznikiem):
    <!-- plik: hdl/vhdl/blink.vhd -->                       → zwijany blok z całym plikiem
    <!-- zakladki: a.vhd | a.v | a.sv -->                    → zakładki VHDL / Verilog / SystemVerilog
Ścieżki są względne do pliku .md.

Użycie: python3 tools/build_site.py && mkdocs build --strict -f _site/mkdocs.yml
"""
import glob
import os
import re
import shutil

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "_site")
SRC = os.path.join(OUT, "src")
REPO = "https://github.com/kanthakdominik/FPGA"
LINK = re.compile(r"(\]\()([^)\s]+)(\))")
ZNACZNIK = re.compile(r"^<!-- (plik|zakladki): (.+?) -->$", re.M)

PLIKI_GLOWNE = ["README.md", "ROADMAP.md", "RESOURCES.md", "NARZEDZIA.md", "SLOWNICZEK.md", "LICENSE.md",
                "docs/SZABLON-TEMATU.md", "docs/STYL-KODU.md"]
STATYCZNE = {"assets": (".svg", ".png", ".jpg", ".jpeg", ".gif", ".webp")}
JEZYKI = {".vhd": ("vhdl", "VHDL"), ".vhdl": ("vhdl", "VHDL"), ".v": ("verilog", "Verilog"),
          ".sv": ("systemverilog", "SystemVerilog"), ".svh": ("systemverilog", "SystemVerilog"),
          ".tcl": ("tcl", "Tcl"), ".sdc": ("tcl", "SDC"), ".py": ("python", "Python"),
          ".c": ("c", "C"), ".h": ("c", "C"), ".mk": ("make", "Makefile")}


def cel_strony(sciezka_repo):
    """Ścieżka pliku w repozytorium → ścieżka na stronie (README.md → index.md)."""
    katalog, nazwa = os.path.split(sciezka_repo)
    return os.path.join(katalog, "index.md") if nazwa == "README.md" else sciezka_repo


def statyczny(rel_repo):
    gora = rel_repo.split(os.sep, 1)[0]
    return gora in STATYCZNE and rel_repo.lower().endswith(STATYCZNE[gora])


def popraw_link(cel, plik_repo):
    if cel.startswith(("http://", "https://", "mailto:", "#")):
        return cel
    sciezka, _, kotwica = cel.partition("#")
    kotwica = "#" + kotwica if kotwica else ""
    katalog = os.path.dirname(plik_repo)
    pelna = os.path.normpath(os.path.join(ROOT, katalog, sciezka))
    rel_repo = os.path.relpath(pelna, ROOT)
    if os.path.isfile(pelna) and statyczny(rel_repo):
        return os.path.relpath(rel_repo, katalog) + kotwica
    if os.path.isdir(pelna) and os.path.exists(os.path.join(pelna, "README.md")):
        rel_repo = os.path.join(rel_repo, "README.md")
    if rel_repo.endswith(".md") and STRONY and rel_repo not in STRONY:   # .md spoza strony, np. deca/*/README.md
        if os.path.isdir(pelna):
            return f"{REPO}/tree/main/{os.path.relpath(pelna, ROOT)}{kotwica}"
        return f"{REPO}/blob/main/{rel_repo}{kotwica}"
    elif not rel_repo.endswith(".md") or not os.path.exists(pelna):
        rodzaj = "tree" if os.path.isdir(pelna) else "blob"
        return f"{REPO}/{rodzaj}/main/{rel_repo}{kotwica}"       # kod HDL, skrypty, konfiguracja → GitHub
    nowy = os.path.relpath(cel_strony(rel_repo), os.path.dirname(cel_strony(plik_repo)))
    return nowy + kotwica


STRONY = set()                                                     # pliki .md kopiowane na stronę

LISTA = re.compile(r"^( *)([-*+]|\d+[.)]) +")


def dostosuj_markdown(tekst):
    """Różnice między Markdownem GitHuba a Python-Markdown (MkDocs): listy, tabele i bloki $$ muszą być
    oddzielone pustą linią od akapitu, a listy zagnieżdżone wymagają wcięcia o 4 spacje."""
    wynik, w_kodzie, w_wzorze = [], False, False
    for linia in tekst.split("\n"):
        poprz = wynik[-1] if wynik else ""
        if linia.lstrip().startswith("```"):
            w_kodzie = not w_kodzie
            wynik.append(linia)
            continue
        if w_kodzie:
            wynik.append(linia)
            continue
        m = LISTA.match(linia)
        if m and 0 < len(m.group(1)) < 4 and LISTA.match(poprz):
            linia = "    " + linia.lstrip()
            m = LISTA.match(linia)
        pusta_przed = poprz.strip() != "" and not poprz.lstrip().startswith(">")
        if m and pusta_przed and not LISTA.match(poprz) and not poprz.startswith("    ") and not poprz.lstrip().startswith("<"):
            wynik.append("")
        elif linia.startswith("|") and pusta_przed and not poprz.startswith("|"):
            wynik.append("")
        elif linia.strip().startswith("$$"):
            if not w_wzorze and pusta_przed:
                wynik.append("")
            jedna = linia.strip() != "$$" and linia.strip().endswith("$$") and len(linia.strip()) > 4
            if not jedna:
                w_wzorze = not w_wzorze
        elif poprz.strip().endswith("$$") and not w_wzorze and linia.strip() and poprz.strip() != "":
            wynik.append("")
        wynik.append(linia)
    return "\n".join(wynik)


def blok_kodu(sciezka_repo, wciecie):
    rozsz = os.path.splitext(sciezka_repo)[1].lower()
    lexer = JEZYKI.get(rozsz, ("text", rozsz))[0]
    kod = open(os.path.join(ROOT, sciezka_repo), encoding="utf-8").read().rstrip("\n")
    pre = " " * wciecie
    return [f"{pre}```{lexer}", *[(pre + l) if l else "" for l in kod.split("\n")], f"{pre}```"]


def rozwin_znaczniki(tekst, plik_repo):
    katalog = os.path.dirname(plik_repo)

    def zamien(m):
        rodzaj, sciezki = m.group(1), [s.strip() for s in m.group(2).split("|")]
        pliki = [os.path.normpath(os.path.join(katalog, s)) for s in sciezki]
        for p in pliki:
            if not os.path.isfile(os.path.join(ROOT, p)):
                raise SystemExit(f"{plik_repo}: znacznik {rodzaj} wskazuje nieistniejący plik {p}")
        linie = [""]
        if rodzaj == "plik":
            p = pliki[0]
            linie += [f'??? example "Pełny plik: {os.path.basename(p)}"', ""] + blok_kodu(p, 4)
        else:
            for p in pliki:
                rozsz = os.path.splitext(p)[1].lower()
                nazwa = JEZYKI.get(rozsz, ("", os.path.basename(p)))[1]
                linie += [f'=== "{nazwa}"', ""] + blok_kodu(p, 4) + [""]
        return "\n".join(linie + [""])

    # znaczniki tylko poza blokami kodu (przykłady w dokumentacji zostają bez zmian)
    czesci = re.split(r"(^```.*?^```[^\n]*$)", tekst, flags=re.S | re.M)
    return "".join(c if c.startswith("```") else ZNACZNIK.sub(zamien, c) for c in czesci)


def kopiuj(plik_repo):
    tekst = open(os.path.join(ROOT, plik_repo), encoding="utf-8").read()
    tekst = LINK.sub(lambda m: m.group(1) + popraw_link(m.group(2), plik_repo) + m.group(3), tekst)
    tekst = re.sub(r"(?<!`)<details>", '<details markdown="1">', dostosuj_markdown(tekst))
    tekst = rozwin_znaczniki(tekst, plik_repo)
    cel = os.path.join(SRC, cel_strony(plik_repo))
    os.makedirs(os.path.dirname(cel), exist_ok=True)
    open(cel, "w", encoding="utf-8").write(tekst)


def tytul(plik_repo):
    pierwsza = open(os.path.join(ROOT, plik_repo), encoding="utf-8").readline().lstrip("# ").strip()
    return pierwsza.replace('"', "'")


def czesci_modulow():
    """Części z mapy modułów w README: [(nazwa części, [katalogi modułów])]."""
    readme = open(os.path.join(ROOT, "README.md"), encoding="utf-8").read()
    mapa = readme.split("<!-- mapa:start -->", 1)[1].split("<!-- mapa:stop -->", 1)[0]
    wynik = []
    for blok in re.split(r"^### ", mapa, flags=re.M)[1:]:
        nazwa = blok.splitlines()[0].strip()
        moduly = re.findall(r"\]\((modules/[^/)]+)/README\.md\)", blok)
        if moduly:
            wynik.append((nazwa, moduly))
    return wynik


def glob_md(wzor):
    return sorted(glob.glob(wzor, root_dir=ROOT))


def pozycje(lista, wciecie):
    return [f'{" " * wciecie}- "{t}": {p}' for t, p in lista if os.path.exists(os.path.join(SRC, p))]


def main():
    shutil.rmtree(OUT, ignore_errors=True)
    pliki = (PLIKI_GLOWNE + glob_md("plytka-deca/*.md") + glob_md("rozmowa-kwalifikacyjna/*.md")
             + glob_md("modules/*/*.md"))
    pliki = [p for p in dict.fromkeys(pliki) if os.path.exists(os.path.join(ROOT, p))]
    STRONY.update(pliki)
    for p in pliki:
        kopiuj(p)

    for katalog, rozszerzenia in STATYCZNE.items():
        for f in glob.glob(f"{katalog}/**/*", root_dir=ROOT, recursive=True):
            if f.lower().endswith(rozszerzenia):
                os.makedirs(os.path.dirname(os.path.join(SRC, f)), exist_ok=True)
                shutil.copy(os.path.join(ROOT, f), os.path.join(SRC, f))

    nav = ["nav:", "  - Start: index.md", "  - Roadmapa: ROADMAP.md", "  - Kurs:"]
    for nazwa, moduly in czesci_modulow():
        nav.append(f'    - "{nazwa.replace(chr(34), chr(39))}":')
        for d in moduly:
            nav.append(f'      - "{tytul(d + "/README.md")}":')
            nav.append(f"        - {d}/index.md")
            for t in glob_md(f"{d}/[0-9][0-9].[0-9][0-9]-*.md"):
                nav.append(f'        - "{tytul(t)}": {t}')
            if os.path.exists(os.path.join(ROOT, d, "SCIAGA.md")):
                nav.append(f'        - "Ściąga": {d}/SCIAGA.md')
    nav += ["  - Płytka DECA:", "    - plytka-deca/index.md"]
    nav += pozycje([("Piny", "plytka-deca/piny.md"), ("Materiały o DECA", "plytka-deca/zrodla.md")], 4)
    nav += ["  - Rozmowa kwalifikacyjna:", "    - rozmowa-kwalifikacyjna/index.md"]
    nav += pozycje([("Pytania", "rozmowa-kwalifikacyjna/pytania.md"),
                    ("Zadania projektowe", "rozmowa-kwalifikacyjna/zadania-projektowe.md"),
                    ("Pułapki", "rozmowa-kwalifikacyjna/pulapki.md")], 4)
    nav += ["  - Materiały:"]
    nav += pozycje([("Źródła", "RESOURCES.md"), ("Narzędzia", "NARZEDZIA.md"), ("Słowniczek", "SLOWNICZEK.md"),
                    ("Styl kodu", "docs/STYL-KODU.md"), ("Szablon tematu", "docs/SZABLON-TEMATU.md"),
                    ("Licencja", "LICENSE.md")], 4)

    os.makedirs(os.path.join(SRC, "javascripts"), exist_ok=True)
    for f in ("mathjax.js", "extra.css"):
        shutil.copy(os.path.join(ROOT, "tools", "site", f), os.path.join(SRC, "javascripts", f))
    konfig = open(os.path.join(ROOT, "tools", "site", "mkdocs.base.yml"), encoding="utf-8").read()
    open(os.path.join(OUT, "mkdocs.yml"), "w", encoding="utf-8").write(konfig.rstrip() + "\n\n" + "\n".join(nav) + "\n")
    print(f"stron: {len(pliki)}, katalog: {SRC}")


if __name__ == "__main__":
    main()
