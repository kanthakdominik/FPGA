// Testbench sumy kontrolnej Internetu: przykład z RFC 1071 (wynik 0x220D) i słowa pseudolosowe.
`default_nettype none
`timescale 1ns / 1ps

module tb_inet_checksum;
    reg         clk = 1'b0, clear = 1'b1, valid = 1'b0;
    reg  [15:0] word = 16'h0000;
    wire [15:0] sum, checksum;

    always #5 clk = ~clk;

    inet_checksum dut (.clk(clk), .clear(clear), .valid(valid), .word(word), .sum(sum), .checksum(checksum));

    localparam [16*4-1:0] RFC = {16'h0001, 16'hF203, 16'hF4F5, 16'hF6F7};

    integer errors = 0, k, model;
    reg [15:0] lfsr_v;

    initial begin
        @(negedge clk);
        clear = 1'b0; valid = 1'b1;
        for (k = 3; k >= 0; k = k - 1) begin
            word = RFC[k*16 +: 16];
            @(negedge clk);
        end
        valid = 1'b0;
        if (sum !== 16'hDDF2 || checksum !== 16'h220D) begin
            $display("RFC 1071: sum=%h checksum=%h", sum, checksum); errors = errors + 1;
        end

        // model: suma w liczbach całkowitych, zwijanie przeniesień na końcu
        clear = 1'b1; @(negedge clk); clear = 1'b0; valid = 1'b1;
        model = 0; lfsr_v = 16'hACE1;
        for (k = 0; k < 300; k = k + 1) begin
            lfsr_v = lfsr_v[0] ? ((lfsr_v >> 1) ^ 16'hB400) : (lfsr_v >> 1);
            word  = lfsr_v;
            model = model + lfsr_v;
            @(negedge clk);
        end
        valid = 1'b0;
        while (model > 16'hFFFF) model = (model & 16'hFFFF) + (model >> 16);
        if (sum !== model) begin
            $display("suma %h, model %h", sum, model); errors = errors + 1;
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
