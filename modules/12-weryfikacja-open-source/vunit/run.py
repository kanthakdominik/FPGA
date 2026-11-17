"""Testy VHDL modułu 12 uruchamiane przez VUnit (GHDL): testbench VUnit, testbench OSVVM i testbench UVVM.

    python3 run.py                    wszystkie testy (równolegle: -p 4)
    python3 run.py --list             lista testów
    python3 run.py "*nasycenie*" -v   wybrane testy z pełnym wydrukiem
    python3 run.py --xunit-xml wyniki.xml

UVVM: katalog z repozytorium UVVM w zmiennej UVVM_HOME (bez niej testbench UVVM jest pomijany).
"""
import os
from pathlib import Path

from vunit import VUnit

TU = Path(__file__).resolve().parent
MOD = TU.parent

vu = VUnit.from_argv(compile_builtins=False)
vu.add_vhdl_builtins()
vu.add_osvvm()                                    # OSVVM dołączony do VUnit (RandomPkg, CoveragePkg, …)

lib = vu.add_library("lib")
lib.add_source_files(MOD / "hdl" / "vhdl" / "fir8.vhd")
lib.add_source_files(TU / "tb_fir8_vunit.vhd")
lib.add_source_files(MOD / "osvvm" / "tb_fir8_osvvm.vhd")

uvvm = os.environ.get("UVVM_HOME")
if uvvm:
    util = vu.add_library("uvvm_util")
    util.add_source_files(Path(uvvm) / "uvvm_util" / "src" / "*.vhd")
    lib.add_source_files(MOD / "uvvm" / "tb_fir8_uvvm.vhd")

# układy z błędami: test „losowe” musi wykryć niezgodność (testbench odwraca warunek dla BUG /= 0)
tb = lib.test_bench("tb_fir8_vunit")
losowe = tb.test("losowe")
losowe.add_config(name="poprawny", generics={"BUG": 0})
losowe.add_config(name="bug1_obciecie", generics={"BUG": 1})
losowe.add_config(name="bug2_bez_nasycenia", generics={"BUG": 2})

vu.set_compile_option("ghdl.a_flags", ["-frelaxed"])
vu.set_sim_option("ghdl.elab_flags", ["-frelaxed"])
vu.main()
