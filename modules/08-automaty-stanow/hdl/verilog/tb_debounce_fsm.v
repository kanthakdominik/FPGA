// Testbench debounce_fsm (N = 8): 30 naciśnięć z drganiami przy wciśnięciu i puszczeniu.
// Model zapisany inaczej niż automat: licznik kolejnych taktów, w których wejście po synchronizacji różni się
// od przyjętego poziomu; poziom zmienia się, gdy licznik osiągnie N + 1.
`default_nettype none
`timescale 1ns / 1ps

module tb_debounce_fsm;
    localparam N = 8, PRESSES = 30;

    reg  clk = 1'b0, rst = 1'b1, btn = 1'b0;
    wire raw, level, rise, fall;

    always #5 clk = ~clk;

    debounce_fsm #(.N(N)) dut (.clk(clk), .rst(rst), .btn(btn), .raw(raw), .level(level), .rise(rise), .fall(fall));

    reg     m1 = 1'b0, m2 = 1'b0, lvl = 1'b0, e_rise = 1'b0, e_fall = 1'b0;
    integer run = 0, errors = 0, rises = 0, falls = 0, raw_edges = 0, p, b, nb, seed = 41;

    task cycle;                                // jeden takt z danym btn; sprawdzenie po zboczu
        input value;
        begin
            btn = value;
            @(negedge clk);
            e_rise = 1'b0; e_fall = 1'b0;      // model zbocza: automat widział stare m2
            if (m2 != lvl) begin
                run = run + 1;
                if (run == N + 1) begin
                    lvl = m2; run = 0; e_rise = m2; e_fall = ~m2;
                end
            end else begin
                run = 0;
            end
            if (m1 && !m2) raw_edges = raw_edges + 1;
            m2 = m1;
            m1 = value;
            if (raw !== m2 || level !== lvl || rise !== e_rise || fall !== e_fall) begin
                $display("t=%0t: raw=%b level=%b rise=%b fall=%b, oczekiwano %b %b %b %b",
                         $time, raw, level, rise, fall, m2, lvl, e_rise, e_fall);
                errors = errors + 1;
            end
            if (rise) rises = rises + 1;
            if (fall) falls = falls + 1;
        end
    endtask

    task bounce_then;                          // kilka krótkich drgań, potem stały poziom
        input value;
        begin
            nb = ($random(seed) & 32'h7fffffff) % 6;      // liczba drgań wylosowana raz
            for (b = 0; b < nb; b = b + 1) begin
                repeat (1 + (($random(seed) & 32'h7fffffff) % (N - 2))) cycle(value);
                repeat (1 + (($random(seed) & 32'h7fffffff) % (N - 2))) cycle(~value);
            end
            repeat (N + 3 + (($random(seed) & 32'h7fffffff) % (2 * N))) cycle(value);
        end
    endtask

    initial begin
        @(negedge clk);
        @(negedge clk) rst = 1'b0;
        repeat (5) cycle(1'b0);
        for (p = 0; p < PRESSES; p = p + 1) begin
            bounce_then(1'b1);                 // wciśnięcie
            bounce_then(1'b0);                 // puszczenie
        end

        $display("nacisniecia: %0d, impulsy rise: %0d, zbocza raw: %0d", PRESSES, rises, raw_edges);
        if (rises != PRESSES || falls != PRESSES) begin
            $display("liczba rise/fall rozna od liczby nacisniec"); errors = errors + 1;
        end
        if (raw_edges <= PRESSES) begin
            $display("test nie wygenerowal drgan"); errors = errors + 1;
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
