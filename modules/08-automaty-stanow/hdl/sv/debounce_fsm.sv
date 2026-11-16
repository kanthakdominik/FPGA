// Eliminacja drgań styków jako automat: synchronizator 2 przerzutników, cztery stany i licznik.
// Nowy poziom jest przyjmowany, gdy wejście po synchronizacji ma go przez N + 1 kolejnych taktów.
// rise / fall — impulsy 1-taktowe przy zmianie poziomu po filtracji; raw — wejście po synchronizacji (bez filtra).
module debounce_fsm #(
    parameter int N = 8                        // takty stabilności, co najmniej 2 (10 ms przy 50 MHz: 500 000)
) (
    input  logic clk,
    input  logic rst,
    input  logic btn,                          // wejście asynchroniczne, 1 = wciśnięty
    output logic raw,
    output logic level,
    output logic rise = 1'b0,
    output logic fall = 1'b0
);
    localparam int CW = $clog2(N);
    localparam logic [CW-1:0] LAST = CW'(N - 1);

    typedef enum logic [1:0] {ST_LOW, ST_WAIT_HIGH, ST_HIGH, ST_WAIT_LOW} state_t;

    logic          s1 = 1'b0, s2 = 1'b0;       // synchronizator
    state_t        state = ST_LOW;
    logic [CW-1:0] cnt = '0;

    always_ff @(posedge clk) begin
        s1 <= btn;
        s2 <= s1;
    end

    always_ff @(posedge clk) begin
        rise <= 1'b0;
        fall <= 1'b0;
        if (rst) begin
            state <= ST_LOW;
            cnt   <= '0;
        end else begin
            unique case (state)
                ST_LOW:
                    if (s2) begin state <= ST_WAIT_HIGH; cnt <= '0; end
                ST_WAIT_HIGH:
                    if (!s2)              state <= ST_LOW;         // drganie — powrót
                    else if (cnt == LAST) begin state <= ST_HIGH; rise <= 1'b1; end
                    else                  cnt <= cnt + CW'(1);
                ST_HIGH:
                    if (!s2) begin state <= ST_WAIT_LOW; cnt <= '0; end
                ST_WAIT_LOW:
                    if (s2)               state <= ST_HIGH;
                    else if (cnt == LAST) begin state <= ST_LOW; fall <= 1'b1; end
                    else                  cnt <= cnt + CW'(1);
            endcase
        end
    end

    assign raw   = s2;
    assign level = (state == ST_HIGH) || (state == ST_WAIT_LOW);
endmodule
