// Testbench (SystemVerilog) 22.02: łącze źródłowo-synchroniczne DDR — zs_nadajnik (PRBS7, 2 bity na takt, zegar 100 MHz,
// UI = 5 ns) -> kanał (dane opóźnione o 1 ns, zegar o 1 ns + przesunięcie) -> zs_odbiornik -> prbs7_spr.
// Odbiornik ma wymagania czasowe tSU = 1,0 ns i tH = 0,5 ns sprawdzane monitorem przy każdym zboczu
// odebranego zegara. Przesunięcie zegara względem danych zmieniane od 0 do 5 ns co 0,25 ns: punkt jest
// dobry, gdy nie ma naruszeń i błędów PRBS. Oczekiwane okno: od tSU do UI − tH, szerokość UI − tSU − tH.
`timescale 1ns / 1ps
`default_nettype none

module tb_ddr;
    localparam real TSU = 1.0, TH = 0.5, UI = 5.0, DANE = 1.0;
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic rst = 1'b1, rst_rx = 1'b1;
    int errors = 0;

    logic [1:0] bity, odebr;
    logic       tx_clk, tx_d;
    logic        rx_clk = 1'b0, rx_d = 1'b0;
    real       przes = 0.0;
    logic [15:0] bledy;
    logic        synch;

    prbs7 #(.N(2)) u_gen (.clk(clk), .rst(rst), .en(1'b1), .q(bity));
    zs_nadajnik u_tx (.clk(clk), .dane(bity), .tx_clk(tx_clk), .tx_d(tx_d));
    always @(tx_d)   rx_d   <= #(DANE) tx_d;                 // kanał: opóźnienie transportowe
    always @(tx_clk) rx_clk <= #(DANE + przes) tx_clk;
    zs_odbiornik u_rx (.rx_clk(rx_clk), .rx_d(rx_d), .dane(odebr));
    prbs7_spr #(.N(2)) u_spr (.clk(rx_clk), .rst(rst_rx), .en(1'b1), .d(odebr), .bledy(bledy), .synch(synch));

    // monitor tSU / tH na wejściu odbiornika (oba zbocza rx_clk próbkują)
    real    t_d = -100.0, t_k = -100.0;
    int narusz = 0;
    logic     mon = 1'b0;
    always @(rx_d) begin
        if (mon && $realtime - t_k < TH) narusz = narusz + 1;
        t_d = $realtime;
    end
    always @(rx_clk) begin
        if (mon && $realtime - t_d < TSU) narusz = narusz + 1;
        t_k = $realtime;
    end

    int k, pierwszy, ostatni;
    logic [8*21-1:0] mapa;
    initial begin
        pierwszy = -1; ostatni = -1;
        repeat (3) @(negedge clk);
        rst = 1'b0;
        for (k = 0; k <= 20; k = k + 1) begin
            przes = 0.25 * k;
            repeat (10) @(negedge clk);
            rst_rx = 1'b1;
            repeat (3) @(negedge clk);
            rst_rx = 1'b0;
            narusz = 0;
            mon    = 1'b1;
            repeat (100) @(negedge clk);
            mon = 1'b0;
            if (narusz == 0 && bledy == 0 && synch) begin
                mapa[8*(20-k) +: 8] = "+";
                if (pierwszy < 0) pierwszy = k;
                ostatni = k;
            end else
                mapa[8*(20-k) +: 8] = ".";
        end
        $display("przesuniecie zegara 0..5 ns co 0,25 ns (+ dobre): %s", mapa);
        $display("okno: %0.2f .. %0.2f ns, szerokosc %0.2f ns (UI - tSU - tH = %0.2f ns)",
                 0.25 * pierwszy, 0.25 * ostatni, 0.25 * (ostatni - pierwszy), UI - TSU - TH);
        if (pierwszy < 0 || 0.25 * pierwszy != TSU || 0.25 * ostatni != UI - TH) errors = errors + 1;
        // dane w środku okna: dłuższy przebieg bez błędów
        przes = 2.75;
        repeat (10) @(negedge clk);
        rst_rx = 1'b1;
        repeat (3) @(negedge clk);
        rst_rx = 1'b0;
        repeat (1000) @(negedge clk);
        $display("srodek okna (2,75 ns): 2000 bitow, bledow PRBS %0d", bledy);
        if (bledy != 0 || !synch) errors = errors + 1;
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
