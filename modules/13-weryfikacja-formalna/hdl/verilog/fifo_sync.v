// Kolejka FIFO synchroniczna z odczytem „z wyprzedzeniem” (rd_data = najstarszy element, gdy !empty).
// Zapis: wr_en && !full; odczyt (zdjęcie elementu): rd_en && !empty; oba w jednym takcie dozwolone.
// Wskaźniki o jeden bit szersze niż adres: równe — pusta; różne tylko najstarszym bitem — pełna.
// Właściwości formalne — w wersji SystemVerilog (fifo_sync.sv, blok `ifdef FORMAL`).
`default_nettype none

module fifo_sync #(
    parameter W  = 8,
    parameter AW = 3                          // głębokość 2^AW
) (
    input  wire          clk,
    input  wire          rst,
    input  wire          wr_en,
    input  wire [W-1:0]  wr_data,
    output wire          full,
    input  wire          rd_en,
    output wire [W-1:0]  rd_data,
    output wire          empty,
    output wire [AW:0]   count
);
    localparam DEPTH = 1 << AW;

    reg [W-1:0] mem [0:DEPTH-1];
    reg [AW:0]  wr_ptr, rd_ptr;

    wire do_wr = wr_en && !full;
    wire do_rd = rd_en && !empty;

    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= {(AW+1){1'b0}};
            rd_ptr <= {(AW+1){1'b0}};
        end else begin
            if (do_wr) wr_ptr <= wr_ptr + 1'b1;
            if (do_rd) rd_ptr <= rd_ptr + 1'b1;
        end
        if (do_wr) mem[wr_ptr[AW-1:0]] <= wr_data;
    end

    assign rd_data = mem[rd_ptr[AW-1:0]];
    assign count   = wr_ptr - rd_ptr;
    assign empty   = (wr_ptr == rd_ptr);
    assign full    = (wr_ptr[AW-1:0] == rd_ptr[AW-1:0]) && (wr_ptr[AW] != rd_ptr[AW]);
endmodule

`default_nettype wire
