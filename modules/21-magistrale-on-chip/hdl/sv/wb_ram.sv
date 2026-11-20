// Pamięć RAM ze slave'em Wishbone B4 w trybie potokowym (21.04): żądanie przyjęte, gdy CYC & STB & !STALL,
// ACK w następnym takcie. STALL co CO-ty takt (CO = 0: nigdy) — symuluje zajętego slave'a w testach.
`default_nettype none

module wb_ram #(
    parameter integer AW = 9,
    parameter integer CO = 0
) (
    input  logic          clk,
    input  logic          rst,
    input  logic          cyc,
    input  logic          stb,
    input  logic          we,
    input  logic [AW-1:0] adr,
    input  logic [31:0]   dat_i,
    input  logic [3:0]    sel,
    output logic  [31:0]   dat_o,
    output logic           ack,
    output logic          stall
);
    logic  [31:0] mem [0:(1 << AW) - 1];
    logic  [7:0]  licz;
    logic        przyj;
    assign przyj = cyc && stb && !stall;

    /* verilator lint_off WIDTHTRUNC */
    localparam [7:0] OST = (CO == 0) ? 0 : CO - 1;
    /* verilator lint_on WIDTHTRUNC */
    assign stall = (CO != 0) && (licz == OST);

    integer b;
    always_ff @(posedge clk) begin
        if (przyj && we)
            for (b = 0; b < 4; b = b + 1)
                if (sel[b]) mem[adr][b*8 +: 8] <= dat_i[b*8 +: 8];
        dat_o <= mem[adr];
    end

    always_ff @(posedge clk) begin
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
