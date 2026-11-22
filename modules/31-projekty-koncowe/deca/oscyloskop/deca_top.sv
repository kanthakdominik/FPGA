// DECA — projekt 2 (31.02): oscyloskop na wbudowanym ADC MAX 10 z obrazem 640×480 przez HDMI (ADV7513).
//   Akwizycja w domenie 10 MHz (adc_pll z ADC_CLK_10, rdzeń adc_rdzen „Control Core Only”, kanał 1, 1 MSPS),
//   obraz w domenie 25 MHz (altpll z 50 MHz), konfiguracja ADV7513 przez I2C (adv7513_konfig).
//   SW[0] — tryb auto (zrzut także bez wyzwolenia), SW[1] — co 10. próbka (podstawa czasu 10 µs/próbkę),
//   KEY[1] — poziom wyzwalania 1/4, 1/2, 3/4 zakresu po kolei, KEY[0] — reset.
//   LED[0] — ADV7513 skonfigurowany, LED[1] — błąd I2C, LED[2] — ostatni zrzut z wyzwolenia,
//   LED[7:3] — licznik wyświetlonych zrzutów. Rdzenie IP: README.md (jak w module 20 i 24).
`default_nettype none

`ifdef __ICARUS__
`define DECA_SYMULACJA
`endif
`ifdef VERILATOR
`define DECA_SYMULACJA
`endif

module deca_top (
    input  logic        MAX10_CLK1_50,
    input  logic        ADC_CLK_10,
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
    // ---- zegary
    logic clk_v, v_locked, clk_a, a_locked;
    logic rst_v, rst_a;
    logic        c_valid, c_sop, c_eop, c_ready, r_valid;
    logic [4:0]  c_kanal, r_kanal;
    logic [11:0] r_dane;
`ifdef DECA_SYMULACJA
    assign clk_v = MAX10_CLK1_50;
    assign v_locked = 1'b1;
    assign HDMI_TX_CLK = ~clk_v;
    assign clk_a = ADC_CLK_10;
    assign a_locked = 1'b1;
    assign c_ready = 1'b1;
    assign r_valid = 1'b0;
    assign r_kanal = 5'd0;
    assign r_dane  = 12'd0;
    /* verilator lint_off UNUSEDSIGNAL */
    logic nieuzyte;
    assign nieuzyte = ^{c_valid, c_sop, c_eop, c_kanal, HDMI_TX_INT};
    /* verilator lint_on UNUSEDSIGNAL */
`else
    logic [4:0] pll_clk;
    altpll #(
        .intended_device_family ("MAX 10"), .lpm_type ("altpll"), .operation_mode ("NORMAL"), .pll_type ("AUTO"),
        .inclk0_input_frequency (20000), .clk0_multiply_by (1), .clk0_divide_by (2), .clk0_duty_cycle (50),
        .clk0_phase_shift ("0"), .compensate_clock ("CLK0"), .width_clock (5)
    ) u_pll (.inclk({1'b0, MAX10_CLK1_50}), .areset(1'b0), .clk(pll_clk), .locked(v_locked));
    assign clk_v = pll_clk[0];
    altddio_out #(.width(1), .intended_device_family("MAX 10")) u_zeg (
        .datain_h(1'b0), .datain_l(1'b1), .outclock(clk_v), .dataout(HDMI_TX_CLK));
    adc_pll u_apll (.inclk0(ADC_CLK_10), .c0(clk_a), .locked(a_locked));
    adc_rdzen u_adc (
        .clock_clk(clk_a), .reset_sink_reset_n(~rst_a), .adc_pll_clock_clk(clk_a), .adc_pll_locked_export(a_locked),
        .command_valid(c_valid), .command_channel(c_kanal), .command_startofpacket(c_sop),
        .command_endofpacket(c_eop), .command_ready(c_ready), .response_valid(r_valid),
        .response_channel(r_kanal), .response_data(r_dane), .response_startofpacket(), .response_endofpacket());
`endif
    assign HDMI_MCLK = 1'bz;
    assign HDMI_LRCLK = 1'bz;
    assign HDMI_SCLK = 1'bz;
    assign HDMI_I2S = 4'bzzzz;

    // ---- resety obu domen
    logic [1:0] rs_v = 2'b00;
    logic [1:0] rs_a = 2'b00;
    always_ff @(posedge clk_v or negedge KEY[0]) if (!KEY[0]) rs_v <= 2'b00; else rs_v <= {rs_v[0], v_locked};
    always_ff @(posedge clk_a or negedge KEY[0]) if (!KEY[0]) rs_a <= 2'b00; else rs_a <= {rs_a[0], a_locked};
    assign rst_v = ~rs_v[1];
    assign rst_a = ~rs_a[1];

    // ---- nastawy w domenie akwizycji: przełączniki i przycisk poziomu (próbkowany co 1 licz_ms)
    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    logic [1:0]  s_sw1 = 2'b00;
    logic [1:0]  s_sw2 = 2'b00;
    logic [13:0] licz_ms = 14'd0;
    logic [1:0]  k1 = 2'b11;
    logic [1:0]  poz_nr = 2'd1;
    always_ff @(posedge clk_a) begin
        s_sw1 <= SW;
        s_sw2 <= s_sw1;
        licz_ms <= (licz_ms == 14'd9999) ? 14'd0 : licz_ms + 1'b1;
        if (licz_ms == 14'd0) begin
            k1 <= {k1[0], KEY[1]};
            if (k1 == 2'b10) poz_nr <= (poz_nr == 2'd2) ? 2'd0 : poz_nr + 1'b1;
        end
    end
    logic [11:0] poziom;
    assign poziom = (poz_nr == 2'd0) ? 12'd1024 : (poz_nr == 2'd1) ? 12'd2048 : 12'd3072;

    logic        nowy;
    logic [11:0] dane;
    /* verilator lint_off PINCONNECTEMPTY */
    adc_sekwencer #(.LICZBA(1), .KANALY({35'd0, 5'd1})) u_sekw (.clk(clk_a), .rst(rst_a), .wlacz(1'b1),
        .command_valid(c_valid), .command_channel(c_kanal), .command_startofpacket(c_sop),
        .command_endofpacket(c_eop), .command_ready(c_ready), .response_valid(r_valid),
        .response_channel(r_kanal), .response_data(r_dane), .wyniki(), .nowy(nowy), .kanal(), .dane(dane));
    /* verilator lint_on PINCONNECTEMPTY */

    // ---- oscyloskop
    logic [23:0] rgb;
    logic        hs, vs, de, wyzwolony;
    logic [15:0] nr_zrzutu;
    oscyloskop u_osc (.clk_a(clk_a), .rst_a(rst_a), .we(nowy), .probka(dane), .poziom(poziom),
        .dziel(s_sw2[1] ? 8'd10 : 8'd1), .tryb_auto(s_sw2[0]), .wyzwolony(wyzwolony), .clk_v(clk_v), .rst_v(rst_v),
        .rgb(rgb), .hs(hs), .vs(vs), .de(de), .nr_zrzutu(nr_zrzutu));
    always_ff @(posedge clk_v) begin
        HDMI_TX_D  <= rgb;
        HDMI_TX_DE <= de;
        HDMI_TX_HS <= hs;
        HDMI_TX_VS <= vs;
    end

    // ---- konfiguracja ADV7513
    logic scl_o, sda_o, gotowe, blad;
    /* verilator lint_off PINCONNECTEMPTY */
    adv7513_konfig #(.F_CLK(25000000), .F_I2C(100000), .OKRES(25000000)) u_adv (
        .clk(clk_v), .rst(rst_v), .start(1'b0), .zajety(), .gotowe(gotowe), .blad(blad),
        .scl_o(scl_o), .sda_o(sda_o), .sda_i(HDMI_I2C_SDA));
    /* verilator lint_on PINCONNECTEMPTY */
    assign HDMI_I2C_SCL = scl_o ? 1'bz : 1'b0;
    assign HDMI_I2C_SDA = sda_o ? 1'bz : 1'b0;

    // wyzwolony z domeny akwizycji tylko na diodę — wolnozmienny, dwa przerzutniki
    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    logic [1:0] s_wyz = 2'b00;
    always_ff @(posedge clk_v) s_wyz <= {s_wyz[0], wyzwolony};
    assign LED = ~{nr_zrzutu[4:0], s_wyz[1], blad, gotowe};
endmodule

`default_nettype wire
