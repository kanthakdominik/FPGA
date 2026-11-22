// DECA — projekt 5 (31.05): potok obróbki obrazu (demozaika RGGB, luminancja, rozmycie, Sobel, krawędzie)
// na obrazie 640×480 z generatora RAW Bayer zamiast kamery, wyjście przez HDMI (ADV7513). Z kamerą MIPI CSI-2
// źródłem RAW jest odbiornik z 24.05 — isp się nie zmienia.
//   KEY[1] — następny tryb (0 kolor, 1 szarość, 2 rozmycie, 3 Sobel, 4 krawędzie), SW[0] — ruch kwadratu,
//   KEY[0] — reset. LED[2:0] — tryb, LED[3] — ADV7513 skonfigurowany, LED[7:4] — średnia jasność ramki (4 bity).
`default_nettype none

`ifdef __ICARUS__
`define DECA_SYMULACJA
`endif
`ifdef VERILATOR
`define DECA_SYMULACJA
`endif

module deca_top (
    input  logic        MAX10_CLK1_50,
    input  logic [1:0]  KEY,
    input  logic [1:0]  SW,
    output logic [7:0]  LED,
    output logic  [23:0] HDMI_TX_D,
    output logic        HDMI_TX_CLK,
    output logic         HDMI_TX_DE,
    output logic         HDMI_TX_HS,
    output logic         HDMI_TX_VS,
    input  logic        HDMI_TX_INT,
    inout  wire         HDMI_I2C_SCL,
    inout  wire         HDMI_I2C_SDA,
    inout  wire         HDMI_MCLK,
    inout  wire         HDMI_LRCLK,
    inout  wire         HDMI_SCLK,
    inout  wire  [3:0]  HDMI_I2S
);
    logic clk, locked;
`ifdef DECA_SYMULACJA
    assign clk = MAX10_CLK1_50;
    assign locked = 1'b1;
    assign HDMI_TX_CLK = ~clk;
    /* verilator lint_off UNUSEDSIGNAL */
    logic nieuzyte;
    assign nieuzyte = ^{HDMI_TX_INT, SW[1]};
    /* verilator lint_on UNUSEDSIGNAL */
`else
    logic [4:0] pll_clk;
    altpll #(
        .intended_device_family ("MAX 10"), .lpm_type ("altpll"), .operation_mode ("NORMAL"), .pll_type ("AUTO"),
        .inclk0_input_frequency (20000), .clk0_multiply_by (1), .clk0_divide_by (2), .clk0_duty_cycle (50),
        .clk0_phase_shift ("0"), .compensate_clock ("CLK0"), .width_clock (5)
    ) u_pll (.inclk({1'b0, MAX10_CLK1_50}), .areset(1'b0), .clk(pll_clk), .locked(locked));
    assign clk = pll_clk[0];
    altddio_out #(.width(1), .intended_device_family("MAX 10")) u_zeg (
        .datain_h(1'b0), .datain_l(1'b1), .outclock(clk), .dataout(HDMI_TX_CLK));
`endif
    assign HDMI_MCLK = 1'bz;
    assign HDMI_LRCLK = 1'bz;
    assign HDMI_SCLK = 1'bz;
    assign HDMI_I2S = 4'bzzzz;

    logic [1:0] rs = 2'b00;
    always_ff @(posedge clk or negedge KEY[0]) if (!KEY[0]) rs <= 2'b00; else rs <= {rs[0], locked};
    logic rst;
    assign rst = ~rs[1];

    // przycisk trybu (próbkowany co ok. 1 ms) i przełącznik ruchu
    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    logic [1:0]  s_sw = 2'b00;
    logic [14:0] licz_ms = 15'd0;
    logic [1:0]  k1 = 2'b11;
    logic [2:0]  tryb = 3'd0;
    always_ff @(posedge clk) begin
        s_sw <= {s_sw[0], SW[0]};
        licz_ms <= (licz_ms == 15'd24999) ? 15'd0 : licz_ms + 1'b1;
        if (rst) tryb <= 3'd0;
        else if (licz_ms == 15'd0) begin
            k1 <= {k1[0], KEY[1]};
            if (k1 == 2'b10) tryb <= (tryb == 3'd4) ? 3'd0 : tryb + 3'd1;
        end
    end

    logic        de, hs, vs;
    logic [23:0] rgb;
    logic [31:0] suma_y;
    projekt_obraz u_obraz (.clk(clk), .rst(rst), .tryb(tryb), .ruch(s_sw[1]), .de(de), .hs(hs), .vs(vs), .rgb(rgb),
                           .suma_y(suma_y));
    always_ff @(posedge clk) begin
        HDMI_TX_D  <= rgb;
        HDMI_TX_DE <= de;
        HDMI_TX_HS <= hs;
        HDMI_TX_VS <= vs;
    end

    logic scl_o, sda_o, gotowe;
    /* verilator lint_off PINCONNECTEMPTY */
    adv7513_konfig #(.F_CLK(25000000), .F_I2C(100000), .OKRES(25000000)) u_adv (
        .clk(clk), .rst(rst), .start(1'b0), .zajety(), .gotowe(gotowe), .blad(),
        .scl_o(scl_o), .sda_o(sda_o), .sda_i(HDMI_I2C_SDA));
    /* verilator lint_on PINCONNECTEMPTY */
    assign HDMI_I2C_SCL = scl_o ? 1'bz : 1'b0;
    assign HDMI_I2C_SDA = sda_o ? 1'bz : 1'b0;

    // średnia jasność: suma / 307 200 ≈ suma >> 18 (×0,85); 4 najstarsze bity średniej 8-bitowej
    /* verilator lint_off UNUSEDSIGNAL */
    logic [31:0] srednia;
    assign srednia = suma_y >> 18;
    /* verilator lint_on UNUSEDSIGNAL */
    assign LED = ~{srednia[7:4], gotowe, tryb};
endmodule

`default_nettype wire
