// Izolacja argumentów mnożarki (16.06). Argumenty zapisywane do rejestrów:
// ISO = 0 — w każdym takcie (mnożarka przelicza też śmieci z magistrali, gdy in_valid = 0),
// ISO = 1 — tylko przy in_valid (clock enable): przy braku danych argumenty stoją, mnożarka i rejestr
// iloczynu nie przełączają się — mniejsza moc dynamiczna przy tej samej funkcji.
`default_nettype none

module izolacja_operandow #(
    parameter W   = 16,
    parameter ISO = 1
) (
    input  wire           clk,
    input  wire           rst,
    input  wire           in_valid,
    input  wire [W-1:0]   a,
    input  wire [W-1:0]   b,
    output reg            out_valid,
    output reg  [2*W-1:0] p
);
    reg [W-1:0] a_r, b_r;
    reg         v_r;
    always @(posedge clk) begin
        if (ISO == 0 || in_valid) begin
            a_r <= a;
            b_r <= b;
        end
        p <= {{W{1'b0}}, a_r} * {{W{1'b0}}, b_r};
    end
    always @(posedge clk)
        if (rst) begin
            v_r       <= 1'b0;
            out_valid <= 1'b0;
        end else begin
            v_r       <= in_valid;
            out_valid <= v_r;
        end
endmodule

`default_nettype wire
