// Testbench (SystemVerilog) UART (20.01), zegar 50 MHz:
//   1. pętla uart_tx -> uart_rx, 115 200 b/s, bez parzystości, nieparzysta i parzysta — po 40 bajtów;
//      długość ramki nadajnika = NB·CLK/BAUD taktów (±1),
//   2. tolerancja odbiornika (500 000 b/s, 8N1): model linii nadaje z szybkością odchyloną o −6…+6 %
//      co 0,5 %; dla każdego odchylenia 20 bajtów; wypisuje zakres odchyleń bez błędów (wymagane ±3,5 %),
//   3. zakłócenia: impuls 0,25 bitu w spoczynku przed każdym bajtem i impuls 1/16 bitu w środku bitu —
//      bajty poprawne, żadnych fałszywych,
//   4. błąd ramki (bit stopu = 0) i błąd parzystości — flagi ustawione.
`timescale 1ns / 1ps
`default_nettype none

module tb_uart;
    logic clk = 1'b0;
    always #10 clk = ~clk;                                  // 50 MHz
    logic rst = 1'b1;
    int errors = 0, i, k, d, n_ok, dmin, dmax;

    // ---------- 1. pętla nadajnik -> odbiornik w trzech konfiguracjach
    logic  [2:0] start = 3'b000;
    logic  [7:0] bajt = 8'd0;
    logic [2:0] gotowy, tx, wazne, bl_r, bl_p;
    wire  [7:0] odebr [0:2];
    genvar g;
    generate
        for (g = 0; g < 3; g = g + 1) begin : g_cfg
            uart_tx #(.CLK_HZ(50_000_000), .BAUD(115_200), .PARZ(g)) u_tx (.clk(clk), .rst(rst),
                .start(start[g]), .dane(bajt), .gotowy(gotowy[g]), .tx(tx[g]));
            uart_rx #(.CLK_HZ(50_000_000), .BAUD(115_200), .PARZ(g)) u_rx (.clk(clk), .rst(rst),
                .rx(tx[g]), .dane(odebr[g]), .wazne(wazne[g]), .blad_ramki(bl_r[g]), .blad_parz(bl_p[g]));
        end
    endgenerate

    // ---------- 2-4. model linii -> odbiorniki 500 000 b/s: 8N1 i 8E1
    localparam real BIT = 2000.0;                           // ns przy 500 000 b/s
    logic        linia = 1'b1, linia_p = 1'b1;
    logic       w0, w2, r0, r2, p0, p2;
    logic [7:0] d0, d2;
    uart_rx #(.CLK_HZ(50_000_000), .BAUD(500_000), .PARZ(0)) u_rx0 (.clk(clk), .rst(rst), .rx(linia),
        .dane(d0), .wazne(w0), .blad_ramki(r0), .blad_parz(p0));
    uart_rx #(.CLK_HZ(50_000_000), .BAUD(500_000), .PARZ(2)) u_rx2 (.clk(clk), .rst(rst), .rx(linia_p),
        .dane(d2), .wazne(w2), .blad_ramki(r2), .blad_parz(p2));

    // odbiór: ostatni bajt i liczniki
    int n_wazne0 = 0, n_wazne2 = 0, n_rx [0:2];
    logic [7:0] ost0, ost2;
    logic       ostr0, ostr2, ostp2;
    logic       log_r0 [0:4095];                              // flaga błędu ramki każdego odebranego bajtu
    initial begin n_rx[0] = 0; n_rx[1] = 0; n_rx[2] = 0; end
    always @(posedge clk) begin
        if (w0) begin log_r0[n_wazne0] = r0; n_wazne0 = n_wazne0 + 1; ost0 = d0; ostr0 = r0; end
        if (w2) begin n_wazne2 = n_wazne2 + 1; ost2 = d2; ostr2 = r2; ostp2 = p2; end
    end

    // nadanie ramki linią: bity od najmłodszego, okres bitu bit_ns
    task nadaj(input [11:0] bity, input int n, input real bit_ns, input int ktora);
        int j;
        begin
            for (j = 0; j < n; j = j + 1) begin
                if (ktora == 0) linia = bity[j]; else linia_p = bity[j];
                #(bit_ns);
            end
        end
    endtask

    // ---------- 1: sprawdzanie pętli
    logic [7:0] wzor [0:2][0:39];
    int   t0, dl [0:2];
    generate
        for (g = 0; g < 3; g = g + 1) begin : g_spr
            always @(posedge clk) if (wazne[g]) begin
                if (odebr[g] !== wzor[g][n_rx[g]] || bl_r[g] || bl_p[g]) begin
                    if (errors < 10) $display("petla PARZ=%0d bajt %0d: %h, oczekiwano %h", g, n_rx[g], odebr[g], wzor[g][n_rx[g]]);
                    errors = errors + 1;
                end
                n_rx[g] = n_rx[g] + 1;
            end
        end
    endgenerate

    logic [7:0] b;
    initial begin
        repeat (5) @(posedge clk);
        rst = 1'b0;
        // 1. pętla
        for (k = 0; k < 3; k = k + 1)
            for (i = 0; i < 40; i = i + 1) begin
                @(negedge clk);
                bajt = (i < 2) ? (i == 0 ? 8'h00 : 8'hFF) : $random;
                wzor[k][i] = bajt;
                start[k] = 1'b1;
                t0 = $time;
                @(negedge clk) start[k] = 1'b0;
                wait (gotowy[k]);
                dl[k] = ($time - t0) / 20;
            end
        repeat (2000) @(posedge clk);
        $display("petla: odebrano %0d / %0d / %0d bajtow; ramka %0d, %0d, %0d taktow", n_rx[0], n_rx[1], n_rx[2],
                 dl[0], dl[1], dl[2]);
        if (n_rx[0] != 40 || n_rx[1] != 40 || n_rx[2] != 40) errors = errors + 1;
        // ramka 10 / 11 / 11 bitów po 434,03 taktu
        if (dl[0] < 4338 || dl[0] > 4344 || dl[1] < 4772 || dl[1] > 4778 || dl[2] < 4772 || dl[2] > 4778) begin
            $display("zla dlugosc ramki nadajnika");
            errors = errors + 1;
        end

        // 2. tolerancja szybkości
        dmin = -5; dmax = -5;
        for (d = 0; d <= 60; d = d + 5) begin                  // +d promili
            n_ok = 0;
            for (i = 0; i < 20; i = i + 1) begin
                b = $random;
                k = n_wazne0;
                nadaj({1'b1, b, 1'b0}, 10, BIT * (1.0 + d / 1000.0), 0);
                #(BIT * (1.0 + d / 1000.0));
                if (n_wazne0 == k + 1 && ost0 == b && !ostr0) n_ok = n_ok + 1;
            end
            if (n_ok == 20 && dmax == d - 5) dmax = d;
        end
        for (d = 0; d <= 60; d = d + 5) begin                  // -d promili
            n_ok = 0;
            for (i = 0; i < 20; i = i + 1) begin
                b = $random;
                k = n_wazne0;
                nadaj({1'b1, b, 1'b0}, 10, BIT * (1.0 - d / 1000.0), 0);
                #(BIT * (1.0 - d / 1000.0));
                if (n_wazne0 == k + 1 && ost0 == b && !ostr0) n_ok = n_ok + 1;
            end
            if (n_ok == 20 && dmin == d - 5) dmin = d;
        end
        $display("tolerancja odbiornika 8N1, 16 probek na bit: od -%0d do +%0d promili bez bledow", dmin, dmax);
        if (dmin < 35 || dmax < 35) errors = errors + 1;

        // 3. zakłócenia
        #(5 * BIT);
        k = n_wazne0;
        n_ok = 0;
        for (i = 0; i < 20; i = i + 1) begin
            b = $random;
            linia = 1'b0; #(BIT / 4); linia = 1'b1; #(2 * BIT);             // impuls 0,25 bitu w spoczynku
            linia = 1'b0; #(BIT);                                           // start
            for (d = 0; d < 8; d = d + 1) begin                             // dane z impulsem 1/16 bitu w środku bitu 3
                linia = b[d];
                if (d == 3) begin
                    #(BIT * 15 / 32); linia = ~b[d]; #(BIT / 16); linia = b[d]; #(BIT * 15 / 32);
                end else
                    #(BIT);
            end
            linia = 1'b1; #(2 * BIT);
            if (ost0 == b && !ostr0) n_ok = n_ok + 1;
        end
        $display("zaklocenia: %0d / 20 bajtow poprawnych, odebranych %0d", n_ok, n_wazne0 - k);
        if (n_ok != 20 || n_wazne0 - k != 20) errors = errors + 1;

        // 4. błąd ramki i parzystości
        k = n_wazne0;
        nadaj({1'b0, 8'hA5, 1'b0}, 10, BIT, 0);                            // bit stopu = 0
        linia = 1'b1; #(3 * BIT);
        // po bicie stopu = 0 linia jest jeszcze niska — odbiornik może zacząć kolejną (fałszywą) ramkę;
        // sprawdzana jest flaga pierwszej ramki
        if (n_wazne0 < k + 1 || log_r0[k] !== 1'b1) begin $display("brak bledu ramki"); errors = errors + 1; end
        k = n_wazne2;
        nadaj({1'b1, 1'b0, 8'h5A, 1'b0}, 11, BIT, 2);                      // 0x5A: 4 jedynki, parzysta = 0 — poprawna
        linia_p = 1'b1; #(2 * BIT);
        if (n_wazne2 != k + 1 || ostp2 || ost2 != 8'h5A) begin $display("zla parzystosc poprawnej ramki"); errors = errors + 1; end
        nadaj({1'b1, 1'b1, 8'h5A, 1'b0}, 11, BIT, 2);                      // zły bit parzystości
        linia_p = 1'b1; #(2 * BIT);
        if (n_wazne2 != k + 2 || !ostp2) begin $display("brak bledu parzystosci"); errors = errors + 1; end

        if (errors == 0) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
