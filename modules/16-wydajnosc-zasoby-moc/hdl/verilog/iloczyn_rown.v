// Iloczyn skalarny czterech par liczb 8-bitowych bez znaku — wersja równoległa (16.02):
// cztery mnożarki i drzewo sumatorów, jeden wynik na takt, opóźnienie 2 takty.
`default_nettype none

module iloczyn_rown (
    input  wire        clk,
    input  wire        rst,
    input  wire        in_valid,
    input  wire [31:0] a,            // a[8*i +: 8], i = 0..3
    input  wire [31:0] b,
    output reg         out_valid,
    output reg  [17:0] y
);
    reg [31:0] a_r, b_r;
    reg        v_r;
    always @(posedge clk) begin
        a_r <= a;
        b_r <= b;
    end

    wire [15:0] p0 = {8'd0, a_r[7:0]} * {8'd0, b_r[7:0]};
    wire [15:0] p1 = {8'd0, a_r[15:8]} * {8'd0, b_r[15:8]};
    wire [15:0] p2 = {8'd0, a_r[23:16]} * {8'd0, b_r[23:16]};
    wire [15:0] p3 = {8'd0, a_r[31:24]} * {8'd0, b_r[31:24]};
    wire [17:0] suma = ({2'b00, p0} + {2'b00, p1}) + ({2'b00, p2} + {2'b00, p3});

    always @(posedge clk) y <= suma;
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
