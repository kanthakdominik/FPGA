// Testbench fir8: impuls, skok, wzorzec nasycenia dodatni i ujemny, 2000 próbek losowych z przerwami
// w in_valid. Model na liczbach całkowitych: suma iloczynów z historii próbek, (s + 1024) >>> 11
// (zaokrąglenie w górę połówki), nasycenie do 16 bitów. Sprawdzane: każda próbka wyjściowa i opóźnienie
// (wynik po 4. zboczu od wysłania = 3 takty potoku); pokrycie: nasycenie w obie strony, połówka LSB.
`default_nettype none
`timescale 1ns / 1ps

module tb_fir8;
    reg                clk = 1'b0, rst = 1'b1, in_valid = 1'b0;
    reg  signed [11:0] in_data = 12'sd0;
    wire               out_valid;
    wire signed [15:0] out_data;

    always #5 clk = ~clk;

    fir8 dut (.clk(clk), .rst(rst), .in_valid(in_valid), .in_data(in_data), .out_valid(out_valid),
              .out_data(out_data));

    function integer coef;
        input integer i;
        begin
            case (i)
                0, 7:    coef = -763;
                2, 5:    coef = 4499;
                3, 4:    coef = 12648;
                default: coef = 0;
            endcase
        end
    endfunction

    integer hist [0:7];                     // historia próbek modelu, hist[0] — najnowsza
    integer expq [0:4095];                  // kolejka oczekiwanych wyjść (bufor cykliczny)
    integer lat  [0:4095];                  // licznik zboczy przy wysłaniu
    integer head = 0, tail = 0;
    integer errors = 0, n_out = 0, n_sat_pos = 0, n_sat_neg = 0, n_half = 0, cycle = 0;
    integer i, n, v, y, seed = 12, n_rand = 2000;
    reg signed [63:0] s;

    always @(posedge clk) cycle = cycle + 1;

    task model;
        input integer xnew;
        begin
            for (i = 7; i > 0; i = i - 1) hist[i] = hist[i-1];
            hist[0] = xnew;
            s = 0;
            for (i = 0; i < 8; i = i + 1) s = s + coef(i) * hist[i];
            if (s % 2048 == 1024 || s % 2048 == -1024) n_half = n_half + 1;
            s = (s + 1024) >>> 11;
            y = s;
            if (y > 32767)  begin y = 32767;  n_sat_pos = n_sat_pos + 1; end
            if (y < -32768) begin y = -32768; n_sat_neg = n_sat_neg + 1; end
        end
    endtask

    task send;
        input integer value;
        begin
            in_valid = 1'b1;
            in_data  = value;
            model(value);
            expq[tail % 4096] = y;
            lat[tail % 4096]  = cycle;
            tail = tail + 1;
            @(negedge clk);
            in_valid = 1'b0;
        end
    endtask

    always @(negedge clk) begin
        if (out_valid) begin
            if (head == tail) begin
                $display("%0t: wyjscie bez wejscia", $time); errors = errors + 1;
            end else begin
                n_out = n_out + 1;
                if (out_data !== expq[head % 4096]) begin
                    errors = errors + 1;
                    if (errors <= 10) $display("%0t: y = %0d, oczekiwano %0d", $time, out_data, expq[head % 4096]);
                end
                if (cycle - lat[head % 4096] != 4) begin
                    errors = errors + 1;
                    if (errors <= 10) $display("%0t: wynik po %0d zboczach zamiast 4", $time, cycle - lat[head % 4096]);
                end
                head = head + 1;
            end
        end
    end

    initial begin
        for (i = 0; i < 8; i = i + 1) hist[i] = 0;
        if (!$value$plusargs("N=%d", n_rand)) n_rand = 2000;  // liczba próbek losowych (+N=…)
        repeat (3) @(negedge clk);
        rst = 1'b0;
        @(negedge clk);
        send(2047);                                          // impuls
        repeat (10) send(0);
        repeat (12) send(1000);                              // skok
        repeat (8) send(0);
        repeat (2) begin                                     // nasycenie: znaki zgodne z h
            for (n = 7; n >= 0; n = n - 1) send(coef(n) < 0 ? -2048 : 2047);
            for (n = 7; n >= 0; n = n - 1) send(coef(n) < 0 ? 2047 : -2048);
        end
        repeat (8) send(0);
        for (n = 0; n < n_rand; n = n + 1) begin             // losowe, z przerwami
            if (($random(seed) & 3) == 0) @(negedge clk);
            if (($random(seed) & 7) == 0) v = ($random(seed) & 1) ? 2047 : -2048;
            else                          v = ($random(seed) & 4095) - 2048;
            send(v);
        end
        repeat (8) @(negedge clk);

        if (head != tail) begin
            $display("brak %0d wyjsc", tail - head); errors = errors + 1;
        end
        if (n_sat_pos == 0 || n_sat_neg == 0 || n_half == 0) begin
            $display("pokrycie: nasycenie +%0d -%0d, polowka LSB %0d", n_sat_pos, n_sat_neg, n_half);
            errors = errors + 1;
        end
        $display("probek: %0d, nasycen: +%0d -%0d, wynikow na polowce LSB: %0d", n_out, n_sat_pos, n_sat_neg, n_half);
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
