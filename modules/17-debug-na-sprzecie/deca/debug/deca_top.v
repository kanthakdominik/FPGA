// Moduł nadrzędny DECA — Verilog. Projekt do uruchamiania i debugowania na sprzęcie (moduł 17):
//   LED[0..2] — bicie serca 1 Hz z trzech zegarów: MAX10_CLK1_50, PLL 100 MHz, ADC_CLK_10
//               (równe tempo migania = trzy zegary działają z właściwą częstotliwością),
//   LED[3]    — PLL zsynchronizowany (świeci), LED[4] — echo KEY[1] (świeci przy naciśnięciu),
//   LED[5]    — analizator uzbrojony, LED[6] — analizator zakończył zapis, LED[7] — SW[0] w górze,
//   pomiar_czestotliwosci — zegary 100 MHz i 10 MHz mierzone zegarem 50 MHz w oknie 1 ms,
//   mini_ila  — 256 próbek po 16 bitów w domenie 100 MHz: {KEY[1], SW[1:0], licznik 13 bitów},
//   In-System Sources and Probes (JTAG): "ILA0" — sterowanie i odczyt analizatora, "FREQ" — wyniki
//               pomiaru częstotliwości (skrypty ila_odczyt.tcl i czestotliwosci.tcl),
//   GPIO0_D[0] — 25 MHz, GPIO0_D[1] — 1 MHz, GPIO0_D[2] — impuls wyzwolenia analizatora,
//   GPIO0_D[3] — KEY[1] bez synchronizacji (drgania styków na oscyloskopie) — złącze P8 (17.04).
// W symulatorach (Icarus, Verilator) zamiast altpll i altsource_probe są zaślepki.
`default_nettype none

`ifdef __ICARUS__
`define DECA_SYMULACJA
`endif
`ifdef VERILATOR
`define DECA_SYMULACJA
`endif

module deca_top (
    input  wire       MAX10_CLK1_50,
    input  wire       ADC_CLK_10,
    input  wire [1:0] KEY,                     // 0 = wciśnięty
    input  wire [1:0] SW,                      // 0 = w dół
    output wire [7:0] LED,                     // 0 = świeci
    output wire [3:0] GPIO0_D
);
    wire clk50 = MAX10_CLK1_50;
    wire clk10 = ADC_CLK_10;

    // ---- PLL: 50 MHz -> 100 MHz ----
    wire clk100, locked;
`ifdef DECA_SYMULACJA
    assign clk100 = MAX10_CLK1_50;
    assign locked = 1'b1;
`else
    wire [4:0] pll_clk;
    altpll #(
        .intended_device_family ("MAX 10"),
        .lpm_type               ("altpll"),
        .operation_mode         ("NORMAL"),
        .pll_type               ("AUTO"),
        .inclk0_input_frequency (20000),
        .clk0_multiply_by       (2),
        .clk0_divide_by         (1),
        .clk0_duty_cycle        (50),
        .clk0_phase_shift       ("0"),
        .compensate_clock       ("CLK0"),
        .width_clock            (5)
    ) u_pll (
        .inclk  ({1'b0, MAX10_CLK1_50}),
        .areset (1'b0),
        .clk    (pll_clk),
        .locked (locked)
    );
    assign clk100 = pll_clk[0];
`endif

    // ---- reset: KEY[0] albo brak synchronizacji PLL; osobny synchronizator w każdej domenie ----
    wire rst_n_async = KEY[0] & locked;
    reg [1:0] rs50 = 2'b00, rs100 = 2'b00, rs10 = 2'b00;
    always @(posedge clk50  or negedge rst_n_async) if (!rst_n_async) rs50  <= 2'b00; else rs50  <= {rs50[0], 1'b1};
    always @(posedge clk100 or negedge rst_n_async) if (!rst_n_async) rs100 <= 2'b00; else rs100 <= {rs100[0], 1'b1};
    always @(posedge clk10  or negedge rst_n_async) if (!rst_n_async) rs10  <= 2'b00; else rs10  <= {rs10[0], 1'b1};
    wire rst50 = ~rs50[1], rst100 = ~rs100[1], rst10 = ~rs10[1];

    // ---- bicie serca 1 Hz z trzech zegarów ----
    wire hb50, hb100, hb10;
    bicie_serca #(.POLOKRES(25000000)) u_hb50  (.clk(clk50),  .rst(rst50),  .led(hb50));
    bicie_serca #(.POLOKRES(50000000)) u_hb100 (.clk(clk100), .rst(rst100), .led(hb100));
    bicie_serca #(.POLOKRES(5000000))  u_hb10  (.clk(clk10),  .rst(rst10),  .led(hb10));

    // ---- wejścia zsynchronizowane z domeną 100 MHz ----
    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    reg [2:0] we_s1 = 3'b111, we_s2 = 3'b111;
    always @(posedge clk100) begin
        we_s1 <= {KEY[1], SW[1:0]};
        we_s2 <= we_s1;
    end
    wire       key1_n = we_s2[2];                    // 0 = wciśnięty
    wire [1:0] sw_s   = we_s2[1:0];

    // ---- pomiar częstotliwości (okno 50000 taktów 50 MHz = 1 ms) ----
    wire [23:0] f100, f10;
    wire        v100, v10;
    pomiar_czestotliwosci #(.CW(24), .BRAMKA(50000)) u_f100 (
        .clk_ref(clk50), .rst(rst50), .clk_mier(clk100), .wynik(f100), .wynik_valid(v100));
    pomiar_czestotliwosci #(.CW(24), .BRAMKA(50000)) u_f10 (
        .clk_ref(clk50), .rst(rst50), .clk_mier(clk10), .wynik(f10), .wynik_valid(v10));

    // ---- badany sygnał i analizator ----
    reg [12:0] licznik = 13'd0;
    always @(posedge clk100) licznik <= licznik + 13'd1;
    wire [15:0] probe = {~key1_n, sw_s, licznik};

    wire [49:0] ila_src;                             // {arm, zbocze, pre, rd_addr, trig_val, trig_mask}
    wire [15:0] rd_data;
    wire        armed, capturing, done, trig_out;
    mini_ila #(.W(16), .AW(8)) u_ila (
        .clk(clk100), .rst(rst100), .probe(probe),
        .arm(ila_src[49]), .trig_zbocze(ila_src[48]), .pre(ila_src[47:40]), .rd_addr(ila_src[39:32]),
        .trig_val(ila_src[31:16]), .trig_mask(ila_src[15:0]),
        .rd_data(rd_data), .armed(armed), .capturing(capturing), .done(done), .trig_out(trig_out)
    );

    // ---- In-System Sources and Probes (JTAG) ----
    wire [18:0] ila_probe  = {armed, capturing, done, rd_data};
    wire [47:0] freq_probe = {f10, f100};
`ifdef DECA_SYMULACJA
    assign ila_src = 50'd0;
    wire unused_sym = &{1'b0, ila_probe, freq_probe, v100, v10};
`else
    altsource_probe #(
        .lpm_type                ("altsource_probe"),
        .lpm_hint                ("UNUSED"),
        .sld_auto_instance_index ("YES"),
        .sld_instance_index      (0),
        .instance_id             ("ILA0"),
        .probe_width             (19),
        .source_width            (50),
        .source_initial_value    ("0"),
        .enable_metastability    ("YES")
    ) u_issp_ila (
        .probe      (ila_probe),
        .source     (ila_src),
        .source_clk (clk100),
        .source_ena (1'b1)
    );
    wire [0:0] freq_src_nc;
    altsource_probe #(
        .lpm_type                ("altsource_probe"),
        .lpm_hint                ("UNUSED"),
        .sld_auto_instance_index ("YES"),
        .sld_instance_index      (1),
        .instance_id             ("FREQ"),
        .probe_width             (48),
        .source_width            (1),
        .source_initial_value    ("0"),
        .enable_metastability    ("NO")
    ) u_issp_freq (
        .probe      (freq_probe),
        .source     (freq_src_nc),
        .source_clk (clk50),
        .source_ena (1'b1)
    );
`endif

    // ---- wyjścia na złącze P8 (pomiary oscyloskopem) ----
    reg       t25 = 1'b0, t1 = 1'b0;
    reg [4:0] dz1 = 5'd0;
    always @(posedge clk50) begin
        t25 <= ~t25;
        if (dz1 == 5'd24) begin
            dz1 <= 5'd0;
            t1  <= ~t1;
        end else begin
            dz1 <= dz1 + 5'd1;
        end
    end
    assign GPIO0_D = {KEY[1], trig_out, t1, t25};

    // ---- diody (0 = świeci) ----
    assign LED = ~{sw_s[0], done, armed, ~key1_n, locked, hb10, hb100, hb50};
endmodule

`default_nettype wire
