// Moduł nadrzędny DECA — SystemVerilog. Test mnożarek na sprzęcie (moduł 19, 19.02): dwie realizacje
// mnożenia 34 × 34 (mnoz_szeroki i mnoz_potok) i mnożenia zespolonego (cztery i trzy mnożenia)
// na danych z LFSR, porównanie w każdym takcie. LED[7] — błąd, LED[6:0] — licznik porównań.
// KEY[0] — reset, SW[0] w górze — celowy błąd w operandzie jednej z mnożarek 34 × 34.
`default_nettype none

module deca_top (
    input  logic       MAX10_CLK1_50,
    input  logic [1:0] KEY,
    input  logic [1:0] SW,
    output logic [7:0] LED                     // 0 = świeci
);
    logic clk;
    assign clk = MAX10_CLK1_50;

    logic [1:0] rs = '0;
    always_ff @(posedge clk or negedge KEY[0])
        if (!KEY[0]) rs <= '0;
        else         rs <= {rs[0], 1'b1};
    logic rst;
    assign rst = ~rs[1];

    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    logic [1:0] sw1 = '0, sw2 = '0;
    always_ff @(posedge clk) begin
        sw1 <= SW;
        sw2 <= sw1;
    end

    // LFSR 64 bity (x^64 + x^63 + x^61 + x^60 + 1)
    logic [63:0] l1 = 64'h0123_4567_89AB_CDEF, l2 = 64'hFEDC_BA98_7654_3210;
    always_ff @(posedge clk) begin
        l1 <= {l1[62:0], l1[63] ^ l1[62] ^ l1[60] ^ l1[59]};
        l2 <= {l2[62:0], l2[63] ^ l2[62] ^ l2[60] ^ l2[59]};
    end

    logic [33:0] a, b, b_bl;
    assign a    = l1[33:0];
    assign b    = l2[33:0];
    assign b_bl = {b[33:1], b[0] ^ sw2[0]};          // celowy błąd

    logic [67:0] p_sz, p_op;
    logic        v_sz, v_op;
    mnoz_szeroki #(.H(17)) u_sz (.clk, .in_valid(1'b1), .a, .b, .out_valid(v_sz), .p(p_sz));
    mnoz_potok #(.WA(34), .WB(34), .ZNAK(1), .LAT(3)) u_op (.clk, .in_valid(1'b1), .a, .b(b_bl),
        .out_valid(v_op), .p(p_op));

    logic [32:0] pr4, pi4, pr3, pi3;
    logic        v4, v3;
    mnoz_zesp #(.W(16), .TRZY(0)) u_z4 (.clk, .in_valid(1'b1), .ar(l1[49:34]), .ai(l1[63:48]),
        .br(l2[49:34]), .bi(l2[63:48]), .out_valid(v4), .pr(pr4), .pi(pi4));
    mnoz_zesp #(.W(16), .TRZY(1)) u_z3 (.clk, .in_valid(1'b1), .ar(l1[49:34]), .ai(l1[63:48]),
        .br(l2[49:34]), .bi(l2[63:48]), .out_valid(v3), .pr(pr3), .pi(pi3));

    logic        blad = 1'b0;
    logic [31:0] licz = '0;
    always_ff @(posedge clk)
        if (rst) begin
            blad <= 1'b0;
            licz <= '0;
        end else if (v_sz && v_op && v4 && v3) begin
            if (p_sz != p_op || pr4 != pr3 || pi4 != pi3) blad <= 1'b1;
            licz <= licz + 1'b1;
        end

    assign LED = ~{blad, licz[31:25]};
endmodule

`default_nettype wire
