# 25 — Audio i Ethernet

> **Część V** · **Oznaczenia:** 🛠️ · **Ścieżki:** DECA · **Szacowany czas:** ok. 16 h

## Po co ten moduł

Dźwięk i sieć na DECA: kodek audio przez I²S, przetwarzanie dźwięku w czasie rzeczywistym, Ethernet 10/100 od warstwy fizycznej do wysyłania pakietów UDP do komputera.

## Wymagane wcześniej

[20 — Interfejsy szeregowe niskiej szybkości](../20-interfejsy-szeregowe/README.md), [21 — Magistrale i interfejsy na chipie](../21-magistrale-on-chip/README.md)

## Tematy

| # | Temat | Kod | DECA |
|---|-------|-----|------|
| 25.01 | [I²S i kodek audio na DECA](25.01-i2s-i-kodek-audio-na-deca.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 25.02 | [Przetwarzanie dźwięku w czasie rzeczywistym](25.02-przetwarzanie-dzwieku-w-czasie-rzeczywistym.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 25.03 | [Ethernet 10/100: MII, PHY i MAC](25.03-ethernet-10-100-mii-phy-i-mac.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 25.04 | [Ramki Ethernet, ARP, IP i UDP w sprzęcie](25.04-ramki-ethernet-arp-ip-i-udp-w-sprzecie.md) | VHDL · Verilog · SystemVerilog | — |
| 25.05 | [Strumień UDP z FPGA do komputera](25.05-strumien-udp-z-fpga-do-komputera.md) | VHDL · Verilog · SystemVerilog | 🛠️ |

## Po tym module potrafisz

- obsłużyć kodek audio przez I²S i I²C,
- przetwarzać próbki dźwięku w czasie rzeczywistym,
- opisać interfejs MII/RMII i współpracę MAC z PHY,
- składać i parsować ramki Ethernet, ARP, IP i UDP w sprzęcie,
- przesłać strumień danych z FPGA do komputera przez UDP.

## Układy w module

- **`i2s_master`** — master I²S: BCLK i WCLK z zegara MCLK, nadawanie i odbiór próbek 24-bitowych stereo ([25.01](25.01-i2s-i-kodek-audio-na-deca.md)).
- **`i2c_zapisy`** — zapis tablicy rejestrów przez I²C z tablicą jako parametrem i wpisami-przerwami (konfiguracja kodeka TLV320AIC3254) ([25.01](25.01-i2s-i-kodek-audio-na-deca.md)).
- **`biquad`, `echo`** — filtr IIR drugiego rzędu (Q2.16, jedna mnożarka w 5 taktach, zaokrąglenie i nasycenie) i echo z linią opóźniającą w pamięci blokowej ([25.02](25.02-przetwarzanie-dzwieku-w-czasie-rzeczywistym.md)).
- **`mii_tx`, `mii_rx`, `mdio`** — MAC Ethernet 10/100 dla MII (preambuła, uzupełnienie, CRC-32, przerwa; odbiór z kontrolą reszty CRC) i zarządzanie PHY przez MDIO ([25.03](25.03-ethernet-10-100-mii-phy-i-mac.md)).
- **`udp_nad`, `arp_odp`** — nadawca datagramów UDP/IPv4 z sumą kontrolną nagłówka i odpowiadanie na ARP w dwóch domenach zegarowych z uczeniem adresu pytającego ([25.04](25.04-ramki-ethernet-arp-ip-i-udp-w-sprzecie.md)).

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche w trzech językach (`vhdl/`, `verilog/`, `sv/`), uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)): `tb_i2s` (model kodeka jako slave I²S), `tb_kodek` (model TLV320AIC3254 ze stronami rejestrów), `tb_dzwiek` (biquad bit w bit z modelem i charakterystyka częstotliwościowa, echo), `tb_mii` (pętla nadajnik–odbiornik, FCS na linii), `tb_mdio` (model PHY), `tb_udp` (ramki pole po polu, suma IP, ARP przy dwóch zegarach).
- [deca/audio/](deca/audio/) — kodek audio DECA: wejście liniowe → biquad → echo → wyjście, wskaźnik poziomu na diodach ([25.01](25.01-i2s-i-kodek-audio-na-deca.md), [25.02](25.02-przetwarzanie-dzwieku-w-czasie-rzeczywistym.md)); [deca/udp/](deca/udp/) — PHY przez MII i MDIO, ARP i strumień datagramów UDP do komputera, z odbiornikiem [odbior_udp.py](deca/udp/odbior_udp.py) ([25.03](25.03-ethernet-10-100-mii-phy-i-mac.md)–[25.05](25.05-strumien-udp-z-fpga-do-komputera.md)); `deca_top` w trzech językach, `.sdc`, `utworz_projekt.tcl` z przypisaniami z [plytka-deca/deca_piny.tcl](../../plytka-deca/deca_piny.tcl) ([opis płytki](../../plytka-deca/README.md)).
- Lint: kod Verilog i SystemVerilog z `hdl/` przechodzi `verilator --lint-only -Wall` bez ostrzeżeń ([07.09](../07-kodowanie-pod-synteze/07.09-styl-kodu-lint-i-przeglady-verilator-verible-vsg.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 25.01 I²S i kodek audio na DECA
- [ ] 25.02 Przetwarzanie dźwięku w czasie rzeczywistym
- [ ] 25.03 Ethernet 10/100: MII, PHY i MAC
- [ ] 25.04 Ramki Ethernet, ARP, IP i UDP w sprzęcie
- [ ] 25.05 Strumień UDP z FPGA do komputera
