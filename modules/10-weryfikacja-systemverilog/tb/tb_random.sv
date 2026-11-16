// 10.02 — losowanie z ograniczeniami: każda konstrukcja sprawdzana na wielu losowaniach.
// Rozkłady sprawdzane statystycznie z tolerancją dobraną do liczby próbek (błąd < 4 odchylenia standardowe).
`timescale 1ns / 1ps

import alu_txn_pkg::*;

// rozkład wag: ADD i SUB po 40 %, pozostałe pięć operacji razem 20 %; a = 0 i a = FF po 10 %
class alu_txn_dist extends alu_txn;
    constraint c_dist {
        op dist {OP_ADD := 4, OP_SUB := 4, [OP_AND:OP_SHR] :/ 2};
        a  dist {8'h00 := 1, 8'hFF := 1, [8'h01:8'hFE] :/ 8};
    }
    constraint c_shift { op inside {OP_SHL, OP_SHR} -> b < W; }   // implikacja: przesunięcie o 0..7
    constraint c_soft  { soft b != 8'h00; }                        // miękkie: ustępuje przy konflikcie
    int n_post = 0;
    function void post_randomize();
        predict();                                                 // odpowiedź z modelu po każdym losowaniu
        n_post++;
    endfunction
endclass

// klasyczny przykład kolejności rozwiązywania: sel -> v == 0
class sel_v;
    rand bit    sel;
    rand data_t v;
    constraint c { sel -> v == 0; }
endclass

class sel_v_ordered extends sel_v;
    constraint c_order { solve sel before v; }
endclass

class cyclic;
    randc bit [2:0] k;                                             // randc: permutacja 8 wartości, potem nowa
endclass

module tb_random;
    int errors = 0;

    task automatic expect_true(bit cond, string what);
        if (!cond) begin
            $display("BLAD: %s", what);
            errors++;
        end
    endtask

    // |n - oczekiwane| < 4 sigma dla rozkładu dwumianowego
    function automatic bit near(int n, int total, real p);
        real mean = total * p, sigma = $sqrt(total * p * (1.0 - p));
        return (n > mean - 4.0 * sigma) && (n < mean + 4.0 * sigma);
    endfunction

    initial begin
        alu_txn       t;
        alu_txn_dist  d;
        sel_v         s;
        sel_v_ordered so;
        cyclic        c;
        int           cnt_op [8];
        int           n_a0, n_aff, n_sel, n_sel_o, ok, n_shift_bad;
        bit [7:0]     seen;
        data_t        first [10];
        data_t        x;
        localparam int N = 4000;

        // 1. bez dodatkowych wag: 7 legalnych kodów po ~1/7
        t = new();
        cnt_op = '{default: 0};
        repeat (N) begin
            if (!t.randomize()) errors++;
            cnt_op[t.op]++;
        end
        expect_true(cnt_op[OP_BAD] == 0, "c_legal: brak OP_BAD");
        for (int i = 0; i < 7; i++) expect_true(near(cnt_op[i], N, 1.0 / 7), $sformatf("rownomiernosc op=%0d", i));

        // 2. dist, implikacja, post_randomize
        d = new();
        cnt_op = '{default: 0};
        n_a0 = 0; n_aff = 0; n_shift_bad = 0;
        repeat (N) begin
            if (!d.randomize()) errors++;
            cnt_op[d.op]++;
            if (d.a == 8'h00) n_a0++;
            if (d.a == 8'hFF) n_aff++;
            if (d.op inside {OP_SHL, OP_SHR} && d.b >= W) n_shift_bad++;
            if (d.b == 8'h00) errors++;                                  // miękkie ograniczenie spełnione
        end
        $display("dist: ADD=%0d SUB=%0d AND..SHR=%0d a=00:%0d a=FF:%0d (N=%0d)",
                 cnt_op[OP_ADD], cnt_op[OP_SUB], N - cnt_op[OP_ADD] - cnt_op[OP_SUB], n_a0, n_aff, N);
        expect_true(near(cnt_op[OP_ADD], N, 0.4) && near(cnt_op[OP_SUB], N, 0.4), "dist: ADD i SUB po 40 %");
        expect_true(near(cnt_op[OP_AND], N, 0.04), "dist :/ — 20 % dzielone na 5 kodow");
        expect_true(near(n_a0, N, 0.1) && near(n_aff, N, 0.1), "dist: a=00 i a=FF po 10 %");
        expect_true(n_shift_bad == 0, "implikacja: przesuniecie b < 8");
        expect_true(d.n_post == N, "post_randomize po kazdym losowaniu");

        // 3. randomize() with — ograniczenia w miejscu wywołania; miękkie ustępuje twardemu
        ok = d.randomize() with { op == OP_SUB; a == b; };
        expect_true(ok && d.op == OP_SUB && d.a == d.b && d.res == 0 && !d.carry, "with: SUB, a == b");
        ok = d.randomize() with { b == 8'h00; };
        expect_true(ok && d.b == 8'h00, "soft: twarde b == 0 wygrywa z miekkim b != 0");

        // 4. sprzeczne ograniczenia: randomize() zwraca 0, pola bez zmian
        x  = d.a;
        ok = d.randomize() with { a > 8'd10; a < 8'd5; };
        expect_true(ok == 0 && d.a == x, "sprzecznosc: wynik 0, obiekt bez zmian");

        // 5. constraint_mode i rand_mode. W alu_txn_dist wyłączenie c_legal nic nie zmienia: dist działa
        //    też jak inside — wartości spoza listy (OP_BAD) mają wagę 0.
        d.c_legal.constraint_mode(0);
        t.c_legal.constraint_mode(0);
        n_a0 = 0; ok = 0;
        repeat (400) begin
            void'(d.randomize());
            void'(t.randomize());
            if (d.op == OP_BAD) n_a0++;
            if (t.op == OP_BAD) ok++;
        end
        $display("constraint_mode(0): OP_BAD w alu_txn %0d/400, w alu_txn_dist %0d/400", ok, n_a0);
        expect_true(ok > 0, "constraint_mode(0): OP_BAD dopuszczony w alu_txn");
        expect_true(n_a0 == 0, "dist ogranicza op do wartosci z listy");
        d.c_legal.constraint_mode(1);
        t.c_legal.constraint_mode(1);
        d.a.rand_mode(0);
        d.a = 8'h42;
        repeat (50) begin
            void'(d.randomize());
            if (d.a != 8'h42) errors++;
        end
        d.a.rand_mode(1);

        // 6. kolejność rozwiązywania: bez solve-before sel = 1 tylko dla 1 z 257 rozwiązań
        s  = new();
        so = new();
        n_sel = 0; n_sel_o = 0;
        repeat (N) begin
            void'(s.randomize());
            void'(so.randomize());
            n_sel   += s.sel;
            n_sel_o += so.sel;
            if ((s.sel && s.v != 0) || (so.sel && so.v != 0)) errors++;
        end
        $display("solve-before: P(sel=1) bez = %0.3f, z = %0.3f", real'(n_sel) / N, real'(n_sel_o) / N);
        expect_true(near(n_sel_o, N, 0.5), "solve sel before v: P(sel=1) = 1/2");
        expect_true(n_sel < N / 50, "bez solve-before: sel = 1 rzadko (1 z 257 rozwiazan)");

        // 7. randc: każde 8 kolejnych losowań to permutacja 0..7
        c = new();
        for (int cycle = 0; cycle < 4; cycle++) begin
            seen = '0;
            repeat (8) begin
                void'(c.randomize());
                seen[c.k] = 1'b1;
            end
            expect_true(seen == 8'hFF, $sformatf("randc: cykl %0d nie jest permutacja", cycle));
        end

        // 8. powtarzalność: to samo ziarno obiektu daje ten sam ciąg
        t.srandom(42);
        foreach (first[i]) begin void'(t.randomize()); first[i] = t.a; end
        t.srandom(42);
        foreach (first[i]) begin void'(t.randomize()); if (t.a != first[i]) errors++; end

        // 9. std::randomize — losowanie zmiennych spoza klasy
        repeat (100) begin
            ok = std::randomize(x) with { x inside {[8'd100:8'd110]}; x % 2 == 0; };
            if (!ok || x < 100 || x > 110 || x[0]) errors++;
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
