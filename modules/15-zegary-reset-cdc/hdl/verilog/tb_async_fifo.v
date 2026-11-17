// Testbench async_fifo (W = 8, głębokość 16): zapis 100 MHz, odczyt 72,99 MHz, 4000 słów. Fazy: zapis
// szybszy od odczytu (kolejka się zapełnia), odczyt szybszy (opróżnia się), po równo. Sprawdzane: kolejność
// i wartości (model w buforze cyklicznym), brak przepełnienia (zapisane − odczytane <= 16) i odczytu z pustej,
// pokrycie: wr_full i rd_empty osiągnięte, zapis odrzucony przy pełnej.
`default_nettype none
`timescale 1ns / 1ps

module tb_async_fifo;
    localparam W = 8, AW = 4, DEPTH = 16, N = 4000;
    reg wr_clk = 1'b0, rd_clk = 1'b0, wr_rst = 1'b1, rd_rst = 1'b1;
    always #5    wr_clk = ~wr_clk;
    always #6.85 rd_clk = ~rd_clk;

    reg          wr_en = 1'b0, rd_en = 1'b0;
    reg  [W-1:0] wr_data = 8'd0;
    wire         wr_full, rd_empty;
    wire [W-1:0] rd_data;
    async_fifo #(.W(W), .AW(AW)) dut (.wr_clk(wr_clk), .wr_rst(wr_rst), .wr_en(wr_en), .wr_data(wr_data),
                                      .wr_full(wr_full), .rd_clk(rd_clk), .rd_rst(rd_rst), .rd_en(rd_en),
                                      .rd_data(rd_data), .rd_empty(rd_empty));

    reg [W-1:0] model [0:8191];
    integer errors = 0, n_wr = 0, n_rd = 0, n_full = 0, n_empty = 0, n_odrz = 0, faza = 0, seed = 5, p;

    always @(negedge wr_clk) begin
        p = (faza == 0) ? 90 : (faza == 1) ? 20 : 50;
        wr_en   <= !wr_rst && n_wr < N && ($unsigned($random(seed)) % 100 < p);
        wr_data <= $random(seed);
    end
    always @(negedge rd_clk) begin
        rd_en <= !rd_rst && ($unsigned($random(seed)) % 100 < ((faza == 0) ? 20 : (faza == 1) ? 90 : 50));
    end

    always @(posedge wr_clk) if (!wr_rst) begin
        if (wr_en && !wr_full) begin model[n_wr] = wr_data; n_wr = n_wr + 1; end
        if (wr_en && wr_full) n_odrz = n_odrz + 1;
        if (wr_full) n_full = n_full + 1;
        if (n_wr - n_rd > DEPTH) begin $display("%0t: przepelnienie", $time); errors = errors + 1; end
    end
    always @(posedge rd_clk) if (!rd_rst) begin
        if (rd_empty) n_empty = n_empty + 1;
        if (rd_en && !rd_empty) begin
            if (n_rd >= n_wr) begin $display("%0t: odczyt z pustej", $time); errors = errors + 1; end
            else if (rd_data !== model[n_rd]) begin
                $display("%0t: odczytano %h, oczekiwano %h", $time, rd_data, model[n_rd]); errors = errors + 1;
            end
            n_rd = n_rd + 1;
        end
    end

    initial begin
        #100;
        @(negedge wr_clk) wr_rst = 1'b0;
        @(negedge rd_clk) rd_rst = 1'b0;
        while (n_rd < N) begin
            #2000;
            faza = (faza + 1) % 3;
        end
        $display("zapisanych %0d, odczytanych %0d; taktow z wr_full %0d, z rd_empty %0d, zapisow odrzuconych %0d",
                 n_wr, n_rd, n_full, n_empty, n_odrz);
        if (n_full == 0 || n_empty == 0 || n_odrz == 0) begin $display("pokrycie niepelne"); errors = errors + 1; end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
    initial begin
        #2000000 $display("FAIL: przekroczony czas"); $finish;
    end
endmodule

`default_nettype wire
