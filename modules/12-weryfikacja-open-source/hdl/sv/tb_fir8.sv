// Testbench fir8 (bez bibliotek — wersja „z modułu 09”): impuls, skok, wzorzec nasycenia dodatni i ujemny,
// 2000 próbek losowych z przerwami w in_valid. Model na liczbach całkowitych: suma iloczynów z historii
// próbek, (s + 1024) >>> 11 (zaokrąglenie w górę połówki), nasycenie do 16 bitów. Sprawdzane: każda próbka
// wyjściowa i opóźnienie 3 takty; pokrycie: nasycenie w obie strony, wynik dokładnie na połówce LSB.
`timescale 1ns / 1ps

module tb_fir8;
    logic               clk = 1'b0, rst = 1'b1, in_valid = 1'b0;
    logic signed [11:0] in_data = '0;
    logic               out_valid;
    logic signed [15:0] out_data;

    always #5 clk = ~clk;

    fir8 dut (.*);

    localparam int H [8] = '{-763, 0, 4499, 12648, 12648, 4499, 0, -763};

    int hist [8] = '{default: 0};         // historia próbek modelu, hist[0] — najnowsza
    int expq [$];                          // oczekiwane wyjścia w kolejności
    int lat [$];                           // takt wejścia dla każdego oczekiwanego wyjścia
    int errors = 0, n_out = 0, n_sat_pos = 0, n_sat_neg = 0, n_half = 0, cycle = 0, e, c;

    always @(posedge clk) cycle++;                       // licznik zboczy narastających

    function automatic int model(int xnew);
        longint s = 0;
        int     y;
        for (int i = 7; i > 0; i--) hist[i] = hist[i-1];
        hist[0] = xnew;
        foreach (H[i]) s += longint'(H[i]) * hist[i];
        if (s % 2048 == 1024 || s % 2048 == -1024) n_half++;
        y = int'((s + 1024) >>> 11);
        if (y > 32767)  begin y = 32767;  n_sat_pos++; end
        if (y < -32768) begin y = -32768; n_sat_neg++; end
        return y;
    endfunction

    task automatic send(int value);
        in_valid = 1'b1;
        in_data  = 12'(value);
        expq.push_back(model(value));
        lat.push_back(cycle);
        @(negedge clk);
        in_valid = 1'b0;
    endtask

    // porównanie na każdym zboczu opadającym; próbka wysłana przy liczniku c jest przyjmowana na zboczu
    // c + 1, a wynik pojawia się po zboczu c + 4 (potok 3 takty)
    always @(negedge clk) begin
        if (out_valid) begin
            if (expq.size() == 0) begin
                $display("%0t: wyjscie bez wejscia", $time); errors++;
            end else begin
                e = expq.pop_front();
                c = lat.pop_front();
                n_out++;
                if (out_data !== 16'(e)) begin
                    errors++;
                    if (errors <= 10) $display("%0t: y = %0d, oczekiwano %0d", $time, out_data, e);
                end
                if (cycle - c != 4) begin
                    errors++;
                    if (errors <= 10) $display("%0t: wynik po %0d zboczach zamiast 4", $time, cycle - c);
                end
            end
        end
    end

    initial begin
        int v, n_rand;
        n_rand = 2000;
        void'($value$plusargs("N=%d", n_rand));               // liczba próbek losowych (+N=…)
        repeat (3) @(negedge clk);
        rst = 1'b0;
        @(negedge clk);
        send(2047);                                           // impuls: wyjścia ~ h * 2047 / 2048
        repeat (10) send(0);
        repeat (12) send(1000);                               // skok
        repeat (8) send(0);
        repeat (2) begin                                      // nasycenie: znaki zgodne z h
            for (int i = 7; i >= 0; i--) send(H[i] < 0 ? -2048 : 2047);
            for (int i = 7; i >= 0; i--) send(H[i] < 0 ? 2047 : -2048);
        end
        repeat (8) send(0);
        for (int n = 0; n < n_rand; n++) begin                // losowe, z przerwami
            if ($urandom_range(3) == 0) @(negedge clk);
            v = ($urandom_range(7) == 0) ? (($urandom_range(1) == 1) ? 2047 : -2048) : $urandom_range(4095) - 2048;
            send(v);
        end
        repeat (8) @(negedge clk);

        if (expq.size() != 0) begin
            $display("brak %0d wyjsc", expq.size()); errors++;
        end
        if (n_sat_pos == 0 || n_sat_neg == 0 || n_half == 0) begin
            $display("pokrycie: nasycenie +%0d -%0d, polowka LSB %0d", n_sat_pos, n_sat_neg, n_half); errors++;
        end
        $display("probek: %0d, nasycen: +%0d -%0d, wynikow na polowce LSB: %0d", n_out, n_sat_pos, n_sat_neg, n_half);
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
