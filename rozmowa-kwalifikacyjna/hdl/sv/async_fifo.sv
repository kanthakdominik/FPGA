// Zadanie 8: asynchroniczna kolejka FIFO (Cummings, SNUG 2002). Wskaźniki binarne do adresowania i ich kopie
// w kodzie Graya; do drugiej domeny przechodzi tylko wskaźnik Graya przez dwa przerzutniki — zmienia się
// jeden bit na raz, więc odczytana wartość jest albo stara, albo nowa, nigdy przypadkowa. Pusta: wskaźnik
// odczytu = zsynchronizowany wskaźnik zapisu. Pełna: wskaźnik zapisu = zsynchronizowany wskaźnik odczytu
// z odwróconymi dwoma najstarszymi bitami. Flagi są pesymistyczne (opóźniona wiedza o drugiej stronie), nigdy
// fałszywie optymistyczne. Odczyt rejestrowany (dane takt po rd_en). AW >= 2.
`default_nettype none

module async_fifo #(
    parameter integer W  = 8,
    parameter integer AW = 4
) (
    input  logic         wr_clk,
    input  logic         wr_rst,
    input  logic         wr_en,
    input  logic [W-1:0] wr_data,
    output logic         full,
    input  logic         rd_clk,
    input  logic         rd_rst,
    input  logic         rd_en,
    output logic  [W-1:0] rd_data = {W{1'b0}},
    output logic         empty
);
    logic [W-1:0] mem [0:(1 << AW) - 1];

    // ---------------------------------------------------------------- wskaźniki (binarne i w kodzie Graya) i synchronizatory
    logic  [AW:0] wbin = {(AW + 1){1'b0}};
    logic  [AW:0] wgray = {(AW + 1){1'b0}};
    logic  [AW:0] rgray_w1 = {(AW + 1){1'b0}};
    logic  [AW:0] rgray_w2 = {(AW + 1){1'b0}};
    logic [AW:0] wbin_next;
    assign wbin_next = wbin + 1'b1;
    logic  [AW:0] rbin = {(AW + 1){1'b0}};
    logic  [AW:0] rgray = {(AW + 1){1'b0}};
    logic  [AW:0] wgray_r1 = {(AW + 1){1'b0}};
    logic  [AW:0] wgray_r2 = {(AW + 1){1'b0}};
    logic [AW:0] rbin_next;
    assign rbin_next = rbin + 1'b1;

    // ---------------------------------------------------------------- domena zapisu
    assign full = (wgray == {~rgray_w2[AW:AW-1], rgray_w2[AW-2:0]});

    always_ff @(posedge wr_clk)
        if (wr_en && !full) mem[wbin[AW-1:0]] <= wr_data;

    always_ff @(posedge wr_clk)
        if (wr_rst) begin
            wbin     <= {(AW + 1){1'b0}};
            wgray    <= {(AW + 1){1'b0}};
            rgray_w1 <= {(AW + 1){1'b0}};
            rgray_w2 <= {(AW + 1){1'b0}};
        end else begin
            rgray_w1 <= rgray;
            rgray_w2 <= rgray_w1;
            if (wr_en && !full) begin
                wbin  <= wbin_next;
                wgray <= wbin_next ^ (wbin_next >> 1);
            end
        end

    // ---------------------------------------------------------------- domena odczytu

    assign empty = (rgray == wgray_r2);

    always_ff @(posedge rd_clk)
        if (rd_en && !empty) rd_data <= mem[rbin[AW-1:0]];

    always_ff @(posedge rd_clk)
        if (rd_rst) begin
            rbin     <= {(AW + 1){1'b0}};
            rgray    <= {(AW + 1){1'b0}};
            wgray_r1 <= {(AW + 1){1'b0}};
            wgray_r2 <= {(AW + 1){1'b0}};
        end else begin
            wgray_r1 <= wgray;
            wgray_r2 <= wgray_r1;
            if (rd_en && !empty) begin
                rbin  <= rbin_next;
                rgray <= rbin_next ^ (rbin_next >> 1);
            end
        end
endmodule

`default_nettype wire
