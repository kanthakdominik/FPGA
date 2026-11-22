#!/usr/bin/env python3
"""Filtr FIR z modułu 26 (struktura transponowana, 31 współczynników) w Amaranth — HDL jako biblioteka Pythona
(28.06). Ten sam układ co hdl/verilog/fir_transp.v z modułu 26, ale współczynniki są stałymi z pliku, a
generator pętlą w Pythonie buduje rejestry sum częściowych.

  python3 fir_amaranth.py [katalog_wyjściowy]
    1. symulacja w Amaranth (asynchroniczny testbench) na wektorach modułu 26 — wynik bit w bit z modelem,
    2. eksport do Veriloga (fir_amaranth.v) — testbench tb_fir_amaranth.v sprawdza go w Icarusie na tych
       samych wektorach.
Wymaga: pip install -r requirements.txt (Amaranth 0.5 z wbudowanym Yosysem).
"""
import sys
from pathlib import Path

from amaranth import Elaboratable, Module, Mux, Signal, signed
from amaranth.back import verilog
from amaranth.sim import Simulator

TU = Path(__file__).resolve().parent
DANE = TU.parent.parent / "26-dsp-w-fpga" / "hdl" / "dane"


def czytaj_hex16(nazwa):
    v = [int(l, 16) for l in (DANE / nazwa).read_text().split()]
    return [x - 0x10000 if x & 0x8000 else x for x in v]


class FirTransp(Elaboratable):
    """y = nasyc16(zaokr(Σ h_k · x[n−k], 15)); jedna próbka na takt (we), wynik takt później (y_wazne)."""

    def __init__(self, h):
        self.h = list(h)
        self.we = Signal()
        self.x = Signal(signed(16))
        self.y = Signal(signed(16))
        self.y_wazne = Signal()

    def elaborate(self, platform):
        m = Module()
        n = len(self.h)
        z = [None] + [Signal(signed(40), name="z%d" % k) for k in range(1, n)]   # sumy częściowe z_1 … z_(N−1)
        pelny = self.x * self.h[0] + z[1]
        zaokr = (pelny + (1 << 14)) >> 15                                       # >> na signed: arytmetyczne
        m.d.sync += self.y_wazne.eq(self.we)
        with m.If(self.we):
            for k in range(1, n - 1):
                m.d.sync += z[k].eq(self.x * self.h[k] + z[k + 1])
            m.d.sync += z[n - 1].eq(self.x * self.h[n - 1])
            m.d.sync += self.y.eq(Mux(zaokr > 32767, 32767, Mux(zaokr < -32768, -32768, zaokr)))
        return m


def main():
    cel = Path(sys.argv[1]) if len(sys.argv) > 1 else TU
    h = czytaj_hex16("fir_wsp.hex")
    xs = czytaj_hex16("fir_we.hex")
    ys = czytaj_hex16("fir_wy.hex")
    dut = FirTransp(h)

    wyniki = []

    async def testbench(ctx):
        for v in xs:
            ctx.set(dut.x, v)
            ctx.set(dut.we, 1)
            await ctx.tick()
            if ctx.get(dut.y_wazne):
                wyniki.append(ctx.get(dut.y))
        ctx.set(dut.we, 0)
        await ctx.tick()

    sim = Simulator(dut)
    sim.add_clock(1e-8)
    sim.add_testbench(testbench)
    sim.run()
    zle = sum(a != b for a, b in zip(wyniki, ys)) + abs(len(wyniki) - len(ys))
    print("Amaranth (symulacja): %d probek, niezgodnych z modelem %d" % (len(wyniki), zle))

    tekst = verilog.convert(dut, name="fir_amaranth", ports=[dut.we, dut.x, dut.y, dut.y_wazne])
    (cel / "fir_amaranth.v").write_text(tekst)
    print("Verilog: %s (%d wierszy)" % (cel / "fir_amaranth.v", tekst.count("\n")))
    print("PASS" if zle == 0 else "FAIL")
    return 1 if zle else 0


if __name__ == "__main__":
    sys.exit(main())
