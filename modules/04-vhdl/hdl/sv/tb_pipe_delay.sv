// Testbench linii opóźniającej: DEPTH = 3 (wyjście = wejście sprzed 3 taktów) i DEPTH = 0 (połączenie).
`timescale 1ns / 1ps

module tb_pipe_delay;
    localparam int W = 8, DEPTH = 3;

    logic         clk = 1'b0;
    logic [W-1:0] x   = '0;
    logic [W-1:0] y3, y0;
    logic [W-1:0] hist [$];                        // kolejka: historia wejść
    logic [W-1:0] lfsr = 8'hA5;

    always #5 clk = ~clk;

    pipe_delay #(.W(W), .DEPTH(DEPTH)) dut3 (.clk, .x, .y(y3));
    pipe_delay #(.W(W), .DEPTH(0))     dut0 (.clk, .x, .y(y0));

    int errors = 0;

    initial begin
        for (int k = 0; k < 40; k++) begin
            @(negedge clk);
            if (k >= DEPTH && y3 != hist[k-DEPTH]) begin
                $display("DEPTH=3: zla wartosc w takcie %0d", k); errors++;
            end
            // LFSR, wielomian x^8 + x^6 + x^5 + x^4 + 1
            lfsr = {lfsr[W-2:0], lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]};
            hist.push_back(lfsr);
            x = lfsr;
            #1;
            if (y0 != lfsr) begin
                $display("DEPTH=0: wyjscie rozne od wejscia"); errors++;
            end
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
