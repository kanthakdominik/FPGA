# Szablon tematu

Każdy plik tematu w `modules/NN-nazwa/` ma ten sam układ. Ten dokument opisuje, co powinno się znaleźć w każdej sekcji, żeby moduły były spójne niezależnie od tego, kiedy zostały napisane.

[← README](../README.md)

## Nagłówek

```markdown
# 07.04 — Liczniki, dzielniki i clock enable

> **Moduł:** [07 — Kodowanie pod syntezę](README.md) · **Kod:** VHDL · Verilog · SystemVerilog · **DECA:** 🛠️ tak · **Status:** ✅ pełny
>
> **Czytaj:**
>
> - P. Chu, *FPGA Prototyping by SystemVerilog Examples*, rozdz. 4 (s. …)
> - Altera, *Quartus Prime Standard Edition User Guide: Design Recommendations*, rozdz. 2.6 — [link](…)
> - ZipCPU — [Building a simple counter](…)

← [07.03](...) · [spis modułu](README.md) · [07.05](...) →
```

Pole **Kod** mówi, w jakich językach jest kod tematu: trzy języki HDL, sam SystemVerilog (weryfikacja), Python lub inne (cocotb, HLS) albo „—”. Pole **DECA** mówi, czy temat ma implementację na płytce.

## Sekcje

| Sekcja | Zawartość | Wskazówki |
|--------|-----------|-----------|
| **Po co to jest** | 2–4 zdania: gdzie to spotkasz w projekcie i na rozmowie kwalifikacyjnej | Konkretnie: „bez tego nie zamkniesz timingu w module 16” |
| **Intuicja** | Wyjaśnienie bez kodu, z analogią albo rysunkiem | Krótkie zdania. Nowe słowo wyjaśnione przy pierwszym użyciu albo podlinkowane do [słowniczka](../SLOWNICZEK.md) |
| **Teoria** | Pojęcia, zależności, wzory razem z warunkami stosowania | Terminy angielskie podawaj w nawiasie przy pierwszym użyciu: „zapas (*slack*)” |
| **Schemat i przebiegi** | Schemat blokowy (Mermaid albo SVG z `assets/`), diagram czasowy | Diagramy czasowe pisz w WaveDrom i zapisuj jako SVG razem z plikiem `.json` źródła |
| **Kod: VHDL / Verilog / SystemVerilog** | Ten sam układ w trzech językach | Pełne pliki w `hdl/`, w tekście najważniejszy fragment i link do pliku. Różnice między językami opisz pod kodem, a nie w komentarzach |
| **Co powstaje po syntezie** | Schemat RTL lub technologiczny, zużycie zasobów (LE, M9K, mnożarki), uwagi z raportu | Wyniki z Quartusa dla MAX 10; tam, gdzie to ciekawe, porównanie z Yosysem |
| **Weryfikacja** | Opis testbencha: co sprawdza i jak, polecenie uruchomienia | Testbench samosprawdzający, wypisuje `PASS` lub `FAIL` ([zasady](STYL-KODU.md#testbenche)) |
| **Na płytce DECA** | Moduł nadrzędny, użyte piny i peryferia, jak sprawdzić działanie | Projekt w `deca/`, wspólne piny z [plytka-deca/](../plytka-deca/README.md) |
| **Reguły i liczby do zapamiętania** | Tabela: reguła lub wartość · kiedy obowiązuje | Sekcję przenosi do `SCIAGA.md` skrypt `tools/zbierz.py` |
| **Typowe pułapki** | 3–6 punktów: błąd, objaw, dlaczego tak się dzieje, jak naprawić | ⚠️ przy błędach, które przechodzą symulację, a psują sprzęt |
| **Pytania rekrutacyjne** | 3–8 pytań w stylu rozmowy technicznej | Odpowiedź pod `<details>`: tyle, ile da się powiedzieć na głos w minutę. `tools/zbierz.py` zbiera je do [rozmowa-kwalifikacyjna/pytania.md](../rozmowa-kwalifikacyjna/pytania.md) |
| **Zadania** | Zadania obliczeniowe, „znajdź błąd w kodzie”, zadania projektowe | Odpowiedzi pod `<details>`; zadania projektowe z kryterium zaliczenia |
| **Źródła** | Konkretne rozdziały, strony, sekcje dokumentacji | Wyłącznie anglojęzyczne, z [RESOURCES.md](../RESOURCES.md) |

## Format pytań i odpowiedzi

```markdown
1. **Czym różni się reset synchroniczny od asynchronicznego i który wybierzesz w MAX 10?**

<details>
<summary>Odpowiedź</summary>

Reset synchroniczny działa tylko na zboczu zegara i jest zwykłym wejściem logiki danych; reset asynchroniczny działa natychmiast przez dedykowane wejście przerzutnika. …
</details>
```

## Format kodu w tekście

Fragment kodu zawsze z nazwą języka i linkiem do pełnego pliku:

````markdown
```vhdl
process (clk)
begin
  if rising_edge(clk) then
    ...
```

Pełny plik: [hdl/vhdl/licznik.vhd](hdl/vhdl/licznik.vhd) · testbench: [tb_licznik.vhd](hdl/vhdl/tb_licznik.vhd)
````

## Kod na stronie kursu

Strona (GitHub Pages) może wstawić całe pliki kodu w miejsce znacznika — na GitHubie znacznik jest niewidoczny, więc pod nim zawsze zostaw zwykły odnośnik:

```markdown
<!-- plik: hdl/vhdl/blink.vhd -->
Pełny plik: [hdl/vhdl/blink.vhd](hdl/vhdl/blink.vhd)

<!-- zakladki: deca/blink/deca_top.vhd | deca/blink/deca_top.v | deca/blink/deca_top.sv -->
Pliki: [deca_top.vhd](deca/blink/deca_top.vhd) · [deca_top.v](deca/blink/deca_top.v) · [deca_top.sv](deca/blink/deca_top.sv)
```

- `plik:` — zwijany blok z całym plikiem (pod fragmentem omawianym w tekście),
- `zakladki:` — ten sam układ w kilku językach, przełączany zakładkami VHDL / Verilog / SystemVerilog.

Ścieżki są względne do pliku tematu. Znacznik do nieistniejącego pliku zatrzymuje budowę strony.

## Po wypełnieniu tematu

```bash
python3 tools/zbierz.py           # ściąga modułu i zbiór pytań rekrutacyjnych
python3 tools/run_hdl_tests.py    # testbenche
python3 tools/check_links.py      # linki
```

## Status tematu i modułu

- 🔲 szkielet — tylko nagłówki.
- 🟡 w trakcie — część sekcji wypełniona.
- ✅ pełny — wszystkie sekcje, kod w trzech językach (jeśli dotyczy) z przechodzącymi testbenchami, projekt na DECA (jeśli dotyczy), pytania z odpowiedziami, źródła.

Po wypełnieniu tematu zmień status w nagłówku pliku i w tabeli tematów w `README.md` modułu i uruchom `tools/zbierz.py` (ściąga i pytania aktualizują się same). Gdy cały moduł jest gotowy — zmień status w mapie modułów w głównym `README.md`.
