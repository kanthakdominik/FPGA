// Testbench mini_ila: badany sygnał to licznik, więc poprawny zapis to kolejne liczby. Scenariusze:
// poziom na wartość (pre = 10), zbocze warunku z maską (bit 4), pre = 0 i pre = 255, maska 0
// (warunek zawsze prawdziwy — wyzwolenie zaraz po zebraniu pre próbek).
`timescale 1ns / 1ps

module tb_mini_ila;
    localparam int W = 16, AW = 8, N = 2**AW;
    logic clk = 1'b0, rst = 1'b1;
    always #5 clk = ~clk;

    logic [W-1:0]  licznik = '0, tval = '0, tmask = '0, rd_data;
    logic          arm = 1'b0, zbocze = 1'b0, armed, capturing, done, trig_out;
    logic [AW-1:0] pre = '0, rd_addr = '0;
    always_ff @(posedge clk) licznik <= licznik + 1'b1;

    mini_ila #(.W(W), .AW(AW)) dut (
        .clk, .rst, .probe(licznik), .arm, .trig_val(tval), .trig_mask(tmask), .trig_zbocze(zbocze),
        .pre, .rd_addr, .rd_data, .armed, .capturing, .done, .trig_out
    );

    int errors = 0, n_trig = 0;
    logic [W-1:0] probki [N];
    always @(posedge clk) if (trig_out) n_trig++;

    task automatic przebieg(logic [W-1:0] v, logic [W-1:0] m, logic z, logic [AW-1:0] p, int czekaj);
        int t0;
        @(negedge clk);
        tval = v; tmask = m; zbocze = z; pre = p;
        repeat (czekaj) @(negedge clk);
        t0 = n_trig;
        arm = 1'b1;
        @(negedge clk) arm = 1'b0;
        if (!armed) begin $display("%0t: brak armed", $time); errors++; end
        wait (done);
        @(posedge clk); @(negedge clk);             // trig_out liczony na następnym zboczu
        if (n_trig != t0 + 1) begin $display("%0t: trig_out %0d razy", $time, n_trig - t0); errors++; end
        for (int i = 0; i < N; i++) begin
            @(negedge clk) rd_addr = AW'(i);
            @(negedge clk) probki[i] = rd_data;
        end
        for (int i = 1; i < N; i++)
            if (probki[i] !== probki[i-1] + 1'b1) begin
                $display("pre=%0d: probka %0d = %h po %h", p, i, probki[i], probki[i-1]);
                errors++;
            end
    endtask

    initial begin
        #23 rst = 1'b0;
        przebieg(16'h0400, 16'hFFFF, 1'b0, 8'd10, 3);
        if (probki[10] !== 16'h0400) begin $display("1: %h", probki[10]); errors++; end
        przebieg(16'h0010, 16'h0010, 1'b1, 8'd100, 0);
        if (!probki[100][4] || probki[99][4]) begin $display("2: %h -> %h", probki[99], probki[100]); errors++; end
        przebieg(16'h0080, 16'h00FF, 1'b0, 8'd0, 0);
        if (probki[0][7:0] !== 8'h80) begin $display("3: %h", probki[0]); errors++; end
        przebieg(16'h0000, 16'h0003, 1'b0, 8'd255, 0);
        if (probki[255][1:0] !== 2'b00) begin $display("4: %h", probki[255]); errors++; end
        przebieg(16'h0000, 16'h0000, 1'b0, 8'd50, 0);
        if (done !== 1'b1 || armed || capturing) begin $display("5: flagi stanu"); errors++; end
        if (errors == 0) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
    initial begin
        #2000000 $display("FAIL: przekroczony czas"); $finish;
    end
endmodule
