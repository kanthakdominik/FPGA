# 25 — Audio i Ethernet

> **Część V** · **Oznaczenia:** 🛠️ · **Ścieżki:** DECA · **Szacowany czas:** ok. 16 h · **Status:** 🔲 szkielet

## Po co ten moduł

Dźwięk i sieć na DECA: kodek audio przez I²S, przetwarzanie dźwięku w czasie rzeczywistym, Ethernet 10/100 od warstwy fizycznej do wysyłania pakietów UDP do komputera.

## Wymagane wcześniej

[20 — Interfejsy szeregowe niskiej szybkości](../20-interfejsy-szeregowe/README.md), [21 — Magistrale i interfejsy na chipie](../21-magistrale-on-chip/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 25.01 | [I²S i kodek audio na DECA](25.01-i2s-i-kodek-audio-na-deca.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 25.02 | [Przetwarzanie dźwięku w czasie rzeczywistym](25.02-przetwarzanie-dzwieku-w-czasie-rzeczywistym.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 25.03 | [Ethernet 10/100: MII, PHY i MAC](25.03-ethernet-10-100-mii-phy-i-mac.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 25.04 | [Ramki Ethernet, ARP, IP i UDP w sprzęcie](25.04-ramki-ethernet-arp-ip-i-udp-w-sprzecie.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 25.05 | [Strumień UDP z FPGA do komputera](25.05-strumien-udp-z-fpga-do-komputera.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |

## Po tym module potrafisz

- obsłużyć kodek audio przez I²S i I²C,
- przetwarzać próbki dźwięku w czasie rzeczywistym,
- opisać interfejs MII/RMII i współpracę MAC z PHY,
- składać i parsować ramki Ethernet, ARP, IP i UDP w sprzęcie,
- przesłać strumień danych z FPGA do komputera przez UDP.

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).
- `deca/` — projekty dla płytki Arrow DECA: moduł nadrzędny w trzech językach, ograniczenia czasowe (`.sdc`) i skrypt `utworz_projekt.tcl`, który tworzy projekt Quartusa z przypisaniami pinów z [plytka-deca/deca_piny.tcl](../../plytka-deca/deca_piny.tcl) ([opis płytki](../../plytka-deca/README.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 25.01 I²S i kodek audio na DECA
- [ ] 25.02 Przetwarzanie dźwięku w czasie rzeczywistym
- [ ] 25.03 Ethernet 10/100: MII, PHY i MAC
- [ ] 25.04 Ramki Ethernet, ARP, IP i UDP w sprzęcie
- [ ] 25.05 Strumień UDP z FPGA do komputera
