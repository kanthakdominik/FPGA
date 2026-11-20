// Moduł nadrzędny DECA — Verilog. Wyjścia o różnej sile i szybkości narastania (22.01) oraz łącze DDR
// w pętli przez zworę (22.02):
//   GPIO0_D[3:0] — ten sam przebieg 25 MHz na czterech pinach z różnymi ustawieniami (utworz_projekt.tcl):
//                  D0: 4 mA, wolne zbocza;  D1: 4 mA, szybkie;  D2: 8 mA, wolne;  D3: 8 mA, szybkie,
//   GPIO0_D[4]   — zegar 50 MHz z rejestru wyjściowego DDR (d_h = 1, d_l = 0),
//   GPIO0_D[5]   — dane PRBS7 z rejestru DDR: 2 bity na takt, 100 Mb/s,
//   GPIO0_D[6]   — wejście DDR (zwora D5 -> D6), kontroler PRBS7 taktowany zegarem wewnętrznym.
//   SW[0] — próbkowanie wejścia zegarem odwróconym (przesunięcie o pół okresu), KEY[1] — kasowanie licznika
//   błędów, KEY[0] — reset. LED[0] — kontroler zsynchronizowany, LED[7:1] — licznik błędów (7 bitów, nasycany).
// Rejestry DDR to megafunkcje ALTDDIO_OUT/ALTDDIO_IN (blok I/O); w symulacji modele ddr_wyj/ddr_wej.
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
    output wire [7:0] LED,                     // 0 = świeci
    inout  wire [6:0] GPIO0_D
);
    wire clk = MAX10_CLK1_50;

    reg [1:0] rs = 2'b00;
    always @(posedge clk or negedge KEY[0]) if (!KEY[0]) rs <= 2'b00; else rs <= {rs[0], 1'b1};
    wire rst = !rs[1];

    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    reg [1:0] s_sw = 2'b00, s_k1 = 2'b11;
    always @(posedge clk) begin
        s_sw <= SW;
        s_k1 <= {s_k1[0], KEY[1]};
    end

    // ---- 25 MHz na czterech pinach
    reg prost = 1'b0;
    always @(posedge clk) prost <= !prost;
    assign GPIO0_D[3:0] = {4{prost}};

    // ---- DDR: zegar i dane PRBS7
    wire [1:0] bity;
    prbs7 #(.N(2)) u_gen (.clk(clk), .rst(rst), .en(1'b1), .q(bity));

    wire clk_wej = s_sw[0] ? ~clk : clk;        // w FPGA: osobny zegar z PLL z przesunięciem fazy (22.02)
    wire q_h, q_l;
`ifdef DECA_SYMULACJA
    ddr_wyj u_zeg (.clk(clk), .d_h(1'b1), .d_l(1'b0), .q(GPIO0_D[4]));
    ddr_wyj u_dan (.clk(clk), .d_h(bity[1]), .d_l(bity[0]), .q(GPIO0_D[5]));
    ddr_wej u_wej (.clk(clk_wej), .d(GPIO0_D[6]), .q_h(q_h), .q_l(q_l));
`else
    altddio_out #(.width(2), .intended_device_family("MAX 10")) u_wyj (
        .datain_h({1'b1, bity[1]}), .datain_l({1'b0, bity[0]}), .outclock(clk), .dataout(GPIO0_D[5:4]));
    wire [0:0] wh, wl;
    altddio_in #(.width(1), .intended_device_family("MAX 10")) u_wej (
        .datain(GPIO0_D[6]), .inclock(clk_wej), .dataout_h(wh), .dataout_l(wl));
    assign q_h = wh[0];
    assign q_l = wl[0];
`endif
    assign GPIO0_D[6] = 1'bz;

    // ---- kontroler w domenie zegara wejściowego
    reg [1:0] odb;
    always @(posedge clk_wej) odb <= {q_h, q_l};
    wire [15:0] bledy;
    wire        synch;
    prbs7_spr #(.N(2)) u_spr (.clk(clk_wej), .rst(rst || !s_k1[1]), .en(1'b1), .d(odb), .bledy(bledy), .synch(synch));

    assign LED = ~{(bledy > 16'd127) ? 7'h7F : bledy[6:0], synch};
endmodule

`default_nettype wire
