// Projekt 1 (31.01): zegar doby i stoper sterowane komendami tekstowymi przez UART 8N1.
//   uart_rx -> komendy -> zegar_stoper;  komendy -> uart_tx (odpowiedzi).
// Parametry dla płytki: 50 MHz, 115 200 b/s, setne sekundy co 500 000 taktów; w testbenchu wszystko szybciej.
`default_nettype none

module projekt_zegar #(
    parameter integer CLK_HZ   = 50_000_000,
    parameter integer BAUD     = 115_200,
    parameter integer CS_DZIEL = 500_000
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        rx,
    output wire        tx,
    output wire [23:0] czas,
    output wire [23:0] stoper,
    output wire        biegnie,
    output wire        pominieto,
    output wire        blad_ramki
);
    wire [7:0]  rx_dane, tx_dane;
    wire        rx_wazne, tx_start, tx_gotowy, ustaw, st_start, st_stop, st_zeruj, st_okr;
    wire [23:0] ustaw_czas;

    /* verilator lint_off PINCONNECTEMPTY */
    uart_rx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) u_rx (.clk(clk), .rst(rst), .rx(rx), .dane(rx_dane),
        .wazne(rx_wazne), .blad_ramki(blad_ramki), .blad_parz());
    zegar_stoper #(.CS_DZIEL(CS_DZIEL)) u_zs (.clk(clk), .rst(rst), .ustaw(ustaw), .ustaw_czas(ustaw_czas),
        .st_start(st_start), .st_stop(st_stop), .st_zeruj(st_zeruj), .st_okr(st_okr), .czas(czas),
        .stoper(stoper), .okr(), .biegnie(biegnie), .tik_cs());
    /* verilator lint_on PINCONNECTEMPTY */
    komendy u_kom (.clk(clk), .rst(rst), .rx_dane(rx_dane), .rx_wazne(rx_wazne), .czas(czas), .stoper(stoper),
        .ustaw(ustaw), .ustaw_czas(ustaw_czas), .st_start(st_start), .st_stop(st_stop), .st_zeruj(st_zeruj),
        .st_okr(st_okr), .tx_start(tx_start), .tx_dane(tx_dane), .tx_gotowy(tx_gotowy), .pominieto(pominieto));
    uart_tx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) u_tx (.clk(clk), .rst(rst), .start(tx_start), .dane(tx_dane),
        .gotowy(tx_gotowy), .tx(tx));
endmodule

`default_nettype wire
