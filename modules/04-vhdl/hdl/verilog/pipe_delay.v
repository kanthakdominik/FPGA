// Linia opóźniająca o DEPTH taktów z rejestrów dff_reg (generate for)
// i przypadek szczególny DEPTH = 0 (generate if: zwykłe połączenie).
`default_nettype none

module pipe_delay #(
    parameter integer W     = 8,
    parameter integer DEPTH = 3
) (
    input  wire         clk,
    input  wire [W-1:0] x,
    output wire [W-1:0] y
);
    generate
        if (DEPTH == 0) begin : g_wire
            assign y = x;
        end else begin : g_regs
            // stage[i*W +: W] = wejście i-tego rejestru; stage[DEPTH*W +: W] = wyjście
            wire [(DEPTH+1)*W-1:0] stage;
            assign stage[0 +: W] = x;

            genvar i;
            for (i = 0; i < DEPTH; i = i + 1) begin : g_stage
                dff_reg #(.W(W)) u_reg (
                    .clk(clk), .d(stage[i*W +: W]), .q(stage[(i+1)*W +: W])
                );
            end

            assign y = stage[DEPTH*W +: W];
        end
    endgenerate
endmodule

`default_nettype wire
