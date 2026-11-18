// Bufor ping-pong (18.04): dwa banki po 2^AW słów w jednej pamięci dwuportowej. Nadawca zapisuje
// kolejne słowa do banku zapisu; po zapełnieniu banki zamieniają się, a odbiorca dostaje cały blok
// do odczytu w dowolnej kolejności (rd_addr), zwalniając go impulsem rd_zwolnij. Gdy odbiorca jeszcze
// trzyma poprzedni blok, nadawca czeka (wr_ready = 0) — żaden blok nie ginie i nie jest nadpisany
// w trakcie odczytu.
`default_nettype none

module pingpong #(
    parameter W  = 16,
    parameter AW = 4
) (
    input  wire          clk,
    input  wire          rst,
    // nadawca
    input  wire          wr_en,
    input  wire [W-1:0]  din,
    output wire          wr_ready,
    // odbiorca
    output wire          rd_gotowy,          // blok do odczytu jest dostępny
    input  wire [AW-1:0] rd_addr,
    output reg  [W-1:0]  dout,               // takt po rd_addr
    input  wire          rd_zwolnij          // impuls: blok przeczytany
);
    reg [W-1:0]  mem [0:(2<<AW)-1];
    reg          wbank;                      // bank zapisu; bank odczytu = ~wbank
    reg [AW-1:0] waddr;
    reg          pelny;                      // bank zapisu zapełniony, czeka na zwolnienie odbiorcy
    reg          zajety;                     // odbiorca trzyma blok w banku ~wbank

    assign wr_ready  = !pelny;
    assign rd_gotowy = zajety;
    wire do_wr = wr_en && !pelny;
    wire ostatni = do_wr && (waddr == {AW{1'b1}});
    // zamiana banków: bank zapisu pełny (teraz albo wcześniej) i odbiorca wolny (albo właśnie zwalnia)
    wire wolny  = !zajety || rd_zwolnij;
    wire zamien = (ostatni || pelny) && wolny;

    always @(posedge clk) begin
        if (do_wr) mem[{wbank, waddr}] <= din;
        dout <= mem[{~wbank, rd_addr}];
    end

    always @(posedge clk)
        if (rst) begin
            wbank  <= 1'b0;
            waddr  <= {AW{1'b0}};
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

`default_nettype wire
