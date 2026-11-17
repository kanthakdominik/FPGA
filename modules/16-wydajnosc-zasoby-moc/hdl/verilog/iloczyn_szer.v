// Iloczyn skalarny czterech par liczb 8-bitowych bez znaku — wersja szeregowa (16.02):
// jedna mnożarka i akumulator, cztery takty na wynik. start przyjmowany, gdy ready = 1
// (także w ostatnim takcie poprzedniego obliczenia — wtedy wynik co 4 takty bez przerwy).
`default_nettype none

module iloczyn_szer (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire        ready,
    output reg         done,
    output reg  [17:0] y
);
    reg [31:0] a_r, b_r;
    reg [1:0]  idx;
    reg        busy;
    reg [17:0] acc;

    // jedna mnożarka: argumenty wybierane multiplekserem według idx
    wire [7:0]  ma   = a_r[8*idx +: 8];
    wire [7:0]  mb   = b_r[8*idx +: 8];
    wire [15:0] prod = {8'd0, ma} * {8'd0, mb};
    wire        last = busy && (idx == 2'd3);

    assign ready = !busy || last;

    always @(posedge clk) begin
        if (rst) begin
            busy <= 1'b0;
            done <= 1'b0;
            idx  <= 2'd0;
        end else begin
            done <= last;
            if (busy) idx <= idx + 2'd1;
            if (start && ready) begin
                busy <= 1'b1;
                idx  <= 2'd0;
            end else if (last) begin
                busy <= 1'b0;
            end
        end
        // ścieżka danych bez resetu
        if (start && ready) begin
            a_r <= a;
            b_r <= b;
        end
        if (busy) acc <= (idx == 2'd0 ? 18'd0 : acc) + {2'b00, prod};
        if (last) y   <= acc + {2'b00, prod};
    end
endmodule

`default_nettype wire
