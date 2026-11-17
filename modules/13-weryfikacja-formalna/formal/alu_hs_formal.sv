// Opakowanie formalne alu_hs z modułu 10 (13.03). Wszystkie wejścia są wolne; otoczenie ograniczają
// założenia (assume): reset w pierwszym takcie i reguła źródła — wstrzymana transakcja nie znika i nie
// zmienia danych. Sprawdzane (assert): reset, opóźnienie 1 takt, trzymanie wyniku przy wstrzymaniu
// (brak nadpisania) i poprawność wyniku względem niezależnego modelu f_* liczonego przy przyjęciu.
// Parametr BUG przekazywany do alu_hs: 0 — PASS, 1 i 2 — kontrprzykład.
module alu_hs_formal #(
    parameter int BUG = 0
) (
    input logic       clk,
    input logic       rst,
    input logic       in_valid,
    input logic [2:0] op,
    input logic [7:0] a,
    input logic [7:0] b,
    input logic       out_ready
);
    localparam int W = 8;

    logic         in_ready, out_valid, carry, zero, err;
    logic [W-1:0] res;

    alu_hs #(.W(W), .BUG(BUG)) dut (
        .clk(clk), .rst(rst), .in_valid(in_valid), .in_ready(in_ready), .op(op), .a(a), .b(b),
        .out_valid(out_valid), .out_ready(out_ready), .res(res), .carry(carry), .zero(zero), .err(err)
    );

    // ---- założenia o otoczeniu ----
    logic f_past_valid = 1'b0;
    always_ff @(posedge clk) f_past_valid <= 1'b1;
    always_comb if (!f_past_valid) assume (rst);

    always_ff @(posedge clk)
        if (f_past_valid && !$past(rst) && $past(in_valid && !in_ready))
            assume (in_valid && $stable(op) && $stable(a) && $stable(b));

    // ---- niezależny model wyniku, zapisywany przy przyjęciu operacji ----
    logic [W-1:0] f_res, f_sum;
    logic         f_carry, f_err;
    wire          f_accept = in_valid && in_ready;

    assign f_sum = a + b;                          // przeniesienie: suma mod 2^W mniejsza od a

    always_ff @(posedge clk) if (f_accept) begin
        f_carry <= 1'b0;
        f_err   <= 1'b0;
        case (op)
            3'd0: begin f_res <= f_sum;  f_carry <= (f_sum < a); end
            3'd1: begin f_res <= a - b;  f_carry <= (a < b);     end
            3'd2: f_res <= a & b;
            3'd3: f_res <= a | b;
            3'd4: f_res <= a ^ b;
            3'd5: f_res <= a << b[2:0];
            3'd6: f_res <= a >> b[2:0];
            default: begin f_res <= '0; f_err <= 1'b1; end
        endcase
    end

    // ---- właściwości ----
    always_ff @(posedge clk) if (f_past_valid) begin
        // reset czyści wyjście
        if ($past(rst)) assert (!out_valid);
        // opóźnienie: wynik w takcie po przyjęciu
        if (!$past(rst) && $past(f_accept)) assert (out_valid);
        // bez przyjęcia nie pojawia się nowy wynik
        if (!$past(rst) && !$past(out_valid) && !$past(f_accept)) assert (!out_valid);
        // wstrzymanie: wynik czeka bez zmian (BUG=2 go nadpisuje)
        if (!$past(rst) && $past(out_valid && !out_ready))
            assert (out_valid && $stable(res) && $stable(carry) && $stable(zero) && $stable(err));
    end

    // wynik zgodny z modelem (BUG=1 łamie to dla SUB z a == b)
    always_comb if (f_past_valid && out_valid)
        assert (res == f_res && carry == f_carry && zero == (f_res == '0) && err == f_err);

    // ---- osiągalność ----
    always_ff @(posedge clk) if (f_past_valid && !rst) begin
        cover (out_valid && !out_ready && in_valid);             // wstrzymanie przy czekającym źródle
        cover (out_valid && err);                                // kod niedozwolony
        cover (out_valid && carry && zero);                      // ADD z przeniesieniem i wynikiem 0
        cover ($past(out_valid && out_ready) && out_valid);      // dwa wyniki z rzędu
    end
endmodule
