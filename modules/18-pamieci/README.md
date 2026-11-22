# 18 — Pamięci w FPGA

> **Część V** · **Oznaczenia:** 🧩🛠️💼 · **Ścieżki:** RTL, DECA · **Szacowany czas:** ok. 14 h

## Po co ten moduł

Wewnętrzne pamięci układu i struktury na nich zbudowane: RAM jedno- i dwuportowy, ROM z inicjalizacją z pliku, FIFO z flagami, bufory pierścieniowe, ping-pong i bufory linii, ochrona danych kodem SECDED. Do tego specyficzna dla MAX 10 pamięć flash użytkownika, obsługiwana własnym sterownikiem przez rejestry rdzenia On-Chip Flash. Eksperyment w Yosysie pokazuje, które wzorce HDL trafiają do bloków pamięci, a które zamieniają się w tysiące przerzutników.

## Wymagane wcześniej

[07 — Kodowanie pod syntezę — wzorce RTL](../07-kodowanie-pod-synteze/README.md)

## Tematy

| # | Temat | Kod | DECA |
|---|-------|-----|------|
| 18.01 | [Bloki pamięci: tryby jedno- i dwuportowe, odczyt podczas zapisu](18.01-bloki-pamieci-tryby-jedno-i-dwuportowe-odczyt.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 18.02 | [ROM i inicjalizacja pamięci z pliku (.mif, .hex, .mem)](18.02-rom-i-inicjalizacja-pamieci-z-pliku-mif-hex-mem.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 18.03 | [Synchroniczna kolejka FIFO i flagi](18.03-synchroniczna-kolejka-fifo-i-flagi.md) | VHDL · Verilog · SystemVerilog | — |
| 18.04 | [Bufory pierścieniowe, ping-pong i bufory linii](18.04-bufory-pierscieniowe-ping-pong-i-bufory-linii.md) | VHDL · Verilog · SystemVerilog | — |
| 18.05 | [Pamięć flash użytkownika w MAX 10 (UFM)](18.05-pamiec-flash-uzytkownika-w-max-10-ufm.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 18.06 | [ECC i ochrona danych w pamięci](18.06-ecc-i-ochrona-danych-w-pamieci.md) | VHDL · Verilog · SystemVerilog | — |

## Po tym module potrafisz

- dobrać tryb bloku pamięci i opisać zachowanie przy jednoczesnym odczycie i zapisie,
- zainicjalizować pamięć z pliku w sposób przenośny między narzędziami,
- zaprojektować synchroniczne FIFO z flagami,
- zbudować bufory pierścieniowe, ping-pong i bufory linii,
- zapisywać, kasować i odczytywać pamięć UFM w MAX 10 i planować zapis z myślą o zużyciu flasha,
- zabezpieczyć dane kodem SECDED i przetestować to wstrzykiwaniem błędów.

## Układy w module

- **`ram_sp`, `ram_sdp`** — pamięć jednoportowa w trzech trybach odczytu podczas zapisu i dwuportowa z dwoma zegarami ([18.01](18.01-bloki-pamieci-tryby-jedno-i-dwuportowe-odczyt.md)).
- **`rom_sinus`** — ROM 256 × 8 z pliku: `$readmemh` w Verilogu/SV, textio i `ram_init_file` w VHDL ([18.02](18.02-rom-i-inicjalizacja-pamieci-z-pliku-mif-hex-mem.md)).
- **`fifo_bram`** — synchroniczne FIFO na bloku pamięci, tryb standardowy i FWFT, `count`, `almost_full`, `almost_empty` ([18.03](18.03-synchroniczna-kolejka-fifo-i-flagi.md)).
- **`pingpong`, `bufor_linii`** — dwa banki z przeciwciśnieniem i bufor dwóch linii obrazu dla okna 3 × 3 ([18.04](18.04-bufory-pierscieniowe-ping-pong-i-bufory-linii.md)).
- **`ufm_sterownik`** — odczyt, zapis i kasowanie strony pamięci flash użytkownika przez rejestry rdzenia On-Chip Flash, z ochroną sektora; w testbenchu model rdzenia ([18.05](18.05-pamiec-flash-uzytkownika-w-max-10-ufm.md)).
- **`secded_koder`, `secded_dekoder`** — kod SECDED 32 + 7 bitów ([18.06](18.06-ecc-i-ochrona-danych-w-pamieci.md)).

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche w trzech językach (`vhdl/`, `verilog/`, `sv/`), uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)); `hdl/dane/` — tablica sinusa w formatach `.hex`, `.mem`, `.mif` i generujący ją [gen_sinus.py](hdl/dane/gen_sinus.py) (pliki są kopiowane do katalogu symulacji).
- [pamieci/](pamieci/) — [wnioskowanie.py](pamieci/wnioskowanie.py): synteza Yosysem (`synth_ecp5`) poprawnych wzorców, ROM z atrybutem [rom_blok.v](pamieci/rom_blok.v) i złych wzorców z [zle_wzorce.v](pamieci/zle_wzorce.v) (odczyt asynchroniczny, reset zawartości, trzy porty odczytu) z liczbą bloków pamięci, przerzutników i LUT ([18.01](18.01-bloki-pamieci-tryby-jedno-i-dwuportowe-odczyt.md)).
- [deca/pamieci/](deca/pamieci/) — „oddychające” diody: ROM sinusa w domenie 50 MHz, tablica jasności w `ram_sdp` przenoszona do domeny 10 MHz, PWM; `make raporty` zapisuje *RAM Summary* do `raporty/pamieci.txt`.
- [deca/ufm/](deca/ufm/) — licznik naciśnięć zapamiętany w UFM; rdzeń `ufm_flash` generuje się raz w Quartusie ([instrukcja](deca/ufm/README.md)).
- Projekty DECA: `deca_top` w trzech językach, `.sdc` i `utworz_projekt.tcl` z przypisaniami pinów z [plytka-deca/deca_piny.tcl](../../plytka-deca/deca_piny.tcl) ([opis płytki](../../plytka-deca/README.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).
