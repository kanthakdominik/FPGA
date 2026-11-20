// Moduł nadrzędny DECA — Verilog. Test mnożarek na sprzęcie (moduł 19, 19.02):
//   generator LFSR daje w każdym takcie 50 MHz nowe operandy; dwie realizacje tego samego iloczynu
//   liczą równolegle i są porównywane:
//     34 × 34 ze znakiem: mnoz_szeroki (cztery mnożenia 18 × 18 z rejestrem za iloczynami częściowymi)
//                         i mnoz_potok (operator *, podział zostawiony Quartusowi), oba z opóźnieniem 3,
//     zespolone 16-bitowe: mnoz_zesp z czterema i z trzema mnożeniami (opóźnienie 4).
//   LED[7] — błąd (lepki), LED[6:0] — licznik porównań (najstarsze bity, widać, że test trwa).
//   KEY[0] — reset (kasuje błąd), SW[0] w górze — celowy błąd: zmieniony bit operandu jednej z mnożarek
//   34 × 34 (sprawdzenie, że porównanie działa). Raport bloków mnożarek i f_max: make raporty.
`default_nettype none

module deca_top (
    input  wire       MAX10_CLK1_50,
    input  wire [1:0] KEY,
    input  wire [1:0] SW,
    output wire [7:0] LED                      // 0 = świeci
);
    wire clk = MAX10_CLK1_50;

    reg [1:0] rs = 2'b00;
    always @(posedge clk or negedge KEY[0]) if (!KEY[0]) rs <= 2'b00; else rs <= {rs[0], 1'b1};
    wire rst = ~rs[1];

    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    reg [1:0] sw1 = 2'b00, sw2 = 2'b00;
    always @(posedge clk) begin
        sw1 <= SW;
        sw2 <= sw1;
    end

    // LFSR 64 bity (x^64 + x^63 + x^61 + x^60 + 1), drugi z przesuniętym ziarnem
    reg [63:0] l1 = 64'h0123_4567_89AB_CDEF, l2 = 64'hFEDC_BA98_7654_3210;
    always @(posedge clk) begin
        l1 <= {l1[62:0], l1[63] ^ l1[62] ^ l1[60] ^ l1[59]};
        l2 <= {l2[62:0], l2[63] ^ l2[62] ^ l2[60] ^ l2[59]};
    end

    wire [33:0] a = l1[33:0];
    wire [33:0] b = l2[33:0];
    wire [33:0] b_bl = {b[33:1], b[0] ^ sw2[0]};       // celowy błąd

    wire [67:0] p_sz, p_op;
    wire        v_sz, v_op;
    mnoz_szeroki #(.H(17)) u_sz (.clk(clk), .in_valid(1'b1), .a(a), .b(b), .out_valid(v_sz), .p(p_sz));
    mnoz_potok #(.WA(34), .WB(34), .ZNAK(1), .LAT(3)) u_op (.clk(clk), .in_valid(1'b1), .a(a), .b(b_bl),
        .out_valid(v_op), .p(p_op));

    wire [32:0] pr4, pi4, pr3, pi3;
    wire        v4, v3;
    mnoz_zesp #(.W(16), .TRZY(0)) u_z4 (.clk(clk), .in_valid(1'b1), .ar(l1[49:34]), .ai(l1[63:48]),
        .br(l2[49:34]), .bi(l2[63:48]), .out_valid(v4), .pr(pr4), .pi(pi4));
    mnoz_zesp #(.W(16), .TRZY(1)) u_z3 (.clk(clk), .in_valid(1'b1), .ar(l1[49:34]), .ai(l1[63:48]),
        .br(l2[49:34]), .bi(l2[63:48]), .out_valid(v3), .pr(pr3), .pi(pi3));

    reg        blad = 1'b0;
    reg [31:0] licz = 32'd0;
    always @(posedge clk)
        if (rst) begin
            blad <= 1'b0;
            licz <= 32'd0;
        end else if (v_sz && v_op && v4 && v3) begin
            if (p_sz != p_op || pr4 != pr3 || pi4 != pi3) blad <= 1'b1;
            licz <= licz + 1'b1;
        end

    assign LED = ~{blad, licz[31:25]};
endmodule

`default_nettype wire
