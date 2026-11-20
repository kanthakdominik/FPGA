// Moduł nadrzędny DECA — Verilog. Wbudowany przetwornik ADC MAX 10 (20.06):
//   rdzeń „Modular ADC Core” w konfiguracji „ADC Control Core Only” (adc_rdzen) i PLL zegara ADC (adc_pll),
//   oba generowane w Quartusie (README.md); sekwencer obiega kanał 1 (ADC1IN1, złącze P9) i termodiodę (17).
//   Uśrednianie po 64 próbkach. Logika i rdzeń pracują na zegarze 10 MHz z PLL.
// Diody: SW[0] = 0 — linijka: liczba świecących diod ~ napięcie na ADC1IN1 (0…2,5 V),
//        SW[0] = 1 — temperatura układu FPGA w °C (binarnie, z termodiody). KEY[0] — reset.
// W symulatorach (Icarus, Verilator) zamiast rdzeni są zaślepki.
`default_nettype none

`ifdef __ICARUS__
`define DECA_SYMULACJA
`endif
`ifdef VERILATOR
`define DECA_SYMULACJA
`endif

module deca_top (
    input  wire       ADC_CLK_10,
    input  wire [1:0] KEY,
    input  wire [1:0] SW,
    output wire [7:0] LED                      // 0 = świeci
);
    wire clk, zablok;

    reg [1:0] rs = 2'b00;
    always @(posedge clk or negedge KEY[0]) if (!KEY[0]) rs <= 2'b00; else rs <= {rs[0] & zablok, zablok};
    wire rst = ~rs[1];

    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    reg [1:0] s_sw = 2'b00;
    always @(posedge clk) s_sw <= SW;

    // ---- rdzenie
    wire        c_valid, c_sop, c_eop, c_ready, r_valid;
    wire [4:0]  c_kanal, r_kanal;
    wire [11:0] r_dane;
`ifdef DECA_SYMULACJA
    assign clk     = ADC_CLK_10;
    assign zablok  = 1'b1;
    assign c_ready = 1'b1;
    assign r_valid = 1'b0;
    assign r_kanal = 5'd0;
    assign r_dane  = 12'd0;
`else
    adc_pll u_pll (.inclk0(ADC_CLK_10), .c0(clk), .locked(zablok));
    adc_rdzen u_adc (
        .clock_clk              (clk),
        .reset_sink_reset_n     (~rst),
        .adc_pll_clock_clk      (clk),
        .adc_pll_locked_export  (zablok),
        .command_valid          (c_valid),
        .command_channel        (c_kanal),
        .command_startofpacket  (c_sop),
        .command_endofpacket    (c_eop),
        .command_ready          (c_ready),
        .response_valid         (r_valid),
        .response_channel       (r_kanal),
        .response_data          (r_dane),
        .response_startofpacket (),
        .response_endofpacket   ()
    );
`endif

    // ---- sekwencer, uśrednianie, termodioda
    wire        nowy;
    wire [4:0]  kanal;
    wire [11:0] dane;
    /* verilator lint_off PINCONNECTEMPTY */
    adc_sekwencer #(.LICZBA(2), .KANALY({5'd17, 5'd1})) u_sekw (.clk(clk), .rst(rst), .wlacz(1'b1),
        .command_valid(c_valid), .command_channel(c_kanal), .command_startofpacket(c_sop),
        .command_endofpacket(c_eop), .command_ready(c_ready), .response_valid(r_valid),
        .response_channel(r_kanal), .response_data(r_dane), .wyniki(), .nowy(nowy), .kanal(kanal), .dane(dane));
    /* verilator lint_on PINCONNECTEMPTY */

    wire        s1_w, s17_w;
    wire [11:0] s1, s17;
    adc_srednia #(.W(12), .K(6)) u_s1  (.clk(clk), .rst(rst), .wazne(nowy && kanal == 5'd1), .dane(dane),
        .wyj_wazne(s1_w), .srednia(s1));
    adc_srednia #(.W(12), .K(6)) u_s17 (.clk(clk), .rst(rst), .wazne(nowy && kanal == 5'd17), .dane(dane),
        .wyj_wazne(s17_w), .srednia(s17));

    wire [7:0] temp_c;
    tsd_temperatura #(.PLIK("../../hdl/dane/tsd_temp.hex")) u_tsd (.clk(clk), .kod(s17), .temp_c(temp_c));

    // linijka: 0…8 diod dla 0…4095
    wire [12:0] s1z = {1'b0, s1} + 13'd255;      // zaokrąglenie: 4095 -> 8 diod
    wire [3:0]  ile = s1z[12:9];
    wire [7:0] linijka = ~(8'hFF << ile);

    assign LED = ~(s_sw[0] ? temp_c : linijka);
endmodule

`default_nettype wire
