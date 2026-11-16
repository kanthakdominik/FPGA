// Linia opóźniająca o DEPTH taktów z rejestrów dff_reg (pętla generate)
// i przypadek szczególny DEPTH = 0 (warunkowe generate: zwykłe połączenie).
module pipe_delay #(
    parameter int W     = 8,
    parameter int DEPTH = 3
) (
    input  logic         clk,
    input  logic [W-1:0] x,
    output logic [W-1:0] y
);
    if (DEPTH == 0) begin : g_wire
        assign y = x;
    end else begin : g_regs
        logic [W-1:0] stage [DEPTH+1];             // tablica rozpakowana: stage[0] = wejście
        assign stage[0] = x;

        for (genvar i = 0; i < DEPTH; i++) begin : g_stage
            dff_reg #(.W(W)) u_reg (.clk, .d(stage[i]), .q(stage[i+1]));
        end

        assign y = stage[DEPTH];
    end
endmodule
