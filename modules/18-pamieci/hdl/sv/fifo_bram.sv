// Synchroniczna kolejka FIFO na pamięci blokowej (18.03). FWFT = 0: dana takt po rd_en; FWFT = 1:
// najstarsza dana czeka na dout, gdy empty = 0 (rejestr wyjściowy pamięci jako stopień wyprzedzenia,
// pojemność 2^AW + 1). almost_full = count >= AF, almost_empty = count <= AE.
module fifo_bram #(
    parameter int W    = 8,
    parameter int AW   = 4,
    parameter bit FWFT = 1'b0,
    parameter int AF   = 12,
    parameter int AE   = 2
) (
    input  logic          clk,
    input  logic          rst,
    input  logic          wr_en,
    input  logic [W-1:0]  din,
    output logic          full,
    output logic          almost_full,
    input  logic          rd_en,
    output logic [W-1:0]  dout,
    output logic          empty,
    output logic          almost_empty,
    output logic [AW+1:0] count
);
    localparam logic [AW:0] PELNA = (AW+1)'(2**AW);

    logic [W-1:0]  mem [2**AW];
    logic [AW-1:0] wr_ptr, rd_ptr;
    logic [AW:0]   n_mem;
    logic          mem_empty, do_wr, do_rd;

    assign mem_empty = (n_mem == '0);
    assign full      = (n_mem == PELNA);
    assign do_wr     = wr_en && !full;

    if (FWFT) begin : g_fwft
        logic valid;
        always_ff @(posedge clk)
            if (rst)        valid <= 1'b0;
            else if (do_rd) valid <= 1'b1;
            else if (rd_en) valid <= 1'b0;
        assign do_rd = !mem_empty && (!valid || rd_en);
        assign empty = !valid;
        assign count = (AW+2)'(n_mem) + (AW+2)'(valid);
    end else begin : g_std
        assign do_rd = rd_en && !mem_empty;
        assign empty = mem_empty;
        assign count = (AW+2)'(n_mem);
    end

    assign almost_full  = (count >= (AW+2)'(AF));
    assign almost_empty = (count <= (AW+2)'(AE));

    always_ff @(posedge clk) begin
        if (do_wr) mem[wr_ptr] <= din;
        if (do_rd) dout <= mem[rd_ptr];
    end

    always_ff @(posedge clk)
        if (rst) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
            n_mem  <= '0;
        end else begin
            if (do_wr) wr_ptr <= wr_ptr + 1'b1;
            if (do_rd) rd_ptr <= rd_ptr + 1'b1;
            n_mem <= n_mem + (AW+1)'(do_wr) - (AW+1)'(do_rd);
        end
endmodule
