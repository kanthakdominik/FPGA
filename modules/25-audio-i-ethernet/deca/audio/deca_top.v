// DECA — dźwięk (moduł 25, 25.01–25.02): wejście liniowe kodeka TLV320AIC3254 -> filtr biquad -> echo -> wyjście.
// Zegar 12,5 MHz z PLL = MCLK kodeka; i2s_master (FPGA jest masterem BCLK/WCLK): fs = 12,5 MHz / 256 = 48,83 kHz.
// Kodek konfigurowany przez I2C (i2c_zapisy, tablica TAB) po wyjściu z resetu (AUDIO_RESET_n) i 2 ms przerwy.
// SW[0] = 1 — filtr: dolnoprzepustowy 1 kHz, z wciśniętym KEY[1] — górnoprzepustowy 1 kHz; SW[0] = 0 — bez filtra.
// SW[1] = 1 — echo 250 ms z wygasaniem 1/2. KEY[0] — reset.
// Diody (0 = świeci): wskaźnik poziomu kanału lewego (LED[k] świeci, gdy szczyt ≥ 2^(15+k) — co 6 dB);
// po błędzie konfiguracji I2C wszystkie diody migają. Ograniczenia: audio.sdc.
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
    input  wire [1:0] SW,
    output wire [7:0] LED,
    output wire       AUDIO_MCLK,
    output wire       AUDIO_BCLK,
    output wire       AUDIO_WCLK,
    output wire       AUDIO_DIN_MFP1,
    input  wire       AUDIO_DOUT_MFP2,
    inout  wire       AUDIO_SCLK_MFP3,
    inout  wire       AUDIO_SCL_SS_n,
    inout  wire       AUDIO_SDA_MOSI,
    inout  wire       AUDIO_MISO_MFP4,
    output wire       AUDIO_SPI_SELECT,
    output wire       AUDIO_RESET_n,
    inout  wire       AUDIO_GPIO_MFP5
);
    wire clk, locked;
`ifdef DECA_SYMULACJA
    reg [1:0] dz = 2'd0;
    always @(posedge MAX10_CLK1_50) dz <= dz + 1'b1;
    assign clk = dz[1];
    assign locked = 1'b1;
    assign AUDIO_MCLK = clk;
`else
    wire [4:0] pll_clk;
    altpll #(
        .intended_device_family ("MAX 10"),
        .lpm_type               ("altpll"),
        .operation_mode         ("NORMAL"),
        .pll_type               ("AUTO"),
        .inclk0_input_frequency (20000),
        .clk0_multiply_by       (1),
        .clk0_divide_by         (4),
        .clk0_duty_cycle        (50),
        .clk0_phase_shift       ("0"),
        .compensate_clock       ("CLK0"),
        .width_clock            (5)
    ) u_pll (.inclk({1'b0, MAX10_CLK1_50}), .areset(1'b0), .clk(pll_clk), .locked(locked));
    assign clk = pll_clk[0];
    altddio_out #(.width(1), .intended_device_family("MAX 10")) u_mclk (
        .datain_h(1'b1), .datain_l(1'b0), .outclock(clk), .dataout(AUDIO_MCLK));
`endif
    assign AUDIO_SPI_SELECT = 1'b0;             // sterowanie kodekiem przez I2C
    assign AUDIO_SCLK_MFP3  = 1'bz;
    assign AUDIO_MISO_MFP4  = 1'bz;
    assign AUDIO_GPIO_MFP5  = 1'bz;

    // ---- reset: FPGA, potem kodek (AUDIO_RESET_n), potem konfiguracja
    reg [1:0]  rs = 2'b00;
    always @(posedge clk or negedge KEY[0]) if (!KEY[0]) rs <= 2'b00; else rs <= {rs[0], locked};
    wire rst = ~rs[1];
    reg [15:0] lr = 16'd0;                      // 0..12 500: kodek w resecie (1 ms), do 37 500: czekanie (2 ms)
    always @(posedge clk) if (rst) lr <= 16'd0; else if (lr != 16'd37500) lr <= lr + 1'b1;
    assign AUDIO_RESET_n = (lr >= 16'd12500);
    wire rst_i2c = (lr != 16'd37500);
    reg [1:0] s_sw = 2'b00, s_k1 = 2'b11;
    always @(posedge clk) begin s_sw <= SW; s_k1 <= {s_k1[0], KEY[1]}; end

    // ---- konfiguracja kodeka (tablica: 25.01)
    localparam integer N = 42;
    localparam [16*N-1:0] TAB = {
        16'h00_00, 16'h01_01, 16'hFF_01,
        16'h0B_81, 16'h0C_82, 16'h0D_00, 16'h0E_80, 16'h12_81, 16'h13_82, 16'h14_80,
        16'h1B_20, 16'h3C_08, 16'h3D_01,
        16'h00_01, 16'h01_08, 16'h02_00, 16'h7B_01, 16'h14_25, 16'h0A_00,
        16'h0C_08, 16'h0D_08, 16'h0E_08, 16'h0F_08, 16'h03_00, 16'h04_00,
        16'h10_00, 16'h11_00, 16'h12_00, 16'h13_00, 16'h09_3C, 16'h47_32,
        16'h34_40, 16'h36_40, 16'h37_40, 16'h39_40, 16'h3B_0C, 16'h3C_0C,
        16'h00_00, 16'h3F_D6, 16'h40_00, 16'h51_C0, 16'h52_00
    };
    wire scl_o, sda_o, k_zaj, k_got, k_blad;
    i2c_zapisy #(.F_CLK(12500000), .F_I2C(100000), .OKRES(0), .ADRES(7'h18), .N(N), .TAB(TAB)) u_konf (
        .clk(clk), .rst(rst_i2c), .start(1'b0), .zajety(k_zaj), .gotowe(k_got), .blad(k_blad),
        .scl_o(scl_o), .sda_o(sda_o), .sda_i(AUDIO_SDA_MOSI));
    assign AUDIO_SCL_SS_n = scl_o ? 1'bz : 1'b0;
    assign AUDIO_SDA_MOSI = sda_o ? 1'bz : 1'b0;

    // ---- I2S
    wire [23:0] rx_l, rx_p;
    reg  [23:0] tx_l = 24'd0, tx_p = 24'd0;
    wire        ramka;
    i2s_master u_i2s (.clk(clk), .rst(rst), .tx_l(tx_l), .tx_p(tx_p), .rx_l(rx_l), .rx_p(rx_p), .ramka(ramka),
                      .bclk(AUDIO_BCLK), .wclk(AUDIO_WCLK), .dout(AUDIO_DIN_MFP1), .din(AUDIO_DOUT_MFP2));

    // ---- filtr (oba kanały) i echo
    wire        gp = !s_k1[1];
    wire signed [17:0] b0 = gp ? 18'sd59836  : 18'sd248;
    wire signed [17:0] b1 = gp ? -18'sd119671 : 18'sd497;
    wire signed [17:0] b2 = b0;
    wire signed [17:0] a1 = -18'sd119174;
    wire signed [17:0] a2 = 18'sd54632;
    wire signed [23:0] f_l, f_p, e_l, e_p;
    wire               fw_l, fw_p, ew_l, ew_p;
    biquad u_bq_l (.clk(clk), .rst(rst), .we(ramka), .x(rx_l), .b0(b0), .b1(b1), .b2(b2), .a1(a1), .a2(a2),
                   .y(f_l), .y_wazne(fw_l));
    biquad u_bq_p (.clk(clk), .rst(rst), .we(ramka), .x(rx_p), .b0(b0), .b1(b1), .b2(b2), .a1(a1), .a2(a2),
                   .y(f_p), .y_wazne(fw_p));
    reg signed [23:0] w_l = 24'sd0, w_p = 24'sd0;
    reg               w_we = 1'b0;
    always @(posedge clk) begin
        w_we <= fw_l;
        if (fw_l) begin
            w_l <= s_sw[0] ? f_l : rx_l;
            w_p <= s_sw[0] ? f_p : rx_p;
        end
    end
    wire [7:0] g = s_sw[1] ? 8'd128 : 8'd0;
    echo #(.D(12000)) u_ec_l (.clk(clk), .rst(rst), .we(w_we), .x(w_l), .g(g), .y(e_l), .y_wazne(ew_l));
    echo #(.D(12000)) u_ec_p (.clk(clk), .rst(rst), .we(w_we), .x(w_p), .g(g), .y(e_p), .y_wazne(ew_p));
    always @(posedge clk) if (ew_l) begin tx_l <= e_l; tx_p <= e_p; end

    // ---- wskaźnik poziomu (kanał lewy, szczyt z opadaniem)
    reg [22:0] szczyt = 23'd0;
    reg [9:0]  dziel = 10'd0;
    wire [22:0] modul = rx_l[23] ? ~rx_l[22:0] : rx_l[22:0];
    always @(posedge clk) if (ramka) begin
        dziel <= dziel + 1'b1;
        if (modul > szczyt) szczyt <= modul;
        else if (dziel == 10'd0) szczyt <= szczyt - (szczyt >> 3);   // ok. -1 dB co 21 ms
    end
    reg [22:0] miga = 23'd0;
    always @(posedge clk) miga <= miga + 1'b1;
    wire [7:0] slupek = {szczyt[22], |szczyt[22:21], |szczyt[22:20], |szczyt[22:19],
                         |szczyt[22:18], |szczyt[22:17], |szczyt[22:16], |szczyt[22:15]};
    assign LED = k_blad ? {8{miga[22]}} : ~slupek;
endmodule

`default_nettype wire
