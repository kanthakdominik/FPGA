"""Mapa rejestrów z SystemRDL (21.05): kompilacja rejestry.rdl biblioteką systemrdl-compiler, tabela rejestrów
i sprawdzenie, że adresy i wartości ID zgadzają się z ręcznie napisanym rdzeniem hdl/verilog/rejestry_rdzen.v.

    pip install systemrdl-compiler
    python3 sprawdz.py
"""
import re
import sys
from pathlib import Path

from systemrdl import RDLCompiler, RDLCompileError

tu = Path(__file__).resolve().parent
rdlc = RDLCompiler()
try:
    rdlc.compile_file(str(tu / "rejestry.rdl"))
    root = rdlc.elaborate()
except RDLCompileError:
    sys.exit(1)
top = root.top

print("| Adres | Rejestr | Pole | Bity | Dostęp SW | Dostęp HW | Reset |")
print("|---|---|---|---|---|---|---|")
mapa = {}
for reg in top.registers():
    mapa[reg.inst_name] = reg.absolute_address
    for f in reg.fields():
        dostep = f.get_property("sw").name
        if f.get_property("onwrite") is not None:
            dostep += " (" + f.get_property("onwrite").name + ")"
        reset = f.get_property("reset")
        print(f"| 0x{reg.absolute_address:02X} | {reg.inst_name} | {f.inst_name} | {f.msb}:{f.lsb} | {dostep} | "
              f"{f.get_property('hw').name} | {'—' if reset is None else hex(reset)} |")

# adresy słów z instrukcji case w rdzeniu: 4'dN: odc_dane = <nazwa>
rtl = (tu.parent / "hdl" / "verilog" / "rejestry_rdzen.v").read_text()
z_rtl = {}
for n, wyr in re.findall(r"4'd(\d+):\s+odc_dane = ([^;]+);", rtl):
    nazwa = re.findall(r"[A-Za-z_]\w*", wyr)[-1].upper()
    z_rtl[nazwa] = int(n) * 4
id_rtl = int(re.search(r"ID = 32'h([0-9A-Fa-f_]+)", rtl).group(1).replace("_", ""), 16)
id_rdl = top.get_child_by_name("ID").get_child_by_name("id").get_property("reset")

bledy = 0
for nazwa, adr in mapa.items():
    if z_rtl.get(nazwa) != adr:
        print(f"NIEZGODNOŚĆ: {nazwa} w RDL 0x{adr:02X}, w RTL {z_rtl.get(nazwa)}")
        bledy += 1
if set(z_rtl) != set(mapa):
    print(f"NIEZGODNOŚĆ zbiorów rejestrów: RTL {sorted(z_rtl)}, RDL {sorted(mapa)}")
    bledy += 1
if id_rtl != id_rdl:
    print(f"NIEZGODNOŚĆ ID: RTL 0x{id_rtl:08X}, RDL 0x{id_rdl:08X}")
    bledy += 1
print(f"\nRejestrów: {len(mapa)}, rozmiar mapy: {top.size} B; zgodność z rejestry_rdzen.v: "
      f"{'tak' if bledy == 0 else 'NIE'}")
sys.exit(1 if bledy else 0)
