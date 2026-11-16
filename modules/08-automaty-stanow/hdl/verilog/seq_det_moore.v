// Detektor sekwencji 1011 (z nakładaniem) — automat Moore'a, styl dwuprocesowy:
// rejestr stanu + blok kombinacyjny (następny stan i wyjście). y = 1 w takcie PO ostatnim bicie wzorca.
`default_nettype none

module seq_det_moore (
    input  wire clk,
    input  wire rst,
    input  wire x,
    output reg  y
);
    // nazwa stanu = dotychczas dopasowany początek wzorca
    localparam [2:0] S0 = 3'd0, S1 = 3'd1, S10 = 3'd2, S101 = 3'd3, S1011 = 3'd4;

    reg [2:0] state = S0, state_next;

    always @(posedge clk)
        if (rst) state <= S0;
        else     state <= state_next;

    always @* begin
        state_next = state;
        y          = 1'b0;
        case (state)
            S0:      state_next = x ? S1    : S0;
            S1:      state_next = x ? S1    : S10;
            S10:     state_next = x ? S101  : S0;
            S101:    state_next = x ? S1011 : S10;
            S1011: begin
                y          = 1'b1;                  // wyjście zależy tylko od stanu
                state_next = x ? S1 : S10;          // nakładanie: końcówka „1” albo „10”
            end
            default: state_next = S0;
        endcase
    end
endmodule

`default_nettype wire
