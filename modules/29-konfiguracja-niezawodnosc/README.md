# 29 — Konfiguracja, bezpieczeństwo i niezawodność

> **Część VI** · **Oznaczenia:** 🛠️💼 · **Ścieżki:** RTL, DECA · **Szacowany czas:** ok. 12 h · **Status:** ✅ pełny

## Po co ten moduł

Co dzieje się z projektem po wdrożeniu: tryby konfiguracji, zdalna aktualizacja z dwoma obrazami w MAX 10, ochrona bitstreamu, odporność na promieniowanie i normy bezpieczeństwa funkcjonalnego.

## Wymagane wcześniej

[03 — Przepływ projektowy od RTL do bitstreamu](../03-przeplyw-projektowy/README.md), [18 — Pamięci w FPGA](../18-pamieci/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 29.01 | [Tryby konfiguracji i pamięci konfiguracyjne](29.01-tryby-konfiguracji-i-pamieci-konfiguracyjne.md) | — | — | ✅ |
| 29.02 | [Podwójny obraz i zdalna aktualizacja w MAX 10](29.02-podwojny-obraz-i-zdalna-aktualizacja-w-max-10.md) | VHDL · Verilog · SystemVerilog | 🛠️ | ✅ |
| 29.03 | [Szyfrowanie i ochrona bitstreamu](29.03-szyfrowanie-i-ochrona-bitstreamu.md) | — | — | ✅ |
| 29.04 | [Promieniowanie i SEU: TMR, scrubbing i ECC](29.04-promieniowanie-i-seu-tmr-scrubbing-i-ecc.md) | VHDL · Verilog · SystemVerilog | — | ✅ |
| 29.05 | [Bezpieczeństwo funkcjonalne: DO-254, IEC 61508, ISO 26262](29.05-bezpieczenstwo-funkcjonalne-do-254-iec-61508.md) | — | — | ✅ |

## Po tym module potrafisz

- dobrać tryb konfiguracji i pamięć konfiguracyjną,
- zrealizować zdalną aktualizację z podwójnym obrazem w MAX 10,
- opisać szyfrowanie i ochronę bitstreamu,
- zastosować TMR, ECC i scrubbing przeciw błędom SEU,
- opisać wymagania DO-254, IEC 61508 i ISO 26262 wobec projektu FPGA.

## Układy w module

- **`aktualizacja`** — master Avalon-MM dla rdzenia Dual Configuration Intel FPGA IP: wybór obrazu w rejestrze wejściowym, odczekanie zajętości rdzenia (> 531 taktów), wyzwolenie rekonfiguracji, odmowa przy niezgodnym CRC, zerowanie licznika nadzorującego ([29.02](29.02-podwojny-obraz-i-zdalna-aktualizacja-w-max-10.md)).
- **`crc32`** — CRC-32 IEEE 802.3 bajt na takt do sprawdzania pobranego obrazu ([29.02](29.02-podwojny-obraz-i-zdalna-aktualizacja-w-max-10.md)).
- **`tmr_glos`**, **`licznik_tmr`** — głosowanie 2 z 3 i licznik w potrójnej redundancji z resynchronizacją lub bez, z portem wstrzykiwania błędów ([29.04](29.04-promieniowanie-i-seu-tmr-scrubbing-i-ecc.md)).
- **`secded_koder`**, **`secded_dekoder`**, **`pamiec_ecc`** — kod SECDED (39,32) i pamięć z ECC, czyszczeniem w tle (zapis zwrotny z blokadą kolizji z zapisem użytkownika), licznikami błędów i portem wstrzykiwania ([29.04](29.04-promieniowanie-i-seu-tmr-scrubbing-i-ecc.md)).

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche w trzech językach (`vhdl/`, `verilog/`, `sv/`), uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)): `tb_aktualizacja` (wartość kontrolna CRC-32, model rdzenia z zajętością 531 taktów), `tb_tmr` (cztery wstrzyknięcia: 0 błędów z resynchronizacją, 260 bez), `tb_ecc` (wszystkie błędy pojedyncze i podwójne w 200 słowach, jedno przejście czyszczenia: 20 zapisów zwrotnych, 3 błędy podwójne, zapisy użytkownika zachowane).
- [deca/obrazy/](deca/obrazy/README.md) — dwa obrazy konfiguracji MAX 10 z jednego źródła (parametr `OBRAZ`), system `system_dual` z rdzeniem Dual Configuration ze skryptu `system.tcl`, przełączanie przyciskiem, odmowa i licznik nadzorujący na przełącznikach; `deca_top` w trzech językach, `.sdc`, `utworz_projekt.tcl` z przypisaniami z [plytka-deca/deca_piny.tcl](../../plytka-deca/deca_piny.tcl), `Makefile` z celami `system`, `obraz0`, `obraz1`, `pof` ([29.02](29.02-podwojny-obraz-i-zdalna-aktualizacja-w-max-10.md)). Projekt nie był kompilowany w Quartusie.
- Lint: kod Verilog i SystemVerilog z `hdl/` przechodzi `verilator --lint-only -Wall` bez ostrzeżeń ([07.09](../07-kodowanie-pod-synteze/07.09-styl-kodu-lint-i-przeglady-verilator-verible-vsg.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [x] 29.01 Tryby konfiguracji i pamięci konfiguracyjne
- [x] 29.02 Podwójny obraz i zdalna aktualizacja w MAX 10
- [x] 29.03 Szyfrowanie i ochrona bitstreamu
- [x] 29.04 Promieniowanie i SEU: TMR, scrubbing i ECC
- [x] 29.05 Bezpieczeństwo funkcjonalne: DO-254, IEC 61508, ISO 26262
