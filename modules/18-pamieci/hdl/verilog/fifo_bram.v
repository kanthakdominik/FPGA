// Synchroniczna kolejka FIFO na pamięci blokowej (18.03): odczyt synchroniczny pamięci, flagi
// i licznik zajętości liczone z rejestrów.
//   FWFT = 0 — tryb standardowy: dana pojawia się na dout takt po rd_en,
//   FWFT = 1 — "first word fall through": najstarsza dana czeka na dout, gdy empty = 0; rd_en ją zdejmuje.
//              Rejestr wyjściowy pamięci pełni rolę stopnia wyprzedzenia, więc kolejka mieści 2^AW + 1 słów.
//   almost_full  = count >= AF, almost_empty = count <= AE (count — liczba słów dostępnych na wyjściu).
`default_nettype none

module fifo_bram #(
    parameter W    = 8,
    parameter AW   = 4,
    parameter FWFT = 0,
    parameter AF   = 12,
    parameter AE   = 2
) (
    input  wire          clk,
    input  wire          rst,
    input  wire          wr_en,
    input  wire [W-1:0]  din,
    output wire          full,
    output wire          almost_full,
    input  wire          rd_en,
    output reg  [W-1:0]  dout,
    output wire          empty,
    output wire          almost_empty,
    output wire [AW+1:0] count
);
    localparam DEPTH = 1 << AW;
    localparam [AW:0] PELNA = DEPTH;

    reg [W-1:0]  mem [0:DEPTH-1];
    reg [AW-1:0] wr_ptr, rd_ptr;
    reg [AW:0]   n_mem;                      // słowa w pamięci

    wire mem_empty = (n_mem == {(AW+1){1'b0}});
    assign full = (n_mem == PELNA);
    wire do_wr = wr_en && !full;
    wire do_rd;                              // odczyt z pamięci do rejestru wyjściowego

    generate
        if (FWFT != 0) begin : g_fwft
            reg valid;                       // słowo czeka w rejestrze wyjściowym
            always @(posedge clk)
                if (rst)        valid <= 1'b0;
                else if (do_rd) valid <= 1'b1;
                else if (rd_en) valid <= 1'b0;
            assign do_rd = !mem_empty && (!valid || rd_en);
            assign empty = !valid;
            assign count = {1'b0, n_mem} + {{(AW+1){1'b0}}, valid};
        end else begin : g_std
            assign do_rd = rd_en && !mem_empty;
            assign empty = mem_empty;
            assign count = {1'b0, n_mem};
        end
    endgenerate

    assign almost_full  = (count >= AF);
    assign almost_empty = (count <= AE);

    always @(posedge clk) begin
        if (do_wr) mem[wr_ptr] <= din;
        if (do_rd) dout <= mem[rd_ptr];
    end

    always @(posedge clk)
        if (rst) begin
            wr_ptr <= {AW{1'b0}};
            rd_ptr <= {AW{1'b0}};
            n_mem  <= {(AW+1){1'b0}};
        end else begin
            if (do_wr) wr_ptr <= wr_ptr + 1'b1;
            if (do_rd) rd_ptr <= rd_ptr + 1'b1;
            n_mem <= n_mem + {{AW{1'b0}}, do_wr} - {{AW{1'b0}}, do_rd};
        end
endmodule

`default_nettype wire
