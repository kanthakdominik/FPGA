"""Uruchamia testy cocotb dla trzech wersji fir8 i trzech wartości BUG (runner cocotb_tools, bez Makefile).

Dla BUG = 0 wszystkie testy muszą przejść, dla BUG = 1 i 2 — co najmniej jeden musi zawieść (testbench
wykrywa błąd). Wynik: tabela i kod wyjścia; raporty JUnit w build/<symulator>_bug<n>/results.xml.
"""
import sys
import time
import xml.etree.ElementTree as ET
from pathlib import Path

from cocotb_tools.runner import get_runner

TU = Path(__file__).resolve().parent
HDL = TU.parent / "hdl"
WARIANTY = [  # symulator, źródło, dodatkowe argumenty kompilacji
    ("icarus", HDL / "verilog" / "fir8.v", []),
    ("ghdl", HDL / "vhdl" / "fir8.vhd", ["--std=08"]),
    ("verilator", HDL / "sv" / "fir8.sv", ["-Wno-fatal", "-Wno-lint", "-Wno-style"]),
]


def wyniki(xml_path):
    """(liczba testów, liczba niezaliczonych) z raportu JUnit."""
    root = ET.parse(xml_path).getroot()
    cases = root.findall(".//testcase")
    failed = [c for c in cases if c.find("failure") is not None or c.find("error") is not None]
    return len(cases), len(failed)


def main():
    zle = 0
    print(f"{'symulator':10} {'BUG':>3} {'testy':>6} {'nieudane':>9} {'czas [s]':>9}  ocena")
    for sim, src, args in WARIANTY:
        for bug in (0, 1, 2):
            build = TU / "build" / f"{sim}_bug{bug}"
            runner = get_runner(sim)
            t0 = time.time()
            extra = {} if sim == "ghdl" else {"timescale": ("1ns", "1ps")}   # Verilog bez `timescale
            runner.build(sources=[src], hdl_toplevel="fir8", parameters={"BUG": bug}, build_dir=build,
                         build_args=args, always=True, log_file=build / "build.log", **extra)
            test_args = ["--std=08"] if sim == "ghdl" else []
            xml = build / "results.xml"
            try:                                      # przy nieudanych testach runner może zgłosić wyjątek
                # katalog roboczy = katalog kompilacji (GHDL szuka tam wyniku elaboracji); moduł testów przez PYTHONPATH
                runner.test(hdl_toplevel="fir8", test_module="test_fir8", test_dir=build, build_dir=build,
                            test_args=test_args, results_xml=str(xml), log_file=build / "test.log",
                            extra_env={"PYTHONPATH": str(TU)})
            except (SystemExit, Exception) as e:      # wynik i tak czytamy z raportu JUnit
                print(f"  ({sim}, BUG={bug}: {type(e).__name__}: {e})")
                if not xml.exists():
                    for log in ("build.log", "test.log"):
                        if (build / log).exists():
                            print((build / log).read_text()[-2500:])
                    zle += 1
                    continue
            n, failed = wyniki(xml)
            ok = (failed == 0) if bug == 0 else (failed > 0)
            zle += not ok
            print(f"{sim:10} {bug:>3} {n:>6} {failed:>9} {time.time() - t0:>9.1f}  "
                  f"{'OK' if ok else 'ZLE'}{'' if bug == 0 else ' (oczekiwano wykrycia)'}")
            if not ok:
                print((build / "test.log").read_text()[-3000:])
    sys.exit(1 if zle else 0)


if __name__ == "__main__":
    main()
