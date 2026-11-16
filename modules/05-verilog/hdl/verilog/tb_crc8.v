// Testbench CRC-8: wartość kontrolna dla "123456789" (0xF4) i porównanie z modelem bit po bicie.
`default_nettype none
`timescale 1ns / 1ps

module tb_crc8;
    reg        clk = 1'b0, rst = 1'b1, en = 1'b0;
    reg  [7:0] data = 8'h00;
    wire [7:0] crc;

    always #5 clk = ~clk;

    crc8 dut (.clk(clk), .rst(rst), .en(en), .data(data), .crc(crc));

    localparam [8*9-1:0] CHECK = "123456789";

    integer errors = 0, k, b;
    reg [7:0] model, lfsr_v;
    reg       fb;

    // model szeregowy: jeden bit danych na krok, od najstarszego
    task model_byte(input [7:0] d);
        begin
            for (b = 7; b >= 0; b = b - 1) begin
                fb    = model[7] ^ d[b];
                model = {model[6:0], 1'b0} ^ (fb ? 8'h07 : 8'h00);
            end
        end
    endtask

    initial begin
        @(negedge clk);
        rst = 1'b0; en = 1'b1; model = 8'h00;
        for (k = 8; k >= 0; k = k - 1) begin       // znaki od lewej: '1' to najstarszy bajt
            data = CHECK[k*8 +: 8];
            model_byte(data);
            @(negedge clk);
        end
        if (crc !== 8'hF4 || model !== 8'hF4) begin
            $display("CRC(123456789) = %h, model %h, oczekiwano F4", crc, model); errors = errors + 1;
        end

        // 200 bajtów pseudolosowych
        rst = 1'b1; @(negedge clk); rst = 1'b0; model = 8'h00; lfsr_v = 8'h5A;
        for (k = 0; k < 200; k = k + 1) begin
            lfsr_v = lfsr_v[0] ? ((lfsr_v >> 1) ^ 8'hB8) : (lfsr_v >> 1);
            data = lfsr_v;
            model_byte(data);
            @(negedge clk);
            if (crc !== model) begin
                $display("bajt %0d: crc=%h model=%h", k, crc, model); errors = errors + 1;
            end
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
