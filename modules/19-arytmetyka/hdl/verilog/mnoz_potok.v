// Mnożarka z potokiem o LAT stopniach (19.02), operandy ze znakiem (ZNAK = 1) albo bez (ZNAK = 0).
// Struktura dopasowana do bloku mnożarki: LAT >= 1 — rejestr wyjściowy, LAT >= 2 — także rejestry
// wejściowe (oba istnieją w bloku MAX 10 i ECP5), LAT >= 3 — dodatkowe rejestry za mnożarką, które
// narzędzie może przesunąć do środka (retiming) albo zostawić w logice.
// Jeden kod dla obu rodzajów liczb: operandy rozszerzone o bit (znakiem albo zerem) i mnożone ze znakiem.
`default_nettype none

module mnoz_potok #(
    parameter WA   = 18,
    parameter WB   = 18,
    parameter ZNAK = 1,
    parameter LAT  = 2
) (
    input  wire               clk,
    input  wire               in_valid,
    input  wire [WA-1:0]      a,
    input  wire [WB-1:0]      b,
    output wire               out_valid,
    output wire [WA+WB-1:0]   p
);
    wire [WA-1:0] a_m;
    wire [WB-1:0] b_m;
    wire          v_m;

    generate
        if (LAT >= 2) begin : g_wej
            reg [WA-1:0] a_r;
            reg [WB-1:0] b_r;
            reg          v_r = 1'b0;
            always @(posedge clk) begin
                a_r <= a;
                b_r <= b;
                v_r <= in_valid;
            end
            assign a_m = a_r;
            assign b_m = b_r;
            assign v_m = v_r;
        end else begin : g_bez_wej
            assign a_m = a;
            assign b_m = b;
            assign v_m = in_valid;
        end
    endgenerate

    wire signed [WA:0]      a_x = {ZNAK != 0 ? a_m[WA-1] : 1'b0, a_m};
    wire signed [WB:0]      b_x = {ZNAK != 0 ? b_m[WB-1] : 1'b0, b_m};
    /* verilator lint_off UNUSEDSIGNAL */
    wire signed [WA+WB+1:0] pelny = a_x * b_x;          // WA+WB+2 bitów; iloczyn mieści się w WA+WB
    /* verilator lint_on UNUSEDSIGNAL */
    wire        [WA+WB-1:0] iloczyn = pelny[WA+WB-1:0];

    localparam NW = (LAT >= 2) ? LAT - 1 : LAT;          // rejestry za mnożarką

    generate
        if (NW == 0) begin : g_komb
            assign p         = iloczyn;
            assign out_valid = v_m;
        end else if (NW == 1) begin : g_wyj1
            reg [WA+WB-1:0] rp;
            reg             rv = 1'b0;
            always @(posedge clk) begin
                rp <= iloczyn;
                rv <= v_m;
            end
            assign p         = rp;
            assign out_valid = rv;
        end else begin : g_wyj
            localparam WP = WA + WB;
            reg [NW*WP-1:0] rp;                              // NW rejestrów iloczynu jeden za drugim
            reg [NW-1:0]    rv = {NW{1'b0}};
            always @(posedge clk) begin
                rp <= {rp[(NW-1)*WP-1:0], iloczyn};
                rv <= {rv[NW-2:0], v_m};
            end
            assign p         = rp[NW*WP-1 -: WP];
            assign out_valid = rv[NW-1];
        end
    endgenerate
endmodule

`default_nettype wire
