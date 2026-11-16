// Rejestr przesuwny szeregowo-równoległy (deserializator): nowy bit wchodzi na najmłodszą pozycję.
module shift_sipo #(
    parameter int W = 8
) (
    input  logic         clk,
    input  logic         shift,
    input  logic         sin,
    output logic [W-1:0] dout
);
    always_ff @(posedge clk)
        if (shift) dout <= {dout[W-2:0], sin};
endmodule
