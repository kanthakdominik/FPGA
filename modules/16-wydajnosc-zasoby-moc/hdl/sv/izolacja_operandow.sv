// Izolacja argumentów mnożarki (16.06): ISO = 0 — argumenty zapisywane w każdym takcie,
// ISO = 1 — tylko przy in_valid (clock enable), więc mnożarka nie przełącza się na śmieciach.
module izolacja_operandow #(
    parameter int W   = 16,
    parameter bit ISO = 1'b1
) (
    input  logic           clk,
    input  logic           rst,
    input  logic           in_valid,
    input  logic [W-1:0]   a,
    input  logic [W-1:0]   b,
    output logic           out_valid,
    output logic [2*W-1:0] p
);
    logic [W-1:0] a_r, b_r;
    logic         v_r;

    always_ff @(posedge clk) begin
        if (!ISO || in_valid) begin
            a_r <= a;
            b_r <= b;
        end
        p <= (2*W)'(a_r) * (2*W)'(b_r);
    end
    always_ff @(posedge clk)
        if (rst) {v_r, out_valid} <= 2'b00;
        else     {v_r, out_valid} <= {in_valid, v_r};
endmodule
