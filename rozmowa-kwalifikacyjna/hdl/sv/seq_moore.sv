// Zadanie 4a: detektor sekwencji 1011 (z nakładaniem) jako automat Moore'a — wyjście zależy tylko od stanu,
// więc pojawia się takt po ostatnim bicie sekwencji. Stany: ile bitów wzorca już pasuje (S4 — cały wzorzec).
`default_nettype none

module seq_moore (
    input  logic clk,
    input  logic rst,
    input  logic x,
    output logic det
);
    typedef enum logic [2:0] {S0, S1, S2, S3, S4} state_t;
    state_t st = S0;
    state_t st_next;

    always_comb begin
        unique case (st)
            S0:      st_next = x ? S1 : S0;
            S1:      st_next = x ? S1 : S2;     // "1", "11" — dalej pasuje "1"
            S2:      st_next = x ? S3 : S0;     // "10"
            S3:      st_next = x ? S4 : S2;     // "101"; "1010" kończy się na "10"
            S4:      st_next = x ? S1 : S2;     // "1011": nakładanie — "10111" -> "1", "10110" -> "10"
            default: st_next = S0;
        endcase
    end

    always_ff @(posedge clk)
        if (rst) st <= S0;
        else     st <= st_next;

    assign det = (st == S4);
endmodule

`default_nettype wire
