// Testbench bufor_linii: obraz 16 × 12 pikseli, piksel(y, x) = (y · 16 + x) mod 256, strumień z losowymi
// przerwami (in_valid = 0). Sprawdzane: dla każdego piksela p0 = piksel(y, x), p1 = piksel(y−1, x),
// p2 = piksel(y−2, x) (zera przed początkiem obrazu); liczba pikseli na wyjściu.
`timescale 1ns / 1ps
module tb_bufor_linii;
    localparam W = 8, SZER = 16, WYS = 12;
    logic clk = 1'b0, rst = 1'b1;
    always #5 clk = ~clk;
    logic          in_valid = 1'b0;
    logic  [W-1:0] piksel = 0;
    logic         out_valid;
    logic [W-1:0] p0, p1, p2;
    bufor_linii #(.W(W), .SZER(SZER)) dut (.clk(clk), .rst(rst), .in_valid(in_valid), .piksel(piksel),
        .out_valid(out_valid), .p0(p0), .p1(p1), .p2(p2));

    function [W-1:0] pix(input int y, input int x);
        pix = (y < 0) ? {W{1'b0}} : (y * 16 + x) % 256;
    endfunction

    int x = 0, y = 0, ox = 0, oy = 0, n_out = 0, errors = 0;
    always @(posedge clk) #1 if (!rst && out_valid) begin
        if (p0 !== pix(oy, ox) || p1 !== pix(oy - 1, ox) || p2 !== pix(oy - 2, ox)) begin
            $display("(%0d,%0d): %0d %0d %0d, oczekiwano %0d %0d %0d", oy, ox, p0, p1, p2,
                     pix(oy, ox), pix(oy - 1, ox), pix(oy - 2, ox));
            errors = errors + 1;
        end
        n_out = n_out + 1;
        ox = ox + 1;
        if (ox == SZER) begin ox = 0; oy = oy + 1; end
    end

    initial begin
        #23 rst = 1'b0;
        while (y < WYS) begin
            @(negedge clk);
            in_valid = ($urandom % 3 != 0);
            if (in_valid) begin
                piksel = pix(y, x);
                x = x + 1;
                if (x == SZER) begin x = 0; y = y + 1; end
            end
        end
        @(negedge clk) in_valid = 1'b0;
        repeat (3) @(negedge clk);
        if (errors == 0 && n_out == SZER * WYS) $display("PASS");
        else $display("FAIL: %0d bledow, %0d pikseli", errors, n_out);
        $finish;
    end
endmodule

