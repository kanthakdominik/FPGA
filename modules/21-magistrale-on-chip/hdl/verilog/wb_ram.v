// Pamięć RAM ze slave'em Wishbone B4 w trybie potokowym (21.04): żądanie przyjęte, gdy CYC & STB & !STALL,
// ACK w następnym takcie. STALL co CO-ty takt (CO = 0: nigdy) — symuluje zajętego slave'a w testach.
`default_nettype none

module wb_ram #(
    parameter integer AW = 9,
    parameter integer CO = 0
) (
    input  wire          clk,
    input  wire          rst,
    input  wire          cyc,
    input  wire          stb,
    input  wire          we,
    input  wire [AW-1:0] adr,
    input  wire [31:0]   dat_i,
    input  wire [3:0]    sel,
    output reg  [31:0]   dat_o,
    output reg           ack,
    output wire          stall
);
    reg  [31:0] mem [0:(1 << AW) - 1];
    reg  [7:0]  licz;
    wire        przyj = cyc && stb && !stall;

    /* verilator lint_off WIDTHTRUNC */
    localparam [7:0] OST = (CO == 0) ? 0 : CO - 1;
    /* verilator lint_on WIDTHTRUNC */
    assign stall = (CO != 0) && (licz == OST);

    integer b;
    always @(posedge clk) begin
        if (przyj && we)
            for (b = 0; b < 4; b = b + 1)
                if (sel[b]) mem[adr][b*8 +: 8] <= dat_i[b*8 +: 8];
        dat_o <= mem[adr];
    end

    always @(posedge clk) begin
        if (rst) begin
            licz <= 8'd0;
            ack  <= 1'b0;
        end else begin
            licz <= (licz == OST) ? 8'd0 : licz + 1'b1;
            ack  <= przyj;
        end
    end
endmodule

`default_nettype wire
