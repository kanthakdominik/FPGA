// Testbench delay_line (DEPTH = 16 i 2): losowe dane i losowe ce, model — kolejka przyjętych próbek.
`timescale 1ns / 1ps

module tb_delay_line;
    logic       clk = 1'b0, ce = 1'b0;
    logic [7:0] din = '0, dout16, dout2;

    always #5 clk = ~clk;

    delay_line #(.W(8), .DEPTH(16)) u_d16 (.clk, .ce, .din, .dout(dout16));
    delay_line #(.W(8), .DEPTH(2))  u_d2  (.clk, .ce, .din, .dout(dout2));

    logic [7:0] hist [$];                      // próbki przyjęte przy ce = 1, w kolejności
    int errors = 0, holds = 0;

    initial begin
        for (int n = 0; n < 400; n++) begin
            @(negedge clk);
            if (ce)         hist.push_back(din);
            else if (n > 0) holds++;
            if (hist.size() >= 16 && dout16 != hist[hist.size() - 16]) begin
                $display("takt %0d: dout16=%h, oczekiwano %h", n, dout16, hist[hist.size() - 16]); errors++;
            end
            if (hist.size() >= 2 && dout2 != hist[hist.size() - 2]) begin
                $display("takt %0d: dout2=%h, oczekiwano %h", n, dout2, hist[hist.size() - 2]); errors++;
            end
            ce  = ($urandom_range(2) != 0);
            din = 8'($urandom);
        end

        if (holds == 0) begin
            $display("test nie sprawdzil wstrzymania (ce = 0)"); errors++;
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
