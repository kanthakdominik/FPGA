// Testbench sumy kontrolnej Internetu: przykład z RFC 1071 (wynik 0x220D) i słowa pseudolosowe.
`timescale 1ns / 1ps

module tb_inet_checksum;
    logic        clk = 1'b0, clear = 1'b1, valid = 1'b0;
    logic [15:0] word = '0, sum, checksum;

    always #5 clk = ~clk;

    inet_checksum dut (.*);

    int errors = 0;

    initial begin
        logic [15:0] rfc [4] = '{16'h0001, 16'hF203, 16'hF4F5, 16'hF6F7};
        logic [15:0] lfsr_v = 16'hACE1;
        longint      model = 0;
        @(negedge clk);
        clear = 1'b0; valid = 1'b1;
        foreach (rfc[k]) begin
            word = rfc[k];
            @(negedge clk);
        end
        valid = 1'b0;
        if (sum != 16'hDDF2 || checksum != 16'h220D) begin
            $display("RFC 1071: sum=%h checksum=%h", sum, checksum); errors++;
        end

        clear = 1'b1; @(negedge clk); clear = 1'b0; valid = 1'b1;
        repeat (300) begin
            lfsr_v = lfsr_v[0] ? ((lfsr_v >> 1) ^ 16'hB400) : (lfsr_v >> 1);
            word   = lfsr_v;
            model += lfsr_v;
            @(negedge clk);
        end
        valid = 1'b0;
        while (model > 'hFFFF) model = (model & 'hFFFF) + (model >> 16);
        if (sum != 16'(model)) begin
            $display("suma %h, model %h", sum, model); errors++;
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
