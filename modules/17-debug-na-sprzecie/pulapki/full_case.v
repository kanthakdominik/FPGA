// Pułapka 4 (17.05): dyrektywa full_case. Dla s = 3 żadna gałąź nie przypisuje y — symulator zostawia
// poprzednią wartość (zachowanie zatrzasku), a synteza z full_case uznaje ten przypadek za "nie dbam"
// i buduje logikę kombinacyjną z dowolną wartością. Dyrektywa zmienia sprzęt, a nie symulację.
`default_nettype none

module full_case_zle (
    input  wire [1:0] s,
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [7:0] c,
    output reg  [7:0] y
);
    always @(*)
        (* full_case *)
        case (s)
            2'd0: y = a;
            2'd1: y = b;
            2'd2: y = c;
        endcase
endmodule

module full_case_dobrze (
    input  wire [1:0] s,
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [7:0] c,
    output reg  [7:0] y
);
    always @(*)
        case (s)
            2'd0:    y = a;
            2'd1:    y = b;
            2'd2:    y = c;
            default: y = 8'd0;
        endcase
endmodule

`default_nettype wire
