// Testbench LFSR (W = 8, x^8 + x^6 + x^5 + x^4 + 1): stan nigdy nie jest zerem,
// nie powtarza się przed końcem okresu i wraca do stanu początkowego po 255 krokach.
`timescale 1ns / 1ps

module tb_lfsr;
    localparam int W = 8;

    logic         clk = 1'b0, rst = 1'b1, en = 1'b0;
    logic [W-1:0] q;
    bit           seen [256];

    always #5 clk = ~clk;

    lfsr #(.W(W), .TAPS(8'hB8), .SEED(8'h01)) dut (.*);

    int errors = 0;

    initial begin
        logic [W-1:0] model = 8'h01;
        @(negedge clk);
        rst = 1'b0; en = 1'b1;
        for (int k = 0; k < 255; k++) begin
            if (q != model) begin
                $display("krok %0d: q=%h model=%h", k, q, model); errors++;
            end
            if (q == 0 || seen[q]) begin
                $display("krok %0d: stan %h zero lub powtorzony", k, q); errors++;
            end
            seen[q] = 1'b1;
            model = model[0] ? ((model >> 1) ^ 8'hB8) : (model >> 1);
            @(negedge clk);
        end
        if (q != 8'h01) begin
            $display("po 255 krokach q=%h zamiast 01", q); errors++;
        end
        en = 1'b0;
        repeat (2) @(negedge clk);
        if (q != 8'h01) begin
            $display("zmiana stanu przy en=0"); errors++;
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
