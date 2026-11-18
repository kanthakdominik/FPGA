// Pamięć dwuportowa prosta (18.01): zapis w domenie clk_w, odczyt synchroniczny w domenie clk_r.
module ram_sdp #(
    parameter int W  = 8,
    parameter int AW = 8
) (
    input  logic          clk_w,
    input  logic          we,
    input  logic [AW-1:0] addr_w,
    input  logic [W-1:0]  din,
    input  logic          clk_r,
    input  logic          re,
    input  logic [AW-1:0] addr_r,
    output logic [W-1:0]  dout
);
    logic [W-1:0] mem [2**AW];

    always_ff @(posedge clk_w)
        if (we) mem[addr_w] <= din;

    always_ff @(posedge clk_r)
        if (re) dout <= mem[addr_r];
endmodule
