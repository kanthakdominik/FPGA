# Ściąga — 28 — Synteza wysokiego poziomu (HLS) i akceleracja

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [28.01 — Czym jest HLS i kiedy się opłaca](28.01-czym-jest-hls-i-kiedy-sie-oplaca.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| HLS: szeregowanie (takty) + przydział (ile jednostek) + wiązanie (kto co) + FSM | zasada działania |
| Ten sam kod + inne dyrektywy = inny układ; jakość ocenia się raportem i kosymulacją | praca z HLS |
| Bez dynamicznej pamięci i rekurencji; pętle o ograniczonej liczbie iteracji; tablice o stałym rozmiarze | kod syntezowalny |
| `static` w funkcji = rejestry trwające między wywołaniami | stan |
| `int` = 32 bity w sprzęcie; szerokości dobiera się `ap_int`/`ap_fixed` (`ac_int`/`ac_fixed`) | zasoby |
| Symulacja C — algorytm; kosymulacja C/RTL — funkcja i protokół RTL, rzeczywiste takty | weryfikacja |
| HLS do algorytmów na danych, RTL do sterowania, interfejsów i układów krytycznych czasowo | wybór |

## [28.02 — Pętle: potokowanie, rozwijanie i interwał inicjacji (II)](28.02-petle-potokowanie-rozwijanie-i-interwal.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Czas pętli ≈ głębokość + (N − 1)·II | potokowanie |
| II ≥ max(ResMII, RecMII); ResMII = ⌈użycia/jednostki⌉, RecMII = ⌈Σ opóźnień / Σ odległości⌉ w cyklu | ocena raportu |
| Pamięć blokowa: 2 porty → najwyżej 2 dostępy na takt na tablicę (bank) | ResMII |
| Akumulator float z sumatorem L-taktowym → II = L; L akumulatorów częściowych → II = 1 | sumy |
| Odczyt–zmiana–zapis pamięci w kolejnych iteracjach → RecMII 2–3; przekazanie w rejestrach + DEPENDENCE false | histogramy, tablice stanu |
| Pętle wewnątrz potokowanej rozwijają się całkowicie | zasoby |
| DEPENDENCE false bez gwarancji = błędny sprzęt; sprawdza dopiero kosymulacja | bezpieczeństwo |
| Akumulator: bity iloczynu + ⌈log₂ N⌉ | typy |

## [28.03 — Interfejsy i pamięć w HLS](28.03-interfejsy-i-pamiec-w-hls.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Skalary i sterowanie → `s_axilite`; duże tablice w DDR → `m_axi`; strumienie → `axis` | dobór interfejsu |
| Osobne `bundle` dla równoległych odczytów i zapisów | przepustowość AXI |
| Bursty: dostęp sekwencyjny, bez warunków i aliasingu; kopiuj DDR → bufor lokalny | `m_axi` |
| Pamięć blokowa: 2 porty; `cyclic` dla kolejnych elementów, `block` dla odległych, `complete` → rejestry | ARRAY_PARTITION |
| ARRAY_RESHAPE: szersze słowo zamiast wielu banków | oszczędność bloków pamięci |
| DATAFLOW: jeden producent i jeden konsument na zmienną, FIFO/ping-pong, rytm najwolniejszego etapu | potok zadań |
| `ap_ctrl_hs` (start/done), `ap_ctrl_chain` (łańcuchy), `ap_ctrl_none` (praca ciągła) | protokół bloku |

## [28.04 — Narzędzia: Vitis HLS, oneAPI i Bambu](28.04-narzedzia-vitis-hls-oneapi-i-bambu.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Etapy: symulacja C → synteza (raport) → kosymulacja → eksport/implementacja | każde narzędzie HLS |
| Vitis HLS — `ap_int`/`ap_fixed`, `#pragma HLS`; oneAPI — SYCL, `ac_int`/`ac_fixed`, atrybuty `[[intel::…]]` | dialekty |
| Szeregowanie statyczne zakłada najgorszy przypadek; dynamiczne (Dynamatic) czeka tylko przy rzeczywistej zależności | wybór podejścia |
| Raport: II i przyczyna, opóźnienie, zegar (oszacowanie!), zasoby, interfejsy | ocena |
| Zegar i zasoby LUT z raportu HLS — orientacyjne; prawda po implementacji | decyzje |
| Otwarte: Bambu (C → Verilog, testbench), Dynamatic, XLS; komercyjne niezależne: Catapult, Stratus | ekosystem |
| Testbench zwraca 0 przy sukcesie; ten sam w csim i cosim | weryfikacja |

## [28.05 — Akceleracja sieci neuronowych: hls4ml i FINN](28.05-akceleracja-sieci-neuronowych-hls4ml-i-finn.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| int8 × int8 → suma int32 → przeskalowanie (przesunięcie z zaokrągleniem) → aktywacja → nasycenie int8 | wnioskowanie całkowitoliczbowe |
| PTQ wystarcza zwykle dla 8 bitów; 4 bity i mniej — QAT (Brevitas, QKeras) | kwantyzacja |
| Reuse factor R: mnożarki ≈ liczba mnożeń / R, II ≈ R | zasoby vs przepustowość |
| Mnożenie przez stałą int8 — często w LUT, bez DSP; wagi 0 znikają | małe sieci |
| hls4ml: `io_parallel` (małe sieci, minimalne opóźnienie), `io_stream` (CNN, DATAFLOW) | wybór stylu |
| FINN: warstwy strumieniowe MVAU, folding PE × SIMD, wagi na układzie | sieci mocno kwantyzowane |
| Overlay (DPU, FPGA AI Suite): jeden procesor sieci, wiele modeli bez syntezy | duże, zmienne modele |
| Dokładność sprawdzaj po kwantyzacji na tym samym zbiorze testowym (tu 98,4% → 98,2%) | walidacja |

## [28.06 — Alternatywne języki HDL: Chisel, SpinalHDL, Amaranth, Clash](28.06-alternatywne-jezyki-hdl-chisel-spinalhdl.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Język konstrukcji sprzętu = program generujący RTL; takty ustala projektant (inaczej niż HLS) | rozróżnienie |
| Chisel → FIRRTL → SystemVerilog; SpinalHDL → VHDL/Verilog; Amaranth → Verilog przez Yosys; Clash → VHDL/Verilog/SV | przepływy |
| Pętla w języku gospodarza działa przy generacji — w sprzęcie zostają jej kopie | generatory |
| Stałe w generatorze → węższe iloczyny i mniej logiki (tu 22 zamiast 32 bitów dla małego współczynnika) | parametryzacja |
| Wygenerowany RTL testuj tymi samymi wektorami co ręczny — wzorzec niezależny od języka | weryfikacja |
| Ograniczenia czasowe, IP, CDC i debug na płytce — nadal w narzędziach producenta | ograniczenia |
