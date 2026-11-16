// Rejestr przesuwny równoległo-szeregowy (serializator): wpis równoległy, wyjście od najstarszego bitu.
module shift_piso #(
    parameter int W = 8
) (
    input  logic         clk,
    input  logic         load,                 // wpis din (ma pierwszeństwo przed shift)
    input  logic         shift,
    input  logic [W-1:0] din,
    output logic         sout
);
    logic [W-1:0] sr;

    always_ff @(posedge clk)
        if (load)       sr <= din;
        else if (shift) sr <= {sr[W-2:0], 1'b0};

    assign sout = sr[W-1];
endmodule
