// Testbench delay_line (DEPTH = 16 i 2): losowe dane i losowe ce, model — historia przyjętych próbek.
`default_nettype none
`timescale 1ns / 1ps

module tb_delay_line;
    reg        clk = 1'b0, ce = 1'b0;
    reg  [7:0] din = 8'h00;
    wire [7:0] dout16, dout2;

    always #5 clk = ~clk;

    delay_line #(.W(8), .DEPTH(16)) u_d16 (.clk(clk), .ce(ce), .din(din), .dout(dout16));
    delay_line #(.W(8), .DEPTH(2))  u_d2  (.clk(clk), .ce(ce), .din(din), .dout(dout2));

    reg [7:0] hist [0:511];                    // próbki przyjęte przy ce = 1, w kolejności
    integer errors = 0, n, accepted = 0, holds = 0, seed = 3;

    initial begin
        for (n = 0; n < 400; n = n + 1) begin
            @(negedge clk);
            if (ce) begin
                hist[accepted] = din;
                accepted = accepted + 1;
            end else if (n > 0) begin
                holds = holds + 1;
            end
            if (accepted >= 16 && dout16 !== hist[accepted - 16]) begin
                $display("takt %0d: dout16=%h, oczekiwano %h", n, dout16, hist[accepted - 16]); errors = errors + 1;
            end
            if (accepted >= 2 && dout2 !== hist[accepted - 2]) begin
                $display("takt %0d: dout2=%h, oczekiwano %h", n, dout2, hist[accepted - 2]); errors = errors + 1;
            end
            ce  = (($random(seed) % 3) != 0);
            din = $random(seed);
        end

        if (holds == 0) begin
            $display("test nie sprawdzil wstrzymania (ce = 0)"); errors = errors + 1;
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
