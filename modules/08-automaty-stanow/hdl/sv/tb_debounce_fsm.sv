// Testbench debounce_fsm (N = 8): 30 naciśnięć z drganiami przy wciśnięciu i puszczeniu.
// Model zapisany inaczej niż automat: licznik kolejnych taktów, w których wejście po synchronizacji różni się
// od przyjętego poziomu; poziom zmienia się, gdy licznik osiągnie N + 1.
`timescale 1ns / 1ps

module tb_debounce_fsm;
    localparam int N = 8, PRESSES = 30;

    logic clk = 1'b0, rst = 1'b1, btn = 1'b0, raw, level, rise, fall;

    always #5 clk = ~clk;

    debounce_fsm #(.N(N)) dut (.*);

    logic m1 = 1'b0, m2 = 1'b0, lvl = 1'b0;
    int   run = 0, errors = 0, rises = 0, falls = 0, raw_edges = 0;

    task automatic cycle(logic value);         // jeden takt z danym btn; sprawdzenie po zboczu
        logic e_rise = 1'b0, e_fall = 1'b0;
        btn = value;
        @(negedge clk);
        if (m2 != lvl) begin                   // model zbocza: automat widział stare m2
            run++;
            if (run == N + 1) begin
                lvl = m2; run = 0; e_rise = m2; e_fall = ~m2;
            end
        end else begin
            run = 0;
        end
        if (m1 && !m2) raw_edges++;
        m2 = m1;
        m1 = value;
        if (raw != m2 || level != lvl || rise != e_rise || fall != e_fall) begin
            $display("t=%0t: raw=%b level=%b rise=%b fall=%b, oczekiwano %b %b %b %b",
                     $time, raw, level, rise, fall, m2, lvl, e_rise, e_fall);
            errors++;
        end
        if (rise) rises++;
        if (fall) falls++;
    endtask

    task automatic bounce_then(logic value);   // kilka krótkich drgań, potem stały poziom
        int nb = $urandom_range(5);
        for (int b = 0; b < nb; b++) begin
            repeat (1 + $urandom_range(N - 3)) cycle(value);
            repeat (1 + $urandom_range(N - 3)) cycle(~value);
        end
        repeat (N + 3 + $urandom_range(2 * N - 1)) cycle(value);
    endtask

    initial begin
        @(negedge clk);
        @(negedge clk) rst = 1'b0;
        repeat (5) cycle(1'b0);
        for (int p = 0; p < PRESSES; p++) begin
            bounce_then(1'b1);                 // wciśnięcie
            bounce_then(1'b0);                 // puszczenie
        end

        $display("nacisniecia: %0d, impulsy rise: %0d, zbocza raw: %0d", PRESSES, rises, raw_edges);
        if (rises != PRESSES || falls != PRESSES) begin
            $display("liczba rise/fall rozna od liczby nacisniec"); errors++;
        end
        if (raw_edges <= PRESSES) begin
            $display("test nie wygenerowal drgan"); errors++;
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
