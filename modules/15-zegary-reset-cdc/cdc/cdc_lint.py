#!/usr/bin/env python3
"""Strukturalna analiza przejść między domenami zegarowymi (CDC) na netliście Yosysa (15.07).

Działa jak uproszczona wersja narzędzi CDC (Questa CDC, SpyGlass CDC, Vivado report_cdc):
1. Yosys: read_verilog, hierarchy, proc, flatten, memory -nomap, opt_dff -> netlista JSON.
2. Każdy bit każdego przerzutnika dostaje domenę = nazwę sieci zegarowej (np. clk_a).
3. Dla każdego przerzutnika szukamy wstecz (przez logikę kombinacyjną) przerzutników i portów, z których
   pochodzą jego dane (D) i zezwolenie (EN). Źródło z innej domeny = przejście (crossing).
4. Klasyfikacja przejścia:
     SYNC                    — D wprost z innej domeny, bez logiki, wyjście idzie tylko do drugiego
                               przerzutnika tej samej domeny (synchronizator >= 2 stopnie)
     DANE_POD_KONTROLA       — dane z innej domeny, ale przerzutnik ma zezwolenie sterowane wyłącznie
                               z własnej domeny (handshake, FIFO, MCP) — poprawne, jeśli protokół
                               gwarantuje stabilność danych; wymaga ograniczenia w SDC
     BRAK_DRUGIEGO_STOPNIA   — błąd: jeden przerzutnik, wyjście od razu do logiki
     METASTABILNE_DO_LOGIKI  — błąd: pierwszy stopień synchronizatora zasila też logikę
     LOGIKA_PRZED_SYNC       — błąd: logika kombinacyjna przed pierwszym przerzutnikiem synchronizatora
     BRAK_SYNCHRONIZACJI     — błąd: dane z innej domeny wchodzą do logiki/rejestru bez synchronizacji
   oraz dla grup bitów:
     WIELOBITOWE_GRAY        — kilka bitów jednego rejestru synchronizowanych osobno, rejestr w kodzie Graya
                               (nazwa zawiera "gray") — poprawne
     WIELOBITOWE_BEZ_GRAYA   — błąd: kilka bitów jednego rejestru synchronizowanych osobno
                               (np. licznik binarny) — możliwe wartości, których nigdy nie było
Porty wejściowe: domena z przyrostka nazwy (--porty _a=clk_a,_b=clk_b); pozostałe — asynchroniczne.

Użycie:  python3 cdc_lint.py TOP plik.v [plik.v ...] [--porty _a=clk_a,_b=clk_b] [--json wynik.json]
Kod wyjścia 1, gdy są błędy.
"""
import argparse
import json
import re
import subprocess
import sys
import tempfile
from collections import defaultdict
from pathlib import Path

BLEDY = {"BRAK_DRUGIEGO_STOPNIA", "METASTABILNE_DO_LOGIKI", "LOGIKA_PRZED_SYNC", "BRAK_SYNCHRONIZACJI",
         "WIELOBITOWE_BEZ_GRAYA"}
ASYNC = "asynchroniczne"


def netlista(top, pliki):
    with tempfile.TemporaryDirectory() as tmp:
        js = Path(tmp) / "net.json"
        skrypt = (f"read_verilog -sv {' '.join(str(p) for p in pliki)}; hierarchy -top {top}; proc; flatten; "
                  f"opt_clean; memory -nomap; opt_dff; opt_clean; write_json {js}")
        p = subprocess.run(["yosys", "-q", "-p", skrypt], capture_output=True, text=True)
        if p.returncode != 0:
            sys.exit(p.stdout + p.stderr)
        return json.loads(js.read_text())["modules"][top]


class Analiza:
    def __init__(self, mod, porty):
        self.mod = mod
        self.nazwa = {}                                   # bit -> czytelna nazwa (rejestr[i])
        for n, d in sorted(mod["netnames"].items(), key=lambda x: (x[0].startswith("$"), x[0].count("."), len(x[0]))):
            szer = len(d["bits"])
            for i, b in enumerate(d["bits"]):
                if isinstance(b, int) and b not in self.nazwa:
                    self.nazwa[b] = n if szer == 1 else f"{n}[{i + d.get('offset', 0)}]"
        self.wejscia = {}                                 # bit -> domena portu wejściowego
        for n, d in mod["ports"].items():
            if d["direction"] != "output":
                dom = ASYNC
                for przyr, zegar in porty.items():
                    if n.endswith(przyr) or n == zegar:
                        dom = zegar
                for b in d["bits"]:
                    if isinstance(b, int):
                        self.wejscia[b] = dom
        self.sterownik = {}                               # bit -> (komórka, port)
        self.odbiorcy = defaultdict(list)                 # bit -> [(komórka, port)]
        self.przerzutniki = {}                            # bit Q -> dict(D, EN, CLK, komórka)
        self.pamieci = {}                                 # bit RD_DATA -> (domena zapisu, bity adresu)
        for cn, c in mod["cells"].items():
            for port, kier in c.get("port_directions", {}).items():
                for b in c["connections"].get(port, []):
                    if not isinstance(b, int):
                        continue
                    if kier == "output":
                        self.sterownik[b] = (cn, port)
                    else:
                        self.odbiorcy[b].append((cn, port))
            typ = c["type"]
            if typ in ("$dff", "$dffe", "$adff", "$adffe", "$sdff", "$sdffe", "$sdffce", "$aldff", "$aldffe",
                       "$dffsr", "$dffsre"):
                con = c["connections"]
                for i, q in enumerate(con["Q"]):
                    self.przerzutniki[q] = {"D": con["D"][i], "EN": con.get("EN", [None])[0],
                                            "CLK": con["CLK"][0], "SRST": con.get("SRST", [None])[0],
                                            "ARST": con.get("ARST", [None])[0], "komorka": cn}
            elif typ == "$mem_v2":
                con, par = c["connections"], c["parameters"]
                wr_clk = con["WR_CLK"][0] if con.get("WR_CLK") else None
                adres = [b for b in con.get("RD_ADDR", []) if isinstance(b, int)]
                for b in con["RD_DATA"]:
                    self.pamieci[b] = (wr_clk, adres, int(str(par.get("RD_CLK_ENABLE", "0")), 2) != 0)
        self.domena_zegara = {}

    def domena(self, bit_clk):
        """Kanoniczna nazwa zegara: nazwa sieci (najkrótsza, bez hierarchii)."""
        return self.nazwa.get(bit_clk, str(bit_clk))

    def zrodla(self, bit, _pamiec=None):
        """Źródła sekwencyjne bitu: {(rodzaj, bit_źródła): ('bez_logiki' | 'przez_logike')}."""
        if _pamiec is None:
            _pamiec = {}
        if not isinstance(bit, int):
            return {}
        if bit in _pamiec:
            return _pamiec[bit]
        _pamiec[bit] = {}
        wynik = {}
        if bit in self.przerzutniki:
            wynik[("ff", bit)] = "bez_logiki"
        elif bit in self.wejscia:
            wynik[("we", bit)] = "bez_logiki"
        elif bit in self.pamieci:
            wynik[("mem", bit)] = "przez_logike"
            for a in self.pamieci[bit][1]:
                for z in self.zrodla(a, _pamiec):
                    wynik[z] = "przez_logike"
        elif bit in self.sterownik:
            cn, port_wy = self.sterownik[bit]
            c = self.mod["cells"][cn]
            for b in self.wejscia_bitu(c, port_wy, bit):
                for z in self.zrodla(b, _pamiec):
                    wynik[z] = "przez_logike"
        _pamiec[bit] = wynik
        return wynik

    BITOWE = {"$not", "$and", "$or", "$xor", "$xnor", "$pos", "$buf", "$mux", "$bwmux"}

    def wejscia_bitu(self, c, port_wy, bit):
        """Bity wejściowe, od których zależy bit wyjścia: w bramkach bitowych tylko ten sam indeks
        (i wybór multipleksera), w pozostałych komórkach (sumatory, porównania) — wszystkie wejścia."""
        con = c["connections"]
        if c["type"] in self.BITOWE and port_wy == "Y":
            i = con["Y"].index(bit)
            wyn = [con[p][i] for p in ("A", "B") if p in con and len(con[p]) == len(con["Y"])]
            wyn += con.get("S", []) if c["type"] == "$mux" else []
            wyn += [con["S"][i]] if c["type"] == "$bwmux" else []
            if wyn:
                return wyn
        return [b for p, k in c["port_directions"].items() if k == "input" for b in con[p]]

    def domena_zrodla(self, z):
        rodzaj, b = z
        if rodzaj == "ff":
            return self.domena(self.przerzutniki[b]["CLK"])
        if rodzaj == "we":
            return self.wejscia[b]
        return self.domena(self.pamieci[b][0]) if self.pamieci[b][0] is not None else ASYNC

    def drugi_stopien(self, q, dom):
        """Przerzutniki tej samej domeny, których D jest wprost wyjściem q; czy q idzie gdzieś jeszcze."""
        nastepne, inne = [], False
        for cn, port in self.odbiorcy.get(q, []):
            c = self.mod["cells"][cn]
            if port == "D" and "Q" in c["connections"]:
                d_bity = c["connections"]["D"]
                q2_lista = [c["connections"]["Q"][i] for i, b in enumerate(d_bity) if b == q]
                q2_lista = [x for x in q2_lista if x in self.przerzutniki]
                if q2_lista and all(self.domena(self.przerzutniki[x]["CLK"]) == dom for x in q2_lista):
                    nastepne.extend(q2_lista)
                    continue
            inne = True
        return nastepne, inne

    def analizuj(self):
        wyniki = []                                       # (klasa, cel, źródła, opis)
        sync_grupy = defaultdict(list)                    # (rejestr źródła, rejestr celu) -> bity
        pamiec = {}
        for q, ff in sorted(self.przerzutniki.items()):
            dom = self.domena(ff["CLK"])
            zr_d = self.zrodla(ff["D"], pamiec)
            en = ff["EN"]
            en_zr = self.zrodla(en, pamiec) if isinstance(en, int) else {}
            sr_zr = self.zrodla(ff["SRST"], pamiec) if isinstance(ff["SRST"], int) else {}
            wszystkie = {**zr_d, **en_zr, **sr_zr}
            obce = {z: s for z, s in wszystkie.items() if self.domena_zrodla(z) != dom}
            if not obce:
                continue
            cel = self.nazwa.get(q, str(q))
            nazwy_zr = sorted(f"{self.nazwa.get(z[1], z[1])} ({self.domena_zrodla(z)})" for z in obce)
            # odczyt pamięci kolejki: dane chronione protokołem wskaźników (Gray + flagi pełna/pusta)
            if all(z[0] == "mem" for z in obce):
                wyniki.append(("DANE_POD_KONTROLA", cel, nazwy_zr, "odczyt pamięci FIFO"))
                continue
            # zezwolenie wyłącznie z własnej domeny?
            if en_zr and all(self.domena_zrodla(z) == dom for z in en_zr):
                wyniki.append(("DANE_POD_KONTROLA", cel, nazwy_zr, f"zezwolenie z domeny {dom}"))
                continue
            obce = {z: s for z, s in zr_d.items() if self.domena_zrodla(z) != dom} or obce
            nastepne, inne = self.drugi_stopien(q, dom)
            bez_logiki = len(obce) == 1 and list(obce.values())[0] == "bez_logiki" and len(zr_d) == 1
            if bez_logiki and nastepne and not inne:
                # długość łańcucha
                n, b = 1, q
                while True:
                    nast, _ = self.drugi_stopien(b, dom)
                    if len(nast) != 1:
                        break
                    n, b = n + 1, nast[0]
                zrodlo = list(obce)[0]
                rej_zr = re.sub(r"\[\d+\]$", "", self.nazwa.get(zrodlo[1], ""))
                rej_cel = re.sub(r"\[\d+\]$", "", cel)
                sync_grupy[(rej_zr, rej_cel)].append(cel)
                wyniki.append(("SYNC", cel, nazwy_zr, f"{n} stopnie w {dom}"))
            elif bez_logiki and nastepne and inne:
                wyniki.append(("METASTABILNE_DO_LOGIKI", cel, nazwy_zr, "pierwszy stopień zasila też logikę"))
            elif bez_logiki:
                wyniki.append(("BRAK_DRUGIEGO_STOPNIA", cel, nazwy_zr, "jeden przerzutnik"))
            elif nastepne:
                wyniki.append(("LOGIKA_PRZED_SYNC", cel, nazwy_zr, "logika przed synchronizatorem"))
            else:
                wyniki.append(("BRAK_SYNCHRONIZACJI", cel, nazwy_zr, "dane bez synchronizacji i bez zezwolenia"))
        for (rej_zr, rej_cel), bity in sorted(sync_grupy.items()):
            if len(bity) > 1:
                klasa = "WIELOBITOWE_GRAY" if "gray" in rej_zr.lower() else "WIELOBITOWE_BEZ_GRAYA"
                wyniki.append((klasa, rej_cel, [rej_zr], f"{len(bity)} bitów synchronizowanych osobno"))
        return wyniki


def main():
    p = argparse.ArgumentParser()
    p.add_argument("top")
    p.add_argument("pliki", nargs="+")
    p.add_argument("--porty", default="", help="przyrostek=zegar,… np. _a=clk_a,_b=clk_b")
    p.add_argument("--json", help="zapis podsumowania")
    a = p.parse_args()
    porty = dict(x.split("=") for x in a.porty.split(",") if x)
    an = Analiza(netlista(a.top, a.pliki), porty)
    wyniki = an.analizuj()
    domeny = sorted({an.domena(ff["CLK"]) for ff in an.przerzutniki.values()})
    print(f"== {a.top}: {len(an.przerzutniki)} bitów przerzutników, domeny zegarowe: {', '.join(domeny)}")
    licz = defaultdict(int)
    for klasa, cel, zr, opis in wyniki:
        licz[klasa] += 1
        znak = "BLAD" if klasa in BLEDY else "ok  "
        print(f"  {znak} {klasa:24s} {cel:28s} <- {', '.join(zr)[:70]}  ({opis})")
    bledy = sum(v for k, v in licz.items() if k in BLEDY)
    print(f"  podsumowanie: " + ", ".join(f"{k} {v}" for k, v in sorted(licz.items())) + f"; bledow: {bledy}")
    if a.json:
        Path(a.json).write_text(json.dumps(dict(licz), indent=1, sort_keys=True))
    return 1 if bledy else 0


if __name__ == "__main__":
    sys.exit(main())
