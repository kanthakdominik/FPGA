// Rejestr przesuwny równoległo-szeregowy (serializator): wpis równoległy, wyjście od najstarszego bitu.
`default_nettype none

module shift_piso #(
    parameter W = 8
) (
    input  wire         clk,
    input  wire         load,                  // wpis din (ma pierwszeństwo przed shift)
    input  wire         shift,
    input  wire [W-1:0] din,
    output wire         sout
);
    reg [W-1:0] sr;

    always @(posedge clk)
        if (load)       sr <= din;
        else if (shift) sr <= {sr[W-2:0], 1'b0};

    assign sout = sr[W-1];
endmodule

`default_nettype wire
