# Ściąga — 25 — Audio i Ethernet

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [25.01 — I²S i kodek audio na DECA](25.01-i2s-i-kodek-audio-na-deca.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| I²S: dane zmieniane przy opadającym BCLK, próbkowane przy narastającym; MSB 1 takt po zmianie WCLK | format I²S |
| WCLK = fs; BCLK = fs × bity ramki (64 → 3,072 MHz przy 48 kHz); MCLK = 256·fs albo 512·fs | zegary audio |
| fs kodeka = MCLK / (NDAC · MDAC · DOSR) — musi równać się WCLK | konfiguracja AIC3254 |
| Słowo krótsze niż slot — wyrównane do lewej, reszta zera | długość słowa |
| AIC3254: strony rejestrów (rejestr 0), reset programowy + ≥ 1 ms, zasilanie analogowe przed wyjściami | kodek na DECA |
| Kolejność startu: zegary → reset kodeka → konfiguracja → odciszenie | każdy kodek |

## [25.02 — Przetwarzanie dźwięku w czasie rzeczywistym](25.02-przetwarzanie-dzwieku-w-czasie-rzeczywistym.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Biquad (postać I): y = b0x + b1x₁ + b2x₂ − a1y₁ − a2y₂; wyższe rzędy — kaskada sekcji 2. rzędu | filtry IIR |
| Współczynniki Q2.16 w 18 bitach (zakres ±2), akumulator ≥ szerokość iloczynu + log₂(liczba składników) | stały przecinek |
| Zaokrąglaj (+½ LSB) i nasycaj — obcięcie daje składową stałą, zawinięcie trzaski | wynik filtru |
| Takty na próbkę = f_clk / fs (12,5 MHz / 48,8 kHz = 256) — tyle mnożeń jednej mnożarki | współdzielenie |
| Echo: y = x + g·y[n−D]; pamięć D × bity; g < 1 — stabilne | efekty opóźnieniowe |
| Filtr Butterwortha 2. rzędu: −3 dB przy f0, −12 dB/oktawę dalej | weryfikacja charakterystyki |

## [25.03 — Ethernet 10/100: MII, PHY i MAC](25.03-ethernet-10-100-mii-phy-i-mac.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Ramka: 7 × 0x55, 0xD5, 6 + 6 + 2 B nagłówka, 46–1500 B danych, 4 B FCS; przerwa ≥ 12 B | Ethernet |
| Ramka bez preambuły 64–1518 B; krótsze dane uzupełniać zerami | minimalna długość |
| CRC-32: 0xEDB88320 (odbity), start 0xFFFFFFFF, negacja; „123456789” → 0xCBF43926; reszta 0xDEBB20E3 | FCS |
| MII: 4 bity, 25 MHz z PHY (100 Mb/s), młodszy półbajt pierwszy; t_SU ≥ 10 ns przy TX | interfejs PHY |
| MDIO: 32 × 1, 01, OP, PHY, REG, TA, 16 bitów; MDC ≤ 2,5 MHz; BMSR bit 2 = łącze | zarządzanie PHY |
| MAC ma 3 domeny zegarowe: TX_CLK, RX_CLK (z PHY) i zegar systemowy | CDC |

## [25.04 — Ramki Ethernet, ARP, IP i UDP w sprzęcie](25.04-ramki-ethernet-arp-ip-i-udp-w-sprzecie.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Nagłówki: Ethernet 14 B + IPv4 20 B + UDP 8 B = 42 B; dane ≤ 1472 B bez fragmentacji | UDP/IPv4 |
| Suma IP: słowa 16-bitowe z przeniesieniem cyklicznym, negacja; sprawdzenie: suma z polem = 0xFFFF | nagłówek IPv4 |
| Suma UDP w IPv4 może być 0 (wyłączona); w IPv6 obowiązkowa | sumy kontrolne |
| ARP: typ 0x0806, 28 B; zapytanie na FF…FF, odpowiedź wprost (operacja 2) | ustalanie MAC |
| Analiza w domenie RX_CLK, odpowiedź w TX_CLK — zgłoszenie bitem przełączanym, dane zatrzaśnięte wcześniej | CDC w MAC |
| UDP: bez połączenia i retransmisji — numer pakietu w danych do wykrywania strat | strumienie danych |

## [25.05 — Strumień UDP z FPGA do komputera](25.05-strumien-udp-z-fpga-do-komputera.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Na kablu: N + 66 B na datagram UDP (preambuła, nagłówki, FCS, przerwa) | przepływność |
| 100 Mb/s: 93,9 Mb/s danych przy 1024 B, 95,7 Mb/s przy 1472 B | planowanie strumienia |
| Numer pakietu w danych — wykrywanie strat i kolejności po stronie odbiorcy | UDP |
| Dane do `udp_nad` z FIFO z całym datagramem — MII nie czeka | prawdziwe źródła |
| Adres MAC lokalny: 0x02 w pierwszym bajcie; adres komputera — z ARP albo rozgłoszenie | adresowanie |
| Straty przy punkt–punkt to zwykle bufor odbiorcy, nie kabel | diagnoza |
