// Zadanie 1: detektor zbocza narastającego i opadającego. Wejście d jest synchroniczne z clk (sygnał z zewnątrz
// najpierw przez synchronizator). Wyjścia kombinacyjne — impuls w tym samym takcie, w którym d ma już nową wartość.
`default_nettype none

module edge_detect (
    input  logic clk,
    input  logic rst,
    input  logic d,
    output logic rise,
    output logic fall
);
    logic d_q = 1'b0;                 // wartość d z poprzedniego taktu

    always_ff @(posedge clk)
        if (rst) d_q <= 1'b0;
        else     d_q <= d;

    assign rise = d & ~d_q;
    assign fall = ~d & d_q;
endmodule

`default_nettype wire
