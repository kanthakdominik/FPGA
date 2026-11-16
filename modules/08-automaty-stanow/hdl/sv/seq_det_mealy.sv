// Detektor sekwencji 1011 (z nakładaniem) — automat Mealy'ego, styl dwuprocesowy z typem wyliczeniowym.
// y = 1 w tym samym takcie, w którym na wejściu jest ostatni bit wzorca.
module seq_det_mealy (
    input  logic clk,
    input  logic rst,
    input  logic x,
    output logic y
);
    typedef enum logic [1:0] {S0, S1, S10, S101} state_t;

    state_t state = S0, state_next;

    always_ff @(posedge clk)
        if (rst) state <= S0;
        else     state <= state_next;

    always_comb begin
        y = 1'b0;
        unique case (state)
            S0:   state_next = x ? S1 : S0;
            S1:   state_next = x ? S1 : S10;
            S10:  state_next = x ? S101 : S0;
            S101: begin
                y          = x;                     // wzorzec kończy się bieżącym bitem
                state_next = x ? S1 : S10;
            end
        endcase
    end
endmodule
