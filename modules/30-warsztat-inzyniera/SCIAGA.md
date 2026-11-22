# Ściąga — 30 — Metodyka i warsztat inżyniera FPGA

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [30.01 — Specyfikacja i dokumentacja: diagramy blokowe i czasowe (WaveDrom)](30.01-specyfikacja-i-dokumentacja-diagramy-blokowe-i.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Specyfikacja przed kodem; wymaganie: jednoznaczne, mierzalne, z ID i sposobem weryfikacji | każdy blok |
| Tabela portów: kierunek, szerokość, domena zegara, stan po resecie | interfejsy |
| Jedno źródło mapy rejestrów (SystemRDL, IP-XACT, JSON/YAML) → RTL, C, testy, dokumentacja | peryferia z rejestrami |
| Generator waliduje: offsety, nakładanie pól, zakres resetu, dostęp, nazwy bez rozróżniania wielkości liter | opis rejestrów |
| Pliki wygenerowane w repozytorium tylko z kontrolą aktualności w CI | kompromis wygody |
| Diagramy jako tekst (WaveDrom, Mermaid, ASCII) — w repozytorium, w diffie, w przeglądzie | dokumentacja |
| Bity zarezerwowane: zapis ignorowany, odczyt 0; W1C — zapis 1 kasuje | mapa rejestrów |

## [30.02 — Zarządzanie rdzeniami IP producenta i własnymi](30.02-zarzadzanie-rdzeniami-ip-producenta-i-wlasnymi.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| IP producenta: w repozytorium plik parametrów (`.ip`, `.qsys`, `.xci`) albo skrypt Tcl; wygenerowany RTL — nie | Quartus, Vivado |
| Wersja narzędzia = część projektu; aktualizacja narzędzia — osobna gałąź, regeneracja IP, pełna regresja | zmiana wersji |
| Własne IP: repozytorium, testy, specyfikacja, `.core`/IP-XACT, CI, wersje MAJOR.MINOR.PATCH | blok wielokrotnego użytku |
| Odwołanie do wersji, nie kopia katalogu | współdzielenie bloków |
| FuseSoC: `dostawca:biblioteka:nazwa:wersja`, zestawy plików, `depend`, cele → Edalize → narzędzie | menedżer rdzeni HDL |
| Licencja i pochodzenie każdego IP w wykazie (jak SBOM) | produkt |
| Proste bloki (FIFO, RAM) — przenośny RTL; IP producenta tam, gdzie konieczne | przenośność |

## [30.03 — Kontrola wersji: co commitować, a co generować](30.03-kontrola-wersji-co-commitowac-a-co-generowac.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| W repozytorium to, z czego zbudujesz wszystko jednym poleceniem na czystej maszynie | każdy projekt |
| Bazy kompilacji, raporty, bitstreamy, wygenerowane IP — poza repozytorium; wydania archiwizuje CI | Quartus, Vivado |
| Projekt tworzony skryptem Tcl > `.qsf`/`.xpr` edytowany w GUI | praca zespołowa, CI |
| IP: plik parametrów lub skrypt Tcl, nie wygenerowany RTL | IP producenta |
| Rejestr wersji: numer + skrót commita + znacznik dirty, odczytywalny z układu | każdy produkt |
| Tag na wydanie + przypięta wersja narzędzia = odtwarzalny bitstream | wydania |
| Krótkie gałęzie; pliki XML narzędzi źle się scalają | zespół |

## [30.04 — Praca w zespole: przeglądy kodu, standardy i sign-off](30.04-praca-w-zespole-przeglady-kodu-standardy-i-sign.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Przegląd po zielonym CI; człowiek ocenia to, czego nie oceni automat | każdy przegląd |
| Małe zmiany, osobno refaktoryzacja i funkcja; skuteczność spada przy dużych zmianach | przegląd kodu |
| Przegląd projektu (architektura, interfejsy, budżety) przed RTL | nowy blok |
| Sign-off: regresja PASS, czas dodatni we wszystkich narożnikach, brak ścieżek bez ograniczeń, CDC, ostrzeżenia, wersja w układzie | wydanie bitstreamu |
| Każde odstępstwo na piśmie: uzasadnienie i osoba odpowiedzialna | waiver |
| Nowe ostrzeżenie narzędzia zatrzymuje wydanie, dopóki nie zostanie wyjaśnione | raporty |
| Piny i standardy I/O przeglądane z projektantem płytki przed zamówieniem PCB | nowa płytka |

## [30.05 — Kariera w FPGA: role, branże i ścieżki rozwoju](30.05-kariera-w-fpga-role-branze-i-sciezki-rozwoju.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Role: design, verification, architect, DSP/HLS, SoC, prototypowanie ASIC, high-speed, FAE, EDA | wybór kierunku |
| 87 % projektów FPGA z nietrywialnym błędem w produkcji (Wilson 2024) — weryfikacja to osobna specjalizacja | argument dla weryfikacji |
| Umiejętności przenośne (HDL, CDC, STA, weryfikacja) > biegłość w jednym narzędziu | rozwój |
| Portfolio: 2–3 projekty doprowadzone do końca, z testami, CI, raportami i sprzętem | rekrutacja |
| Rozmowa techniczna: podstawy cyfrowe, CDC, STA, FIFO, automaty, potokowanie + „dlaczego” | przygotowanie |
| VHDL — Europa, lotnictwo, obronność; (System)Verilog — USA, półprzewodniki, weryfikacja | wybór języka |
