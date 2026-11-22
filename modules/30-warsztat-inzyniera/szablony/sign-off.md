# Lista sign-off wydania bitstreamu — szablon

Do [30.04](../30.04-praca-w-zespole-przeglady-kodu-standardy-i-sign.md). Wydanie (tag w repozytorium) powstaje dopiero, gdy wszystkie punkty są spełnione albo mają zatwierdzone odstępstwo (*waiver*) z uzasadnieniem i podpisem.

| Pole | Wartość |
|---|---|
| Projekt / wersja | … / vX.Y.Z (tag) |
| Commit | pełny skrót SHA |
| Narzędzia | Quartus … / Vivado …, symulatory …, wersje IP |
| Układ i płytka | …, rewizja płytki |

## Funkcja

- [ ] Regresja symulacyjna: wszystkie testy PASS, liczba testów i ziarna zapisane; pokrycie funkcjonalne ≥ cel.
- [ ] Testy na sprzęcie: protokół testów z wynikami dla tej wersji bitstreamu.
- [ ] Lista znanych błędów i ograniczeń zaktualizowana.

## Czas

- [ ] Wszystkie ścieżki z ograniczeniami: setup i hold dodatnie we wszystkich modelach (narożnikach) temperatury i napięcia.
- [ ] Brak ścieżek bez ograniczeń (*unconstrained*); każdy `set_false_path` / `set_max_delay` przejrzany i uzasadniony.
- [ ] Raport CDC: każde przejście między domenami rozpoznane jako zsynchronizowane albo wyjaśnione.
- [ ] Ograniczenia I/O odpowiadają arkuszom danych układów na płytce.

## Implementacja

- [ ] Ostrzeżenia krytyczne narzędzia: zero albo każde z odstępstwem.
- [ ] Wykorzystanie zasobów i zapas (np. < 80 % logiki dla przyszłych zmian) zapisane.
- [ ] Przypisania pinów, standardy I/O, prądy i terminacje zgodne ze schematem płytki (przegląd z projektantem płytki).
- [ ] Szacunek mocy i temperatury złącza w budżecie.

## Konfiguracja i wydanie

- [ ] Bitstream zbudowany przez CI z czystego repozytorium tym tagiem (powtarzalność: ponowna kompilacja daje ten sam wynik czasowy).
- [ ] Wersja i skrót commita wbudowane w rejestr wersji, odczytywalne w działającym układzie.
- [ ] Pliki programowania (`.sof`/`.pof`, `.bit`/`.mcs`), raporty i sumy SHA-256 zarchiwizowane.
- [ ] Ustawienia bezpieczeństwa (szyfrowanie, blokada JTAG, odczytu) zgodne z wymaganiami produktu ([29.03](../../29-konfiguracja-niezawodnosc/29.03-szyfrowanie-i-ochrona-bitstreamu.md)).

## Podpisy

| Rola | Imię i nazwisko | Data | Decyzja |
|---|---|---|---|
| Projektant | | | |
| Weryfikacja | | | |
| Prowadzący projekt | | | |
