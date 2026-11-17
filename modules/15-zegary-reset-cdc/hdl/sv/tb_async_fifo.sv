// Testbench async_fifo (W = 8, głębokość 16): zapis 100 MHz, odczyt 72,99 MHz, 4000 słów. Fazy: zapis
// szybszy od odczytu (kolejka się zapełnia), odczyt szybszy (opróżnia się), losowo. Sprawdzane: kolejność
// i wartości (model w kolejce), brak przepełnienia (zapisane − odczytane <= 16) i odczytu z pustej,
// pokrycie: wr_full i rd_empty osiągnięte, zapis odrzucony przy pełnej.
`timescale 1ns / 1ps

module tb_async_fifo;
    localparam int W = 8, AW = 4, DEPTH = 1 << AW, N = 4000;
    logic wr_clk = 1'b0, rd_clk = 1'b0, wr_rst = 1'b1, rd_rst = 1'b1;
    always #5     wr_clk = ~wr_clk;
    always #6.85  rd_clk = ~rd_clk;

    logic         wr_en = 1'b0, rd_en = 1'b0, wr_full, rd_empty;
    logic [W-1:0] wr_data = '0, rd_data;
    async_fifo #(.W(W), .AW(AW)) dut (.*);

    logic [W-1:0] model [$];
    int errors = 0, n_wr = 0, n_rd = 0, n_full = 0, n_empty = 0, n_odrz = 0, faza = 0;

    // faza: 0 — zapis często, odczyt rzadko; 1 — odwrotnie; 2 — po równo
    always @(negedge wr_clk) begin
        wr_en   <= !wr_rst && n_wr < N && ($urandom_range(99) < (faza == 0 ? 90 : faza == 1 ? 20 : 50));
        wr_data <= W'($urandom);
    end
    always @(negedge rd_clk)
        rd_en <= !rd_rst && ($urandom_range(99) < (faza == 0 ? 20 : faza == 1 ? 90 : 50));

    always @(posedge wr_clk) if (!wr_rst) begin
        if (wr_en && !wr_full) begin model.push_back(wr_data); n_wr++; end
        if (wr_en && wr_full) n_odrz++;
        if (wr_full) n_full++;
        if (n_wr - n_rd > DEPTH) begin $display("%0t: przepelnienie", $time); errors++; end
    end
    always @(posedge rd_clk) if (!rd_rst) begin
        if (rd_empty) n_empty++;
        if (rd_en && !rd_empty) begin
            if (model.size() == 0) begin $display("%0t: odczyt z pustej", $time); errors++; end
            else begin
                if (rd_data !== model[0]) begin
                    $display("%0t: odczytano %h, oczekiwano %h", $time, rd_data, model[0]); errors++;
                end
                void'(model.pop_front());
            end
            n_rd++;
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
        if (n_full == 0 || n_empty == 0 || n_odrz == 0) begin $display("pokrycie niepelne"); errors++; end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
    initial begin
        #2000000 $display("FAIL: przekroczony czas"); $finish;
    end
endmodule
