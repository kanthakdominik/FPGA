// DECA — projekt 4 (31.04): Nios V/m z peryferium udp_dma wysyła datagramy UDP z bufora w pamięci przez PHY
// DP83620 (MII 100 Mb/s). System system_udp z Platform Designer (system.tcl, komponent udp_dma_hw.tcl); bufory
// domyślnie w pamięci wewnętrznej, w wariancie z DDR3 — w pamięci zewnętrznej (README.md).
// PHY: reset 10 ms po starcie, MDIO nieużywane (autonegocjacja z ustawień domyślnych PHY), tylko nadawanie.
// KEY[0] — reset. LED[0] — reset PHY zwolniony, LED[1] — nadawanie (TX_EN, wydłużone), reszta zgaszona.
`default_nettype none

`ifdef __ICARUS__
`define DECA_SYMULACJA
`endif
`ifdef VERILATOR
`define DECA_SYMULACJA
`endif

module deca_top (
    input  wire       MAX10_CLK1_50,
    input  wire [1:0] KEY,
    output wire [7:0] LED,
    input  wire       NET_TX_CLK,
    output wire [3:0] NET_TXD,
    output wire       NET_TX_EN,
    output wire       NET_RESET_n,
    output wire       NET_MDC,
    inout  wire       NET_MDIO,
    output wire       NET_PCF_EN
);
    wire clk = MAX10_CLK1_50;
    reg [1:0] rs = 2'b00;
    always @(posedge clk or negedge KEY[0]) if (!KEY[0]) rs <= 2'b00; else rs <= {rs[0], 1'b1};
    wire rst_n = rs[1];

    // reset PHY: 10 ms w stanie niskim, potem 10 ms na start PHY
    reg [19:0] lr = 20'd0;
    always @(posedge clk) if (!rst_n) lr <= 20'd0; else if (lr != 20'd1000000) lr <= lr + 1'b1;
    assign NET_RESET_n = (lr >= 20'd500000);
    assign NET_MDC     = 1'b0;
    assign NET_MDIO    = 1'bz;
    assign NET_PCF_EN  = 1'b0;

    // reset domeny nadawania (zegar z PHY): synchroniczne zwolnienie
    reg [1:0] trs = 2'b00;
    always @(posedge NET_TX_CLK or negedge rst_n) if (!rst_n) trs <= 2'b00; else trs <= {trs[0], 1'b1};
    wire tx_rst = ~trs[1];

`ifdef DECA_SYMULACJA
    /* verilator lint_off PINCONNECTEMPTY */
    udp_dma u_udp (.clk(clk), .rst(!rst_n), .s_address(4'd0), .s_read(1'b0), .s_write(1'b0), .s_writedata(32'd0),
        .s_readdata(), .irq(), .m_address(), .m_read(), .m_waitrequest(1'b0), .m_readdata(32'd0),
        .m_readdatavalid(1'b0), .tx_clk(NET_TX_CLK), .tx_rst(tx_rst), .txd(NET_TXD), .tx_en(NET_TX_EN));
    /* verilator lint_on PINCONNECTEMPTY */
`else
    system_udp u_sys (
        .clk_clk         (clk),
        .reset_reset_n   (rst_n),
        .tx_clk_clk      (NET_TX_CLK),
        .tx_reset_reset  (tx_rst),
        .mii_txd         (NET_TXD),
        .mii_tx_en       (NET_TX_EN)
    );
`endif

    // wydłużenie TX_EN na diodę (ok. 84 ms przy 25 MHz)
    reg [21:0] dl = 22'd0;
    always @(posedge NET_TX_CLK) dl <= NET_TX_EN ? 22'h3FFFFF : (dl != 22'd0 ? dl - 1'b1 : 22'd0);
    assign LED = ~{6'd0, dl != 22'd0, NET_RESET_n};
endmodule

`default_nettype wire
