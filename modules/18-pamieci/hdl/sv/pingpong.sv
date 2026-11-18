// Bufor ping-pong (18.04): dwa banki po 2^AW słów; nadawca zapisuje kolejne słowa, po zapełnieniu banku
// odbiorca dostaje blok do odczytu w dowolnej kolejności i zwalnia go impulsem rd_zwolnij; nadawca czeka
// (wr_ready = 0), dopóki odbiorca trzyma poprzedni blok.
module pingpong #(
    parameter int W  = 16,
    parameter int AW = 4
) (
    input  logic          clk,
    input  logic          rst,
    input  logic          wr_en,
    input  logic [W-1:0]  din,
    output logic          wr_ready,
    output logic          rd_gotowy,
    input  logic [AW-1:0] rd_addr,
    output logic [W-1:0]  dout,
    input  logic          rd_zwolnij
);
    logic [W-1:0]  mem [2**(AW+1)];
    logic          wbank, pelny, zajety;
    logic [AW-1:0] waddr;
    logic          do_wr, ostatni, wolny, zamien;

    assign wr_ready  = !pelny;
    assign rd_gotowy = zajety;
    assign do_wr     = wr_en && !pelny;
    assign ostatni   = do_wr && (waddr == '1);
    assign wolny     = !zajety || rd_zwolnij;
    assign zamien    = (ostatni || pelny) && wolny;

    always_ff @(posedge clk) begin
        if (do_wr) mem[{wbank, waddr}] <= din;
        dout <= mem[{~wbank, rd_addr}];
    end

    always_ff @(posedge clk)
        if (rst) begin
            wbank  <= 1'b0;
            waddr  <= '0;
            pelny  <= 1'b0;
            zajety <= 1'b0;
        end else begin
            if (do_wr) waddr <= waddr + 1'b1;
            if (zamien) begin
                wbank  <= ~wbank;
                pelny  <= 1'b0;
                zajety <= 1'b1;
            end else begin
                if (ostatni)    pelny  <= 1'b1;
                if (rd_zwolnij) zajety <= 1'b0;
            end
        end
endmodule
