// ALU z handshake valid/ready — układ weryfikowany w module 10. Operacja przyjęta, gdy in_valid = 1
// i in_ready = 1; wynik w rejestrze wyjściowym w następnym takcie, trzymany bez zmian do odebrania
// (out_valid = 1 i out_ready = 1). in_ready = 1, gdy rejestr wyjściowy jest wolny albo zwalniany w tym takcie.
//
//   op: 0 ADD  {carry, res} = a + b          4 XOR  res = a ^ b
//       1 SUB  {carry, res} = a - b (carry = pożyczka, a < b)
//       2 AND  res = a & b                   5 SHL  res = a << b[SH-1:0]
//       3 OR   res = a | b                   6 SHR  res = a >> b[SH-1:0] (logiczne)
//       7 —    kod niedozwolony: err = 1, res = 0
//   carry = 0 poza ADD i SUB, zero = (res == 0).
//
// Parametr BUG wstrzykuje błąd do ćwiczeń weryfikacji (0 = układ poprawny):
//   1 — pożyczka SUB liczona jako a <= b (błąd tylko dla a == b),
//   2 — in_ready = 1 zawsze (ignorowanie wstrzymania: nadpisanie nieodebranego wyniku).
module alu_hs #(
    parameter int W   = 8,
    parameter int BUG = 0
) (
    input  logic         clk,
    input  logic         rst,
    input  logic         in_valid,
    output logic         in_ready,
    input  logic [2:0]   op,
    input  logic [W-1:0] a,
    input  logic [W-1:0] b,
    output logic         out_valid = 1'b0,
    input  logic         out_ready,
    output logic [W-1:0] res,
    output logic         carry,
    output logic         zero,
    output logic         err
);
    localparam int SH = $clog2(W);

    logic [W-1:0] r;
    logic         c, e;

    always_comb begin
        r = '0;
        c = 1'b0;
        e = 1'b0;
        unique case (op)
            3'd0: {c, r} = {1'b0, a} + {1'b0, b};
            3'd1: begin
                {c, r} = {1'b0, a} - {1'b0, b};
                if (BUG == 1) c = (a <= b);
            end
            3'd2: r = a & b;
            3'd3: r = a | b;
            3'd4: r = a ^ b;
            3'd5: r = a << b[SH-1:0];
            3'd6: r = a >> b[SH-1:0];
            3'd7: e = 1'b1;
        endcase
    end

    assign in_ready = (BUG == 2) ? 1'b1 : (!out_valid || out_ready);

    always_ff @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
        end else if (in_valid && in_ready) begin
            out_valid <= 1'b1;
            res       <= r;
            carry     <= c;
            zero      <= (r == '0);
            err       <= e;
        end else if (out_ready) begin
            out_valid <= 1'b0;
        end
    end
endmodule
