// Zadanie 6: synchroniczna kolejka FIFO 2^AW słów z flagami full i empty. Wskaźniki mają jeden bit więcej niż
// adres: równe — pusta, różne tylko najstarszym bitem — pełna. Odczyt rejestrowany (dane takt po rd_en, jak
// z pamięci blokowej). Zapis przy full i odczyt przy empty są ignorowane.
`default_nettype none

module sync_fifo #(
    parameter integer W  = 8,
    parameter integer AW = 4
) (
    input  wire         clk,
    input  wire         rst,
    input  wire         wr_en,
    input  wire [W-1:0] wr_data,
    output wire         full,
    input  wire         rd_en,
    output reg  [W-1:0] rd_data = {W{1'b0}},
    output wire         empty
);
    reg [W-1:0] mem [0:(1 << AW) - 1];
    reg [AW:0]  wp = {(AW + 1){1'b0}};
    reg [AW:0]  rp = {(AW + 1){1'b0}};

    assign empty = (wp == rp);
    assign full  = (wp[AW] != rp[AW]) && (wp[AW-1:0] == rp[AW-1:0]);

    always @(posedge clk) begin
        if (wr_en && !full) mem[wp[AW-1:0]] <= wr_data;
        if (rd_en && !empty) rd_data <= mem[rp[AW-1:0]];
    end

    always @(posedge clk)
        if (rst) begin
            wp <= {(AW + 1){1'b0}};
            rp <= {(AW + 1){1'b0}};
        end else begin
            if (wr_en && !full)  wp <= wp + 1'b1;
            if (rd_en && !empty) rp <= rp + 1'b1;
        end
endmodule

`default_nettype wire
