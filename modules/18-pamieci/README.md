# 18 — Pamięci w FPGA

> **Część V** · **Oznaczenia:** 🧩🛠️💼 · **Ścieżki:** RTL, DECA · **Szacowany czas:** ok. 14 h · **Status:** 🔲 szkielet

## Po co ten moduł

Wewnętrzne pamięci układu i struktury na nich zbudowane: RAM jedno- i dwuportowy, ROM z inicjalizacją, FIFO, bufory pierścieniowe i ping-pong. Do tego specyficzna dla MAX 10 pamięć flash użytkownika.

## Wymagane wcześniej

[07 — Kodowanie pod syntezę — wzorce RTL](../07-kodowanie-pod-synteze/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 18.01 | [Bloki pamięci: tryby jedno- i dwuportowe, odczyt podczas zapisu](18.01-bloki-pamieci-tryby-jedno-i-dwuportowe-odczyt.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 18.02 | [ROM i inicjalizacja pamięci z pliku (.mif, .hex, .mem)](18.02-rom-i-inicjalizacja-pamieci-z-pliku-mif-hex-mem.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 18.03 | [Synchroniczna kolejka FIFO i flagi](18.03-synchroniczna-kolejka-fifo-i-flagi.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 18.04 | [Bufory pierścieniowe, ping-pong i bufory linii](18.04-bufory-pierscieniowe-ping-pong-i-bufory-linii.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 18.05 | [Pamięć flash użytkownika w MAX 10 (UFM)](18.05-pamiec-flash-uzytkownika-w-max-10-ufm.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 18.06 | [ECC i ochrona danych w pamięci](18.06-ecc-i-ochrona-danych-w-pamieci.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |

## Po tym module potrafisz

- dobrać tryb bloku pamięci i opisać zachowanie przy jednoczesnym odczycie i zapisie,
- zainicjalizować pamięć z pliku w sposób przenośny między narzędziami,
- zaprojektować synchroniczne FIFO z flagami,
- zbudować bufory pierścieniowe, ping-pong i bufory linii,
- zapisywać i odczytywać pamięć UFM w MAX 10.

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).
- `deca/` — projekty Quartusa dla płytki Arrow DECA: moduł nadrzędny, przypisania pinów (`.qsf`), ograniczenia czasowe (`.sdc`) ([opis płytki](../../plytka-deca/README.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 18.01 Bloki pamięci: tryby jedno- i dwuportowe, odczyt podczas zapisu
- [ ] 18.02 ROM i inicjalizacja pamięci z pliku (.mif, .hex, .mem)
- [ ] 18.03 Synchroniczna kolejka FIFO i flagi
- [ ] 18.04 Bufory pierścieniowe, ping-pong i bufory linii
- [ ] 18.05 Pamięć flash użytkownika w MAX 10 (UFM)
- [ ] 18.06 ECC i ochrona danych w pamięci
