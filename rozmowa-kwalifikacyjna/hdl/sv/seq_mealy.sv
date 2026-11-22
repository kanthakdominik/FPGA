// Zadanie 4b: ten sam detektor 1011 jako automat Mealy'ego — wyjście zależy od stanu i wejścia, więc pojawia się
// w takcie ostatniego bitu i potrzebny jest o jeden stan mniej. Wyjście kombinacyjne z wejścia: zakłócenie
// na x przechodzi na det, a ścieżka x -> det wydłuża ścieżkę krytyczną w następnym bloku.
`default_nettype none

module seq_mealy (
    input  logic clk,
    input  logic rst,
    input  logic x,
    output logic det
);
    typedef enum logic [1:0] {S0, S1, S2, S3} state_t;
    state_t st = S0;
    state_t st_next;

    always_comb begin
        unique case (st)
            S0:      st_next = x ? S1 : S0;
            S1:      st_next = x ? S1 : S2;
            S2:      st_next = x ? S3 : S0;
            default: st_next = x ? S1 : S2;     // S3 ("101"): 1 — wykrycie, dalej "1"; 0 — "10"
        endcase
    end

    always_ff @(posedge clk)
        if (rst) st <= S0;
        else     st <= st_next;

    assign det = (st == S3) & x;
endmodule

`default_nettype wire
