// Testbench (SystemVerilog) zadania 6: FIFO 16 × 8 b, losowe zapisy i odczyty w trzech fazach (przewaga zapisów, odczytów, po
// równo). Model: kolejka w tablicy. Sprawdzane w każdym takcie: full i empty zgodne z zapełnieniem modelu, dane
// odczytu (takt po rd_en) w kolejności zapisu; pokrycie: pełna, pusta, zapis przy pełnej, odczyt przy pustej.
`timescale 1ns / 1ps
`default_nettype none

module tb_sync_fifo;
    logic        clk = 1'b0;
    logic        rst = 1'b1;
    logic        wr_en = 1'b0;
    logic        rd_en = 1'b0;
    logic  [7:0] wr_data = 8'd0;
    logic [7:0] rd_data;
    logic       full, empty;
    always #5 clk = ~clk;

    sync_fifo #(.W(8), .AW(4)) dut (.clk(clk), .rst(rst), .wr_en(wr_en), .wr_data(wr_data), .full(full),
                                    .rd_en(rd_en), .rd_data(rd_data), .empty(empty));

    logic [7:0] model [0:4095];
    int   errors = 0, n_wr = 0, n_rd = 0, faza = 0, i, seed = 9;
    int   cnt = 0, n_full = 0, n_empty = 0, n_wr_full = 0, n_rd_empty = 0;
    logic       pending = 1'b0;
    logic [7:0] exp_data = 8'd0;

    always @(posedge clk)
        if (!rst) begin
            if (pending && rd_data !== exp_data) begin
                $display("%0t: odczytano %h, oczekiwano %h", $time, rd_data, exp_data); errors = errors + 1;
            end
            pending = 1'b0;
            if (full !== (n_wr - n_rd == 16) || empty !== (n_wr == n_rd)) begin
                $display("%0t: full=%b empty=%b przy zapelnieniu %0d", $time, full, empty, n_wr - n_rd);
                errors = errors + 1;
            end
            if (full)  n_full = n_full + 1;
            if (empty) n_empty = n_empty + 1;
            if (wr_en && full)  n_wr_full = n_wr_full + 1;
            if (rd_en && empty) n_rd_empty = n_rd_empty + 1;
            cnt = n_wr - n_rd;                      // zapełnienie przed zboczem — to widzi układ
            if (rd_en && cnt > 0) begin
                exp_data = model[n_rd % 4096];
                pending  = 1'b1;
                n_rd     = n_rd + 1;
            end
            if (wr_en && cnt < 16) begin
                model[n_wr % 4096] = wr_data;
                n_wr = n_wr + 1;
            end
        end

    initial begin
        repeat (3) @(negedge clk);
        rst = 1'b0;
        for (i = 0; i < 3000; i = i + 1) begin
            @(negedge clk);
            faza    = (i / 200) % 3;
            wr_en   = ($unsigned($random(seed)) % 100) < ((faza == 0) ? 80 : (faza == 1) ? 20 : 50);
            rd_en   = ($unsigned($random(seed)) % 100) < ((faza == 0) ? 20 : (faza == 1) ? 80 : 50);
            wr_data = $random(seed);
        end
        @(negedge clk) begin wr_en = 1'b0; rd_en = 1'b0; end
        @(negedge clk);
        $display("zapisanych %0d, odczytanych %0d; taktow z full %0d, z empty %0d; zapisow przy full %0d, odczytow przy empty %0d",
                 n_wr, n_rd, n_full, n_empty, n_wr_full, n_rd_empty);
        if (n_full == 0 || n_empty == 0 || n_wr_full == 0 || n_rd_empty == 0) begin
            $display("pokrycie niepelne"); errors = errors + 1;
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
    initial begin #200000; $display("FAIL: przekroczony czas"); $finish; end
endmodule

`default_nettype wire
