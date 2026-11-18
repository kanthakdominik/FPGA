// Pamięć jednoportowa z odczytem synchronicznym (18.01). TRYB — wynik odczytu w takcie zapisu
// pod ten sam adres: 0 READ_FIRST (stara zawartość), 1 WRITE_FIRST (nowa dana), 2 NO_CHANGE.
module ram_sp #(
    parameter int W    = 8,
    parameter int AW   = 8,
    parameter int TRYB = 0
) (
    input  logic          clk,
    input  logic          we,
    input  logic [AW-1:0] addr,
    input  logic [W-1:0]  din,
    output logic [W-1:0]  dout
);
    logic [W-1:0] mem [2**AW];

    if (TRYB == 1) begin : g_write_first
        always_ff @(posedge clk)
            if (we) begin
                mem[addr] <= din;
                dout      <= din;
            end else begin
                dout <= mem[addr];
            end
    end else if (TRYB == 2) begin : g_no_change
        always_ff @(posedge clk)
            if (we) mem[addr] <= din;
            else    dout      <= mem[addr];
    end else begin : g_read_first
        always_ff @(posedge clk) begin
            if (we) mem[addr] <= din;
            dout <= mem[addr];
        end
    end
endmodule
