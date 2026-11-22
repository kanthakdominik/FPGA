// Rdzeń RV32I z potokiem pięciostopniowym (27.07): IF, ID, EX, MEM, WB. Pamięci z odczytem synchronicznym
// (bloki pamięci FPGA): i_dane przychodzi takt po i_adr, d_rdane takt po d_adr — dlatego adres instrukcji to
// „następny PC” (rejestr adresu w pamięci jest częścią stopnia IF), a dane z pamięci trafiają do stopnia WB.
//   - przekazywanie (forwarding) MEM -> EX i WB -> EX, zapis do rejestrów widoczny w ID w tym samym takcie;
//   - load-use: instrukcja zależna od odczytu tuż przed nią czeka 1 takt (bąbelek w EX);
//   - skoki i skoki warunkowe rozstrzygane w EX (statyczna predykcja „niewykonany”): 2 takty kary.
// Interfejs pamięci jak w rv_jedno, ale z opóźnieniem odczytu 1 takt; wycofana — instrukcja opuszcza WB.
`default_nettype none

module rv_potok #(
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
    localparam [31:0] NOP = 32'h0000_0013;          // addi x0, x0, 0

    wire        przekieruj, stoj;
    wire [31:0] cel;

    // ------------------------------------------------------------------ IF
    reg  [31:0] pc_f;
    assign i_adr = rst ? START : przekieruj ? cel : stoj ? pc_f : pc_f + 32'd4;
    always @(posedge clk) pc_f <= i_adr;

    reg  [31:0] pc_d, ins_d;
    reg         v_d;
    always @(posedge clk)
        if (rst || przekieruj) begin
            v_d <= 1'b0; ins_d <= NOP; pc_d <= 32'd0;
        end else if (!stoj) begin
            v_d <= 1'b1; ins_d <= i_dane; pc_d <= pc_f;
        end

    // ------------------------------------------------------------------ ID
    wire [4:0]  rd_d, rs1_d, rs2_d;
    wire [2:0]  f3_d;
    wire [31:0] imm_d;
    wire [3:0]  alu_op_d;
    wire        a_pc_d, a_zero_d, b_imm_d, zapis_rd_d, odczyt_d, zapis_d, galaz_d, jal_d, jalr_d;
    wire        uzywa_rs1_d, uzywa_rs2_d, nielegalna_d;
    rv_dekoder u_dek (.ins(ins_d), .rd(rd_d), .rs1(rs1_d), .rs2(rs2_d), .f3(f3_d), .imm(imm_d), .alu_op(alu_op_d),
        .a_pc(a_pc_d), .a_zero(a_zero_d), .b_imm(b_imm_d), .zapis_rd(zapis_rd_d), .odczyt(odczyt_d),
        .zapis(zapis_d), .galaz(galaz_d), .jal(jal_d), .jalr(jalr_d), .uzywa_rs1(uzywa_rs1_d),
        .uzywa_rs2(uzywa_rs2_d), .nielegalna(nielegalna_d));
    wire        ok_d = v_d && !nielegalna_d;     // nielegalna instrukcja przechodzi jak NOP

    wire        we_w;
    wire [4:0]  rd_w;
    wire [31:0] wynik_wb;
    wire [31:0] v1_d, v2_d;
    rv_rejestry #(.PRZEZ(1)) u_rej (.clk(clk), .we(we_w), .wa(rd_w), .wd(wynik_wb),
        .ra1(rs1_d), .ra2(rs2_d), .rd1(v1_d), .rd2(v2_d));

    // ------------------------------------------------------------------ ID/EX
    reg  [31:0] pc_e, a_e, b_e, imm_e;
    reg  [4:0]  rs1_e, rs2_e, rd_e;
    reg  [2:0]  f3_e;
    reg  [3:0]  alu_op_e;
    reg         v_e, a_pc_e, a_zero_e, b_imm_e, zapis_rd_e, odczyt_e, zapis_e, galaz_e, jal_e, jalr_e;

    assign stoj = v_e && odczyt_e && rd_e != 5'd0 && v_d &&
                  ((uzywa_rs1_d && rs1_d == rd_e) || (uzywa_rs2_d && rs2_d == rd_e));

    always @(posedge clk) begin
        pc_e <= pc_d; a_e <= v1_d; b_e <= v2_d; imm_e <= imm_d;
        rs1_e <= rs1_d; rs2_e <= rs2_d; rd_e <= rd_d; f3_e <= f3_d; alu_op_e <= alu_op_d;
        a_pc_e <= a_pc_d; a_zero_e <= a_zero_d; b_imm_e <= b_imm_d;
        if (rst || przekieruj || stoj) begin                    // bąbelek
            v_e <= 1'b0; zapis_rd_e <= 1'b0; odczyt_e <= 1'b0; zapis_e <= 1'b0;
            galaz_e <= 1'b0; jal_e <= 1'b0; jalr_e <= 1'b0;
        end else begin
            v_e <= v_d; zapis_rd_e <= zapis_rd_d && ok_d; odczyt_e <= odczyt_d && ok_d; zapis_e <= zapis_d && ok_d;
            galaz_e <= galaz_d && ok_d; jal_e <= jal_d && ok_d; jalr_e <= jalr_d && ok_d;
        end
    end

    // ------------------------------------------------------------------ EX
    reg  [31:0] wynik_m;
    reg  [4:0]  rd_m;
    reg         v_m, zapis_rd_m, odczyt_m;
    wire        z_m_1 = v_m && zapis_rd_m && !odczyt_m && rd_m != 5'd0;
    wire        z_w_1 = we_w && rd_w != 5'd0;
    wire [31:0] fa = (z_m_1 && rd_m == rs1_e) ? wynik_m : (z_w_1 && rd_w == rs1_e) ? wynik_wb : a_e;
    wire [31:0] fb = (z_m_1 && rd_m == rs2_e) ? wynik_m : (z_w_1 && rd_w == rs2_e) ? wynik_wb : b_e;

    wire [31:0] y;
    rv_alu u_alu (.a(a_zero_e ? 32'd0 : a_pc_e ? pc_e : fa), .b(b_imm_e ? imm_e : fb), .op(alu_op_e), .y(y));

    reg warunek;
    always @(*)
        case (f3_e)
            3'd0:    warunek = fa == fb;
            3'd1:    warunek = fa != fb;
            3'd4:    warunek = $signed(fa) < $signed(fb);
            3'd5:    warunek = $signed(fa) >= $signed(fb);
            3'd6:    warunek = fa < fb;
            default: warunek = fa >= fb;
        endcase

    assign przekieruj = v_e && (jal_e || jalr_e || (galaz_e && warunek));
    assign cel        = jalr_e ? {y[31:1], 1'b0} : pc_e + imm_e;
    wire [31:0] wynik_e = (jal_e || jalr_e) ? pc_e + 32'd4 : y;

    // ------------------------------------------------------------------ EX/MEM i MEM
    reg  [31:0] adr_m, sdane_m;
    reg  [2:0]  f3_m;
    reg         zapis_m;
    always @(posedge clk) begin
        wynik_m <= wynik_e; rd_m <= rd_e; adr_m <= y; sdane_m <= fb; f3_m <= f3_e;
        if (rst) begin
            v_m <= 1'b0; zapis_rd_m <= 1'b0; odczyt_m <= 1'b0; zapis_m <= 1'b0;
        end else begin
            v_m <= v_e; zapis_rd_m <= zapis_rd_e; odczyt_m <= odczyt_e; zapis_m <= zapis_e;
        end
    end

    reg  [31:0] wynik_w;
    reg  [2:0]  f3_w;
    reg  [1:0]  adr_w;
    reg  [4:0]  rd_w_r;
    reg         v_w, zapis_rd_w, odczyt_w;
    wire [31:0] z_wy, o_wy;
    wire [3:0]  z_strb;
    rv_wyrownanie u_wyr (.z_f3(f3_m), .z_adr(adr_m[1:0]), .z_dane(sdane_m), .z_wy(z_wy), .z_strb(z_strb),
        .o_f3(f3_w), .o_adr(adr_w), .o_dane(d_rdane), .o_wy(o_wy));
    assign d_adr    = {adr_m[31:2], 2'b00};
    assign d_wdane  = z_wy;
    assign d_wstrb  = (v_m && zapis_m) ? z_strb : 4'd0;
    assign d_odczyt = v_m && odczyt_m;

    // ------------------------------------------------------------------ MEM/WB i WB
    always @(posedge clk) begin
        wynik_w <= wynik_m; rd_w_r <= rd_m; f3_w <= f3_m; adr_w <= adr_m[1:0];
        if (rst) begin
            v_w <= 1'b0; zapis_rd_w <= 1'b0; odczyt_w <= 1'b0;
        end else begin
            v_w <= v_m; zapis_rd_w <= zapis_rd_m; odczyt_w <= odczyt_m;
        end
    end
    assign rd_w     = rd_w_r;
    assign we_w     = v_w && zapis_rd_w;
    assign wynik_wb = odczyt_w ? o_wy : wynik_w;
    assign wycofana = v_w;
endmodule

`default_nettype wire
