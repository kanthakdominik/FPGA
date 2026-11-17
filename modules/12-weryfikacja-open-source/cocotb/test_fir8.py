"""Testy cocotb dla fir8 — ten sam plik dla wersji VHDL (GHDL), Verilog (Icarus) i SystemVerilog (Verilator).

Driver podaje próbki na zboczu opadającym, monitor zbiera wyjścia po zboczu narastającym (ReadOnly),
porównanie z modelem numpy dokładnie co do bitu (model/fir_model.py).
"""
import os
import sys

import cocotb
import numpy as np
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, ReadOnly, RisingEdge

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "model"))
from fir_model import fir8_fixed, fir8_float, saturation_pattern, stats  # noqa: E402

LATENCY = 3  # takty od zbocza przyjmującego próbkę do zbocza, po którym wynik jest na wyjściu


async def reset(dut):
    Clock(dut.clk, 10, unit="ns").start()            # cocotb 2: start() sam uruchamia zadanie zegara
    dut.rst.value = 1
    dut.in_valid.value = 0
    dut.in_data.value = 0
    await ClockCycles(dut.clk, 3)
    await FallingEdge(dut.clk)
    dut.rst.value = 0


async def monitor(dut, out, cycles):
    """Zbiera wyjścia (liczby ze znakiem) i takt, w którym się pojawiły."""
    n = 0
    while True:
        await RisingEdge(dut.clk)
        await ReadOnly()
        n += 1
        if dut.out_valid.value == 1:
            out.append(dut.out_data.value.to_signed())
            cycles.append(n)


async def drive(dut, samples, gaps=None, rng=None):
    """Podaje próbki; gaps: prawdopodobieństwo taktu bez próbki. Zwraca takty, w których wysłano próbki."""
    sent = []
    n = 0
    for v in samples:
        while gaps and rng.random() < gaps:
            await FallingEdge(dut.clk)
            dut.in_valid.value = 0
            n += 1
        await FallingEdge(dut.clk)
        dut.in_valid.value = 1
        dut.in_data.value = int(v)
        n += 1
        sent.append(n)
    await FallingEdge(dut.clk)
    dut.in_valid.value = 0
    await ClockCycles(dut.clk, LATENCY + 2)
    return sent


def compare(dut, x, got):
    exp = fir8_fixed(x)
    got = np.array(got, dtype=np.int64)
    assert len(got) == len(exp), f"wyjść {len(got)}, oczekiwano {len(exp)}"
    bad = np.flatnonzero(got != exp)
    if len(bad):
        i = bad[0]
        dut._log.error("niezgodnych próbek: %d z %d; pierwsza #%d: y = %d, oczekiwano %d (różnica %d)",
                       len(bad), len(exp), i, got[i], exp[i], got[i] - exp[i])
    assert len(bad) == 0, "wynik różni się od modelu"


@cocotb.test()
async def latency(dut):
    """Opóźnienie potoku: próbka przyjęta na zboczu R0, out_valid = 1 po zboczu R3 i tylko przez jeden takt."""
    await reset(dut)
    await FallingEdge(dut.clk)
    dut.in_valid.value = 1
    dut.in_data.value = 2047
    await RisingEdge(dut.clk)                       # R0: próbka przyjęta
    await FallingEdge(dut.clk)
    dut.in_valid.value = 0
    seen = []
    for _ in range(4):                              # R1 … R4
        await RisingEdge(dut.clk)
        await ReadOnly()
        seen.append(int(dut.out_valid.value))
    assert seen == [0, 0, 1, 0], f"out_valid po zboczach R1…R4: {seen}, oczekiwano [0, 0, 1, 0]"


@cocotb.test()
async def impulse(dut):
    """Odpowiedź impulsowa = współczynniki × 2047 / 2048 po zaokrągleniu."""
    await reset(dut)
    out, cyc = [], []
    cocotb.start_soon(monitor(dut, out, cyc))
    x = [2047] + [0] * 9
    await drive(dut, x)
    compare(dut, x, out)
    dut._log.info("odpowiedź impulsowa: %s", out[:8])


@cocotb.test()
async def saturation(dut):
    """Wzorzec o znakach zgodnych ze współczynnikami: nasycenie w obie strony."""
    await reset(dut)
    out, cyc = [], []
    cocotb.start_soon(monitor(dut, out, cyc))
    x = saturation_pattern() * 2 + [0] * 8
    await drive(dut, x)
    st = stats(x)
    assert st["nasycenie+"] > 0 and st["nasycenie-"] > 0
    compare(dut, x, out)


@cocotb.test()
async def random_numpy(dut):
    """5000 próbek losowych (co ósma skrajna) z przerwami w in_valid; porównanie bit w bit z numpy."""
    rng = np.random.default_rng(int(os.environ.get("SEED", "1")))
    x = rng.integers(-2048, 2048, 5000)
    edge = rng.random(len(x)) < 1 / 8
    x[edge] = rng.choice([-2048, 2047], int(edge.sum()))
    await reset(dut)
    out, cyc = [], []
    cocotb.start_soon(monitor(dut, out, cyc))
    await drive(dut, x, gaps=0.25, rng=rng)
    compare(dut, x, out)
    err = np.array(out) - fir8_float(x)
    dut._log.info("próbek %d, %s, błąd względem filtru idealnego: max %.3f LSB", len(x), stats(x),
                  np.abs(err[np.abs(out) < 32767]).max())
