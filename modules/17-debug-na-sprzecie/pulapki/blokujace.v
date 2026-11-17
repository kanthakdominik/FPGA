// Pułapka 5 (17.05): przypisania blokujące (=) w dwóch blokach taktowanych tym samym zegarem.
// Sprzęt: dwa rejestry wymieniają się wartościami w każdym takcie. Symulator wykonuje bloki po kolei
// (kolejność nieokreślona): pierwszy nadpisuje wartość, którą drugi miał przeczytać — po pierwszym
// takcie oba rejestry są równe. Wynik symulacji zależy od kolejności, sprzęt nie.
`default_nettype none

module blokujace_zle (
    input  wire       clk,
    input  wire       load,
    input  wire [7:0] da,
    input  wire [7:0] db,
    output reg  [7:0] a,
    output reg  [7:0] b
);
    always @(posedge clk) if (load) a = da; else a = b;
    always @(posedge clk) if (load) b = db; else b = a;
endmodule

module blokujace_dobrze (
    input  wire       clk,
    input  wire       load,
    input  wire [7:0] da,
    input  wire [7:0] db,
    output reg  [7:0] a,
    output reg  [7:0] b
);
    always @(posedge clk) if (load) a <= da; else a <= b;
    always @(posedge clk) if (load) b <= db; else b <= a;
endmodule

`default_nettype wire
