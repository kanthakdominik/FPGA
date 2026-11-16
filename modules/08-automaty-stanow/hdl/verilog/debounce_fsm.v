// Eliminacja drgań styków jako automat: synchronizator 2 przerzutników, cztery stany i licznik.
// Nowy poziom jest przyjmowany, gdy wejście po synchronizacji ma go przez N + 1 kolejnych taktów.
// rise / fall — impulsy 1-taktowe przy zmianie poziomu po filtracji; raw — wejście po synchronizacji (bez filtra).
`default_nettype none

module debounce_fsm #(
    parameter N = 8                            // takty stabilności, co najmniej 2 (10 ms przy 50 MHz: 500 000)
) (
    input  wire clk,
    input  wire rst,
    input  wire btn,                           // wejście asynchroniczne, 1 = wciśnięty
    output wire raw,
    output wire level,
    output reg  rise = 1'b0,
    output reg  fall = 1'b0
);
    localparam CW = $clog2(N);
    localparam [CW-1:0] LAST = N - 1;
    localparam [CW-1:0] ONE  = 1;
    localparam [1:0] ST_LOW = 2'd0, ST_WAIT_HIGH = 2'd1, ST_HIGH = 2'd2, ST_WAIT_LOW = 2'd3;

    reg          s1 = 1'b0, s2 = 1'b0;         // synchronizator
    reg [1:0]    state = ST_LOW;
    reg [CW-1:0] cnt = {CW{1'b0}};

    always @(posedge clk) begin
        s1 <= btn;
        s2 <= s1;
    end

    always @(posedge clk) begin
        rise <= 1'b0;
        fall <= 1'b0;
        if (rst) begin
            state <= ST_LOW;
            cnt   <= {CW{1'b0}};
        end else begin
            case (state)
                ST_LOW:
                    if (s2) begin state <= ST_WAIT_HIGH; cnt <= {CW{1'b0}}; end
                ST_WAIT_HIGH:
                    if (!s2)             state <= ST_LOW;          // drganie — powrót
                    else if (cnt == LAST) begin state <= ST_HIGH; rise <= 1'b1; end
                    else                 cnt <= cnt + ONE;
                ST_HIGH:
                    if (!s2) begin state <= ST_WAIT_LOW; cnt <= {CW{1'b0}}; end
                default:                                           // ST_WAIT_LOW
                    if (s2)              state <= ST_HIGH;
                    else if (cnt == LAST) begin state <= ST_LOW; fall <= 1'b1; end
                    else                 cnt <= cnt + ONE;
            endcase
        end
    end

    assign raw   = s2;
    assign level = (state == ST_HIGH) || (state == ST_WAIT_LOW);
endmodule

`default_nettype wire
