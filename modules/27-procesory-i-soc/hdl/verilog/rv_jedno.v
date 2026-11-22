// Rdzeń RV32I jednocyklowy (27.07): każda instrukcja w jednym takcie (CPI = 1). Wymaga pamięci z odczytem
// kombinacyjnym (i_dane dla i_adr, d_rdane dla d_adr w tym samym takcie) — w FPGA to pamięć rozproszona albo
// symulacja; dla bloków pamięci z rejestrem odczytu służy rdzeń potokowy rv_potok. Długa ścieżka:
// PC -> pamięć instrukcji -> dekoder -> rejestry -> ALU -> pamięć danych -> wyrównanie -> rejestry.
// Zapis do pamięci: d_wstrb ≠ 0 (maska bajtów), dane powielone na pasy (d_wdane), adres wyrównany do słowa.
`default_nettype none

module rv_jedno #(
    parameter [31:0] START = 32'h0000_0000
) (
    input  wire        clk,
    input  wire        rst,
    output wire [31:0] i_adr,
    input  wire [31:0] i_dane,
    output wire [31:0] d_adr,
    output wire [31:0] d_wdane,
    output wire [3:0]  d_wstrb,
    output wire        d_odczyt,
    input  wire [31:0] d_rdane,
    output wire        wycofana
);
    reg  [31:0] pc;
    assign i_adr = pc;

    wire [4:0]  rd, rs1, rs2;
    wire [2:0]  f3;
    wire [31:0] imm;
    wire [3:0]  alu_op;
    wire        a_pc, a_zero, b_imm, zapis_rd, odczyt, zapis, galaz, jal, jalr;
    /* verilator lint_off PINCONNECTEMPTY */
    rv_dekoder u_dek (.ins(i_dane), .rd(rd), .rs1(rs1), .rs2(rs2), .f3(f3), .imm(imm), .alu_op(alu_op),
        .a_pc(a_pc), .a_zero(a_zero), .b_imm(b_imm), .zapis_rd(zapis_rd), .odczyt(odczyt), .zapis(zapis),
        .galaz(galaz), .jal(jal), .jalr(jalr), .uzywa_rs1(), .uzywa_rs2(), .nielegalna());
    /* verilator lint_on PINCONNECTEMPTY */

    wire [31:0] v1, v2, wynik;
    rv_rejestry #(.PRZEZ(0)) u_rej (.clk(clk), .we(zapis_rd && !rst), .wa(rd), .wd(wynik),
        .ra1(rs1), .ra2(rs2), .rd1(v1), .rd2(v2));

    wire [31:0] a = a_zero ? 32'd0 : a_pc ? pc : v1;
    wire [31:0] b = b_imm ? imm : v2;
    wire [31:0] y;
    rv_alu u_alu (.a(a), .b(b), .op(alu_op), .y(y));

    reg warunek;
    always @(*)
        case (f3)
            3'd0:    warunek = v1 == v2;
            3'd1:    warunek = v1 != v2;
            3'd4:    warunek = $signed(v1) < $signed(v2);
            3'd5:    warunek = $signed(v1) >= $signed(v2);
            3'd6:    warunek = v1 < v2;
            default: warunek = v1 >= v2;
        endcase

    wire [31:0] pc4 = pc + 32'd4;
    wire [31:0] pc_nast = jal ? pc + imm : jalr ? {y[31:1], 1'b0} : (galaz && warunek) ? pc + imm : pc4;

    wire [31:0] z_wy, o_wy;
    wire [3:0]  z_strb;
    rv_wyrownanie u_wyr (.z_f3(f3), .z_adr(y[1:0]), .z_dane(v2), .z_wy(z_wy), .z_strb(z_strb),
        .o_f3(f3), .o_adr(y[1:0]), .o_dane(d_rdane), .o_wy(o_wy));
    assign d_adr    = {y[31:2], 2'b00};
    assign d_wdane  = z_wy;
    assign d_wstrb  = (zapis && !rst) ? z_strb : 4'd0;
    assign d_odczyt = odczyt && !rst;

    assign wynik    = odczyt ? o_wy : (jal || jalr) ? pc4 : y;
    assign wycofana = !rst;

    always @(posedge clk)
        pc <= rst ? START : pc_nast;
endmodule

`default_nettype wire
