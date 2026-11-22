// Testbench zadania 8: FIFO 16 × 8 b, zapis 100 MHz, odczyt 73 MHz, 3000 słów w trzech fazach (przewaga zapisu,
// odczytu, po równo). Model w tablicy po stronie zapisu; dane odczytu (takt po rd_en) w kolejności zapisu,
// nigdy więcej niż 16 słów w kolejce, nigdy odczyt z pustej; pokrycie: full i empty osiągnięte.
`timescale 1ns / 1ps
`default_nettype none

module tb_async_fifo;
    localparam integer N = 3000;
    reg        wr_clk = 1'b0;
    reg        rd_clk = 1'b0;
    reg        wr_rst = 1'b1;
    reg        rd_rst = 1'b1;
    reg        wr_en = 1'b0;
    reg        rd_en = 1'b0;
    reg  [7:0] wr_data = 8'd0;
    wire [7:0] rd_data;
    wire       full, empty;
    always #5    wr_clk = ~wr_clk;
    always #6.85 rd_clk = ~rd_clk;

    async_fifo #(.W(8), .AW(4)) dut (.wr_clk(wr_clk), .wr_rst(wr_rst), .wr_en(wr_en), .wr_data(wr_data), .full(full),
                                     .rd_clk(rd_clk), .rd_rst(rd_rst), .rd_en(rd_en), .rd_data(rd_data),
                                     .empty(empty));

    reg [7:0] model [0:N-1];
    integer   errors = 0, n_wr = 0, n_rd = 0, faza = 0, seed = 21, n_full = 0, n_empty = 0;
    reg       pending = 1'b0;
    reg [7:0] exp_data = 8'd0;

    always @(negedge wr_clk) begin
        wr_en   <= !wr_rst && n_wr < N && ($unsigned($random(seed)) % 100 < ((faza == 0) ? 90 : (faza == 1) ? 20 : 50));
        wr_data <= $random(seed);
    end
    always @(negedge rd_clk)
        rd_en <= !rd_rst && ($unsigned($random(seed)) % 100 < ((faza == 0) ? 20 : (faza == 1) ? 90 : 50));

    always @(posedge wr_clk)
        if (!wr_rst) begin
            if (full) n_full = n_full + 1;
            if (wr_en && !full) begin model[n_wr] = wr_data; n_wr = n_wr + 1; end
            if (n_wr - n_rd > 16) begin $display("%0t: przepelnienie", $time); errors = errors + 1; end
        end
    always @(posedge rd_clk)
        if (!rd_rst) begin
            if (pending && rd_data !== exp_data) begin
                $display("%0t: odczytano %h, oczekiwano %h", $time, rd_data, exp_data); errors = errors + 1;
            end
            pending = 1'b0;
            if (empty) n_empty = n_empty + 1;
            if (rd_en && !empty) begin
                if (n_rd >= n_wr) begin $display("%0t: odczyt z pustej", $time); errors = errors + 1; end
                else begin exp_data = model[n_rd]; pending = 1'b1; end
                n_rd = n_rd + 1;
            end
        end

    initial begin
        #100;
        @(negedge wr_clk) wr_rst = 1'b0;
        @(negedge rd_clk) rd_rst = 1'b0;
        while (n_rd < N) begin
            #3000;
            faza = (faza + 1) % 3;
        end
        repeat (3) @(posedge rd_clk);
        $display("zapisanych %0d, odczytanych %0d; taktow z full %0d, z empty %0d", n_wr, n_rd, n_full, n_empty);
        if (n_full == 0 || n_empty == 0) begin $display("pokrycie niepelne"); errors = errors + 1; end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
    initial begin #2000000; $display("FAIL: przekroczony czas"); $finish; end
endmodule

`default_nettype wire
