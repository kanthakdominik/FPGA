# Lista kontrolna przeglądu kodu RTL — szablon

Do [30.04](../30.04-praca-w-zespole-przeglady-kodu-standardy-i-sign.md). Przegląd zaczyna się **po** zielonym CI (testy, lint, synteza) — automaty sprawdzają to, co da się sprawdzić automatycznie, człowiek resztę. Każdy punkt: ✅ / ❌ (z komentarzem w przeglądzie) / n.d.

## Zgodność ze specyfikacją

- [ ] Każde wymaganie z [specyfikacji](specyfikacja-bloku.md) ma implementację i test; nie ma funkcji bez wymagania.
- [ ] Interfejsy zgodne z protokołem (nazwy, opóźnienia, zachowanie przy `ready = 0`, reset).
- [ ] Parametry mają sprawdzane zakresy (asercja przy elaboracji lub komentarz z ograniczeniem).

## Zegary, resety, CDC

- [ ] Każdy sygnał przechodzący między domenami ma synchronizator odpowiedni do rodzaju (bit, impuls, magistrala — Gray/FIFO/handshake) i ograniczenie w `.sdc`.
- [ ] Brak zegarów z logiki, bramkowania zegara poza dedykowanymi blokami, zatrzasków.
- [ ] Reset: zwolnienie synchroniczne w każdej domenie; rejestry danych bez resetu tam, gdzie nie jest potrzebny.

## Logika

- [ ] Automaty: wszystkie stany osiągalne i wychodzące, stan niedozwolony prowadzi do bezpiecznego, wyjścia zdefiniowane w każdym stanie.
- [ ] Szerokości: brak niejawnych obcięć i rozszerzeń (lint czysty albo pragma z uzasadnieniem); arytmetyka ze znakiem jawnie `signed`.
- [ ] Liczniki i wskaźniki: zachowanie na granicy (przepełnienie, zawinięcie, pełny/pusty).
- [ ] Brak pętli kombinacyjnych, brak czułości na kolejność procesów.

## Czytelność i utrzymanie

- [ ] Nazwy zgodne ze [standardem kodowania](../../../docs/STYL-KODU.md); jednostki i domeny w nazwach tam, gdzie to pomaga (`_ms`, `_clk2`).
- [ ] Komentarz nagłówka: co blok robi, opóźnienie, ograniczenia. Komentarze mówią „dlaczego”, nie „co”.
- [ ] Stałe magiczne zastąpione parametrami lub stałymi z wygenerowanej mapy rejestrów.

## Weryfikacja

- [ ] Testbench samosprawdzający się (PASS/FAIL), bez ręcznego oglądania przebiegów.
- [ ] Przypadki brzegowe i błędne dane, nie tylko „szczęśliwa ścieżka”; ziarno losowe wypisywane.
- [ ] Pokrycie kodu i funkcjonalne przejrzane — luki wyjaśnione.

## Implementacja

- [ ] Raport syntezy: brak nieoczekiwanych zatrzasków, usuniętej logiki, wywnioskowanych pamięci w przerzutnikach.
- [ ] Zasoby i fmax w budżecie; ostrzeżenia syntezy przejrzane.
