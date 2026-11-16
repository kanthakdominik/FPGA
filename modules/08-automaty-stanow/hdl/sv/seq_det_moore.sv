// Detektor sekwencji 1011 (z nakładaniem) — automat Moore'a, styl dwuprocesowy z typem wyliczeniowym.
// y = 1 w takcie PO ostatnim bicie wzorca.
module seq_det_moore (
    input  logic clk,
    input  logic rst,
    input  logic x,
    output logic y
);
    typedef enum logic [2:0] {S0, S1, S10, S101, S1011} state_t;   // kodowanie wybiera syntezator

    state_t state = S0, state_next;

    always_ff @(posedge clk)
        if (rst) state <= S0;
        else     state <= state_next;

    always_comb begin
        state_next = state;
        y          = 1'b0;
        unique case (state)
            S0:    state_next = x ? S1    : S0;
            S1:    state_next = x ? S1    : S10;
            S10:   state_next = x ? S101  : S0;
            S101:  state_next = x ? S1011 : S10;
            S1011: begin
                y          = 1'b1;                  // wyjście zależy tylko od stanu
                state_next = x ? S1 : S10;          // nakładanie: końcówka „1” albo „10”
            end
            default: state_next = S0;
        endcase
    end
endmodule
