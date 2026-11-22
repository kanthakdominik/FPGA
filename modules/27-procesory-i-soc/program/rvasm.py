#!/usr/bin/env python3
"""Asembler i symulator zestawu instrukcji RV32I dla modułu 27 (27.07) — bez zewnętrznych narzędzi.

Asembler (dwa przebiegi) rozumie wszystkie instrukcje RV32I, popularne pseudoinstrukcje (li, la, mv, j, jr,
call, ret, nop, not, neg, beqz, bnez, bgt, ble, bgtu, bleu, seqz, snez) i dyrektywy .org, .word, .asciz,
.align, .equ. Symulator (ISS) wykonuje program instrukcja po instrukcji i zapisuje ślad zapisów do pamięci —
wzorzec, z którym testbenche porównują rdzenie rv_jedno i rv_potok (k-ty zapis z k-tym, niezależnie od
liczby taktów).

Mapa pamięci (jak rv_soc):
  0x0000_0000  RAM (program i dane)
  0x1000_0000  LED (zapis) / wejścia (odczyt)       0x1000_0004  licznik taktów (odczyt)
  0x1000_0008  TOHOST — zapis kończy symulację      0x1000_000C  KONSOLA — zapis znaku
  0x1000_0010  licznik instrukcji (odczyt)          0x1000_0100  pwm_avl (STER, OKRES, WYPELN, STATUS)

Użycie:
  python3 rvasm.py             — złóż test.S i deca.S, wykonaj test w ISS, zapisz pliki .hex i .mif
  python3 rvasm.py --sprawdz   — wygeneruj do katalogu tymczasowego i porównaj z plikami w repozytorium (CI)
  python3 rvasm.py --bin2hex prog.bin prog.hex   — obraz binarny (objcopy) na słowa szesnastkowe
"""
import re
import sys
import tempfile
from pathlib import Path

TU = Path(__file__).resolve().parent
MOD = TU.parent

REJ = {"zero": 0, "ra": 1, "sp": 2, "gp": 3, "tp": 4, "t0": 5, "t1": 6, "t2": 7, "s0": 8, "fp": 8, "s1": 9,
       "a0": 10, "a1": 11, "a2": 12, "a3": 13, "a4": 14, "a5": 15, "a6": 16, "a7": 17, "s2": 18, "s3": 19,
       "s4": 20, "s5": 21, "s6": 22, "s7": 23, "s8": 24, "s9": 25, "s10": 26, "s11": 27, "t3": 28, "t4": 29,
       "t5": 30, "t6": 31}
REJ.update({"x%d" % i: i for i in range(32)})

R_OP = {"add": (0, 0), "sub": (0, 0x20), "sll": (1, 0), "slt": (2, 0), "sltu": (3, 0), "xor": (4, 0),
        "srl": (5, 0), "sra": (5, 0x20), "or": (6, 0), "and": (7, 0)}
I_OP = {"addi": 0, "slti": 2, "sltiu": 3, "xori": 4, "ori": 6, "andi": 7}
SH_OP = {"slli": (1, 0), "srli": (5, 0), "srai": (5, 0x20)}
B_OP = {"beq": 0, "bne": 1, "blt": 4, "bge": 5, "bltu": 6, "bgeu": 7}
L_OP = {"lb": 0, "lh": 1, "lw": 2, "lbu": 4, "lhu": 5}
S_OP = {"sb": 0, "sh": 1, "sw": 2}


class BladAsm(Exception):
    pass


def podziel_hi_lo(v):
    v &= 0xFFFFFFFF
    hi = ((v + 0x800) >> 12) & 0xFFFFF
    lo = v - (hi << 12)
    lo = ((lo + 0x800) & 0xFFF) - 0x800
    return hi, lo


class Asembler:
    def __init__(self):
        self.sym = {}
        self.rozm = {}                      # rozmiar pseudoinstrukcji z pierwszego przebiegu (li)
        self.idx = 0

    def wartosc(self, tekst, wymagaj=True):
        t = tekst.strip()
        m = re.fullmatch(r"%(hi|lo)\((.+)\)", t)
        if m:
            v = self.wartosc(m.group(2), wymagaj)
            if v is None:
                return None
            hi, lo = podziel_hi_lo(v)
            return hi if m.group(1) == "hi" else lo
        if t.startswith("'") and t.endswith("'") and len(t) == 3:
            return ord(t[1])
        suma, znak, poz = 0, 1, 0
        for czesc in re.findall(r"[+-]|[^+-]+", t.replace(" ", "")):
            if czesc == "+":
                znak = 1
                continue
            if czesc == "-":
                znak = -1
                continue
            if re.fullmatch(r"0[xX][0-9a-fA-F_]+|\d+", czesc):
                v = int(czesc.replace("_", ""), 0)
            elif czesc in self.sym:
                v = self.sym[czesc]
            elif wymagaj:
                raise BladAsm("nieznany symbol: " + czesc)
            else:
                return None
            suma += znak * v
            znak = 1
            poz += 1
        if poz == 0:
            raise BladAsm("puste wyrażenie: " + tekst)
        return suma

    @staticmethod
    def rej(t):
        t = t.strip()
        if t not in REJ:
            raise BladAsm("nieznany rejestr: " + t)
        return REJ[t]

    def adres_z(self, t):
        m = re.fullmatch(r"(.*)\((\w+)\)", t.strip())
        if not m:
            raise BladAsm("oczekiwano offset(rejestr): " + t)
        off = m.group(1).strip() or "0"
        return self.wartosc(off), self.rej(m.group(2))

    # ------------------------------------------------------------ kodowanie
    @staticmethod
    def k_r(f7, rs2, rs1, f3, rd, op):
        return (f7 << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op

    @staticmethod
    def k_i(imm, rs1, f3, rd, op):
        if not -2048 <= imm <= 2047:
            raise BladAsm("stała I poza zakresem: %d" % imm)
        return ((imm & 0xFFF) << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op

    @staticmethod
    def k_s(imm, rs2, rs1, f3):
        if not -2048 <= imm <= 2047:
            raise BladAsm("stała S poza zakresem: %d" % imm)
        imm &= 0xFFF
        return ((imm >> 5) << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | ((imm & 0x1F) << 7) | 0x23

    @staticmethod
    def k_b(off, rs2, rs1, f3):
        if off & 1 or not -4096 <= off <= 4094:
            raise BladAsm("skok warunkowy poza zakresem: %d" % off)
        o = off & 0x1FFF
        return (((o >> 12) & 1) << 31) | (((o >> 5) & 0x3F) << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | \
               (((o >> 1) & 0xF) << 8) | (((o >> 11) & 1) << 7) | 0x63

    @staticmethod
    def k_j(off, rd):
        if off & 1 or not -(1 << 20) <= off < (1 << 20):
            raise BladAsm("skok poza zakresem: %d" % off)
        o = off & 0x1FFFFF
        return (((o >> 20) & 1) << 31) | (((o >> 1) & 0x3FF) << 21) | (((o >> 11) & 1) << 20) | \
               (((o >> 12) & 0xFF) << 12) | (rd << 7) | 0x6F

    @staticmethod
    def k_u(imm, rd, op):
        return ((imm & 0xFFFFF) << 12) | (rd << 7) | op

    # ------------------------------------------------------------ rozmiar i kodowanie jednej linii
    def rozmiar(self, mn, arg):
        if mn == "li":
            v = self.wartosc(arg[1], wymagaj=False)
            return 4 if v is not None and -2048 <= v <= 2047 else 8
        if mn in ("la", "call_far"):
            return 8
        return 4

    def koduj(self, mn, a, pc):
        r = self.rej
        if mn in R_OP:
            f3, f7 = R_OP[mn]
            return [self.k_r(f7, r(a[2]), r(a[1]), f3, r(a[0]), 0x33)]
        if mn in I_OP:
            return [self.k_i(self.wartosc(a[2]), r(a[1]), I_OP[mn], r(a[0]), 0x13)]
        if mn in SH_OP:
            f3, f7 = SH_OP[mn]
            sh = self.wartosc(a[2])
            if not 0 <= sh <= 31:
                raise BladAsm("przesunięcie poza zakresem")
            return [self.k_r(f7, sh, r(a[1]), f3, r(a[0]), 0x13)]
        if mn in B_OP:
            return [self.k_b(self.wartosc(a[2]) - pc, r(a[1]), r(a[0]), B_OP[mn])]
        if mn in L_OP:
            off, rs1 = self.adres_z(a[1])
            return [self.k_i(off, rs1, L_OP[mn], r(a[0]), 0x03)]
        if mn in S_OP:
            off, rs1 = self.adres_z(a[1])
            return [self.k_s(off, r(a[0]), rs1, S_OP[mn])]
        if mn == "lui":
            return [self.k_u(self.wartosc(a[1]), r(a[0]), 0x37)]
        if mn == "auipc":
            return [self.k_u(self.wartosc(a[1]), r(a[0]), 0x17)]
        if mn == "jal":
            if len(a) == 1:
                return [self.k_j(self.wartosc(a[0]) - pc, 1)]
            return [self.k_j(self.wartosc(a[1]) - pc, r(a[0]))]
        if mn == "jalr":
            if len(a) == 1:
                return [self.k_i(0, r(a[0]), 0, 1, 0x67)]
            if len(a) == 2:
                off, rs1 = self.adres_z(a[1])
                return [self.k_i(off, rs1, 0, r(a[0]), 0x67)]
            return [self.k_i(self.wartosc(a[2]), r(a[1]), 0, r(a[0]), 0x67)]
        if mn == "fence":
            return [0x0FF0000F]
        if mn == "ecall":
            return [0x00000073]
        if mn == "ebreak":
            return [0x00100073]
        # pseudoinstrukcje
        if mn == "nop":
            return [0x00000013]
        if mn == "li":
            v = self.wartosc(a[1])
            if self.rozm[self.idx] == 4:
                return [self.k_i(v, 0, 0, r(a[0]), 0x13)]
            hi, lo = podziel_hi_lo(v)
            return [self.k_u(hi, r(a[0]), 0x37), self.k_i(lo, r(a[0]), 0, r(a[0]), 0x13)]
        if mn == "la":
            hi, lo = podziel_hi_lo(self.wartosc(a[1]))
            return [self.k_u(hi, r(a[0]), 0x37), self.k_i(lo, r(a[0]), 0, r(a[0]), 0x13)]
        if mn == "mv":
            return [self.k_i(0, r(a[1]), 0, r(a[0]), 0x13)]
        if mn == "not":
            return [self.k_i(-1, r(a[1]), 4, r(a[0]), 0x13)]
        if mn == "neg":
            return [self.k_r(0x20, r(a[1]), 0, 0, r(a[0]), 0x33)]
        if mn == "seqz":
            return [self.k_i(1, r(a[1]), 3, r(a[0]), 0x13)]
        if mn == "snez":
            return [self.k_r(0, r(a[1]), 0, 3, r(a[0]), 0x33)]
        if mn == "j":
            return [self.k_j(self.wartosc(a[0]) - pc, 0)]
        if mn == "call":
            return [self.k_j(self.wartosc(a[0]) - pc, 1)]
        if mn == "jr":
            return [self.k_i(0, r(a[0]), 0, 0, 0x67)]
        if mn == "ret":
            return [self.k_i(0, 1, 0, 0, 0x67)]
        if mn == "beqz":
            return [self.k_b(self.wartosc(a[1]) - pc, 0, r(a[0]), 0)]
        if mn == "bnez":
            return [self.k_b(self.wartosc(a[1]) - pc, 0, r(a[0]), 1)]
        zamiana = {"bgt": "blt", "ble": "bge", "bgtu": "bltu", "bleu": "bgeu"}
        if mn in zamiana:
            return [self.k_b(self.wartosc(a[2]) - pc, r(a[0]), r(a[1]), B_OP[zamiana[mn]])]
        raise BladAsm("nieznana instrukcja: " + mn)

    # ------------------------------------------------------------ dwa przebiegi
    @staticmethod
    def linie(tekst):
        for nr, l in enumerate(tekst.splitlines(), 1):
            l = re.sub(r"(#|//).*$", "", l) if '"' not in l else re.sub(r"#[^\"]*$", "", l)
            l = l.strip()
            while True:
                m = re.match(r"^([A-Za-z_.][\w.]*):\s*(.*)$", l)
                if not m:
                    break
                yield nr, ("etykieta", m.group(1))
                l = m.group(2).strip()
            if l:
                yield nr, ("tekst", l)

    @staticmethod
    def rozbij(l):
        m = re.match(r"^(\.?\w+)\s*(.*)$", l)
        mn, reszta = m.group(1).lower(), m.group(2).strip()
        if mn == ".asciz":
            return mn, [reszta]
        arg = [x.strip() for x in reszta.split(",")] if reszta else []
        return mn, arg

    @staticmethod
    def asciz(t):
        t = t.strip()
        if not (t.startswith('"') and t.endswith('"')):
            raise BladAsm(".asciz wymaga napisu w cudzysłowie")
        return t[1:-1].encode().decode("unicode_escape").encode("latin-1") + b"\0"

    def zloz(self, tekst):
        pozycje = list(self.linie(tekst))
        for przebieg in (1, 2):
            pc, obraz = 0, {}
            for idx, (nr, (rodzaj, l)) in enumerate(pozycje):
                self.idx = idx
                try:
                    if rodzaj == "etykieta":
                        if przebieg == 1:
                            if l in self.sym:
                                raise BladAsm("powtórzona etykieta: " + l)
                            self.sym[l] = pc
                        continue
                    mn, a = self.rozbij(l)
                    if mn == ".equ":
                        if przebieg == 1:
                            self.sym[a[0]] = self.wartosc(a[1])
                    elif mn == ".org":
                        nowy = self.wartosc(a[0])
                        if nowy < pc:
                            raise BladAsm(".org wstecz")
                        pc = nowy
                    elif mn == ".align":
                        k = 1 << self.wartosc(a[0])
                        pc = (pc + k - 1) // k * k
                    elif mn == ".word":
                        for x in a:
                            if przebieg == 2:
                                v = self.wartosc(x) & 0xFFFFFFFF
                                for i in range(4):
                                    obraz[pc + i] = (v >> (8 * i)) & 0xFF
                            pc += 4
                    elif mn == ".asciz":
                        b = self.asciz(a[0])
                        if przebieg == 2:
                            for i, v in enumerate(b):
                                obraz[pc + i] = v
                        pc += len(b)
                    else:
                        if pc & 3:
                            raise BladAsm("instrukcja pod adresem niewyrównanym")
                        if przebieg == 1:
                            self.rozm[idx] = self.rozmiar(mn, a)
                            pc += self.rozm[idx]
                        else:
                            for slowo in self.koduj(mn, a, pc):
                                for i in range(4):
                                    obraz[pc + i] = (slowo >> (8 * i)) & 0xFF
                                pc += 4
                except BladAsm as e:
                    raise BladAsm("wiersz %d: %s (%s)" % (nr, e, l)) from None
        dl = (max(obraz) // 4 + 1) if obraz else 0
        return [sum(obraz.get(4 * w + i, 0) << (8 * i) for i in range(4)) for w in range(dl)]


# ---------------------------------------------------------------- symulator zestawu instrukcji
def zn(v, bity):
    v &= (1 << bity) - 1
    return v - (1 << bity) if v >> (bity - 1) else v


class Iss:
    TOHOST, KONSOLA = 0x10000008, 0x1000000C

    def __init__(self, slowa, ram_slowa=2048):
        self.ram = bytearray(4 * ram_slowa)
        for i, s in enumerate(slowa):
            self.ram[4 * i:4 * i + 4] = s.to_bytes(4, "little")
        self.io = {}
        self.x = [0] * 32
        self.pc = 0
        self.zapisy = []
        self.konsola = ""
        self.instrukcje = 0
        self.koniec = False

    def czytaj(self, adr, n):
        if adr >> 28 == 0:
            a = adr % len(self.ram)
            return int.from_bytes(self.ram[a:a + n], "little")
        slowo = self.io.get(adr & ~3, 0)
        return (slowo >> (8 * (adr & 3))) & ((1 << (8 * n)) - 1)

    def pisz(self, adr, n, v):
        sl = adr & ~3
        przes = 8 * (adr & 3)
        maska = ((1 << (8 * n)) - 1) << przes
        strb = ((1 << n) - 1) << (adr & 3)
        dane = (v << przes) & maska
        self.zapisy.append((sl & 0xFFFFFFFF, dane, strb))
        if adr >> 28 == 0:
            a = adr % len(self.ram)
            self.ram[a:a + n] = (v & ((1 << (8 * n)) - 1)).to_bytes(n, "little")
        else:
            self.io[sl] = (self.io.get(sl, 0) & ~maska) | dane
            if sl == self.TOHOST:
                self.koniec = True
            if sl == self.KONSOLA:
                self.konsola += chr(v & 0xFF)

    def krok(self):
        ins = self.czytaj(self.pc, 4)
        op, rd, f3 = ins & 0x7F, (ins >> 7) & 31, (ins >> 12) & 7
        rs1, rs2, f7 = (ins >> 15) & 31, (ins >> 20) & 31, ins >> 25
        a, b = self.x[rs1], self.x[rs2]
        imm_i = zn(ins >> 20, 12)
        imm_s = zn(((ins >> 25) << 5) | ((ins >> 7) & 31), 12)
        imm_b = zn((((ins >> 31) & 1) << 12) | (((ins >> 7) & 1) << 11) | (((ins >> 25) & 0x3F) << 5) |
                   (((ins >> 8) & 0xF) << 1), 13)
        imm_u = ins & 0xFFFFF000
        imm_j = zn((((ins >> 31) & 1) << 20) | (((ins >> 12) & 0xFF) << 12) | (((ins >> 20) & 1) << 11) |
                   (((ins >> 21) & 0x3FF) << 1), 21)
        nast = (self.pc + 4) & 0xFFFFFFFF
        wynik = None

        def alu(f3, x, y, alt):
            s = y & 31
            if f3 == 0:
                return x - y if alt else x + y
            if f3 == 1:
                return x << s
            if f3 == 2:
                return int(zn(x, 32) < zn(y, 32))
            if f3 == 3:
                return int((x & 0xFFFFFFFF) < (y & 0xFFFFFFFF))
            if f3 == 4:
                return x ^ y
            if f3 == 5:
                return zn(x, 32) >> s if alt else (x & 0xFFFFFFFF) >> s
            if f3 == 6:
                return x | y
            return x & y

        if op == 0x37:
            wynik = imm_u
        elif op == 0x17:
            wynik = self.pc + imm_u
        elif op == 0x6F:
            wynik, nast = nast, (self.pc + imm_j) & 0xFFFFFFFF
        elif op == 0x67:
            wynik, nast = nast, (a + imm_i) & 0xFFFFFFFE
        elif op == 0x63:
            war = {0: a == b, 1: a != b, 4: zn(a, 32) < zn(b, 32), 5: zn(a, 32) >= zn(b, 32),
                   6: a < b, 7: a >= b}[f3]
            if war:
                nast = (self.pc + imm_b) & 0xFFFFFFFF
        elif op == 0x03:
            adr = (a + imm_i) & 0xFFFFFFFF
            n = {0: 1, 1: 2, 2: 4, 4: 1, 5: 2}[f3]
            if adr % n:
                raise RuntimeError("niewyrównany odczyt pod 0x%08X" % adr)
            v = self.czytaj(adr, n)
            wynik = zn(v, 8 * n) if f3 in (0, 1) else v
        elif op == 0x23:
            adr = (a + imm_s) & 0xFFFFFFFF
            n = {0: 1, 1: 2, 2: 4}[f3]
            if adr % n:
                raise RuntimeError("niewyrównany zapis pod 0x%08X" % adr)
            self.pisz(adr, n, b)
        elif op == 0x13:
            wynik = alu(f3, a, imm_i & 0xFFFFFFFF if f3 not in (1, 5) else rs2, f3 == 5 and f7 == 0x20)
        elif op == 0x33:
            wynik = alu(f3, a, b, f7 == 0x20)
        elif op == 0x0F:
            pass
        else:
            raise RuntimeError("nieobsługiwana instrukcja 0x%08X pod 0x%08X" % (ins, self.pc))
        if wynik is not None and rd:
            self.x[rd] = wynik & 0xFFFFFFFF
        self.pc = nast
        self.instrukcje += 1

    def uruchom(self, limit=2_000_000):
        while not self.koniec:
            self.krok()
            if self.instrukcje > limit:
                raise RuntimeError("program nie zakończył się zapisem do TOHOST")
        return self


# ---------------------------------------------------------------- pliki
def hex_slowa(slowa):
    return "".join("%08X\n" % s for s in slowa)


def mif(slowa, glebokosc):
    t = ["-- Plik wygenerowany przez program/rvasm.py — nie edytować ręcznie.",
         "WIDTH=32;", "DEPTH=%d;" % glebokosc, "ADDRESS_RADIX=HEX;", "DATA_RADIX=HEX;", "CONTENT BEGIN"]
    for i in range(glebokosc):
        t.append("  %03X : %08X;" % (i, slowa[i] if i < len(slowa) else 0))
    t.append("END;")
    return "\n".join(t) + "\n"


def generuj(cel_hdl, cel_deca, cel_program):
    asm = Asembler()
    test = asm.zloz((TU / "test.S").read_text(encoding="utf-8"))
    iss = Iss(test).uruchom()
    deca = Asembler().zloz((TU / "deca.S").read_text(encoding="utf-8"))
    pliki = {
        cel_hdl / "test_prog.hex": hex_slowa(test),
        cel_hdl / "test_zapisy.hex": "".join("%08X%08X%X\n" % z for z in iss.zapisy),
        cel_hdl / "test_liczby.hex": "%08X\n%08X\n" % (len(iss.zapisy), iss.instrukcje),
        cel_deca / "deca_prog.hex": hex_slowa(deca),
        cel_deca / "deca_prog.mif": mif(deca, 2048),
    }
    for p, t in pliki.items():
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(t)
    return test, iss, deca, list(pliki)


def main():
    if len(sys.argv) == 4 and sys.argv[1] == "--bin2hex":
        dane = Path(sys.argv[2]).read_bytes()
        dane += b"\0" * (-len(dane) % 4)
        Path(sys.argv[3]).write_text(hex_slowa([int.from_bytes(dane[i:i + 4], "little")
                                                for i in range(0, len(dane), 4)]))
        return 0
    if "--sprawdz" in sys.argv:
        with tempfile.TemporaryDirectory() as d:
            d = Path(d)
            _, iss, _, pliki = generuj(d / "hdl", d / "deca", d / "program")
            zle = 0
            for p in pliki:
                wzor = (MOD / "hdl" / "dane" / p.name) if p.parent.name == "hdl" else (MOD / "deca" / "rv" / p.name)
                if not wzor.exists() or wzor.read_text() != p.read_text():
                    print("NIEZGODNY z programem źródłowym:", wzor.relative_to(MOD))
                    zle += 1
            print("ISS: %d instrukcji, %d zapisów, konsola: %r" % (iss.instrukcje, len(iss.zapisy), iss.konsola))
            if zle:
                print("Uruchom: python3 program/rvasm.py i zatwierdź wygenerowane pliki.")
                return 1
            print("Wszystkie pliki zgodne z programami źródłowymi (%d)." % len(pliki))
            return 0
    test, iss, deca, pliki = generuj(MOD / "hdl" / "dane", MOD / "deca" / "rv", TU)
    print("test.S: %d słów, ISS: %d instrukcji, %d zapisów do pamięci" % (len(test), iss.instrukcje,
                                                                       len(iss.zapisy)))
    print("konsola: %r" % iss.konsola)
    print("deca.S: %d słów" % len(deca))
    for p in pliki:
        print("  zapisano", p.relative_to(MOD))
    return 0


if __name__ == "__main__":
    sys.exit(main())
