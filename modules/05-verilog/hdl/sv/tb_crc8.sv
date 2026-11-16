// Testbench CRC-8: wartość kontrolna dla "123456789" (0xF4) i porównanie z modelem bit po bicie.
`timescale 1ns / 1ps

module tb_crc8;
    logic       clk = 1'b0, rst = 1'b1, en = 1'b0;
    logic [7:0] data = '0, crc;

    always #5 clk = ~clk;

    crc8 dut (.*);

    int         errors = 0;
    logic [7:0] model;

    // model szeregowy: jeden bit danych na krok, od najstarszego
    function automatic logic [7:0] model_byte(logic [7:0] m, logic [7:0] d);
        for (int b = 7; b >= 0; b--) begin
            logic fb = m[7] ^ d[b];
            m = {m[6:0], 1'b0} ^ (fb ? 8'h07 : 8'h00);
        end
        return m;
    endfunction

    initial begin
        string      s = "123456789";
        logic [7:0] lfsr_v = 8'h5A;
        @(negedge clk);
        rst = 1'b0; en = 1'b1; model = '0;
        foreach (s[k]) begin
            data  = s[k];
            model = model_byte(model, data);
            @(negedge clk);
        end
        if (crc != 8'hF4 || model != 8'hF4) begin
            $display("CRC(123456789) = %h, model %h, oczekiwano F4", crc, model); errors++;
        end

        rst = 1'b1; @(negedge clk); rst = 1'b0; model = '0;
        repeat (200) begin
            lfsr_v = lfsr_v[0] ? ((lfsr_v >> 1) ^ 8'hB8) : (lfsr_v >> 1);
            data   = lfsr_v;
            model  = model_byte(model, data);
            @(negedge clk);
            if (crc != model) begin
                $display("crc=%h model=%h", crc, model); errors++;
            end
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
