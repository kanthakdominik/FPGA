// DECA — projekt 1 (31.01): zegar i stoper sterowane komendami UART 115 200 b/s 8N1.
//   GPIO0_D[0] — TX (do RX przejściówki USB-UART 3,3 V), GPIO0_D[1] — RX (z TX przejściówki).
//   Terminal (np. picocom -b 115200): ?, T123456, S, P, R, L, W — opis w 31.01.
//   LED[6:0] — sekundy zegara w BCD (SW[0] = 1: sekundy stopera), LED[7] — stoper biegnie.
//   KEY[0] — reset. Diody świecą stanem niskim.
`default_nettype none

module deca_top (
    input  wire       MAX10_CLK1_50,
    input  wire [1:0] KEY,
    input  wire [1:0] SW,
    output wire [7:0] LED,
    inout  wire [1:0] GPIO0_D
);
    wire clk = MAX10_CLK1_50;
    reg [1:0] rs = 2'b00;
    always @(posedge clk or negedge KEY[0]) if (!KEY[0]) rs <= 2'b00; else rs <= {rs[0], 1'b1};
    wire rst = ~rs[1];

    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    reg [1:0] s_sw = 2'b00;
    always @(posedge clk) s_sw <= {s_sw[0], SW[0]};

    wire        tx, biegnie;
    wire [23:0] czas, stoper;
    /* verilator lint_off PINCONNECTEMPTY */
    projekt_zegar #(.CLK_HZ(50_000_000), .BAUD(115_200), .CS_DZIEL(500_000)) u_p (.clk(clk), .rst(rst),
        .rx(GPIO0_D[1]), .tx(tx), .czas(czas), .stoper(stoper), .biegnie(biegnie), .pominieto(),
        .blad_ramki());
    /* verilator lint_on PINCONNECTEMPTY */
    assign GPIO0_D[0] = tx;
    assign GPIO0_D[1] = 1'bz;

    /* verilator lint_off UNUSEDSIGNAL */
    wire [23:0] pokaz = s_sw[1] ? stoper : czas;
    /* verilator lint_on UNUSEDSIGNAL */
    wire [6:0] sek = s_sw[1] ? pokaz[14:8] : pokaz[6:0];
    assign LED = ~{biegnie, sek};
endmodule

`default_nettype wire
