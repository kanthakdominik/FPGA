// Pamięć jednoportowa z odczytem synchronicznym (18.01) — wzorzec, z którego synteza buduje blok RAM
// (M9K w MAX 10). TRYB określa wynik odczytu w takcie zapisu pod ten sam adres:
//   0 — READ_FIRST (stara zawartość), 1 — WRITE_FIRST (nowa dana), 2 — NO_CHANGE (wyjście bez zmian).
`default_nettype none

module ram_sp #(
    parameter W    = 8,
    parameter AW   = 8,
    parameter TRYB = 0
) (
    input  wire          clk,
    input  wire          we,
    input  wire [AW-1:0] addr,
    input  wire [W-1:0]  din,
    output reg  [W-1:0]  dout
);
    reg [W-1:0] mem [0:(1<<AW)-1];

    generate
        if (TRYB == 1) begin : g_write_first
            always @(posedge clk)
                if (we) begin
                    mem[addr] <= din;
                    dout      <= din;
                end else begin
                    dout <= mem[addr];
                end
        end else if (TRYB == 2) begin : g_no_change
            always @(posedge clk)
                if (we) mem[addr] <= din;
                else    dout      <= mem[addr];
        end else begin : g_read_first
            always @(posedge clk) begin
                if (we) mem[addr] <= din;
                dout <= mem[addr];
            end
        end
    endgenerate
endmodule

`default_nettype wire
