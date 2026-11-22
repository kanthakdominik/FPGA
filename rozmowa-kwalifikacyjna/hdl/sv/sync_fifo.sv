// Zadanie 6: synchroniczna kolejka FIFO 2^AW słów z flagami full i empty. Wskaźniki mają jeden bit więcej niż
// adres: równe — pusta, różne tylko najstarszym bitem — pełna. Odczyt rejestrowany (dane takt po rd_en, jak
// z pamięci blokowej). Zapis przy full i odczyt przy empty są ignorowane.
`default_nettype none

module sync_fifo #(
    parameter integer W  = 8,
    parameter integer AW = 4
) (
    input  logic         clk,
    input  logic         rst,
    input  logic         wr_en,
    input  logic [W-1:0] wr_data,
    output logic         full,
    input  logic         rd_en,
    output logic  [W-1:0] rd_data = {W{1'b0}},
    output logic         empty
);
    logic [W-1:0] mem [0:(1 << AW) - 1];
    logic [AW:0]  wp = {(AW + 1){1'b0}};
    logic [AW:0]  rp = {(AW + 1){1'b0}};

    assign empty = (wp == rp);
    assign full  = (wp[AW] != rp[AW]) && (wp[AW-1:0] == rp[AW-1:0]);

    always_ff @(posedge clk) begin
        if (wr_en && !full) mem[wp[AW-1:0]] <= wr_data;
        if (rd_en && !empty) rd_data <= mem[rp[AW-1:0]];
    end

    always_ff @(posedge clk)
        if (rst) begin
            wp <= {(AW + 1){1'b0}};
            rp <= {(AW + 1){1'b0}};
        end else begin
            if (wr_en && !full)  wp <= wp + 1'b1;
            if (rd_en && !empty) rp <= rp + 1'b1;
        end
endmodule

`default_nettype wire
