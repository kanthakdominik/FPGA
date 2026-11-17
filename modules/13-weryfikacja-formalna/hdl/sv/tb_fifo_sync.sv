// Testbench fifo_sync: 3000 taktów losowych zapisów i odczytów w trzech fazach (napełnianie, równowaga,
// opróżnianie), model w kolejce SystemVeriloga. W każdym takcie sprawdzane: count, full, empty i rd_data
// (najstarszy element). Pokrycie: pełna, pusta po pełnej, jednoczesny zapis i odczyt, zapis odrzucony.
`timescale 1ns / 1ps

module tb_fifo_sync;
    localparam int W = 8, AW = 3, DEPTH = 1 << AW;
    logic          clk = 1'b0, rst = 1'b1, wr_en = 1'b0, rd_en = 1'b0;
    logic [W-1:0]  wr_data = '0, rd_data;
    logic          full, empty;
    logic [AW:0]   count;
    logic [W-1:0]  q [$];
    int            errors = 0, n_full = 0, n_empty_after_full = 0, n_both = 0, n_rejected = 0;
    bit            was_full = 0;

    always #5 clk = ~clk;

    fifo_sync #(.W(W), .AW(AW)) dut (.*);

    initial begin
        int p_wr;
        repeat (2) @(negedge clk);
        rst = 1'b0;
        for (int n = 0; n < 3000; n++) begin
            p_wr    = (n % 600 < 200) ? 80 : (n % 600 < 400) ? 50 : 20;     // fazy
            wr_en   = ($urandom_range(99) < p_wr);
            rd_en   = ($urandom_range(99) < 100 - p_wr);
            wr_data = W'($urandom);
            #1;
            if (count !== ($bits(count))'(q.size()) || full !== (q.size() == DEPTH) || empty !== (q.size() == 0)) begin
                $display("takt %0d: count=%0d full=%b empty=%b, model %0d", n, count, full, empty, q.size());
                errors++;
            end
            if (q.size() > 0 && rd_data !== q[0]) begin
                $display("takt %0d: rd_data=%h, oczekiwano %h", n, rd_data, q[0]); errors++;
            end
            if (full) begin n_full++; was_full = 1; end
            if (was_full && empty) n_empty_after_full++;
            if (wr_en && full) n_rejected++;
            if (rd_en && q.size() > 0) void'(q.pop_front());
            if (wr_en && !full) q.push_back(wr_data);
            if (wr_en && rd_en && !full && !empty) n_both++;
            @(negedge clk);
        end
        if (n_full == 0 || n_empty_after_full == 0 || n_both == 0 || n_rejected == 0) begin
            $display("pokrycie: full %0d, pusta po pelnej %0d, zapis+odczyt %0d, odrzucone %0d",
                     n_full, n_empty_after_full, n_both, n_rejected);
            errors++;
        end
        $display("taktow z pelna: %0d, zapisow odrzuconych: %0d", n_full, n_rejected);
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
