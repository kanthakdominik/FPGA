// Opakowanie formalne licznika cnt10 (13.01, 13.02). Wejścia opakowania (rst, en) są wolne:
// solver wybiera ich wartości w każdym takcie — jedynym ograniczeniem jest reset w pierwszym takcie.
//   -D INVARIANT     dodaje niezmiennik q <= 9, bez którego indukcja nie domyka dowodu q != 12,
//   -D NIEOSIAGALNY  dodaje cover stanu 10 — nieosiągalnego, więc zadanie cover kończy się FAIL.
module cnt10_formal (
    input logic clk,
    input logic rst,
    input logic en
);
    logic [3:0] q;
    logic       wrap;

    cnt10 dut (.clk(clk), .rst(rst), .en(en), .q(q), .wrap(wrap));

    // ---- otoczenie ----
    logic f_past_valid = 1'b0;                    // 0 tylko w pierwszym takcie
    always_ff @(posedge clk) f_past_valid <= 1'b1;
    always_comb if (!f_past_valid) assume (rst);

    // ---- właściwość docelowa ----
    always_comb if (f_past_valid) assert (q != 4'd12);

`ifdef INVARIANT
    // ---- niezmiennik: mocniejszy, ale indukcyjny ----
    always_comb if (f_past_valid) assert (q <= 4'd9);
`endif

    // ---- zachowanie krok po kroku ----
    always_ff @(posedge clk) if (f_past_valid) begin
        if ($past(rst))      assert (q == 4'd0);
        else if (!$past(en)) assert ($stable(q));
        else if ($past(q) == 4'd9) assert (q == 4'd0);
        else                 assert (q == $past(q) + 4'd1);
    end
    always_comb assert (wrap == (en && q == 4'd9));

    // ---- osiągalność ----
    always_comb if (f_past_valid && !rst) begin
        cover (wrap);                              // pełny obieg 0…9 i przejście na 0
        cover (q == 4'd9 && !en);                  // wstrzymanie na 9
`ifdef NIEOSIAGALNY
        cover (q == 4'd10);                        // nie da się — cover kończy się FAIL
`endif
    end
endmodule
