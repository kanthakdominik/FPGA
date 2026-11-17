// Licznik dziesiętny 0…9 z zezwoleniem — najprostszy układ do pierwszych dowodów formalnych (13.01, 13.02).
// wrap = 1 w takcie, w którym licznik przechodzi z 9 na 0. Stany 10…15 są nieosiągalne z resetu.
module cnt10 (
    input  logic       clk,
    input  logic       rst,
    input  logic       en,
    output logic [3:0] q,
    output logic       wrap
);
    always_ff @(posedge clk) begin
        if (rst)     q <= '0;
        else if (en) q <= (q == 4'd9) ? 4'd0 : q + 4'd1;
    end

    assign wrap = en && (q == 4'd9);
endmodule
