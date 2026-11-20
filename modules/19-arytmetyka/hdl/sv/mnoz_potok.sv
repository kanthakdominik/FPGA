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
    input  logic               clk,
    input  logic               in_valid,
    input  logic [WA-1:0]      a,
    input  logic [WB-1:0]      b,
    output logic               out_valid,
    output logic [WA+WB-1:0]   p
);
    logic [WA-1:0] a_m;
    logic [WB-1:0] b_m;
    logic          v_m;

    generate
        if (LAT >= 2) begin : g_wej
            logic [WA-1:0] a_r;
            logic [WB-1:0] b_r;
            logic          v_r = 1'b0;
            always_ff @(posedge clk) begin
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

    logic signed [WA:0]      a_x;
    assign a_x = {ZNAK != 0 ? a_m[WA-1] : 1'b0, a_m};
    logic signed [WB:0]      b_x;
    assign b_x = {ZNAK != 0 ? b_m[WB-1] : 1'b0, b_m};
    /* verilator lint_off UNUSEDSIGNAL */
    logic signed [WA+WB+1:0] pelny;
    assign pelny = a_x * b_x;          // WA+WB+2 bitów; iloczyn mieści się w WA+WB
    /* verilator lint_on UNUSEDSIGNAL */
    logic        [WA+WB-1:0] iloczyn;
    assign iloczyn = pelny[WA+WB-1:0];

    localparam NW = (LAT >= 2) ? LAT - 1 : LAT;          // rejestry za mnożarką

    generate
        if (NW == 0) begin : g_komb
            assign p         = iloczyn;
            assign out_valid = v_m;
        end else if (NW == 1) begin : g_wyj1
            logic [WA+WB-1:0] rp;
            logic             rv = 1'b0;
            always_ff @(posedge clk) begin
                rp <= iloczyn;
                rv <= v_m;
            end
            assign p         = rp;
            assign out_valid = rv;
        end else begin : g_wyj
            localparam WP = WA + WB;
            logic [NW*WP-1:0] rp;                              // NW rejestrów iloczynu jeden za drugim
            logic [NW-1:0]    rv = {NW{1'b0}};
            always_ff @(posedge clk) begin
                rp <= {rp[(NW-1)*WP-1:0], iloczyn};
                rv <= {rv[NW-2:0], v_m};
            end
            assign p         = rp[NW*WP-1 -: WP];
            assign out_valid = rv[NW-1];
        end
    endgenerate
endmodule

`default_nettype wire
