// Detektor zboczy sygnału synchronicznego: impuls jednego taktu przy zmianie wejścia.
// Wejście d musi już być zsynchronizowane z clk (np. wyjście debouncer).
`default_nettype none

module edge_detect (
    input  wire clk,
    input  wire d,
    output wire rise,                              // d: 0 -> 1
    output wire fall,                              // d: 1 -> 0
    output wire any                                // dowolna zmiana
);
    reg d_q = 1'b0;                                // reg: przypisywany w bloku always

    always @(posedge clk)
        d_q <= d;

    // wire: wyjścia kombinacyjne z assign
    assign rise = d & ~d_q;
    assign fall = ~d & d_q;
    assign any  = d ^ d_q;
endmodule

`default_nettype wire
