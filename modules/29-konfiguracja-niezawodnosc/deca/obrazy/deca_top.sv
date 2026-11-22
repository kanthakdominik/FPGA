// DECA — dwa obrazy konfiguracji MAX 10 i przełączanie z logiki (29.02). Ten sam projekt kompiluje się dwa razy:
// OBRAZ = 0 („fabryczny”: wolne miganie LED[0]) i OBRAZ = 1 („aplikacja”: biegnące światło); oba .sof trafiają
// do jednego .pof w trybie Dual Compressed Images (CFM0 i CFM1). KEY[1] — przełączenie na drugi obraz przez
// rdzeń Dual Configuration (system_dual z Platform Designer), SW[0] — „CRC nowego obrazu poprawne” (gdy 0 —
// odmowa, LED[7] miga szybko), SW[1] — wyzerowanie licznika nadzorującego co ok. 0,67 s, LED[6] — numer obrazu.
// Bez wygenerowanego systemu kompiluje się wariant symulacyjny (DECA_SYMULACJA) bez rdzenia.
`default_nettype none
`ifdef __ICARUS__
`define DECA_SYMULACJA
`endif
`ifdef VERILATOR
`define DECA_SYMULACJA
`endif

module deca_top #(
    parameter integer OBRAZ = 0
) (
    input  logic       MAX10_CLK1_50,
    input  logic [1:0] KEY,                     // 0 = wciśnięty
    input  logic [1:0] SW,
    output logic [7:0] LED                      // 0 = świeci
);
    logic clk;
    assign clk = MAX10_CLK1_50;

    logic [1:0] rs = 2'b11;
    always_ff @(posedge clk) rs <= {rs[0], ~KEY[0]};
    logic rst;
    assign rst = rs[1];

    // przycisk KEY[1] próbkowany co 1 ms, impuls przy wciśnięciu; SW synchronizowane
    logic [15:0] ms = 16'd0;
    logic [1:0]  k1 = 2'b11;
    logic        start = 1'b0;
    logic [1:0]  sw1 = 2'b00;
    logic [1:0]  sw2 = 2'b00;
    always_ff @(posedge clk) begin
        start <= 1'b0;
        sw1 <= SW;
        sw2 <= sw1;
        ms <= (ms == 16'd49999) ? 16'd0 : ms + 1'b1;
        if (ms == 16'd0) begin
            k1 <= {k1[0], KEY[1]};
            if (k1[0] == 1'b0 && k1[1] == 1'b1) start <= 1'b1;
        end
    end

    // licznik czasu: miganie, biegnące światło, okres zerowania licznika nadzorującego
    logic [25:0] t = 26'd0;
    always_ff @(posedge clk) t <= t + 1'b1;
    logic pies;
    assign pies = sw2[1] && t[24:0] == 25'd0;          // co 2^25 taktów ≈ 0,67 s

    logic [2:0]  av_address;
    logic        av_write, av_read, zajety, odmowa, wyzwolono;
    logic [31:0] av_writedata;
    aktualizacja #(.CZAS(600)) u_akt (.clk(clk), .rst(rst), .start(start), .obraz(OBRAZ == 0),
        .obraz_ok(sw2[0]), .pies(pies), .av_address(av_address), .av_write(av_write), .av_writedata(av_writedata),
        .av_read(av_read), .zajety(zajety), .odmowa(odmowa), .wyzwolono(wyzwolono));

`ifdef DECA_SYMULACJA
    /* verilator lint_off UNUSEDSIGNAL */
    logic nieuzyte;
    assign nieuzyte = ^{av_address, av_write, av_writedata, av_read, wyzwolono};
    /* verilator lint_on UNUSEDSIGNAL */
`else
    logic [31:0] av_readdata;
    system_dual u_sys (
        .clk_clk                   (clk),
        .reset_reset_n             (!rst),
        .dual_boot_avalon_address  (av_address),
        .dual_boot_avalon_read     (av_read),
        .dual_boot_avalon_writedata(av_writedata),
        .dual_boot_avalon_write    (av_write),
        .dual_boot_avalon_readdata (av_readdata)
    );
`endif

    // sygnalizacja odmowy: LED[7] miga szybko przez ok. 2 s
    logic [26:0] odm = 27'd0;
    always_ff @(posedge clk)
        if (odmowa) odm <= 27'd100_000_000;
        else if (odm != 27'd0) odm <= odm - 1'b1;

    logic [5:0] wzor;
    assign wzor = (OBRAZ == 0) ? {5'd0, t[25]} : (6'd1 << (t[25:23] % 3'd6));
    assign LED = ~{(odm != 27'd0) && t[21], OBRAZ != 0, zajety ? 6'h3F : wzor};
endmodule

`default_nettype wire
