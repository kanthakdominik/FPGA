// Generator NCO (26.03): akumulator fazy 32 bity, ćwiartka sinusa w ROM (sin_tab: 256 × 16 bitów), wyjścia sin i cos.
// Faza -> ćwiartka (bity 31..30) i adres (29..22); w ćwiartkach 1 i 3 adres odwrócony (255 - a), w 2 i 3 wynik
// z przeciwnym znakiem; cos = sin(faza + 90°). Próbka dla fazy sprzed dodania ftw; opóźnienie 2 takty (wazne).
// Częstotliwość: f = ftw · f_we / 2^32 (f_we — częstotliwość impulsów we).
`default_nettype none

module nco (
    input  logic               clk,
    input  logic               rst,
    input  logic               we,
    input  logic        [31:0] ftw,
    output logic  signed [15:0] sin_o,
    output logic  signed [15:0] cos_o,
    output logic                wazne
);
    logic  [31:0] faza;
    /* verilator lint_off UNUSEDSIGNAL */                // faza_c[21:0] — poniżej adresu ROM
    logic [31:0] faza_c;
    assign faza_c = faza + 32'h4000_0000;
    /* verilator lint_on UNUSEDSIGNAL */
    logic [1:0]  qs;
    assign qs = faza[31:30];
    logic [1:0]  qc;
    assign qc = faza_c[31:30];
    logic [7:0]  as_;
    assign as_ = qs[0] ? ~faza[29:22]   : faza[29:22];      // 255 - a = ~a
    logic [7:0]  ac;
    assign ac = qc[0] ? ~faza_c[29:22] : faza_c[29:22];
    logic [15:0] rs, rc;
    logic         ns, nc, v1;
    sin_tab u_s (.clk(clk), .a(as_), .q(rs));
    sin_tab u_c (.clk(clk), .a(ac),  .q(rc));

    always_ff @(posedge clk) begin
        if (rst) begin
            faza <= 32'd0; ns <= 1'b0; nc <= 1'b0; v1 <= 1'b0; wazne <= 1'b0; sin_o <= 16'sd0; cos_o <= 16'sd0;
        end else begin
            v1 <= we;
            ns <= qs[1];
            nc <= qc[1];
            if (we) faza <= faza + ftw;
            wazne <= v1;
            sin_o <= ns ? -$signed(rs) : $signed(rs);
            cos_o <= nc ? -$signed(rc) : $signed(rc);
        end
    end
endmodule

`default_nettype wire
