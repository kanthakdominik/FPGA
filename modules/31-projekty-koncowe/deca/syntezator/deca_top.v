// DECA — projekt 3 (31.03): syntezator 4-głosowy sterowany przez MIDI (31 250 b/s), wyjście przez kodek
// TLV320AIC3254 (I2S, fs = 12,5 MHz / 256 = 48,83 kHz; konfiguracja kodeka jak w module 25).
//   GPIO0_D[1] — wejście MIDI (przez transoptor wg specyfikacji MIDI, 3,3 V) albo TX przejściówki USB-UART
//   ustawionej na 31 250 b/s, wysyłającej surowe bajty MIDI. KEY[0] — reset.
//   LED[3:0] — aktywne głosy, LED[7:4] — poziom sygnału (co 6 dB); po błędzie konfiguracji kodeka migają.
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
    inout  wire [1:0] GPIO0_D,
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
    /* verilator lint_off UNUSEDSIGNAL */
    wire nieuzyte = ^{SW, AUDIO_DOUT_MFP2, GPIO0_D[0]};
    /* verilator lint_on UNUSEDSIGNAL */
`else
    wire [4:0] pll_clk;
    altpll #(
        .intended_device_family ("MAX 10"), .lpm_type ("altpll"), .operation_mode ("NORMAL"), .pll_type ("AUTO"),
        .inclk0_input_frequency (20000), .clk0_multiply_by (1), .clk0_divide_by (4), .clk0_duty_cycle (50),
        .clk0_phase_shift ("0"), .compensate_clock ("CLK0"), .width_clock (5)
    ) u_pll (.inclk({1'b0, MAX10_CLK1_50}), .areset(1'b0), .clk(pll_clk), .locked(locked));
    assign clk = pll_clk[0];
    altddio_out #(.width(1), .intended_device_family("MAX 10")) u_mclk (
        .datain_h(1'b1), .datain_l(1'b0), .outclock(clk), .dataout(AUDIO_MCLK));
`endif
    assign AUDIO_SPI_SELECT = 1'b0;
    assign AUDIO_SCLK_MFP3  = 1'bz;
    assign AUDIO_MISO_MFP4  = 1'bz;
    assign AUDIO_GPIO_MFP5  = 1'bz;
    assign GPIO0_D          = 2'bzz;

    // ---- reset: FPGA, kodek (AUDIO_RESET_n 1 ms), przerwa 2 ms, konfiguracja I2C
    reg [1:0]  rs = 2'b00;
    always @(posedge clk or negedge KEY[0]) if (!KEY[0]) rs <= 2'b00; else rs <= {rs[0], locked};
    wire rst = ~rs[1];
    reg [15:0] lr = 16'd0;
    always @(posedge clk) if (rst) lr <= 16'd0; else if (lr != 16'd37500) lr <= lr + 1'b1;
    assign AUDIO_RESET_n = (lr >= 16'd12500);
    wire rst_i2c = (lr != 16'd37500);

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
    wire scl_o, sda_o, k_blad;
    /* verilator lint_off PINCONNECTEMPTY */
    i2c_zapisy #(.F_CLK(12500000), .F_I2C(100000), .OKRES(0), .ADRES(7'h18), .N(N), .TAB(TAB)) u_konf (
        .clk(clk), .rst(rst_i2c), .start(1'b0), .zajety(), .gotowe(), .blad(k_blad),
        .scl_o(scl_o), .sda_o(sda_o), .sda_i(AUDIO_SDA_MOSI));
    /* verilator lint_on PINCONNECTEMPTY */
    assign AUDIO_SCL_SS_n = scl_o ? 1'bz : 1'b0;
    assign AUDIO_SDA_MOSI = sda_o ? 1'bz : 1'b0;

    // ---- syntezator
    wire signed [23:0] probka;
    wire               nowa;
    wire [3:0]         aktywne;
    /* verilator lint_off PINCONNECTEMPTY */
    projekt_syntezator #(.CLK_HZ(12_500_000), .BAUD(31_250)) u_synt (.clk(clk), .rst(rst), .rx(GPIO0_D[1]),
        .bclk(AUDIO_BCLK), .wclk(AUDIO_WCLK), .dout(AUDIO_DIN_MFP1), .probka(probka), .nowa(nowa),
        .aktywne(aktywne), .blad_ramki());
    /* verilator lint_on PINCONNECTEMPTY */

    // ---- wskaźnik poziomu: szczyt |probka| z zanikaniem co 2^13 próbek
    reg [22:0] szczyt = 23'd0;
    reg [12:0] zanik = 13'd0;
    wire [23:0] modul = probka[23] ? -probka : probka;
    always @(posedge clk)
        if (nowa) begin
            zanik <= zanik + 1'b1;
            if (modul[22:0] > szczyt) szczyt <= modul[22:0];
            else if (zanik == 13'd0) szczyt <= szczyt >> 1;
        end
    wire [3:0] poziom = {szczyt[22], szczyt[21], szczyt[20], szczyt[19]};
    reg [22:0] mig = 23'd0;
    always @(posedge clk) mig <= mig + 1'b1;
    assign LED = k_blad ? {8{mig[22]}} : ~{poziom, aktywne};
endmodule

`default_nettype wire
