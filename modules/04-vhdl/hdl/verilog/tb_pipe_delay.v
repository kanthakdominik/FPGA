// Testbench linii opóźniającej: DEPTH = 3 (wyjście = wejście sprzed 3 taktów) i DEPTH = 0 (połączenie).
`default_nettype none
`timescale 1ns / 1ps

module tb_pipe_delay;
    localparam integer W = 8, DEPTH = 3, N = 40;

    reg          clk = 1'b0;
    reg  [W-1:0] x   = 0;
    wire [W-1:0] y3, y0;
    reg  [W-1:0] hist [0:N-1];
    reg  [W-1:0] lfsr = 8'hA5;

    always #5 clk = ~clk;

    pipe_delay #(.W(W), .DEPTH(DEPTH)) dut3 (.clk(clk), .x(x), .y(y3));
    pipe_delay #(.W(W), .DEPTH(0))     dut0 (.clk(clk), .x(x), .y(y0));

    integer errors = 0, k;

    initial begin
        for (k = 0; k < N; k = k + 1) begin
            @(negedge clk);
            if (k >= DEPTH && y3 !== hist[k-DEPTH]) begin
                $display("DEPTH=3: zla wartosc w takcie %0d", k); errors = errors + 1;
            end
            // LFSR, wielomian x^8 + x^6 + x^5 + x^4 + 1
            lfsr    = {lfsr[W-2:0], lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]};
            hist[k] = lfsr;
            x       = lfsr;
            #1;
            if (y0 !== lfsr) begin
                $display("DEPTH=0: wyjscie rozne od wejscia"); errors = errors + 1;
            end
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
