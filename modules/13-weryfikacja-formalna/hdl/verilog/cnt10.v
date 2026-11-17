// Licznik dziesiętny 0…9 z zezwoleniem — najprostszy układ do pierwszych dowodów formalnych (13.01, 13.02).
// wrap = 1 w takcie, w którym licznik przechodzi z 9 na 0. Stany 10…15 są nieosiągalne z resetu.
`default_nettype none

module cnt10 (
    input  wire       clk,
    input  wire       rst,
    input  wire       en,
    output reg  [3:0] q,
    output wire       wrap
);
    always @(posedge clk) begin
        if (rst)     q <= 4'd0;
        else if (en) q <= (q == 4'd9) ? 4'd0 : q + 4'd1;
    end

    assign wrap = en && (q == 4'd9);
endmodule

`default_nettype wire
