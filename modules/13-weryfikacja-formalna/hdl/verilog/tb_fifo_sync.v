// Testbench fifo_sync: 3000 taktów losowych zapisów i odczytów w trzech fazach (napełnianie, równowaga,
// opróżnianie), model w buforze cyklicznym. W każdym takcie sprawdzane: count, full, empty i rd_data
// (najstarszy element). Pokrycie: pełna, pusta po pełnej, jednoczesny zapis i odczyt, zapis odrzucony.
`default_nettype none
`timescale 1ns / 1ps

module tb_fifo_sync;
    localparam W = 8, AW = 3, DEPTH = 8;
    reg          clk = 1'b0, rst = 1'b1, wr_en = 1'b0, rd_en = 1'b0;
    reg  [W-1:0] wr_data = 8'd0;
    wire [W-1:0] rd_data;
    wire         full, empty;
    wire [AW:0]  count;
    reg  [W-1:0] q [0:DEPTH-1];
    integer      head = 0, size = 0, n, p_wr, seed = 31;
    integer      errors = 0, n_full = 0, n_empty_after_full = 0, n_both = 0, n_rejected = 0;
    reg          was_full = 1'b0;

    always #5 clk = ~clk;

    fifo_sync #(.W(W), .AW(AW)) dut (.clk(clk), .rst(rst), .wr_en(wr_en), .wr_data(wr_data), .full(full),
                                     .rd_en(rd_en), .rd_data(rd_data), .empty(empty), .count(count));

    initial begin
        repeat (2) @(negedge clk);
        rst = 1'b0;
        for (n = 0; n < 3000; n = n + 1) begin
            p_wr    = (n % 600 < 200) ? 80 : (n % 600 < 400) ? 50 : 20;
            wr_en   = ($unsigned($random(seed)) % 100) < p_wr;
            rd_en   = ($unsigned($random(seed)) % 100) < 100 - p_wr;
            wr_data = $random(seed);
            #1;
            if (count !== size || full !== (size == DEPTH) || empty !== (size == 0)) begin
                $display("takt %0d: count=%0d full=%b empty=%b, model %0d", n, count, full, empty, size);
                errors = errors + 1;
            end
            if (size > 0 && rd_data !== q[head]) begin
                $display("takt %0d: rd_data=%h, oczekiwano %h", n, rd_data, q[head]); errors = errors + 1;
            end
            if (full) begin n_full = n_full + 1; was_full = 1'b1; end
            if (was_full && empty) n_empty_after_full = n_empty_after_full + 1;
            if (wr_en && full) n_rejected = n_rejected + 1;
            if (wr_en && rd_en && !full && !empty) n_both = n_both + 1;
            if (rd_en && size > 0) begin head = (head + 1) % DEPTH; size = size - 1; end
            if (wr_en && !full) begin q[(head + size) % DEPTH] = wr_data; size = size + 1; end
            @(negedge clk);
        end
        if (n_full == 0 || n_empty_after_full == 0 || n_both == 0 || n_rejected == 0) begin
            $display("pokrycie: full %0d, pusta po pelnej %0d, zapis+odczyt %0d, odrzucone %0d",
                     n_full, n_empty_after_full, n_both, n_rejected);
            errors = errors + 1;
        end
        $display("taktow z pelna: %0d, zapisow odrzuconych: %0d", n_full, n_rejected);
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
