// Układ do ćwiczeń analizy czasowej w OpenSTA (moduł 14): dzielnik ze ścieżką wielotaktową
// i nadajnik-odbiornik SPI z zegarem generowanym. Ten sam kod co w projekcie DECA, bez PLL.
`default_nettype none

module sta_demo (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [15:0] a,
    input  wire [7:0]  b,
    input  wire [7:0]  tx,
    input  wire        miso,
    output wire [15:0] q,
    output wire [7:0]  r,
    output wire        d_done,
    output wire [7:0]  rx,
    output wire        s_done,
    output wire        sclk,
    output wire        mosi,
    output wire        cs_n
);
    wire d_busy, s_busy;

    dzielnik_mc #(.W(16), .V(8), .N(4)) u_dziel (
        .clk(clk), .rst(rst), .start(start), .a(a), .b(b), .busy(d_busy), .done(d_done), .q(q), .r(r)
    );

    spi_master #(.DIV(2)) u_spi (
        .clk(clk), .rst(rst), .start(start), .tx(tx), .busy(s_busy), .done(s_done), .rx(rx),
        .sclk(sclk), .mosi(mosi), .cs_n(cs_n), .miso(miso)
    );
endmodule

`default_nettype wire
