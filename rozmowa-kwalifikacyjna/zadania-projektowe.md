# Zadania projektowe „na tablicę”

[← rozmowa kwalifikacyjna](README.md)

> **Status:** ✅ pełny

Dwanaście zadań, które na rozmowach technicznych na stanowiska FPGA i RTL padają najczęściej — od detektora zbocza po slave AXI4-Lite i filtr FIR. Każde ma: treść tak, jak ją zwykle słychać, pytania doprecyzowujące, które warto zadać przed pisaniem, rozwiązanie z omówieniem, testbench i typowe błędy kandydatów.

Rozwiązania są w trzech językach w katalogu [hdl/](hdl/) — VHDL, Verilog i SystemVerilog — i każde ma samosprawdzający się testbench uruchamiany w GitHub Actions (GHDL, Icarus Verilog, Verilator), tak jak kod w modułach. W tekście pokazany jest jeden język na zadanie (na zmianę); pozostałe są pod linkami. Liczby w „Wynik w CI” pochodzą z Icarus Verilog (dla zadania 8 — z GHDL); w pozostałych symulatorach inne są tylko liczby zależne od generatora losowego, wynik jest taki sam.

## Jak ćwiczyć

1. Przeczytaj treść i zanim cokolwiek napiszesz, wypisz pytania doprecyzowujące. Na rozmowie to połowa oceny: pokazuje, że wiesz, od czego zależy rozwiązanie.
2. Narysuj schemat blokowy: rejestry, logika kombinacyjna między nimi, przebiegi czasowe dwóch–trzech taktów.
3. Napisz kod na kartce w 10–15 minut. Bez symulatora — tak jak przy tablicy.
4. Dopiero potem porównaj z rozwiązaniem i uruchom testbench. Celowo wprowadź jeden z „typowych błędów” i sprawdź, czy testbench go wykryje.
5. Powiedz na głos, ile zasobów zajmie układ i co ogranicza jego częstotliwość.

## Spis zadań

| # | Zadanie | Poziom | Temat w bazie | Kod |
|---|---------|--------|---------------|-----|
| 1 | Detektor zbocza narastającego i opadającego | podstawowy | [08.04](../modules/08-automaty-stanow/08.04-eliminacja-drgan-stykow-i-wykrywanie-zboczy.md) | `edge_detect` |
| 2 | Licznik modulo N z wyjściem przeniesienia | podstawowy | [07.04](../modules/07-kodowanie-pod-synteze/07.04-liczniki-dzielniki-i-clock-enable.md) | `mod_counter` |
| 3 | Dzielnik zegara przez 3 z wypełnieniem 50 % | średni | [07.04](../modules/07-kodowanie-pod-synteze/07.04-liczniki-dzielniki-i-clock-enable.md) | `clk_div3` |
| 4 | Detektor sekwencji bitów — Moore i Mealy | podstawowy | [08.01](../modules/08-automaty-stanow/08.01-automat-moore-a-i-mealy-ego-w-hdl-style.md) | `seq_moore`, `seq_mealy` |
| 5 | Arbiter round-robin | średni | [08.05](../modules/08-automaty-stanow/08.05-handshake-valid-ready-i-przeplyw-danych.md) | `rr_arbiter` |
| 6 | Synchroniczne FIFO z flagami | średni | [18.03](../modules/18-pamieci/18.03-synchroniczna-kolejka-fifo-i-flagi.md) | `sync_fifo` |
| 7 | Impuls między domenami zegarowymi | średni | [15.03](../modules/15-zegary-reset-cdc/15.03-synchronizatory-jednobitowe-i-synchronizacja.md) | `pulse_sync` |
| 8 | Asynchroniczne FIFO z licznikami Graya | zaawansowany | [15.05](../modules/15-zegary-reset-cdc/15.05-asynchroniczna-kolejka-fifo.md) | `async_fifo` |
| 9 | Nadajnik UART | podstawowy | [20.01](../modules/20-interfejsy-szeregowe/20.01-uart-nadajnik-odbiornik-i-nadprobkowanie.md) | `uart_tx` |
| 10 | Slave AXI4-Lite z czterema rejestrami | zaawansowany | [21.02](../modules/21-magistrale-on-chip/21.02-rejestry-sterujace-axi4-lite-i-avalon-mm.md) | `axil_regs` |
| 11 | Skid buffer | zaawansowany | [08.05](../modules/08-automaty-stanow/08.05-handshake-valid-ready-i-przeplyw-danych.md) | `skid_buffer` |
| 12 | Filtr FIR z potokowaniem | zaawansowany | [26.01](../modules/26-dsp-w-fpga/26.01-filtry-fir-struktury-bezposrednia-transponowana.md) | `fir_transposed` |

Zasoby po syntezie w Yosysie (LUT4 i przerzutniki, liczone w CI) są w tabeli na końcu strony.

## Zadanie 1 — detektor zbocza

**Poziom:** podstawowy · **Kod:** [VHDL](hdl/vhdl/edge_detect.vhd) · [Verilog](hdl/verilog/edge_detect.v) · [SystemVerilog](hdl/sv/edge_detect.sv) · testbench `tb_edge_detect` w trzech językach

**Treść.** „Napisz układ, który na wyjściu `rise` daje impuls jednotaktowy, gdy wejście `d` zmieni się z 0 na 1, a na `fall` — z 1 na 0.”

**Pytania doprecyzowujące:**

- Czy `d` jest synchroniczne z zegarem? Jeśli to przycisk albo sygnał z innej domeny — najpierw synchronizator (i ewentualnie eliminacja drgań).
- Impuls ma się pojawić w tym samym takcie co zmiana (wyjście kombinacyjne) czy takt później (wyjście z rejestru, bez ścieżki kombinacyjnej z wejścia)?
- Jaki stan po resecie: czy `d = 1` zaraz po resecie to zbocze?

**Rozwiązanie.** Jeden przerzutnik pamięta poprzednią wartość, zbocze to różnica między próbką bieżącą a poprzednią:

```verilog
reg d_q = 1'b0;
always @(posedge clk)
    if (rst) d_q <= 1'b0;
    else     d_q <= d;

assign rise = d & ~d_q;
assign fall = ~d & d_q;
```

Wersja z wyjściem rejestrowanym: dwa przerzutniki (`d_q`, `d_qq`) i `rise = d_q & ~d_qq` — impuls takt później, ale bez logiki między wejściem a wyjściem. Przy wejściu asynchronicznym ten drugi wariant naturalnie łączy się z synchronizatorem: trzy przerzutniki, z których dwa pierwsze synchronizują.

**Testbench.** Losowe `d` (zmiana na zboczu opadającym zegara), w każdym takcie porównanie z modelem `d & ~poprzednie`. Wynik w CI: 83 zbocza narastające i 83 opadające, wszystkie zgodne z modelem.

**Typowe błędy:**

- `always @(posedge d)` — wejście danych jako zegar; nie do przyjęcia w FPGA.
- Brak synchronizatora dla przycisku — metastabilność, a przy drganiach styków wiele impulsów.
- Porównanie z wartością sprzed dwóch taktów przy wyjściu kombinacyjnym — impuls przesunięty albo podwójny.

## Zadanie 2 — licznik modulo N

**Poziom:** podstawowy · **Kod:** [VHDL](hdl/vhdl/mod_counter.vhd) · [Verilog](hdl/verilog/mod_counter.v) · [SystemVerilog](hdl/sv/mod_counter.sv) · testbench `tb_mod_counter`

**Treść.** „Licznik od 0 do N − 1 z wejściem zezwolenia i wyjściem przeniesienia, sparametryzowany przez N.”

**Pytania doprecyzowujące:**

- Czy N jest potęgą dwójki (wtedy wystarczy naturalne przepełnienie)?
- Przeniesienie jako impuls w takcie przejścia N − 1 → 0, czy jako poziom „licznik = N − 1”? Czy ma zależeć od zezwolenia (do kaskady liczników — tak)?
- Reset synchroniczny czy asynchroniczny, ładowanie wartości?

**Rozwiązanie** (VHDL): szerokość jako generic, porównanie z `N − 1`, przeniesienie = zezwolenie ∧ ostatnia wartość — wtedy drugi licznik w kaskadzie dostaje je jako swoje zezwolenie i zmienia się dokładnie raz na N impulsów:

```vhdl
at_last <= '1' when cnt = N - 1 else '0';

process (clk)
begin
  if rising_edge(clk) then
    if rst = '1' then
      cnt <= (others => '0');
    elsif en = '1' then
      if at_last = '1' then cnt <= (others => '0'); else cnt <= cnt + 1; end if;
    end if;
  end if;
end process;

carry <= en and at_last;
```

W Verilogu szerokość liczy `$clog2(N)`, a porównanie bez ostrzeżeń o szerokości daje wycinek stałej: `localparam integer LAST = N - 1;` i `q == LAST[W-1:0]`.

**Testbench.** Dwa egzemplarze (N = 10 i N = 6) z losowym zezwoleniem; model w testbenchu, a na końcu liczba przeniesień = liczba taktów z zezwoleniem / N. Wynik w CI: 452 takty z zezwoleniem, 45 przeniesień dla N = 10 i 75 dla N = 6 — zgodnie z 452 / 10 i 452 / 6.

**Typowe błędy:**

- Porównanie z N zamiast N − 1 (licznik liczy do N, czyli modulo N + 1).
- Przeniesienie bez zezwolenia — w kaskadzie drugi licznik zlicza tyle razy, ile taktów pierwszy stoi na N − 1.
- Licznik jako dzielnik zegara z wyjściem użytym jako zegar — zobacz zadanie 3 i [pułapkę 14](pulapki.md).

## Zadanie 3 — dzielnik zegara przez 3

**Poziom:** średni · **Kod:** [VHDL](hdl/vhdl/clk_div3.vhd) · [Verilog](hdl/verilog/clk_div3.v) · [SystemVerilog](hdl/sv/clk_div3.sv) · testbench `tb_clk_div3`

**Treść.** „Podziel zegar przez 3 tak, żeby wyjście miało wypełnienie 50 %.”

**Pytania doprecyzowujące:**

- Do czego służy wyjście? Jeśli do taktowania logiki w FPGA — właściwa odpowiedź to PLL albo impuls zezwolenia co 3 takty, a nie dzielnik. Jeśli to zegar na pin dla zewnętrznego układu — dzielnik ma sens.
- Czy dopuszczalne jest użycie zbocza opadającego?

**Rozwiązanie.** Z samych zboczy narastających dostaje się tylko wypełnienia 1/3 albo 2/3 — 50 % wymaga połowy okresu, więc drugi przerzutnik pracuje na zboczu opadającym:

```verilog
always @(posedge clk)
    if (rst) begin cnt <= 2'd0; p <= 1'b0; end
    else begin
        cnt <= (cnt == 2'd2) ? 2'd0 : cnt + 2'd1;
        p   <= (cnt == 2'd2);          // 1 przez jeden okres z trzech
    end

always @(negedge clk)
    if (rst) n <= 1'b0;
    else     n <= p;                    // p opóźnione o pół okresu

assign clk_out = p | n;                 // 1,5 okresu z 3
```

Wyjście to bramka OR dwóch przerzutników — wolne od zakłóceń (zmienia się zawsze tylko jedno wejście), ale przesunięte względem zegara wejściowego. Warto to powiedzieć wprost i dodać, że w FPGA logiki nie taktuje się takim sygnałem.

**Testbench.** Mierzy czasy zboczy `clk_out`: okres 30 ns i stan wysoki 15 ns w każdym z 20 okresów (zegar 10 ns). Wynik w CI: 20 okresów po 30 ns, każdy ze stanem wysokim 15 ns.

**Typowe błędy:**

- Licznik 0–2 i `clk_out = (cnt < 2)` — wypełnienie 66 %.
- Zmiana `clk_out` w obu blokach (`posedge` i `negedge`) — sygnał z dwóch procesów, niesyntezowalny.
- Bramka AND/OR z sygnałów, które mogą zmieniać się jednocześnie — zakłócenia na zegarze.

## Zadanie 4 — detektor sekwencji 1011

**Poziom:** podstawowy · **Kod:** [VHDL](hdl/vhdl/seq_moore.vhd) · [Verilog](hdl/verilog/seq_moore.v) · [SystemVerilog](hdl/sv/seq_moore.sv) oraz `seq_mealy` w tych samych katalogach · testbench `tb_seq_detect`

**Treść.** „Szeregowe wejście `x`, jeden bit na takt. Ustaw `det`, gdy ostatnie cztery bity to 1011. Narysuj automat Moore'a i Mealy'ego.”

**Pytania doprecyzowujące:**

- Z nakładaniem czy bez? (W ciągu 1011011 wzorzec występuje dwa razy z nakładaniem i raz bez.)
- Kiedy ma się pojawić `det` — w takcie ostatniego bitu (Mealy) czy takt później (Moore)?
- Czy wyjście może zależeć kombinacyjnie od wejścia?

**Rozwiązanie.** Stan to długość najdłuższego przedrostka wzorca, który jest końcówką dotychczasowego ciągu. Najwięcej uwagi wymagają przejścia „z porażki” — po niepasującym bicie nie zawsze wraca się do zera: po „101” i bicie 0 zostaje „10” (stan S2), a po pełnym „1011” i bicie 1 — „1” (S1). W SystemVerilogu stany jako `enum`:

```systemverilog
typedef enum logic [2:0] {S0, S1, S2, S3, S4} state_t;
state_t st = S0;
state_t st_next;

always_comb begin
    unique case (st)
        S0:      st_next = x ? S1 : S0;
        S1:      st_next = x ? S1 : S2;     // "1", "11"
        S2:      st_next = x ? S3 : S0;     // "10"
        S3:      st_next = x ? S4 : S2;     // "101"; "1010" kończy się na "10"
        S4:      st_next = x ? S1 : S2;     // "1011": nakładanie
        default: st_next = S0;
    endcase
end

assign det = (st == S4);                    // Moore: tylko od stanu
```

Mealy ma o jeden stan mniej (S0–S3), a `det = (st == S3) & x` — wynik w takcie ostatniego bitu, ale z kombinacyjną ścieżką od wejścia do wyjścia.

**Testbench.** Oba automaty na tym samym losowym ciągu z wtrąconym 1011011; model to rejestr ostatnich trzech bitów: Mealy `det = ({hist, x} == 1011)`, Moore — ta sama wartość takt później. Wynik w CI: 37 wykryć wzorca, oba automaty zgodne z modelem w każdym takcie.

**Typowe błędy:**

- Powrót do S0 po każdym niepasującym bicie — gubi wzorce typu 10**1011**.
- Brak nakładania po wykryciu (S4 → S0).
- Wyjście Moore'a liczone z `st_next` — to w rzeczywistości Mealy.

## Zadanie 5 — arbiter round-robin

**Poziom:** średni · **Kod:** [VHDL](hdl/vhdl/rr_arbiter.vhd) · [Verilog](hdl/verilog/rr_arbiter.v) · [SystemVerilog](hdl/sv/rr_arbiter.sv) · testbench `tb_rr_arbiter`

**Treść.** „Cztery układy zgłaszają żądania dostępu do wspólnego zasobu. Przydziel dostęp sprawiedliwie — tak, żeby nikt nie czekał w nieskończoność.”

**Pytania doprecyzowujące:**

- Przydział na jeden takt czy do zwolnienia zasobu (sygnał `done`, transakcja wielotaktowa)?
- Przydział kombinacyjny (w tym samym takcie co żądanie) czy z rejestru?
- Ile zgłaszających i czy N jest potęgą dwójki? Czy potrzebne są priorytety albo wagi?

**Rozwiązanie.** Wskaźnik `ptr` wskazuje, od kogo zaczyna się szukanie; po przydziale przechodzi na pozycję za zwycięzcą, więc ten, kto właśnie dostał dostęp, ma teraz najniższy priorytet. Gwarancja: trwające żądanie czeka najwyżej N − 1 taktów. W VHDL:

```vhdl
process (req, ptr)
  variable idx : natural range 0 to N - 1;
  variable f   : boolean;
begin
  f   := false;
  win <= ptr;
  for i in 0 to N - 1 loop
    idx := (ptr + i) mod N;
    if not f and req(idx) = '1' then
      f   := true;
      win <= idx;
    end if;
  end loop;
  if f then found <= '1'; else found <= '0'; end if;
end process;
...
elsif found = '1' then ptr <= (win + 1) mod N;
```

Dla dużych N szybsza jest wersja z maską: przydział o stałym priorytecie dla `req & maska_wyższych_od_ptr`, a gdy ten jest pusty — dla samego `req`; oba to łańcuchy „znajdź pierwszą jedynkę”, które dobrze mapują się na logikę przeniesień.

**Testbench.** Najpierw stałe zgłoszenia wszystkich — przydziały muszą krążyć 0, 1, 2, 3, 0, …; potem losowe zgłoszenia trwające do przydziału, model z tym samym algorytmem, sprawdzenie jednej jedynki w `grant` i najdłuższego oczekiwania. Wynik w CI: 1006 przydziałów, najdłuższe oczekiwanie 3 takty (= N − 1).

**Typowe błędy:**

- Wskaźnik przesuwany o 1 co takt zamiast za zwycięzcę — sprawiedliwość tylko przy stałych zgłoszeniach.
- Stały priorytet „najpierw 0” — zagłodzenie zgłoszeń o wyższych numerach.
- Brak sprawdzenia, że przydział trafia tylko w aktywne żądanie.

## Zadanie 6 — synchroniczne FIFO

**Poziom:** średni · **Kod:** [VHDL](hdl/vhdl/sync_fifo.vhd) · [Verilog](hdl/verilog/sync_fifo.v) · [SystemVerilog](hdl/sv/sync_fifo.sv) · testbench `tb_sync_fifo`

**Treść.** „Kolejka FIFO o głębokości 16 słów 8-bitowych z flagami `full` i `empty`. Jeden zegar.”

**Pytania doprecyzowujące:**

- Odczyt rejestrowany (dane takt po `rd_en`, jak z pamięci blokowej) czy show-ahead (słowo czeka na wyjściu)?
- Co przy zapisie do pełnej i odczycie z pustej — ignorować, sygnalizować błąd?
- Czy potrzebne są flagi „prawie pełna / prawie pusta” albo licznik zapełnienia?

**Rozwiązanie.** Wskaźniki zapisu i odczytu mają **o jeden bit więcej** niż adres. Równe wskaźniki — kolejka pusta; równe adresy, ale różne najstarsze bity — pełna (zapis „okrążył” odczyt). Bez dodatkowego bitu oba stany wyglądają tak samo.

```verilog
assign empty = (wp == rp);
assign full  = (wp[AW] != rp[AW]) && (wp[AW-1:0] == rp[AW-1:0]);

always @(posedge clk) begin
    if (wr_en && !full)  mem[wp[AW-1:0]] <= wr_data;
    if (rd_en && !empty) rd_data <= mem[rp[AW-1:0]];     // odczyt rejestrowany: blok RAM
end
always @(posedge clk)
    if (rst) begin wp <= {(AW + 1){1'b0}}; rp <= {(AW + 1){1'b0}}; end
    else begin
        if (wr_en && !full)  wp <= wp + 1'b1;
        if (rd_en && !empty) rp <= rp + 1'b1;
    end
```

Alternatywa — licznik zapełnienia (0..16) i flagi z porównania z 0 i 16; łatwo dodać „prawie pełną”, ale jest jeden sumator więcej na ścieżce.

**Testbench.** Losowe zapisy i odczyty w trzech fazach (przewaga zapisów, odczytów, po równo); model to kolejka w tablicy. W każdym takcie flagi zgodne z zapełnieniem modelu i dane w kolejności zapisu, na końcu pokrycie: kolejka pełna, pusta, zapis przy pełnej i odczyt przy pustej wystąpiły. Wynik w CI: 940 słów zapisanych i 936 odczytanych w kolejności; kolejka pełna w 695 taktach, pusta w 740; 553 zapisy przy pełnej i 563 odczyty przy pustej poprawnie zignorowane.

**Typowe błędy:**

- Wskaźniki bez dodatkowego bitu i `full = (wp + 1 == rp)` — kolejka mieści 15 słów zamiast 16 (czasem akceptowalne, ale trzeba to powiedzieć).
- Zapis do pełnej bez blokady — nadpisanie najstarszego słowa.
- Reset pamięci w pętli — zamiast bloku RAM powstają przerzutniki ([pułapka 27](pulapki.md)).

## Zadanie 7 — impuls między domenami zegarowymi

**Poziom:** średni · **Kod:** [VHDL](hdl/vhdl/pulse_sync.vhd) · [Verilog](hdl/verilog/pulse_sync.v) · [SystemVerilog](hdl/sv/pulse_sync.sv) · testbench `tb_pulse_sync`

**Treść.** „W domenie A powstaje impuls o długości jednego taktu. Przenieś go do domeny B tak, żeby tam też był jednym impulsem. Zegary są niezależne.”

**Pytania doprecyzowujące:**

- Która domena jest szybsza i o ile? Czy wiadomo, jak często przychodzą impulsy?
- Czy nadawca musi wiedzieć, że impuls dotarł (potwierdzenie)?
- Czy z impulsem idą dane?

**Rozwiązanie.** Synchronizator dwóch przerzutników nie wystarczy: impuls z szybszej domeny może trwać krócej niż okres zegara B i zniknąć między zboczami. Impuls zamienia się na **zmianę stanu** przełącznika, która trwa, aż przyjdzie następny impuls:

```vhdl
-- domena A
if pulse_a = '1' then tog_a <= not tog_a; end if;
-- domena B: synchronizator i wykrycie zmiany
sync_b  <= sync_b(1 downto 0) & tog_a;
pulse_b <= sync_b(2) xor sync_b(1);
```

Ograniczenie: kolejny impuls może przyjść dopiero, gdy poprzednia zmiana przeszła przez synchronizator — odstęp ok. 3 taktów B. Jeśli to nie jest zagwarantowane, potrzebny handshake (potwierdzenie wraca do A i blokuje kolejny impuls) albo licznik impulsów przenoszony w kodzie Graya.

**Testbench.** Dwa egzemplarze: z szybkiej domeny (10 ns) do wolnej (27 ns) i odwrotnie, po 60 impulsów; liczba impulsów po stronie B musi się zgadzać, a każdy impuls B trwa dokładnie jeden takt. Wynik w CI: 60 / 60 impulsów w obu kierunkach, każdy o długości jednego taktu.

**Typowe błędy:**

- Sam synchronizator z dwóch przerzutników dla impulsu z szybszej domeny.
- Wydłużenie impulsu w A „na wszelki wypadek” o stałą liczbę taktów — działa tylko dla znanego stosunku częstotliwości.
- Brak wzmianki o minimalnym odstępie między impulsami.

## Zadanie 8 — asynchroniczne FIFO

**Poziom:** zaawansowany · **Kod:** [VHDL](hdl/vhdl/async_fifo.vhd) · [Verilog](hdl/verilog/async_fifo.v) · [SystemVerilog](hdl/sv/async_fifo.sv) · testbench `tb_async_fifo`

**Treść.** „FIFO z zapisem w jednej domenie zegarowej i odczytem w drugiej. Wyjaśnij, skąd wiadomo, że jest pełne i puste.”

**Pytania doprecyzowujące:**

- Czy głębokość jest potęgą dwójki (wymagane przy kodzie Graya z zawijaniem)?
- Jaka jest relacja częstotliwości — czy kolejka ma pokrywać różnicę przepustowości, czy tylko przejście domen?
- Czy flagi mogą być „pesymistyczne” (opóźnione)?

**Rozwiązanie.** Każda strona ma swój wskaźnik binarny (do adresowania pamięci dwuportowej) i jego kopię w **kodzie Graya** — tylko ta kopia przechodzi przez synchronizator dwóch przerzutników do drugiej domeny. Kod Graya zmienia jeden bit na krok, więc druga strona zobaczy starą albo nową wartość, nigdy przypadkową.

- **Pusta** (domena odczytu): wskaźnik odczytu w Grayu = zsynchronizowany wskaźnik zapisu.
- **Pełna** (domena zapisu): wskaźnik zapisu = zsynchronizowany wskaźnik odczytu z **odwróconymi dwoma najstarszymi bitami** (w kodzie Graya różnica o pełne okrążenie tak właśnie wygląda).

```verilog
assign full = (wgray == {~rgray_w2[AW:AW-1], rgray_w2[AW-2:0]});
...
if (wr_en && !full) begin
    wbin  <= wbin_next;
    wgray <= wbin_next ^ (wbin_next >> 1);      // binarny -> Gray
end
...
assign empty = (rgray == wgray_r2);
```

Flagi są **pesymistyczne**: strona zapisu widzi wskaźnik odczytu sprzed 2–3 taktów, więc może uznać kolejkę za pełną, choć zwolniło się już miejsce — nigdy odwrotnie. Do ograniczeń czasowych: `set_max_delay -datapath_only` między wskaźnikami Graya a synchronizatorami ([15.07](../modules/15-zegary-reset-cdc/15.07-ograniczenia-i-weryfikacja-cdc.md)).

**Testbench.** Zapis 100 MHz, odczyt 73 MHz, 3000 słów w fazach z przewagą zapisu i odczytu; model po stronie zapisu, sprawdzenie kolejności, braku przepełnienia i odczytu z pustej oraz pokrycia obu flag. Wynik w CI: 3000 słów zapisanych i odczytanych w kolejności, bez przepełnienia; kolejka pełna w 4239 taktach zapisu, pusta w 2079 taktach odczytu.

**Typowe błędy:**

- Synchronizacja wskaźnika binarnego.
- Konwersja na kod Graya **po** synchronizatorze (kombinacyjnie z wielu bitów) zamiast przed nim, z rejestru.
- Warunek pełnej przez porównanie z odwróceniem tylko najstarszego bitu (to działa dla binarnych, nie dla Graya).

## Zadanie 9 — nadajnik UART

**Poziom:** podstawowy · **Kod:** [VHDL](hdl/vhdl/uart_tx.vhd) · [Verilog](hdl/verilog/uart_tx.v) · [SystemVerilog](hdl/sv/uart_tx.sv) · testbench `tb_uart_tx`

**Treść.** „Nadajnik UART 8N1, 115 200 b/s przy zegarze 50 MHz. Wejścia: bajt i `start`, wyjście: `tx` i informacja, że można wysłać następny bajt.”

**Pytania doprecyzowujące:**

- Kolejność bitów (UART — od najmłodszego), parzystość, liczba bitów stopu?
- Co, jeśli `start` przyjdzie w trakcie nadawania — ignorować, kolejkować?
- Jaki błąd szybkości jest dopuszczalny? (50 MHz / 115 200 = 434,03 — dzielnik 434 daje błąd 0,007 %.)

**Rozwiązanie.** Ramka w 10-bitowym rejestrze przesuwnym `{stop, dane, start}`, wysyłana od najmłodszego bitu; licznik odmierza DIV = CLK_HZ / BAUD taktów na bit:

```vhdl
elsif busy = '0' then
  if start = '1' then
    sh <= '1' & data & '0'; nbit <= 0; cnt <= 0; busy <= '1';
  end if;
elsif cnt = DIV - 1 then
  cnt <= 0;
  sh  <= '1' & sh(9 downto 1);                      -- następny bit, z lewej wchodzą jedynki
  if nbit = 9 then busy <= '0'; else nbit <= nbit + 1; end if;
else
  cnt <= cnt + 1;
end if;
...
tx <= sh(0);
```

`ready` spada w takcie po przyjęciu `start` — warto o tym powiedzieć, bo układ, który sprawdzi `ready` w następnym takcie po wystawieniu `start`, zobaczy jeszcze starą wartość (ten problem pojawia się w [31.01](../modules/31-projekty-koncowe/31.01-projekt-1-zegar-i-stoper-sterowany-komendami.md) i [31.06](../modules/31-projekty-koncowe/31.06-projekt-6-wlasny-procesor-risc-v-z-peryferiami.md)).

**Testbench.** 10 taktów na bit; odbiornik w testbenchu wykrywa zbocze bitu startu i próbkuje środki bitów — przy błędzie podzielnika o jeden takt na bit próbka bitu stopu wypadłaby poza bit. Bajty 0x55, 0xA3, 0x00, 0xFF i 20 losowych, start w trakcie nadawania musi zostać zignorowany. Wynik w CI: 24 bajty wysłane i odebrane bez błędów, `start` w trakcie nadawania zignorowany.

**Typowe błędy:**

- Wysyłanie od najstarszego bitu.
- Bit stopu krótszy o takt (koniec nadawania przy wejściu w bit stopu, a nie po nim) — przy nadawaniu ciągłym odbiornik gubi synchronizację.
- `tx` z logiki kombinacyjnej (np. multiplekser po numerze bitu) — zakłócenia na linii; wyjście powinno pochodzić z przerzutnika.

## Zadanie 10 — slave AXI4-Lite

**Poziom:** zaawansowany · **Kod:** [VHDL](hdl/vhdl/axil_regs.vhd) · [Verilog](hdl/verilog/axil_regs.v) · [SystemVerilog](hdl/sv/axil_regs.sv) · testbench `tb_axil_regs`

**Treść.** „Slave AXI4-Lite z czterema rejestrami 32-bitowymi do zapisu i odczytu, z obsługą `wstrb`.”

**Pytania doprecyzowujące:**

- Czy kanały AW i W mogą przyjść w różnych taktach i w dowolnej kolejności? (Według specyfikacji — tak. Slave może poczekać z `awready` na oba kanały, ale musi poprawnie obsłużyć każdą kolejność.)
- Wymagana przepustowość — czy wystarczy jeden zapis na kilka taktów?
- Co przy adresie spoza mapy — `OKAY` czy `SLVERR`?

**Rozwiązanie.** Każdy kanał zapisu ma własny rejestr „przyjęty” (`aw_full`, `w_full`), więc kolejność AW i W nie ma znaczenia; zapis do rejestru i odpowiedź B, gdy są oba. `awready` i `wready` są wyłączone, dopóki odpowiedź czeka na `bready`. Odczyt: dane w takcie po przyjęciu adresu, trzymane do `rready`. Zapis z maską bajtów (Verilog):

```verilog
assign awready = !aw_full && !bvalid;
assign wready  = !w_full && !bvalid;
...
if (awvalid && awready) begin aw_full <= 1'b1; aw_idx <= awaddr[3:2]; end
if (wvalid && wready)   begin w_full <= 1'b1; w_data <= wdata; w_strb <= wstrb; end
if (aw_full && w_full) begin
    case (aw_idx) ... r1 <= merge(r1, w_data, w_strb); ... endcase
    aw_full <= 1'b0; w_full <= 1'b0; bvalid <= 1'b1;
end
if (bvalid && bready) bvalid <= 1'b0;
```

Gdzie można przyspieszyć: przyjmować AW i W od razu przy `bvalid`, jeśli odpowiedź zostanie przyjęta w tym samym takcie, i zapisywać w takcie przyjęcia drugiego kanału zamiast takt później.

**Testbench.** Zapisy z AW przed W, W przed AW i obu naraz, maska jednego bajtu i dwóch, `bready` i `rready` opóźnione (sprawdzenie, że `bvalid` nie znika bez `bready`), potem 200 losowych zapisów i odczytów porównywanych z modelem. Wynik w CI: 111 zapisów i 99 odczytów zgodnych z modelem, wyjścia rejestrów po zapisach z maską: `reg0 = FFFF1111`, `reg3 = DEADAAEF`.

**Typowe błędy:**

- `awready = 1` na stałe i zapis tylko w takcie, w którym `awvalid && wvalid` — adres przyjęty w takcie bez danych przepada, bo master uznał go za przesłany.
- `ready` zależne kombinacyjnie od `valid` w sposób, który tworzy pętlę z masterem.
- `bvalid` jako impuls jednotaktowy, bez czekania na `bready`.

## Zadanie 11 — skid buffer

**Poziom:** zaawansowany · **Kod:** [VHDL](hdl/vhdl/skid_buffer.vhd) · [Verilog](hdl/verilog/skid_buffer.v) · [SystemVerilog](hdl/sv/skid_buffer.sv) · testbench `tb_skid_buffer`

**Treść.** „Wstaw rejestr w strumień z handshakiem valid/ready tak, żeby przecinał wszystkie ścieżki kombinacyjne — także `ready` — i nie zmniejszał przepustowości.”

**Pytania doprecyzowujące:**

- Czy `ready` od strony źródła musi być wyjściem rejestru (zwykle tak — o to chodzi w zadaniu)?
- Czy dopuszczalny jest „pęcherz” (jeden takt przerwy) przy zatrzymaniu odbiorcy?

**Rozwiązanie.** Zwykły rejestr z `s_ready = m_ready || !m_valid` ma pełną przepustowość, ale `ready` przechodzi przez niego kombinacyjnie; zarejestrowanie `ready` bez niczego więcej gubi słowo przyjęte w takcie, w którym odbiorca się zatrzymał. Skid buffer dokłada **drugi rejestr** na to jedno słowo:

```vhdl
s_ready <= not skid_v;                       -- wyjście rejestru

elsif m_ready = '1' or o_v = '0' then        -- wyjście wolne albo właśnie oddaje słowo
  if skid_v = '1' then
    o_d <= skid_d; o_v <= '1'; skid_v <= '0';
  else
    o_d <= s_data; o_v <= s_valid;
  end if;
elsif s_valid = '1' and skid_v = '0' then    -- wyjście stoi, a słowo przyjęte: do rejestru poślizgu
  skid_d <= s_data; skid_v <= '1';
end if;
```

Kosztem jest podwójny rejestr danych. To jest podstawowy element potoków AXI-Stream i przecinania długich ścieżek `ready` w dużych układach.

**Testbench.** Źródło wysyła kolejne liczby z losowym `s_valid`, odbiorca losowo zatrzymuje `m_ready`; sprawdzane: każda liczba dotarła raz i w kolejności, `m_valid` i `m_data` stoją do przyjęcia, a przy pełnym ruchu przez 100 taktów — 100 przesłań. Wynik w CI: 1148 słów bez strat i dubli, 100 przesłań w 100 taktach przy pełnym ruchu.

**Typowe błędy:**

- `s_ready` jako zarejestrowane `m_ready` bez rejestru poślizgu — zgubione słowo.
- Rozwiązanie z przepustowością 50 % (przyjmowanie co drugi takt).
- Zmiana `m_data`, gdy `m_valid = 1` i `m_ready = 0` ([pułapka 34](pulapki.md)).

## Zadanie 12 — filtr FIR w strukturze transponowanej

**Poziom:** zaawansowany · **Kod:** [VHDL](hdl/vhdl/fir_transposed.vhd) · [Verilog](hdl/verilog/fir_transposed.v) · [SystemVerilog](hdl/sv/fir_transposed.sv) · testbench `tb_fir_transposed`

**Treść.** „Filtr FIR rzędu 7 (8 współczynników) dla próbek 12-bitowych. Ma pracować z wysoką częstotliwością zegara.”

**Pytania doprecyzowujące:**

- Współczynniki stałe czy ładowane? Symetryczne (można dzielić mnożarki: (x[n] + x[n−7])·h0)?
- Próbka co takt czy rzadziej (wtedy jedna mnożarka współdzielona w czasie)?
- Szerokość wyjścia — pełna precyzja czy zaokrąglenie i nasycenie?

**Rozwiązanie.** W strukturze bezpośredniej mnożenia są równoległe, ale ich wyniki trzeba zsumować drzewem sumatorów — ścieżka krytyczna rośnie z liczbą współczynników (trzeba potokować drzewo). W strukturze **transponowanej** każda próbka jest mnożona przez wszystkie współczynniki naraz, a sumy częściowe płyną przez rejestry: ścieżka krytyczna to zawsze jedno mnożenie i jedno dodawanie, a pary mnożarka–sumator mapują się wprost na bloki DSP z akumulatorem.

```verilog
// y[n] = sum h[k] * x[n-k],  h = 2, -10, 40, 96, 96, 40, -10, 2
y <= xe * h(0) + $signed(s[23:0]);
for (k = 0; k < 6; k = k + 1)
    s[24 * k +: 24] <= xe * h(k + 1) + $signed(s[24 * (k + 1) +: 24]);
s[24 * 6 +: 24] <= xe * h(7);
```

Szerokość: 12 bitów próbki + 8 bitów współczynnika + ⌈log2(Σ|h|)⌉ zapasu; Σ|h| = 296, więc największy wynik to 2048 · 296 = 606 208 i 24 bity wystarczą z naddatkiem. Wada struktury transponowanej: wejście `x` ma duży fanout (trafia do wszystkich mnożarek) — przy wielu współczynnikach dzieli się je rejestrami.

**Testbench.** Odpowiedź impulsowa (na wyjściu kolejne współczynniki), stała 1000 (wynik 256 000 — wzmocnienie DC = Σh = 256), potem 2000 losowych próbek z pełnego zakresu i losowym `en`; model to splot z ostatnimi 8 próbkami. Wynik w CI: 1523 próbki zgodne z modelem, największe |y| = 562 996 (zakres 24 bitów: 8 388 607).

**Typowe błędy:**

- Za wąskie wyjście albo akumulator — przepełnienie przy próbkach z krańca zakresu (testbench celowo wysyła serie ±2047).
- Mnożenie bez znaku (`unsigned` / brak `$signed`) przy ujemnych współczynnikach.
- Odwrócona kolejność współczynników w strukturze transponowanej (dla filtrów symetrycznych błąd jest niewidoczny — dlatego warto testować też niesymetryczne).

## Zasoby po syntezie

Yosys, mapowanie na LUT4 (ten sam skrypt co w modułach), parametry domyślne:

| Zadanie | Moduł | LUT4 | FF | Głębokość logiki |
|---|---|---:|---:|---:|
| 1 | `edge_detect` | 2 | 1 | 1 |
| 2 | `mod_counter` (N = 10) | 6 | 4 | 2 |
| 3 | `clk_div3` | 5 | 4 | 1 |
| 4 | `seq_moore` / `seq_mealy` | 4 / 3 | 3 / 2 | 1 / 1 |
| 5 | `rr_arbiter` (N = 4) | 25 | 2 | 5 |
| 6 | `sync_fifo` (16 × 8) | 145 | 146 | 4 |
| 7 | `pulse_sync` | 2 | 4 | 1 |
| 8 | `async_fifo` (16 × 8) | 154 | 174 | 4 |
| 9 | `uart_tx` (50 MHz, 115 200 b/s) | 40 | 23 | 3 |
| 10 | `axil_regs` | 126 | 202 | 2 |
| 11 | `skid_buffer` (8 bitów) | 15 | 18 | 2 |
| 12 | `fir_transposed` | 578 | 164 | 11 |

Pamięci w `sync_fifo` i `async_fifo` (16 × 8 bitów) Yosys buduje z przerzutników; w Quartusie trafiłyby do bloku M9K albo, przy tej wielkości, zostały w logice. `fir_transposed` bez bloków DSP to kilkaset LUT4 — w Quartusie 8 mnożeń przez stałe zamieni się na sumy przesunięć albo trafi do mnożarek 9 × 9.

## Uruchomienie

```bash
python3 tools/run_hdl_tests.py rozmowa-kwalifikacyjna      # 36 testbenchy: GHDL, Icarus, Verilator
python3 tools/lint_hdl.py rozmowa-kwalifikacyjna --strict  # lint Verilatorem bez ostrzeżeń
python3 tools/synteza_yosys.py rozmowa-kwalifikacyjna      # zasoby
```

CI uruchamia je razem z resztą bazy (domyślne ścieżki skryptów obejmują ten katalog).
