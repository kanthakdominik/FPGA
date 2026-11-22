# Specyfikacja bloku: `<nazwa>` — szablon

Szablon do [30.01](../30.01-specyfikacja-i-dokumentacja-diagramy-blokowe-i.md). Skopiuj go, usuń wskazówki w nawiasach i wypełnij każdą sekcję albo wpisz „nie dotyczy” z uzasadnieniem.

| Pole | Wartość |
|---|---|
| Wersja dokumentu | 0.1 (zmiany — tabela na końcu) |
| Autor / recenzent | … / … |
| Stan | szkic · do przeglądu · zatwierdzona |
| Powiązane wymagania | REQ-… (identyfikatory z wymagań systemu) |

## 1. Cel i zakres

(Co blok robi, w jednym akapicie. Czego **nie** robi — granice odpowiedzialności, np. „nie sprawdza CRC, robi to …”.)

## 2. Wymagania

| ID | Wymaganie („blok musi …”) | Weryfikacja (test, analiza, przegląd) |
|---|---|---|
| BLK-001 | … | tb_…: przypadek … |

(Każde wymaganie jednoznaczne, mierzalne, z jednym sposobem weryfikacji. Liczby z jednostkami i tolerancją.)

## 3. Schemat blokowy

(Wejścia z lewej, wyjścia z prawej, domeny zegara obwiedzione, rejestry na granicach zaznaczone. Źródło diagramu jako tekst w repozytorium: ASCII, WaveDrom, Mermaid, draw.io w formacie tekstowym.)

## 4. Interfejsy

| Port | Kierunek | Szerokość | Domena zegara | Opis, protokół, stan po resecie |
|---|---|---|---|---|
| clk | in | 1 | — | … MHz |

Protokoły standardowe: nazwa i wersja specyfikacji (Avalon-MM z readLatency = 1, AXI4-Stream bez TKEEP…), odstępstwa wypisane jawnie.

## 5. Zegary i resety

(Częstotliwości, relacje między zegarami, przejścia między domenami i ich synchronizatory; reset: synchroniczny/asynchroniczny, poziom aktywny, czas trwania, stan wyjść w czasie resetu.)

## 6. Mapa rejestrów

(Generowana z opisu — patrz [rejestry/](../rejestry/pwm_avl.json) — tu tylko odnośnik do wygenerowanego `*_regs.md` i zasady: dostęp, bity zarezerwowane, efekty uboczne odczytu.)

## 7. Działanie i przebiegi czasowe

(Automaty stanów, opóźnienia w taktach, przepustowość, zachowanie przy przepełnieniu i błędach. Diagramy czasowe WaveDrom z wersją tekstową.)

## 8. Parametry i konfiguracja

| Parametr | Zakres | Domyślnie | Wpływ |
|---|---|---|---|

## 9. Wydajność i zasoby

(Docelowe fmax, przepustowość, opóźnienie; LUT/FF/RAM/DSP — z syntezy, nie z głowy.)

## 10. Obsługa błędów i bezpieczeństwo

(Co się dzieje przy niepoprawnych danych, przepełnieniu, utracie zegara; liczniki błędów, przerwania; ochrona przed SEU, jeśli wymagana.)

## 11. Weryfikacja

(Plan: testy kierunkowe i losowe, pokrycie funkcjonalne, asercje, weryfikacja formalna; kryterium zakończenia.)

## 12. Otwarte kwestie

| # | Pytanie | Właściciel | Termin |
|---|---|---|---|

## Historia zmian

| Wersja | Data | Autor | Zmiana |
|---|---|---|---|
