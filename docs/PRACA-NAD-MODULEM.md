# Praca nad modułem — instrukcja dla Claude

Zwięzły opis procesu, którym powstają moduły kursu. Nowa sesja czyta ten plik zamiast historii poprzednich czatów.
Wzór gotowego modułu: `modules/19-arytmetyka/` i `modules/20-interfejsy-szeregowe/`.

## Zakres jednego modułu

- 6 tematów zgodnie z tabelą w `README.md` modułu (nazwy plików już istnieją w szkielecie).
- Kod: VHDL, Verilog, SystemVerilog (SV generowany z Verilogu: `python3 tools/v2sv.py hdl/verilog hdl/sv`).
- Testbenche samosprawdzające (`tb_*`, wypisują `PASS` / `FAIL: n bledow`), po jednym na temat albo wspólne.
- DECA: **1–2 projekty na moduł** (nie więcej), tylko gdy temat ma sens na płytce.
- Teksty po polsku, źródła wyłącznie anglojęzyczne. Liczby w tekstach z symulacji i syntezy w CI, nie z pamięci.

## Szablon tematu

Patrz [SZABLON-TEMATU.md](SZABLON-TEMATU.md) i dowolny temat modułu 19/20. Kolejność sekcji:
nagłówek (Moduł · Kod · DECA `🛠️ tak`/`—` · Status `✅ pełny`), „Czytaj”, nawigacja `← [prev] · [spis modułu](README.md) · [next] →`
(pierwszy `← ·`, ostatni kończy `· →`), znaczniki `<!-- plik: ścieżka -->`, potem: Po co to jest; Intuicja; Teoria;
Schemat i przebiegi; Kod: VHDL / Verilog / SystemVerilog; Co powstaje po syntezie; Weryfikacja; Uruchomienie
(+ `### Na płytce DECA`); Reguły i liczby do zapamiętania (tabela); Typowe pułapki; Pytania rekrutacyjne
(`<details><summary>Odpowiedź</summary>`); Zadania (z **Kryterium zaliczenia:**); Źródła.

## README modułu i główny README

- `**Status:** ✅ pełny`, w tabeli tematów kolumna 5 `✅`, w „Postęp” `- [x]`; 🛠️ w oznaczeniach, jeśli są projekty DECA.
- Sekcje „Układy w module” i „Kod w module” przed „## Powtórka” (wzór: moduł 20).
- Wiersz w głównym `README.md`: `🔲 szkielet` → `✅ pełny`.

## Narzędzia (lokalnie nie ma symulatorów — wszystko sprawdza CI)

- `tools/run_hdl_tests.py <moduł>` — testbenche (Icarus `-g2005`, Verilator dla SV, GHDL `--std=08`), kopiuje `hdl/dane`, kompiluje topy DECA.
- `tools/lint_hdl.py` — `verilator --lint-only -Wall`, tryb ścisły: localparamy z jawną szerokością, pragmy `lint_off` dla celowych WIDTHTRUNC/UNUSEDSIGNAL.
- `tools/synteza_yosys.py` — LUT4/FF do sekcji „Co powstaje po syntezie”.
- Przed commitem: `python3 tools/zbierz.py && python3 tools/check_links.py && rm -rf _site && python3 tools/build_site.py && mkdocs build --strict -q -f _site/mkdocs.yml`.

## Próby w CI (oszczędnie: celem są 2–3 rundy)

1. `git checkout probe-sv && git reset --hard main` (pliki nieśledzone: `git stash -u` / `stash pop`).
2. `.github/workflows/probe.yml` z gałęzi `probe-sv` — zamień ścieżkę modułu (`sed`). Kroki: testy, lint, synteza, wydruk wyników tb.
3. `git push -f origin probe-sv`; log: `gh run view $rid -R kanthakdominik/FPGA --log | sed -E 's/^[^\t]*\t[^\t]*\t[0-9TZ:.-]+ //' > /tmp/log` i **grep tylko po `FAIL|Error|%Warning|zaliczonych|Komunikat|LUT4`** — nie czytać całych logów.
4. Na `main`: `git checkout probe-sv -- modules/NN-... README.md rozmowa-kwalifikacyjna/pytania.md`, `git reset`, `git add -A`, commit z trailerami sesji; **nigdy nie przenosić probe.yml**. Sprawdzić zadania CI: `gh api repos/kanthakdominik/FPGA/actions/runs/$rid/jobs`.

## Pułapki, które już kosztowały rundy CI

- VHDL nie rozróżnia wielkości liter: `NS`/`ns`, `us`, `ms` (jednostki czasu!), `DZ`/`dz`, `aw`/`AW`; brak `_` na końcu nazwy.
- VHDL-2008: brak wyrażeń warunkowych wewnątrz wyrażeń (to VHDL-2019) — funkcja albo współbieżne `when`; sekwencyjne `x <= a when c else b;` jest OK. Brak zmiennych dzielonych; agregaty bez nie-statycznych wyborów; napisy w `string` tylko ASCII.
- Dwa procesy sterujące tym samym elementem tablicy sygnałów (np. w `generate`) = wiele sterowników — osobne sygnały.
- Quartus nie czyta plików przez `textio` w syntezie: tablice VHDL liczyć funkcją przy elaboracji albo `.mif` + `ram_init_file`.
- SV z `v2sv.py`: tablice sterowane z portów instancji muszą zostać `wire`; brak `logic x = wyrażenie` (to jednorazowa inicjalizacja).
- Lint ścisły: porównania z parametrami przez typowane localparamy; `{30'd0, ...}` przy domyślnych parametrach szerszych niż wartość.
- Testbench: oczekiwane wartości liczyć modelem (Python lub w tb), wartości testowe dawać z dala od granic zaokrąglenia.
- DECA: projekty nie są testowane w Quartusie (tylko kompilacja w symulatorach) — zaznaczać w podsumowaniu.

## Prywatność

Adres e-mail właściciela repozytorium nie trafia do treści ani na zewnątrz.
