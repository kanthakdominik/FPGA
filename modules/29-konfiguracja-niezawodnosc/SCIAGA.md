# Ściąga — 29 — Konfiguracja, bezpieczeństwo i niezawodność

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [29.01 — Tryby konfiguracji i pamięci konfiguracyjne](29.01-tryby-konfiguracji-i-pamieci-konfiguracyjne.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| SRAM — ładowanie przy każdym starcie; flash/antifuse — od razu gotowe, konfiguracja odporna na SEU | wybór technologii |
| MAX 10: CRAM to SRAM, ładowany z wewnętrznego CFM; schematy tylko JTAG i wewnętrzny | MAX 10, DECA |
| Master (AS/SPI) — układ czyta sam; slave (PS, SelectMAP/FPP) — host podaje dane i wybiera obraz | wybór trybu |
| Etapy: POR → czyszczenie (`nSTATUS`/`INIT_B` = 0) → konfiguracja (CRC ramek) → inicjalizacja → `DONE` = 1 | każdy układ SRAM |
| t ≈ bity / (szerokość × f): 30 Mb przy ×4 i 50 MHz → 0,15 s | wymagany czas startu |
| W czasie konfiguracji wyjścia w stanie Z — stan krytycznych sygnałów ustala rezystor zewnętrzny | projekt płytki |
| `nCONFIG`/`PROGRAM_B` = 0 — rekonfiguracja od początku | reset układu |

## [29.02 — Podwójny obraz i zdalna aktualizacja w MAX 10](29.02-podwojny-obraz-i-zdalna-aktualizacja-w-max-10.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Nowy obraz zawsze do obszaru, z którego układ nie startuje; obrazu złotego nie nadpisuj | każda aktualizacja w terenie |
| Kolejność: zapis → CRC/podpis z odczytu flasha → przełączenie → licznik nadzorujący | bezpieczna aktualizacja |
| MAX 10: tryb Dual Compressed Images, CFM0 + CFM1; powrót do drugiego obrazu po błędzie CRC lub wygaśnięciu licznika | MAX 10 |
| Dual Configuration IP: offset 1 = {config_sel, overwrite}, offset 0 bit 0 = rekonfiguracja, bit 1 = zeruj licznik | sterowanie z logiki |
| `busy` ≤ 531 taktów po zapisie/odczycie; zapisy w tym czasie ignorowane (poza zerowaniem licznika) | sekwencja zapisów |
| CRC-32(„123456789”) = 0xCBF43926; wielomian odbity 0xEDB88320, start 0xFFFFFFFF, wynik negowany | test CRC |
| CRC wykrywa przypadkowe błędy, nie celową podmianę — do tego podpis | ochrona obrazu |

## [29.03 — Szyfrowanie i ochrona bitstreamu](29.03-szyfrowanie-i-ochrona-bitstreamu.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Szyfrowanie = poufność; uwierzytelnianie = autentyczność i integralność — potrzebne oba | każdy obraz w terenie |
| MAX 10: AES-128, klucz w wewnętrznym flashu (`.ekp`), JTAG Secure, Verify Protect, Chip ID; brak uwierzytelniania | MAX 10, DECA |
| 7 Series: AES-256-CBC + HMAC-SHA-256; UltraScale: AES-256-GCM, RSA-2048; Stratix 10/Agilex: ECDSA w SDM | porównanie rodzin |
| BBRAM — kasowalny, wymaga baterii; eFUSE — trwały, jednorazowy; PUF — klucz nie leży jawnie | wybór pamięci klucza |
| Uwierzytelnij przed użyciem danych (lekcja Starbleed) | projekt protokołu |
| Podpis asymetryczny: klucz prywatny poza urządzeniem, publiczny (lub skrót) w układzie | aktualizacja zdalna |
| Licznik nieudanych prób + klucz sesyjny — ochrona przed DPA | układy z szyfrowaniem |

## [29.04 — Promieniowanie i SEU: TMR, scrubbing i ECC](29.04-promieniowanie-i-seu-tmr-scrubbing-i-ecc.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| FIT = błędy na 10⁹ h; częstość = FIT/Mb × Mb bitów istotnych; flota mnoży wynik przez liczbę urządzeń | szacowanie SEU |
| Strumień odniesienia: ok. 13 n/(cm²·h) > 10 MeV, poziom morza; samolot — kilkaset razy więcej | otoczenie |
| W FPGA SRAM CRAM dominuje; flash/antifuse — konfiguracja odporna | wybór układu |
| MAX 10: Error Detection CRC → `CRC_ERROR`, naprawa = rekonfiguracja; większe rodziny poprawiają ramki w działaniu | CRAM |
| TMR: y = ab + ac + bc; z resynchronizacją zawodzi dopiero przy 2 błędach w jednym takcie | logika krytyczna |
| Synteza scala kopie — `preserve`/`dont_merge`, `DONT_TOUCH`, `syn_preserve`; sprawdź raport | każdy TMR |
| SECDED (39,32): poprawia 1, wykrywa 2; bez czyszczenia błędy się kumulują | pamięci |
| Zapis zwrotny czyszczenia blokowany, gdy użytkownik zapisał ten adres w międzyczasie | scrubber |
| Ochronę sprawdza się wstrzykiwaniem: symulacja → emulacja w CRAM → wiązka | weryfikacja |

## [29.05 — Bezpieczeństwo funkcjonalne: DO-254, IEC 61508, ISO 26262](29.05-bezpieczenstwo-funkcjonalne-do-254-iec-61508.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Błędy systematyczne → proces; awarie przypadkowe → architektura i metryki | każdy projekt bezpieczeństwa |
| DO-254: DAL A–E; PHAC na początek, HAS na koniec; FAA AC 20-152A (2022) | lotnictwo |
| IEC 61508: SIL 1–4; część 2, załącznik F — techniki dla ASIC/FPGA | przemysł |
| ISO 26262: ASIL A–D; SPFM ≥ 90/97/99 %, LFM ≥ 60/80/90 %, PMHF < 100/100/10 FIT (B/C/D) | motoryzacja |
| Śledzenie w obie strony: wymaganie ↔ kod ↔ test; kod bez wymagania — do usunięcia lub uzasadnienia | weryfikacja |
| Pokrycie kodu szuka luk w wymaganiach i testach, nie zastępuje testów do wymagań | weryfikacja |
| Narzędzie bez niezależnej kontroli wyniku → ocena/kwalifikacja; synteza zwykle sprawdzana testami na sprzęcie | narzędzia |
| Mechanizm diagnostyczny też ulega awarii — test diagnostyki (LFM) | architektura |
