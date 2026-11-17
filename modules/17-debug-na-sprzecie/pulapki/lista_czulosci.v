// Pułapka 1 (17.05): niepełna lista czułości. Symulator wykonuje blok tylko przy zmianie sygnałów
// z listy — przy zmianie samego b wyjście się nie zmienia. Synteza listę czułości ignoruje i buduje
// zwykłą bramkę AND. Symulacja RTL i sprzęt działają różnie.
`default_nettype none

module lista_czulosci_zle (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output reg  [7:0] y
);
    always @(a) y = a & b;           // brak b na liście
endmodule

module lista_czulosci_dobrze (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output reg  [7:0] y
);
    always @(*) y = a & b;
endmodule

`default_nettype wire
