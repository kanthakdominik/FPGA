# 28 — Synteza wysokiego poziomu (HLS) i akceleracja

> **Część VI** · **Oznaczenia:** 🧩 · **Ścieżki:** RTL · **Szacowany czas:** ok. 14 h · **Status:** 🔲 szkielet

## Po co ten moduł

Projektowanie sprzętu w C++ i innych językach wysokiego poziomu: jak działa HLS, jak sterować potokowaniem i interfejsami, gdzie HLS się sprawdza, a gdzie lepszy jest ręczny RTL. Do tego akceleracja sieci neuronowych i alternatywne języki HDL.

## Wymagane wcześniej

[16 — Wydajność, zasoby i pobór mocy](../16-wydajnosc-zasoby-moc/README.md), [26 — Cyfrowe przetwarzanie sygnałów w FPGA](../26-dsp-w-fpga/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 28.01 | [Czym jest HLS i kiedy się opłaca](28.01-czym-jest-hls-i-kiedy-sie-oplaca.md) | Python / inne | — | 🔲 |
| 28.02 | [Pętle: potokowanie, rozwijanie i interwał inicjacji (II)](28.02-petle-potokowanie-rozwijanie-i-interwal.md) | Python / inne | — | 🔲 |
| 28.03 | [Interfejsy i pamięć w HLS](28.03-interfejsy-i-pamiec-w-hls.md) | Python / inne | — | 🔲 |
| 28.04 | [Narzędzia: Vitis HLS, oneAPI i Bambu](28.04-narzedzia-vitis-hls-oneapi-i-bambu.md) | Python / inne | — | 🔲 |
| 28.05 | [Akceleracja sieci neuronowych: hls4ml i FINN](28.05-akceleracja-sieci-neuronowych-hls4ml-i-finn.md) | Python / inne | — | 🔲 |
| 28.06 | [Alternatywne języki HDL: Chisel, SpinalHDL, Amaranth, Clash](28.06-alternatywne-jezyki-hdl-chisel-spinalhdl.md) | Python / inne | — | 🔲 |

## Po tym module potrafisz

- opisać, co HLS robi z pętlami i tablicami,
- sterować potokowaniem, rozwijaniem i interwałem inicjacji,
- zaprojektować interfejsy i dostęp do pamięci w HLS,
- porównać narzędzia HLS i ocenić wynik,
- opisać akcelerację sieci neuronowych i języki takie jak Chisel czy Amaranth.

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 28.01 Czym jest HLS i kiedy się opłaca
- [ ] 28.02 Pętle: potokowanie, rozwijanie i interwał inicjacji (II)
- [ ] 28.03 Interfejsy i pamięć w HLS
- [ ] 28.04 Narzędzia: Vitis HLS, oneAPI i Bambu
- [ ] 28.05 Akceleracja sieci neuronowych: hls4ml i FINN
- [ ] 28.06 Alternatywne języki HDL: Chisel, SpinalHDL, Amaranth, Clash
