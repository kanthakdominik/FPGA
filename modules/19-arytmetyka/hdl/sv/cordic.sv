// CORDIC w pełnym potoku (19.04): obroty o kąty atan(2^-i) samymi przesunięciami i dodawaniami.
//   TRYB = 0 — obrót (rotation): (x, y) obrócony o kąt z_in; dla x_in = A/K, y_in = 0 daje A·cos, A·sin.
//   TRYB = 1 — wektorowanie (vectoring): obrót do osi x; x_out = K·|(x, y)|, z_out = z_in + atan2(y, x).
// Kąt binarny A-bitowy ze znakiem: 2^A = pełny obrót, zakres [-180°, 180°). Wstępny obrót o ±90°
// rozszerza zakres zbieżności CORDIC (±99,9°) na cały okrąg. Wzmocnienie K = Π sqrt(1 + 2^-2i)
// ≈ 1,64676 (N >= 10) — wyjścia są K razy większe, dlatego mają W+2 bitów.
// Wewnątrz: W+2 bitów części całkowitej i G bitów ochronnych ułamka; na wyjściu zaokrąglenie.
// Potok: obrót wstępny, N iteracji, zaokrąglenie — opóźnienie N+2 taktów, wynik w każdym takcie.
`default_nettype none

module cordic #(
    parameter W    = 16,                   // bity x, y na wejściu
    parameter A    = 24,                   // bity kąta (A <= 30)
    parameter N    = 18,                   // liczba iteracji (N <= A - 2)
    parameter G    = 4,                    // bity ochronne ułamka (G >= 2)
    parameter TRYB = 0
) (
    input  logic           clk,
    input  logic           in_valid,
    input  logic [W-1:0]   x_in,
    input  logic [W-1:0]   y_in,
    input  logic [A-1:0]   z_in,
    output logic            out_valid = 1'b0,
    output logic  [W+1:0]   x_out,
    output logic  [W+1:0]   y_out,
    output logic  [A-1:0]   z_out
);
    localparam WI = W + 2 + G;

    // atan(2^-i) w jednostkach 2^-32 pełnego obrotu, zaokrąglone do A bitów
    function [31:0] atan32(input integer i);
        case (i)
             0: atan32 = 32'h20000000;
             1: atan32 = 32'h12E4051E;
             2: atan32 = 32'h09FB385B;
             3: atan32 = 32'h051111D4;
             4: atan32 = 32'h028B0D43;
             5: atan32 = 32'h0145D7E1;
             6: atan32 = 32'h00A2F61E;
             7: atan32 = 32'h00517C55;
             8: atan32 = 32'h0028BE53;
             9: atan32 = 32'h00145F2F;
            10: atan32 = 32'h000A2F98;
            11: atan32 = 32'h000517CC;
            12: atan32 = 32'h00028BE6;
            13: atan32 = 32'h000145F3;
            14: atan32 = 32'h0000A2FA;
            15: atan32 = 32'h0000517D;
            16: atan32 = 32'h000028BE;
            17: atan32 = 32'h0000145F;
            18: atan32 = 32'h00000A30;
            19: atan32 = 32'h00000518;
            20: atan32 = 32'h0000028C;
            21: atan32 = 32'h00000146;
            22: atan32 = 32'h000000A3;
            23: atan32 = 32'h00000051;
            24: atan32 = 32'h00000029;
            25: atan32 = 32'h00000014;
            26: atan32 = 32'h0000000A;
            27: atan32 = 32'h00000005;
            28: atan32 = 32'h00000003;
            29: atan32 = 32'h00000001;
            30: atan32 = 32'h00000001;
            31: atan32 = 32'h00000000;
            default: atan32 = 32'h00000000;
        endcase
    endfunction

    /* verilator lint_off UNUSEDSIGNAL */
    function [A-1:0] atan_a(input integer i);
        logic [32:0] t;
        begin
            t      = {1'b0, atan32(i)} + (33'd1 << (31 - A));
            atan_a = t[31 -: A];
        end
    endfunction
    /* verilator lint_on UNUSEDSIGNAL */

    logic signed [WI-1:0] x0;
    assign x0 = {{2{x_in[W-1]}}, x_in, {G{1'b0}}};
    logic signed [WI-1:0] y0;
    assign y0 = {{2{y_in[W-1]}}, y_in, {G{1'b0}}};
    localparam [A-1:0] CWIERC = {2'b01, {(A-2){1'b0}}};       // 90°

    // stan potoku: indeks 0 — po obrocie wstępnym, k — po k iteracjach
    wire signed [WI-1:0] x [0:N];
    wire signed [WI-1:0] y [0:N];
    wire signed [A-1:0]  z [0:N];
    wire                 v [0:N];

    logic signed [WI-1:0] xp, yp;
    logic signed [A-1:0]  zp;
    logic                 vp = 1'b0;

    always_ff @(posedge clk) begin
        vp <= in_valid;
        if (TRYB == 0) begin
            case (z_in[A-1:A-2])
                2'b01:   begin xp <= -y0; yp <= x0;  zp <= z_in - CWIERC; end   // (90°, 180°): obrót o +90°
                2'b10:   begin xp <= y0;  yp <= -x0; zp <= z_in + CWIERC; end   // [-180°, -90°): o -90°
                default: begin xp <= x0;  yp <= y0;  zp <= z_in;          end
            endcase
        end else begin
            if (x_in[W-1] && !y_in[W-1])     begin xp <= y0;  yp <= -x0; zp <= z_in + CWIERC; end
            else if (x_in[W-1])              begin xp <= -y0; yp <= x0;  zp <= z_in - CWIERC; end
            else                             begin xp <= x0;  yp <= y0;  zp <= z_in;          end
        end
    end

    assign x[0] = xp;
    assign y[0] = yp;
    assign z[0] = zp;
    assign v[0] = vp;

    genvar k;
    generate
        for (k = 0; k < N; k = k + 1) begin : g_it
            localparam [A-1:0] KAT = atan_a(k);
            // kierunek obrotu: obrót — zgodnie ze znakiem reszty kąta, wektorowanie — przeciwnie do znaku y
            logic                d_plus;
            assign d_plus = (TRYB == 0) ? !z[k][A-1] : y[k][WI-1];
            logic signed [WI-1:0] xs;
            assign xs = x[k] >>> k;
            logic signed [WI-1:0] ys;
            assign ys = y[k] >>> k;
            logic  signed [WI-1:0] xr, yr;
            logic  signed [A-1:0]  zr;
            logic                  vr = 1'b0;
            always_ff @(posedge clk) begin
                vr <= v[k];
                if (d_plus) begin
                    xr <= x[k] - ys;
                    yr <= y[k] + xs;
                    zr <= z[k] - KAT;
                end else begin
                    xr <= x[k] + ys;
                    yr <= y[k] - xs;
                    zr <= z[k] + KAT;
                end
            end
            assign x[k+1] = xr;
            assign y[k+1] = yr;
            assign z[k+1] = zr;
            assign v[k+1] = vr;
        end
    endgenerate

    // zaokrąglenie: połówka w górę, usunięcie G bitów ochronnych
    localparam [WI-1:0] POL = {{(WI-G){1'b0}}, 1'b1, {(G-1){1'b0}}};
    /* verilator lint_off UNUSEDSIGNAL */
    logic [WI-1:0] xz;
    assign xz = x[N] + POL;
    logic [WI-1:0] yz;
    assign yz = y[N] + POL;
    /* verilator lint_on UNUSEDSIGNAL */

    always_ff @(posedge clk) begin
        out_valid <= v[N];
        x_out     <= xz[WI-1:G];
        y_out     <= yz[WI-1:G];
        z_out     <= z[N];
    end
endmodule

`default_nettype wire
