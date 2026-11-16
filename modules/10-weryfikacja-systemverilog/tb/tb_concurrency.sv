// 10.06 — współbieżność w testbenchu: fork-join (trzy warianty), disable fork, wait fork, przechwycenie
// zmiennej pętli, mailbox ograniczony, semafor jako blokada wspólnej magistrali, zdarzenia i straż czasu.
// Każdy wynik sprawdzany czasem symulacji albo kolejnością zapisów.
`timescale 1ns / 1ps

module tb_concurrency;
    int errors = 0;

    task automatic expect_true(bit cond, string what);
        if (!cond) begin
            $display("BLAD (%0t): %s", $time, what);
            errors++;
        end
    endtask

    function automatic string q2s(int q[$]);
        string s = "";
        foreach (q[i]) s = {s, $sformatf("%0d ", q[i])};
        return s;
    endfunction

    // dwa „drivery” dzielą jedną magistralę; semafor zapewnia wyłączność
    semaphore bus_lock = new(1);
    int       bus_owner = -1, overlaps = 0;
    time      busy [2][$];

    task automatic use_bus(int who, int n);
        repeat (n) begin
            bus_lock.get(1);
            if (bus_owner != -1) overlaps++;
            bus_owner = who;
            busy[who].push_back($time);
            #7;
            bus_owner = -1;
            bus_lock.put(1);
            #1;
        end
    endtask

    event     ev_go;
    mailbox #(int) mb = new(2);             // ograniczona do 2 elementów

    initial begin
        time t0;
        int  got [$], order [$], x, put_time [5];
        bit  late_done;

        // 1. fork-join: czeka na wszystkie gałęzie
        t0 = $time;
        fork
            #10;
            #30;
            #20;
        join
        expect_true($time - t0 == 30, "join: koniec po najdluzszej galezi (30)");

        // 2. fork-join_any + disable fork: pierwsza gałąź kończy, reszta przerwana
        t0 = $time;
        late_done = 0;
        fork
            #10;
            begin #40; late_done = 1; end
        join_any
        expect_true($time - t0 == 10, "join_any: koniec po najkrotszej galezi (10)");
        disable fork;
        #50;
        expect_true(late_done == 0, "disable fork: przerwana galaz nie dokonczyla pracy");

        // 3. fork-join_none + wait fork: rodzic biegnie dalej, potem czeka na dzieci
        t0 = $time;
        fork
            #15 order.push_back(2);
            #5  order.push_back(1);
        join_none
        order.push_back(0);                 // rodzic przed dziećmi, w tym samym czasie
        wait fork;
        expect_true($time - t0 == 15 && q2s(order) == "0 1 2 ", "join_none + wait fork: kolejnosc 0,1,2 i czas 15");

        // 4. przechwycenie zmiennej pętli: kopia automatic w każdej gałęzi
        order.delete();
        for (int i = 0; i < 3; i++) begin
            automatic int k = i;
            fork
                #(10 - k) order.push_back(k);
            join_none
        end
        wait fork;
        expect_true(q2s(order) == "2 1 0 ", "kopia automatic: kazda galaz widzi swoje i (2,1,0 wg czasu)");

        // 5. mailbox ograniczony: producent czeka, gdy pełny; kolejność FIFO; try_put/try_get
        t0 = $time;
        fork
            for (int i = 0; i < 5; i++) begin
                mb.put(i);
                put_time[i] = $time - t0;
            end
            begin
                #20;
                repeat (5) begin
                    mb.get(x);
                    got.push_back(x);
                    #10;
                end
            end
        join
        expect_true(q2s(got) == "0 1 2 3 4 ", "mailbox: kolejnosc FIFO");
        expect_true(put_time[1] == 0 && put_time[2] == 20 && put_time[4] == 40,
                    "mailbox(2): trzeci put czeka na pierwszy get");
        expect_true(mb.try_get(x) == 0 && mb.num() == 0, "try_get na pustej skrzynce zwraca 0");
        void'(mb.try_put(7));
        void'(mb.try_put(8));
        expect_true(mb.try_put(9) == 0 && mb.num() == 2, "try_put na pelnej skrzynce zwraca 0");
        void'(mb.try_get(x));
        void'(mb.try_get(x));

        // 6. semafor: dwa procesy, żadnego nakładania się dostępu
        fork
            use_bus(0, 5);
            use_bus(1, 5);
        join
        expect_true(overlaps == 0 && busy[0].size() == 5 && busy[1].size() == 5, "semafor: wylacznosc magistrali");

        // 7. zdarzenie: wait(ev.triggered) nie gubi wyzwolenia w tym samym kroku czasu
        t0 = $time;
        fork
            -> ev_go;                       // wyzwolenie w czasie t0
            begin
                wait (ev_go.triggered);     // zadziała nawet, gdy ta gałąź ruszy po wyzwoleniu
                x = 1;
            end
        join
        expect_true(x == 1 && $time == t0, "wait(ev.triggered): bez zakleszczenia");

        // 8. straż czasu: operacja, która może się zawiesić, ograniczona limitem
        x = 0;
        fork
            begin : praca
                @(ev_go);                   // nigdy nie nastąpi — nikt już nie wyzwala
                x = 1;
            end
            begin : straz
                #100;
                x = 2;
            end
        join_any
        disable fork;
        expect_true(x == 2, "straz czasu przerwala zawieszona operacje");

        $display("czas symulacji: %0t", $time);
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
