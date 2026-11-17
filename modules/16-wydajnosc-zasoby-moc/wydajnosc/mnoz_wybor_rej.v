// Obudowa mnoz_wybor do pomiaru f_max (16.02): rejestry na wszystkich wejściach, żeby ścieżka
// przez mnożarkę i multiplekser była ścieżką rejestr-rejestr (nextpnr liczy f_max tylko dla takich).
`default_nettype none

module mnoz_wybor_rej #(
    parameter W       = 16,
    parameter WSPOLNY = 0
) (
    input  wire           clk,
    input  wire           sel,
    input  wire [W-1:0]   a,
    input  wire [W-1:0]   b,
    input  wire [W-1:0]   c,
    input  wire [W-1:0]   d,
    output wire [2*W-1:0] y
);
    reg         sel_r;
    reg [W-1:0] a_r, b_r, c_r, d_r;
    always @(posedge clk) begin
        sel_r <= sel;
        a_r   <= a;
        b_r   <= b;
        c_r   <= c;
        d_r   <= d;
    end
    mnoz_wybor #(.W(W), .WSPOLNY(WSPOLNY)) u (.clk(clk), .sel(sel_r), .a(a_r), .b(b_r), .c(c_r), .d(d_r), .y(y));
endmodule

`default_nettype wire
