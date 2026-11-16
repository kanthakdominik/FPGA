// 10.01 — programowanie obiektowe bez układu: uchwyty, kopie płytkie i głębokie, składowe statyczne,
// dziedziczenie, metody wirtualne (polimorfizm), $cast, klasa abstrakcyjna, klasa parametryzowana typem.
// Każda właściwość sprawdzana warunkiem; wynik PASS albo FAIL: N bledow.
`timescale 1ns / 1ps

import alu_txn_pkg::*;

// klasa parametryzowana typem: kolejka FIFO z licznikiem maksymalnego zapełnienia
class fifo #(type T = int);
    local T   q[$];
    int       max_size = 0;

    function void push(T x);
        q.push_back(x);
        if (q.size() > max_size) max_size = q.size();
    endfunction

    function T pop();
        return q.pop_front();
    endfunction

    function int size();
        return q.size();
    endfunction
endclass

// klasa abstrakcyjna: nie da się utworzyć obiektu, metoda czysto wirtualna musi być zdefiniowana w potomku
virtual class checker_base;
    int n_err = 0;
    pure virtual function bit check(alu_txn t);
    function void run(alu_txn t);
        if (!check(t)) n_err++;
    endfunction
endclass

class zero_flag_checker extends checker_base;
    virtual function bit check(alu_txn t);
        return t.zero == (t.res == 0);
    endfunction
endclass

// obiekt z uchwytem do innego obiektu — różnica kopii płytkiej i głębokiej
class txn_pair;
    alu_txn first = new();
    int     tag;
endclass

module tb_oop;
    int errors = 0;

    task automatic expect_true(bit cond, string what);
        if (!cond) begin
            $display("BLAD: %s", what);
            errors++;
        end
    endtask

    initial begin
        alu_txn      t1, t2, t3, list[$];
        alu_txn_edge e, e2;
        alu_txn_bad  bad;
        txn_pair     p1, p2, p3;
        fifo #(alu_txn) fq;
        fifo #(int)     fi;
        zero_flag_checker zc;
        checker_base      cb;
        int unsigned n0;

        // 1. uchwyt to odnośnik: przypisanie nie kopiuje obiektu
        alu_txn::reset_count();
        t1   = new();
        t1.a = 8'd10;
        t2   = t1;
        t2.a = 8'd20;
        expect_true(t1.a == 8'd20 && t1 == t2, "przypisanie uchwytu powinno wskazywac ten sam obiekt");

        // 2. clone() tworzy niezależny obiekt z nowym id
        t3   = t1.clone();
        t3.a = 8'd30;
        expect_true(t1.a == 8'd20 && t3 != t1, "clone() powinien dac niezalezna kopie");
        expect_true(t3.id == 1 && alu_txn::n_created == 2, "licznik statyczny: 2 obiekty, id 0 i 1");

        // 3. kopia płytka (new p1) dzieli obiekty zagnieżdżone, kopia głęboka nie
        p1         = new();
        p1.tag     = 1;
        p1.first.a = 8'd5;
        p2         = new p1;               // kopia płytka: nowe pole tag, ten sam uchwyt first
        p2.tag     = 2;
        p2.first.a = 8'd6;
        expect_true(p1.tag == 1 && p1.first.a == 8'd6, "kopia plytka: wspolny obiekt first, osobne tag");
        p3         = new p1;
        p3.first   = p1.first.clone();     // kopia głęboka: własny obiekt first
        p3.first.a = 8'd7;
        expect_true(p1.first.a == 8'd6, "kopia gleboka nie powinna zmieniac oryginalu");

        // 4. polimorfizm: kolejka uchwytów klasy bazowej, metody wirtualne potomków
        e   = new();
        bad = new();
        list.push_back(t1);
        list.push_back(e);
        list.push_back(bad);
        expect_true(list[0].kind() == "txn" && list[1].kind() == "edge" && list[2].kind() == "bad",
                    "metoda wirtualna powinna wybrac wersje z klasy obiektu");
        expect_true(list[1].convert2string().substr(0, 3) == "edge",
                    "convert2string() klasy bazowej wywoluje kind() potomka");

        // 5. clone() wirtualny zwraca obiekt tej samej klasy co oryginał
        t3 = list[1].clone();
        expect_true(t3.kind() == "edge", "clone() potomka powinien zwracac potomka");

        // 6. $cast: rzutowanie w dół udaje się tylko, gdy obiekt naprawdę jest potomkiem
        expect_true($cast(e2, list[1]) == 1, "$cast na alu_txn_edge dla obiektu edge");
        expect_true($cast(e2, list[0]) == 0, "$cast na alu_txn_edge dla obiektu bazowego powinien zawiesc");

        // 7. ograniczenia dziedziczone i nadpisane
        repeat (50) begin
            if (!e.randomize())   errors++;
            if (!bad.randomize()) errors++;
            expect_true(e.op != OP_BAD && e.a inside {8'h00, 8'h01, 8'h7F, 8'h80, 8'hFE, 8'hFF},
                        "edge: c_legal z klasy bazowej i c_edge");
            expect_true(bad.op == OP_BAD, "bad: c_legal nadpisane");
        end

        // 8. klasa abstrakcyjna przez uchwyt bazowy
        zc = new();
        cb = zc;
        repeat (100) begin
            void'(t1.randomize());
            t1.predict();
            cb.run(t1);
        end
        expect_true(zc.n_err == 0, "model: flaga zero zgodna z wynikiem");

        // 9. klasa parametryzowana — dwie specjalizacje
        fq = new();
        fi = new();
        foreach (list[i]) fq.push(list[i]);
        for (int i = 0; i < 5; i++) fi.push(i * i);
        expect_true(fq.pop() == t1 && fq.size() == 2 && fq.max_size == 3, "fifo #(alu_txn)");
        n0 = 0;
        while (fi.size() > 0) n0 += fi.pop();
        expect_true(n0 == 30, "fifo #(int): 0+1+4+9+16");

        $display("utworzonych obiektow alu_txn: %0d", alu_txn::n_created);
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
