// Zadanie 4b: ten sam detektor 1011 jako automat Mealy'ego — wyjście zależy od stanu i wejścia, więc pojawia się
// w takcie ostatniego bitu i potrzebny jest o jeden stan mniej. Wyjście kombinacyjne z wejścia: zakłócenie
// na x przechodzi na det, a ścieżka x -> det wydłuża ścieżkę krytyczną w następnym bloku.
`default_nettype none

module seq_mealy (
    input  wire clk,
    input  wire rst,
    input  wire x,
    output wire det
);
    localparam [1:0] S0 = 2'd0, S1 = 2'd1, S2 = 2'd2, S3 = 2'd3;
    reg [1:0] st = S0;
    reg [1:0] st_next;

    always @(*) begin
        case (st)
            S0:      st_next = x ? S1 : S0;
            S1:      st_next = x ? S1 : S2;
            S2:      st_next = x ? S3 : S0;
            default: st_next = x ? S1 : S2;     // S3 ("101"): 1 — wykrycie, dalej "1"; 0 — "10"
        endcase
    end

    always @(posedge clk)
        if (rst) st <= S0;
        else     st <= st_next;

    assign det = (st == S3) & x;
endmodule

`default_nettype wire
