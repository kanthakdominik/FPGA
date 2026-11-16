// Detektor zboczy sygnału synchronicznego: impuls jednego taktu przy zmianie wejścia.
module edge_detect (
    input  logic clk,
    input  logic d,                                // zsynchronizowane z clk
    output logic rise,
    output logic fall,
    output logic any
);
    logic d_q = 1'b0;                              // logic: jeden typ zamiast wire i reg

    always_ff @(posedge clk)
        d_q <= d;

    assign rise = d & ~d_q;
    assign fall = ~d & d_q;
    assign any  = d ^ d_q;
endmodule
