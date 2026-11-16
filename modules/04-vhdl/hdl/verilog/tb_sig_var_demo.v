// Testbench: q_sig to d sprzed 2 taktów, q_var — sprzed 1 taktu.
`default_nettype none
`timescale 1ns / 1ps

module tb_sig_var_demo;
    localparam [0:23] SEQ = 24'b101100111000101101001110;

    reg  clk = 1'b0;
    reg  d   = 1'b0;
    wire q_sig, q_var;

    always #5 clk = ~clk;

    sig_var_demo dut (.clk(clk), .d(d), .q_sig(q_sig), .q_var(q_var));

    integer errors = 0, k;

    initial begin
        for (k = 0; k < 24; k = k + 1) begin
            @(negedge clk);
            if (k >= 2) begin
                if (q_var !== SEQ[k-1]) begin
                    $display("q_var w takcie %0d", k); errors = errors + 1;
                end
                if (q_sig !== SEQ[k-2]) begin
                    $display("q_sig w takcie %0d", k); errors = errors + 1;
                end
            end
            d = SEQ[k];
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
