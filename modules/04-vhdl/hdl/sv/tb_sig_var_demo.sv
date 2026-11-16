// Testbench: q_sig to d sprzed 2 taktów, q_var — sprzed 1 taktu.
`timescale 1ns / 1ps

module tb_sig_var_demo;
    localparam logic [0:23] SEQ = 24'b101100111000101101001110;

    logic clk = 1'b0;
    logic d   = 1'b0;
    logic q_sig, q_var;

    always #5 clk = ~clk;

    sig_var_demo dut (.*);

    int errors = 0;

    initial begin
        for (int k = 0; k < 24; k++) begin
            @(negedge clk);
            if (k >= 2) begin
                if (q_var != SEQ[k-1]) begin
                    $display("q_var w takcie %0d", k); errors++;
                end
                if (q_sig != SEQ[k-2]) begin
                    $display("q_sig w takcie %0d", k); errors++;
                end
            end
            d = SEQ[k];
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
