// Liczba jedynek w słowie — przypisania blokujące w bloku kombinacyjnym działają jak zmienne VHDL.
`default_nettype none

module popcount #(
    parameter integer W = 8
) (
    input  wire [W-1:0]           d,
    output reg  [$clog2(W+1)-1:0] count
);
    integer i;

    always @* begin
        count = 0;
        for (i = 0; i < W; i = i + 1)
            count = count + d[i];                  // = : nowa wartość widoczna w następnej iteracji
    end
endmodule

`default_nettype wire
