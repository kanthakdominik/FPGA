// Testbench ALU: wszystkie operacje i pary argumentów 4-bitowych, model na liczbach całkowitych.
`default_nettype none
`timescale 1ns / 1ps

module tb_alu;
    localparam integer W = 4;
    localparam integer M = 1 << W;

    reg  [W-1:0] a, b;
    reg  [2:0]   op;
    wire [W-1:0] y;
    wire         carry, zero;

    alu #(.W(W)) dut (.a(a), .b(b), .op(op), .y(y), .carry(carry), .zero(zero));

    integer errors = 0, o, i, j, ey, ec;

    initial begin
        for (o = 0; o < 8; o = o + 1)
            for (i = 0; i < M; i = i + 1)
                for (j = 0; j < M; j = j + 1) begin
                    a = i; b = j; op = o; #1;
                    ec = 0;
                    case (o)
                        0: begin ey = (i + j) % M;     ec = (i + j) / M;  end
                        1: begin ey = (i - j + M) % M; ec = (i >= j);     end
                        2: ey = i & j;
                        3: ey = i | j;
                        4: ey = i ^ j;
                        5: begin ey = (2 * i) % M;     ec = i / (M / 2);  end
                        6: begin ey = i / 2;           ec = i % 2;        end
                        default: ey = j;
                    endcase
                    if (y !== ey || carry !== ec || zero !== (ey == 0)) begin
                        $display("op=%0d a=%0d b=%0d: y=%0d carry=%b zero=%b", o, i, j, y, carry, zero);
                        errors = errors + 1;
                    end
                end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
