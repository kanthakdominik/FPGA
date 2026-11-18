// Testbench rom_sinus: wszystkie 256 adresów porównane z wartością liczoną w testbenchu ($sin),
// tolerancja ±1 (zaokrąglanie); sprawdzenie, że plik się wczytał (brak X) i że en = 0 trzyma wyjście.
`timescale 1ns / 1ps
module tb_rom_sinus;
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic        en = 1'b0;
    logic  [7:0] addr = 8'd0;
    logic [7:0] dout;
    rom_sinus #(.W(8), .AW(8), .PLIK("sinus.hex")) dut (.clk(clk), .en(en), .addr(addr), .dout(dout));

    real    v;
    int k, oczek, wy, errors = 0;
    initial begin
        for (k = 0; k < 256; k = k + 1) begin
            @(negedge clk) en = 1'b1; addr = k;
            @(posedge clk); #1;
            v = 127.5 + 127.5 * $sin(2.0 * 3.14159265358979 * k / 256.0);
            oczek = $rtoi(v + 0.5);
            wy = dout;
            if (^dout === 1'bx || wy < oczek - 1 || wy > oczek + 1) begin
                $display("adres %0d: %0d, oczekiwano %0d", k, dout, oczek);
                errors = errors + 1;
            end
        end
        @(negedge clk) en = 1'b0; addr = 8'd0;          // wyjście ma zostać z adresu 255
        @(posedge clk); #1;
        if (dout !== 8'h7d && dout !== 8'h7c) begin $display("en = 0 nie trzyma wyjscia: %h", dout); errors = errors + 1; end
        if (errors == 0) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

