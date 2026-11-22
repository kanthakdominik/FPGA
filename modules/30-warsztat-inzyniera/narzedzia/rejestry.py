#!/usr/bin/env python3
"""Generator mapy rejestrów z jednego opisu (30.01, 30.02): JSON -> pakiet VHDL, nagłówek Verilog, nagłówek C,
dokumentacja Markdown i opisy pól dla WaveDrom (typ "reg").

Jedno źródło prawdy zamiast czterech ręcznie pilnowanych kopii — ta sama idea co SystemRDL/PeakRDL
i IP-XACT, w kilkuset liniach biblioteki standardowej.

  python3 rejestry.py opis.json --zapisz     # generuje pliki do <katalog opisu>/wygenerowane/
  python3 rejestry.py --sprawdz              # wszystkie opisy z rejestry/: walidacja, porównanie
                                             # z plikami w repozytorium i zgodność z ręcznym pwm.h (moduł 27)
"""
import argparse
import json
import re
import sys
from pathlib import Path

TU = Path(__file__).resolve().parent
MODUL = TU.parent
REPO = MODUL.parent.parent
DOSTEPY = {"RW", "RO", "WO", "W1C"}
NAZWA = re.compile(r"^[A-Z][A-Z0-9_]*$")
NAGLOWEK = "WYGENEROWANE przez narzedzia/rejestry.py z {zrodlo} — nie edytuj ręcznie"


class BladOpisu(Exception):
    pass


def wczytaj(sciezka):
    with open(sciezka, encoding="utf-8") as f:
        opis = json.load(f)
    waliduj(opis)
    return opis


def waliduj(o):
    bledy = []
    w = o.get("szerokosc", 32)
    ab = o.get("bity_adresu")
    if not re.match(r"^[a-z][a-z0-9_]*$", o.get("nazwa", "")):
        bledy.append("nazwa bloku: małe litery, cyfry, _")
    if not isinstance(ab, int) or ab < 1:
        bledy.append("bity_adresu: liczba dodatnia")
    offsety, nazwy = {}, set()
    for r in o.get("rejestry", []):
        n = r.get("nazwa", "?")
        if not NAZWA.match(n):
            bledy.append(f"{n}: nazwa rejestru wielkimi literami")
        if n.lower() in nazwy:
            bledy.append(f"{n}: nazwa powtórzona (także bez rozróżniania wielkości liter — VHDL)")
        nazwy.add(n.lower())
        off = r.get("offset")
        if not isinstance(off, int) or off < 0 or (isinstance(ab, int) and off >= 2 ** ab):
            bledy.append(f"{n}: offset {off} poza zakresem 0..{2 ** ab - 1 if isinstance(ab, int) else '?'}")
        elif off in offsety:
            bledy.append(f"{n}: offset {off} zajęty przez {offsety[off]}")
        else:
            offsety[off] = n
        zajete = 0
        pola = r.get("pola", [])
        if not pola:
            bledy.append(f"{n}: brak pól")
        nazwy_pol = set()
        for p in pola:
            pn = p.get("nazwa", "?")
            if not NAZWA.match(pn):
                bledy.append(f"{n}.{pn}: nazwa pola wielkimi literami")
            if pn in nazwy_pol:
                bledy.append(f"{n}.{pn}: pole powtórzone")
            nazwy_pol.add(pn)
            msb, lsb = p.get("bity", [None, None])
            if not (isinstance(msb, int) and isinstance(lsb, int) and 0 <= lsb <= msb < w):
                bledy.append(f"{n}.{pn}: bity [{msb}:{lsb}] poza słowem {w}-bitowym")
                continue
            maska = ((1 << (msb - lsb + 1)) - 1) << lsb
            if zajete & maska:
                bledy.append(f"{n}.{pn}: bity [{msb}:{lsb}] nachodzą na inne pole")
            zajete |= maska
            if p.get("dostep") not in DOSTEPY:
                bledy.append(f"{n}.{pn}: dostęp {p.get('dostep')} spoza {sorted(DOSTEPY)}")
            rst = p.get("reset", 0)
            if not isinstance(rst, int) or rst < 0 or rst >= 2 ** (msb - lsb + 1):
                bledy.append(f"{n}.{pn}: reset {rst} nie mieści się w polu")
    if bledy:
        raise BladOpisu("\n".join(bledy))


def pola_z_wartosciami(o, r):
    """Dla każdego pola: (nazwa, msb, lsb, szerokość, maska, reset w słowie)."""
    wynik = []
    for p in r["pola"]:
        msb, lsb = p["bity"]
        szer = msb - lsb + 1
        maska = ((1 << szer) - 1) << lsb
        wynik.append((p, msb, lsb, szer, maska, p.get("reset", 0) << lsb))
    return wynik


def reset_rejestru(o, r):
    return sum(x[5] for x in pola_z_wartosciami(o, r))


def bajty(o):
    return o.get("szerokosc", 32) // 8


def gen_c(o, zrodlo):
    pre = o["nazwa"].upper()
    w = o.get("szerokosc", 32)
    hx = w // 4
    s = [f"/* {NAGLOWEK.format(zrodlo=zrodlo)}", f" * {o['opis']}, wersja opisu {o.get('wersja', '?')}.",
         " * _OFF — numer słowa (adresowanie słowami w komponencie), _BAJT — przesunięcie w bajtach od adresu",
         " * bazowego, _POZ — pozycja najmłodszego bitu pola, _MASKA — maska pola w słowie. */",
         f"#ifndef {pre}_REGS_H", f"#define {pre}_REGS_H", ""]
    for r in sorted(o["rejestry"], key=lambda x: x["offset"]):
        n = f"{pre}_{r['nazwa']}"
        s.append(f"/* {r['nazwa']} — {r['opis']} */")
        s.append(f"#define {n}_OFF {r['offset']}u")
        s.append(f"#define {n}_BAJT 0x{r['offset'] * bajty(o):X}u")
        s.append(f"#define {n}_RESET 0x{reset_rejestru(o, r):0{hx}X}u")
        for p, msb, lsb, szer, maska, _ in pola_z_wartosciami(o, r):
            if szer == w:
                continue
            s.append(f"#define {n}_{p['nazwa']}_POZ {lsb}u")
            s.append(f"#define {n}_{p['nazwa']}_MASKA 0x{maska:0{hx}X}u  /* {p['dostep']}: {p['opis']} */")
        s.append("")
    s.append(f"#endif /* {pre}_REGS_H */")
    return "\n".join(s) + "\n"


def gen_vh(o, zrodlo):
    pre = o["nazwa"].upper()
    w = o.get("szerokosc", 32)
    ab = o["bity_adresu"]
    s = [f"// {NAGLOWEK.format(zrodlo=zrodlo)}", f"// {o['opis']}, wersja opisu {o.get('wersja', '?')}.",
         "// Plik dołączany wewnątrz modułu: `include \"" + o["nazwa"] + "_regs.vh\" (stałe localparam).",
         "// Moduł zwykle używa części stałych — ostrzeżenie UNUSEDPARAM wyłączone tylko dla tego pliku.",
         "/* verilator lint_off UNUSEDPARAM */", ""]
    for r in sorted(o["rejestry"], key=lambda x: x["offset"]):
        n = f"{pre}_{r['nazwa']}"
        s.append(f"// {r['nazwa']} — {r['opis']}")
        s.append(f"localparam [{ab - 1}:0] {n}_OFF = {ab}'d{r['offset']};")
        s.append(f"localparam [{w - 1}:0] {n}_RESET = {w}'h{reset_rejestru(o, r):0{w // 4}X};")
        for p, msb, lsb, szer, maska, _ in pola_z_wartosciami(o, r):
            if szer == w:
                continue
            s.append(f"localparam integer {n}_{p['nazwa']}_POZ = {lsb};")
            s.append(f"localparam integer {n}_{p['nazwa']}_SZER = {szer};")
    s.append("/* verilator lint_on UNUSEDPARAM */")
    return "\n".join(s) + "\n"


def gen_vhd(o, zrodlo):
    pre = o["nazwa"].upper()
    w = o.get("szerokosc", 32)
    ab = o["bity_adresu"]
    pak = f"{o['nazwa']}_regs_pkg"
    s = [f"-- {NAGLOWEK.format(zrodlo=zrodlo)}", f"-- {o['opis']}, wersja opisu {o.get('wersja', '?')}.",
         "library ieee;", "use ieee.std_logic_1164.all;", "", f"package {pak} is",
         f"  constant {pre}_SZEROKOSC : natural := {w};", f"  constant {pre}_BITY_ADRESU : natural := {ab};"]
    for r in sorted(o["rejestry"], key=lambda x: x["offset"]):
        n = f"{pre}_{r['nazwa']}"
        s.append(f"  -- {r['nazwa']} — {r['opis']}")
        s.append(f"  constant {n}_OFF : natural := {r['offset']};")
        s.append(f"  constant {n}_RESET : std_logic_vector({w - 1} downto 0) := x\"{reset_rejestru(o, r):0{w // 4}X}\";")
        for p, msb, lsb, szer, maska, _ in pola_z_wartosciami(o, r):
            if szer == w:
                continue
            s.append(f"  constant {n}_{p['nazwa']}_POZ : natural := {lsb};")
            s.append(f"  constant {n}_{p['nazwa']}_SZER : natural := {szer};")
    s.append(f"end package {pak};")
    return "\n".join(s) + "\n"


def gen_md(o, zrodlo):
    w = o.get("szerokosc", 32)
    s = [f"# Mapa rejestrów `{o['nazwa']}`", "", f"> {NAGLOWEK.format(zrodlo=zrodlo)}.", "",
         f"{o['opis']}. Wersja opisu {o.get('wersja', '?')}, słowa {w}-bitowe, "
         f"{o['bity_adresu']} bity adresu (słowa), przesunięcia w bajtach dla procesora.", "",
         "| Słowo | Bajt | Rejestr | Bity | Pole | Dostęp | Reset | Opis |",
         "|------:|-----:|---------|------|------|--------|------:|------|"]
    for r in sorted(o["rejestry"], key=lambda x: x["offset"]):
        pierwszy = True
        for p, msb, lsb, szer, maska, rst in sorted(pola_z_wartosciami(o, r), key=lambda x: -x[1]):
            bity = f"{msb}" if msb == lsb else f"{msb}:{lsb}"
            kol = (f"{r['offset']} | 0x{r['offset'] * bajty(o):X} | {r['nazwa']}" if pierwszy else " |  | ")
            s.append(f"| {kol} | {bity} | {p['nazwa']} | {p['dostep']} | {p.get('reset', 0)} | {p['opis']} |")
            pierwszy = False
    s.append("")
    s.append("Bity niewymienione są zarezerwowane: zapis ignorowany, odczyt 0. "
             "W1C — zapis 1 kasuje bit, zapis 0 nic nie zmienia.")
    return "\n".join(s) + "\n"


def gen_wavedrom(o, zrodlo):
    """Opisy pól w formacie WaveDrom "reg" (bitfield) — jeden obiekt na rejestr."""
    w = o.get("szerokosc", 32)
    wynik = {"zrodlo": zrodlo, "uwaga": NAGLOWEK.format(zrodlo=zrodlo), "rejestry": {}}
    for r in sorted(o["rejestry"], key=lambda x: x["offset"]):
        reg, bit = [], 0
        for p, msb, lsb, szer, maska, _ in sorted(pola_z_wartosciami(o, r), key=lambda x: x[2]):
            if lsb > bit:
                reg.append({"bits": lsb - bit})
            reg.append({"name": p["nazwa"], "bits": szer, "attr": p["dostep"]})
            bit = msb + 1
        if bit < w:
            reg.append({"bits": w - bit})
        wynik["rejestry"][r["nazwa"]] = {"reg": reg, "config": {"bits": w, "lanes": 2 if w > 16 else 1}}
    return json.dumps(wynik, ensure_ascii=False, indent=2) + "\n"


GENERATORY = {
    "{n}_regs.h": gen_c,
    "{n}_regs.vh": gen_vh,
    "{n}_regs_pkg.vhd": gen_vhd,
    "{n}_regs.md": gen_md,
    "{n}_regs_wavedrom.json": gen_wavedrom,
}


def generuj(sciezka):
    o = wczytaj(sciezka)
    zrodlo = f"rejestry/{Path(sciezka).name}"
    return {szablon.format(n=o["nazwa"]): f(o, zrodlo) for szablon, f in GENERATORY.items()}, o


def zgodnosc_z_pwm_h(o):
    """Porównuje stałe z ręcznie napisanym sterownikiem modułu 27 — jedno źródło prawdy wykrywa rozjazd."""
    plik = REPO / "modules" / "27-procesory-i-soc" / "program" / "c" / "pwm.h"
    if o["nazwa"] != "pwm_avl" or not plik.exists():
        return []
    stale = dict(re.findall(r"^#define[ \t]+(PWM_\w+)[ \t]+(\S.*?)[ \t]*$", plik.read_text(encoding="utf-8"), re.M))

    def wartosc(t):
        t = t.strip()
        m = re.fullmatch(r"\(1u << (\d+)\)", t)
        if m:
            return 1 << int(m.group(1))
        return int(t.rstrip("u"), 0)

    rej = {r["nazwa"]: r for r in o["rejestry"]}
    bledy, sprawdzone = [], 0
    for nazwa, tekst in stale.items():
        czesci = nazwa.split("_")[1:]
        if len(czesci) == 1 and czesci[0] in rej:
            oczek = rej[czesci[0]]["offset"]
        elif len(czesci) == 2 and czesci[0] in rej:
            pole = [p for p in rej[czesci[0]]["pola"] if p["nazwa"] == czesci[1]]
            if not pole:
                bledy.append(f"pwm.h: {nazwa} — brak pola {czesci[1]} w opisie")
                continue
            msb, lsb = pole[0]["bity"]
            oczek = ((1 << (msb - lsb + 1)) - 1) << lsb
        else:
            continue
        sprawdzone += 1
        if wartosc(tekst) != oczek:
            bledy.append(f"pwm.h: {nazwa} = {tekst}, opis daje {oczek:#x}")
    return bledy if bledy else [f"OK  pwm.h (moduł 27): {sprawdzone} stałych zgodnych z opisem"]


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("opisy", nargs="*", type=Path)
    ap.add_argument("--zapisz", action="store_true", help="zapisz pliki do wygenerowane/")
    ap.add_argument("--sprawdz", action="store_true", help="porównaj z plikami w repozytorium")
    a = ap.parse_args()
    opisy = a.opisy or sorted((MODUL / "rejestry").glob("*.json"))
    niezgodne = 0
    for sciezka in opisy:
        try:
            pliki, o = generuj(sciezka)
        except BladOpisu as e:
            print(f"BŁĄD w {sciezka}:\n{e}")
            niezgodne += 1
            continue
        katalog = Path(sciezka).parent / "wygenerowane"
        print(f"{sciezka.name}: {len(o['rejestry'])} rejestry, "
              f"{sum(len(r['pola']) for r in o['rejestry'])} pól")
        for nazwa, tresc in pliki.items():
            cel = katalog / nazwa
            if a.zapisz:
                katalog.mkdir(exist_ok=True)
                cel.write_text(tresc, encoding="utf-8")
                print(f"  zapisano {cel.relative_to(MODUL)}")
            if a.sprawdz:
                if not cel.exists() or cel.read_text(encoding="utf-8") != tresc:
                    print(f"  NIEZGODNE {cel.relative_to(MODUL)} — uruchom z --zapisz i dodaj do commita")
                    niezgodne += 1
                else:
                    print(f"  OK  {cel.relative_to(MODUL)}")
        if a.sprawdz:
            for linia in zgodnosc_z_pwm_h(o):
                print(f"  {linia}")
                if not linia.startswith("OK"):
                    niezgodne += 1
    # walidator musi odrzucać błędne opisy — kilka celowo zepsutych wariantów
    if a.sprawdz:
        wzor = json.loads((MODUL / "rejestry" / "pwm_avl.json").read_text(encoding="utf-8"))
        przypadki = {
            "nachodzące pola": lambda o: o["rejestry"][0]["pola"][1].update(bity=[1, 0]),
            "powtórzony offset": lambda o: o["rejestry"][1].update(offset=0),
            "offset poza adresem": lambda o: o["rejestry"][3].update(offset=4),
            "reset za duży": lambda o: o["rejestry"][0]["pola"][0].update(reset=2),
            "nieznany dostęp": lambda o: o["rejestry"][3]["pola"][0].update(dostep="W0C"),
            "powtórzona nazwa rejestru": lambda o: o["rejestry"][2].update(nazwa="OKRES"),
        }
        odrzucone = 0
        for opis_przypadku, psuj in przypadki.items():
            o = json.loads(json.dumps(wzor))
            psuj(o)
            try:
                waliduj(o)
                print(f"  BŁĄD: walidator przepuścił: {opis_przypadku}")
                niezgodne += 1
            except BladOpisu:
                odrzucone += 1
        print(f"  walidator: {odrzucone}/{len(przypadki)} błędnych opisów odrzuconych")
    if a.sprawdz:
        print("PASS" if niezgodne == 0 else f"FAIL: {niezgodne} niezgodności")
    return 1 if niezgodne else 0


if __name__ == "__main__":
    sys.exit(main())
