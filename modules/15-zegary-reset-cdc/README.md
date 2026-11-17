# 15 — Zegary, reset i przejścia między domenami (CDC)

> **Część IV** · **Oznaczenia:** 🧩🛠️💼 · **Ścieżki:** RTL, weryfikacja, DECA · **Szacowany czas:** ok. 18 h · **Status:** ✅ pełny

## Po co ten moduł

Najczęstsze źródło błędów, które przechodzą symulację i pojawiają się dopiero na sprzęcie. Moduł omawia generowanie zegarów, metastabilność, synchronizatory, asynchroniczne FIFO i strategie resetu. Każdy układ ma testbench z zegarami o niezależnych okresach (także z modelowanym rozrzutem opóźnień bitów), MTBF jest policzony skryptem, przejścia między domenami są sprawdzane strukturalnie (własny analizator CDC na netliście Yosysa) i w analizie czasowej (OpenSTA), a całość działa na DECA między dwoma niezależnymi oscylatorami.

## Wymagane wcześniej

[14 — Statyczna analiza czasowa (STA)](../14-analiza-czasowa/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 15.01 | [Generowanie zegarów: PLL, clock enable i dlaczego nie bramkować zegara](15.01-generowanie-zegarow-pll-clock-enable-i-dlaczego.md) | VHDL · Verilog · SystemVerilog | 🛠️ | ✅ |
| 15.02 | [Metastabilność i MTBF — rachunek](15.02-metastabilnosc-i-mtbf-rachunek.md) | Python / inne | — | ✅ |
| 15.03 | [Synchronizatory jednobitowe i synchronizacja impulsów](15.03-synchronizatory-jednobitowe-i-synchronizacja.md) | VHDL · Verilog · SystemVerilog | — | ✅ |
| 15.04 | [Przesyłanie słów: handshake, kod Graya i MCP](15.04-przesylanie-slow-handshake-kod-graya-i-mcp.md) | VHDL · Verilog · SystemVerilog | — | ✅ |
| 15.05 | [Asynchroniczna kolejka FIFO](15.05-asynchroniczna-kolejka-fifo.md) | VHDL · Verilog · SystemVerilog | 🛠️ | ✅ |
| 15.06 | [Strategie resetu: synchronizator resetu i RDC](15.06-strategie-resetu-synchronizator-resetu-i-rdc.md) | VHDL · Verilog · SystemVerilog | — | ✅ |
| 15.07 | [Ograniczenia i weryfikacja CDC](15.07-ograniczenia-i-weryfikacja-cdc.md) | Python / inne | 🛠️ | ✅ |

## Po tym module potrafisz

- wygenerować zegary PLL-em i wyjaśnić, dlaczego nie bramkuje się zegara logiką,
- policzyć MTBF synchronizatora,
- przesłać pojedynczy bit, impuls i słowo wielobitowe między domenami,
- zaprojektować asynchroniczne FIFO z licznikami w kodzie Graya,
- zaprojektować synchronizator resetu i opisać przejścia w ograniczeniach.

## Układ budowany w module

- **`sync_bit`** — synchronizator 2FF (parametry `STAGES`, `W`) z atrybutami `ASYNC_REG` i `SYNCHRONIZER_IDENTIFICATION` ([15.03](15.03-synchronizatory-jednobitowe-i-synchronizacja.md)).
- **`sync_pulse`** — przesyłanie impulsu przez przełącznik (toggle) z potwierdzeniem i `busy` ([15.03](15.03-synchronizatory-jednobitowe-i-synchronizacja.md)).
- **`cdc_handshake`** i **`gray_cdc`** — słowo przez dwufazowy handshake i licznik w kodzie Graya ([15.04](15.04-przesylanie-slow-handshake-kod-graya-i-mcp.md)).
- **`async_fifo`** — asynchroniczna kolejka Cummingsa ze wskaźnikami Graya ([15.05](15.05-asynchroniczna-kolejka-fifo.md)).
- **`rst_sekwencer`** — synchronizatory resetu dwóch domen z kolejnością zwalniania ([15.06](15.06-strategie-resetu-synchronizator-resetu-i-rdc.md)).
- **`bramkowanie`** — clock enable kontra bramkowanie zegara bramką AND i komórką ICG ([15.01](15.01-generowanie-zegarow-pll-clock-enable-i-dlaczego.md)).

## Kod w module

- `hdl/` — wszystkie układy z samosprawdzającymi się testbenchami w trzech językach (`vhdl/`, `verilog/`, `sv/`); zegary o okresach bez wspólnej wielokrotności, testy pokrycia flag FIFO, rozrzut opóźnień bitów dla kodu Graya. Uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).
- [cdc/](cdc/) — [mtbf.py](cdc/mtbf.py) (rachunek MTBF z 15.02), [cdc_lint.py](cdc/cdc_lint.py) (strukturalna analiza CDC na netliście Yosysa) z przykładami [cdc_przyklady.v](cdc/cdc_przyklady.v) i sprawdzeniem [sprawdz_cdc.py](cdc/sprawdz_cdc.py), [e07_cdc.tcl](cdc/e07_cdc.tcl) z [sprawdz_sta_cdc.py](cdc/sprawdz_sta_cdc.py) — ograniczenia przejścia w OpenSTA ([15.07](15.07-ograniczenia-i-weryfikacja-cdc.md)).
- [deca/cdc/](deca/cdc/) — projekt DECA z dwoma niezależnymi zegarami (50 MHz i 10 MHz): `deca_top` w trzech językach (FIFO z kontrolą ciągłości, impuls z przycisku, handshake przełączników, sekwencer resetu), ograniczenia [cdc.sdc](deca/cdc/cdc.sdc) (grupy, `set_net_delay`, `set_max_skew`), [raporty.tcl](deca/cdc/raporty.tcl) (`make raporty`: przejścia, nieograniczone, rozrzut, MTBF) i `utworz_projekt.tcl` z przypisaniami pinów z [plytka-deca/deca_piny.tcl](../../plytka-deca/deca_piny.tcl) ([opis płytki](../../plytka-deca/README.md)).
- CI: zadanie *Analiza czasowa i CDC* w [checks.yml](../../.github/workflows/checks.yml) — MTBF, analiza strukturalna i OpenSTA z tabelą wyników w podsumowaniu przebiegu.
- Lint: kod Verilog i SystemVerilog z `hdl/` przechodzi `verilator --lint-only -Wall` (wyłączenia tylko tam, gdzie są celem przykładu — bramkowanie zegara, zatrzask ICG) — sprawdzane w CI ([07.09](../07-kodowanie-pod-synteze/07.09-styl-kodu-lint-i-przeglady-verilator-verible-vsg.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 15.01 Generowanie zegarów: PLL, clock enable i dlaczego nie bramkować zegara
- [ ] 15.02 Metastabilność i MTBF — rachunek
- [ ] 15.03 Synchronizatory jednobitowe i synchronizacja impulsów
- [ ] 15.04 Przesyłanie słów: handshake, kod Graya i MCP
- [ ] 15.05 Asynchroniczna kolejka FIFO
- [ ] 15.06 Strategie resetu: synchronizator resetu i RDC
- [ ] 15.07 Ograniczenia i weryfikacja CDC
