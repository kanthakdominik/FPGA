// Testbench mini_ila: badanym sygnałem jest licznik zwiększany w każdym takcie, więc poprawny zapis
// to kolejne liczby. Scenariusze: wyzwolenie poziomem na wartość (pre = 10), wyzwolenie zboczem
// warunku z maską (bit 4 = 1), skrajne pre = 0 i pre = 255, warunek prawdziwy w czasie zbierania
// próbek wstępnych (musi zostać zignorowany), ponowne uzbrojenie. Sprawdzane: próbka wyzwolenia
// na pozycji pre, wszystkie 256 próbek kolejnymi wartościami, impuls trig_out, flagi stanu.
`timescale 1ns / 1ps
`default_nettype none

module tb_mini_ila;
    localparam W = 16, AW = 8, N = 1 << AW;
    reg clk = 1'b0, rst = 1'b1;
    always #5 clk = ~clk;

    reg  [W-1:0]  licznik = {W{1'b0}};
    reg           arm = 1'b0, zbocze = 1'b0;
    reg  [W-1:0]  tval = {W{1'b0}}, tmask = {W{1'b0}};
    reg  [AW-1:0] pre = {AW{1'b0}}, rd_addr = {AW{1'b0}};
    wire [W-1:0]  rd_data;
    wire          armed, capturing, done, trig_out;
    always @(posedge clk) licznik <= licznik + 1'b1;

    mini_ila #(.W(W), .AW(AW)) dut (
        .clk(clk), .rst(rst), .probe(licznik), .arm(arm), .trig_val(tval), .trig_mask(tmask),
        .trig_zbocze(zbocze), .pre(pre), .rd_addr(rd_addr), .rd_data(rd_data),
        .armed(armed), .capturing(capturing), .done(done), .trig_out(trig_out)
    );

    integer errors = 0, n_trig = 0, i;
    reg [W-1:0] probki [0:N-1];
    always @(posedge clk) if (trig_out) n_trig = n_trig + 1;

    task odczytaj;
        begin
            for (i = 0; i < N; i = i + 1) begin
                @(negedge clk) rd_addr = i;
                @(negedge clk) probki[i] = rd_data;
            end
        end
    endtask

    task przebieg(input [W-1:0] v, input [W-1:0] m, input z, input [AW-1:0] p, input integer czekaj);
        integer t0;
        begin
            @(negedge clk);
            tval = v; tmask = m; zbocze = z; pre = p;
            repeat (czekaj) @(negedge clk);
            t0 = n_trig;
            arm = 1'b1;
            @(negedge clk) arm = 1'b0;
            if (!armed) begin $display("%0t: brak armed po uzbrojeniu", $time); errors = errors + 1; end
            wait (done);
            @(posedge clk); @(negedge clk);         // trig_out liczony na następnym zboczu
            if (n_trig != t0 + 1) begin $display("%0t: trig_out %0d razy", $time, n_trig - t0); errors = errors + 1; end
            odczytaj;
        end
    endtask

    task sprawdz_ciaglosc(input [AW-1:0] p);
        begin
            for (i = 1; i < N; i = i + 1)
                if (probki[i] !== probki[i-1] + 1'b1) begin
                    $display("pre=%0d: probka %0d = %h po %h", p, i, probki[i], probki[i-1]);
                    errors = errors + 1;
                end
        end
    endtask

    initial begin
        #23 rst = 1'b0;
        // 1. poziom: wartość 0x0400, pre = 10
        przebieg(16'h0400, 16'hFFFF, 1'b0, 8'd10, 3);
        sprawdz_ciaglosc(8'd10);
        if (probki[10] !== 16'h0400) begin $display("1: probka wyzwolenia %h", probki[10]); errors = errors + 1; end
        // 2. zbocze warunku: bit 4 przechodzi z 0 na 1, pre = 100
        przebieg(16'h0010, 16'h0010, 1'b1, 8'd100, 0);
        sprawdz_ciaglosc(8'd100);
        if (!probki[100][4] || probki[99][4]) begin
            $display("2: brak zbocza bitu 4: %h -> %h", probki[99], probki[100]); errors = errors + 1;
        end
        // 3. pre = 0: wyzwolenie na pierwszej próbce o młodszym bajcie 0x80
        przebieg(16'h0080, 16'h00FF, 1'b0, 8'd0, 0);
        sprawdz_ciaglosc(8'd0);
        if (probki[0][7:0] !== 8'h80) begin $display("3: probka wyzwolenia %h", probki[0]); errors = errors + 1; end
        // 4. pre = 255: wyzwolenie jest ostatnią próbką
        przebieg(16'h0000, 16'h0003, 1'b0, 8'd255, 0);
        sprawdz_ciaglosc(8'd255);
        if (probki[255][1:0] !== 2'b00) begin $display("4: probka wyzwolenia %h", probki[255]); errors = errors + 1; end
        // 5. maska 0 = warunek zawsze prawdziwy: wyzwolenie zaraz po zebraniu pre = 50 próbek
        przebieg(16'h0000, 16'h0000, 1'b0, 8'd50, 0);
        sprawdz_ciaglosc(8'd50);
        if (done !== 1'b1 || armed || capturing) begin $display("5: flagi stanu"); errors = errors + 1; end
        if (errors == 0) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
    initial begin
        #2000000 $display("FAIL: przekroczony czas"); $finish;
    end
endmodule

`default_nettype wire
