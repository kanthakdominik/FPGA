// Wyrównanie danych pamięci dla RV32I (27.07): zapis — powielenie bajtu/półsłowa na wszystkie pasy i maska
// bajtów (wstrb) według funct3 i dwóch młodszych bitów adresu; odczyt — wybór pasa i rozszerzenie znaku
// (LB, LH) albo zerami (LBU, LHU). Kombinacyjne; adresy niewyrównane nie są obsługiwane.
`default_nettype none

module rv_wyrownanie (
    /* verilator lint_off UNUSEDSIGNAL */                    // z_f3[2]: SB/SH/SW różnią się bitami 1:0
    input  wire [2:0]  z_f3,
    /* verilator lint_on UNUSEDSIGNAL */
    input  wire [1:0]  z_adr,
    input  wire [31:0] z_dane,
    output reg  [31:0] z_wy,
    output reg  [3:0]  z_strb,
    input  wire [2:0]  o_f3,
    input  wire [1:0]  o_adr,
    input  wire [31:0] o_dane,
    output reg  [31:0] o_wy
);
    always @(*)
        case (z_f3[1:0])
            2'd0:    begin z_wy = {4{z_dane[7:0]}};  z_strb = 4'b0001 << z_adr; end
            2'd1:    begin z_wy = {2{z_dane[15:0]}}; z_strb = z_adr[1] ? 4'b1100 : 4'b0011; end
            default: begin z_wy = z_dane;            z_strb = 4'b1111; end
        endcase

    /* verilator lint_off UNUSEDSIGNAL */
    wire [31:0] przes = o_dane >> {o_adr, 3'b000};     // użyte 16 młodszych bitów
    /* verilator lint_on UNUSEDSIGNAL */
    always @(*)
        case (o_f3)
            3'd0:    o_wy = {{24{przes[7]}}, przes[7:0]};
            3'd1:    o_wy = {{16{przes[15]}}, przes[15:0]};
            3'd4:    o_wy = {24'd0, przes[7:0]};
            3'd5:    o_wy = {16'd0, przes[15:0]};
            default: o_wy = o_dane;
        endcase
endmodule

`default_nettype wire
