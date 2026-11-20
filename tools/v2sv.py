# Przekład Verilog -> SystemVerilog dla kodu kursu: python3 tools/v2sv.py <plik.v | katalog> <katalog_sv>
# Po przekładzie sprawdź ręcznie: tablice sterowane z portów instancji zostają `wire`, nie ma `logic x = wyrażenie`.
import re, sys
from pathlib import Path
src, dst = Path(sys.argv[1]), Path(sys.argv[2])
pliki = [src] if src.is_file() else sorted(src.glob("*.v"))
for f in pliki:
    tb = f.name.startswith("tb_")
    s = f.read_text()
    out = []
    lines = s.split("\n")
    i = 0
    while i < len(lines):
        l = lines[i]
        # wire z inicjalizatorem (może być wielowierszowy do średnika)
        m = re.match(r"^(\s*)wire(\s+(?:signed\s+)?(?:\[[^\]]*\]\s*)?)(\w+)\s*=\s*(.*)$", l)
        if m and not re.search(r",\s*\w+\s*=", m.group(4).split("//")[0]):
            ind, typ, name, rest = m.groups()
            stmt = rest
            j = i
            while not stmt.split("//")[0].rstrip().endswith(";"):
                j += 1
                stmt += "\n" + lines[j]
            kom = ""
            if "//" in stmt.split("\n")[-1]:
                pass
            out.append(f"{ind}logic{typ}{name};")
            out.append(f"{ind}assign {name} = {stmt}")
            i = j + 1
            continue
        l = re.sub(r"\bwire\b", "logic", l)
        l = re.sub(r"\breg\b", "logic", l)
        if tb:
            l = re.sub(r"\binteger\b", "int", l)
        else:
            l = re.sub(r"always @\(posedge", r"always_ff @(posedge", l)
            l = l.replace("always @(*)", "always_comb")
        l = re.sub(r"\binout(\s+)logic\b", r"inout\1wire ", l)
        out.append(l)
        i += 1
    s = "\n".join(out)
    s = s.replace("`default_nettype logic", "`default_nettype wire").replace("// Testbench", "// Testbench (SystemVerilog)", 1)
    (dst / (f.stem + ".sv")).write_text(s)
    print(f.name)
