// Testbench ALU: wszystkie operacje i pary argumentów 4-bitowych, model na liczbach całkowitych.
`timescale 1ns / 1ps

module tb_alu;
    localparam int W = 4;
    localparam int M = 2**W;

    logic [W-1:0] a, b, y;
    logic [2:0]   op;
    logic         carry, zero;

    alu #(.W(W)) dut (.*);

    int errors = 0;

    initial begin
        for (int o = 0; o < 8; o++)
            for (int i = 0; i < M; i++)
                for (int j = 0; j < M; j++) begin
                    int ey, ec;
                    a = W'(i); b = W'(j); op = 3'(o); #1;
                    ec = 0;
                    case (o)
                        0: begin ey = (i + j) % M;     ec = (i + j) / M;  end
                        1: begin ey = (i - j + M) % M; ec = int'(i >= j); end
                        2: ey = i & j;
                        3: ey = i | j;
                        4: ey = i ^ j;
                        5: begin ey = (2 * i) % M;     ec = i / (M / 2);  end
                        6: begin ey = i / 2;           ec = i % 2;        end
                        default: ey = j;
                    endcase
                    if (int'(y) != ey || int'(carry) != ec || zero != (ey == 0)) begin
                        $display("op=%0d a=%0d b=%0d: y=%0d carry=%b zero=%b", o, i, j, y, carry, zero);
                        errors++;
                    end
                end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
