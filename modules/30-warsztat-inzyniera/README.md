# 30 — Metodyka i warsztat inżyniera FPGA

> **Część VII** · **Oznaczenia:** 💼 · **Ścieżki:** RTL, weryfikacja · **Szacowany czas:** ok. 8 h

## Po co ten moduł

Umiejętności pozatechniczne, które odróżniają inżyniera od hobbysty: specyfikacja i dokumentacja, zarządzanie rdzeniami IP, kontrola wersji, przeglądy kodu i sign-off. Moduł opisuje też role i ścieżki kariery w branży.

## Wymagane wcześniej

[09 — Symulacja i testbenche](../09-symulacja-i-testbench/README.md), [14 — Statyczna analiza czasowa (STA)](../14-analiza-czasowa/README.md)

## Tematy

| # | Temat | Kod | DECA |
|---|-------|-----|------|
| 30.01 | [Specyfikacja i dokumentacja: diagramy blokowe i czasowe (WaveDrom)](30.01-specyfikacja-i-dokumentacja-diagramy-blokowe-i.md) | Python / inne | — |
| 30.02 | [Zarządzanie rdzeniami IP producenta i własnymi](30.02-zarzadzanie-rdzeniami-ip-producenta-i-wlasnymi.md) | Python / inne | — |
| 30.03 | [Kontrola wersji: co commitować, a co generować](30.03-kontrola-wersji-co-commitowac-a-co-generowac.md) | — | — |
| 30.04 | [Praca w zespole: przeglądy kodu, standardy i sign-off](30.04-praca-w-zespole-przeglady-kodu-standardy-i-sign.md) | — | — |
| 30.05 | [Kariera w FPGA: role, branże i ścieżki rozwoju](30.05-kariera-w-fpga-role-branze-i-sciezki-rozwoju.md) | — | — |

## Po tym module potrafisz

- napisać specyfikację bloku z diagramami blokowymi i czasowymi,
- zarządzać rdzeniami IP i ich wersjami,
- zdecydować, co trafia do repozytorium, a co jest generowane,
- prowadzić przegląd kodu i listę kontrolną sign-off,
- opisać role w branży FPGA i ścieżki rozwoju.

## Kod w module

Moduł jest metodyczny, więc zamiast nowych bloków RTL zawiera narzędzia i szablony pracy — wszystko na przykładzie peryferium `pwm_avl` z [27.03](../27-procesory-i-soc/27.03-wlasny-peryferial-z-rejestrami-i-sterownik-w-c.md) i sprawdzane w GitHub Actions skryptem [narzedzia/sprawdz.sh](narzedzia/sprawdz.sh):

- [narzedzia/rejestry.py](narzedzia/rejestry.py) — generator mapy rejestrów z jednego opisu [rejestry/pwm_avl.json](rejestry/pwm_avl.json): walidacja, pakiet VHDL, nagłówki Verilog i C, tabela Markdown, pola WaveDrom ([rejestry/wygenerowane/](rejestry/wygenerowane/pwm_avl_regs.md)); `--sprawdz` porównuje pliki z repozytorium i z ręcznym `pwm.h`; testy integracyjne [tb_pwm_regs.v](rejestry/tb_pwm_regs.v) i [tb_pwm_regs.vhd](rejestry/tb_pwm_regs.vhd) sterują `pwm_avl` tylko przez wygenerowane stałe ([30.01](30.01-specyfikacja-i-dokumentacja-diagramy-blokowe-i.md)).
- [narzedzia/wavedrom_ascii.py](narzedzia/wavedrom_ascii.py) — diagramy czasowe WaveJSON z [diagramy/](diagramy/avalon_pwm.json) jako tekst; CI pilnuje, że wstawki w tematach są aktualne ([30.01](30.01-specyfikacja-i-dokumentacja-diagramy-blokowe-i.md)).
- [pwm_avl_regs.core](pwm_avl_regs.core) i [../27-procesory-i-soc/pwm_avl.core](../27-procesory-i-soc/pwm_avl.core) — rdzenie FuseSoC z zależnością i celami `sim`, `lint` ([30.02](30.02-zarzadzanie-rdzeniami-ip-producenta-i-wlasnymi.md)).
- [szablony/](szablony/specyfikacja-bloku.md) — specyfikacja bloku, lista kontrolna przeglądu RTL, lista sign-off wydania, `.gitignore` dla Quartusa i Vivado ([30.01](30.01-specyfikacja-i-dokumentacja-diagramy-blokowe-i.md), [30.03](30.03-kontrola-wersji-co-commitowac-a-co-generowac.md), [30.04](30.04-praca-w-zespole-przeglady-kodu-standardy-i-sign.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 30.01 Specyfikacja i dokumentacja: diagramy blokowe i czasowe (WaveDrom)
- [ ] 30.02 Zarządzanie rdzeniami IP producenta i własnymi
- [ ] 30.03 Kontrola wersji: co commitować, a co generować
- [ ] 30.04 Praca w zespole: przeglądy kodu, standardy i sign-off
- [ ] 30.05 Kariera w FPGA: role, branże i ścieżki rozwoju
