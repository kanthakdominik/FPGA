// Detektor sekwencji 1011 (z nakładaniem) — automat Mealy'ego, styl dwuprocesowy.
// y = 1 w tym samym takcie, w którym na wejściu jest ostatni bit wzorca (wyjście zależy od stanu i wejścia).
`default_nettype none

module seq_det_mealy (
    input  wire clk,
    input  wire rst,
    input  wire x,
    output reg  y
);
    localparam [1:0] S0 = 2'd0, S1 = 2'd1, S10 = 2'd2, S101 = 2'd3;

    reg [1:0] state = S0, state_next;

    always @(posedge clk)
        if (rst) state <= S0;
        else     state <= state_next;

    always @* begin
        y = 1'b0;
        case (state)
            S0:      state_next = x ? S1 : S0;
            S1:      state_next = x ? S1 : S10;
            S10:     state_next = x ? S101 : S0;
            default: begin                          // S101
                y          = x;                     // wzorzec kończy się bieżącym bitem
                state_next = x ? S1 : S10;
            end
        endcase
    end
endmodule

`default_nettype wire
