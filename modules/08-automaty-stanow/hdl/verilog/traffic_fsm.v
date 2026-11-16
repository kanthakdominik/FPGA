// Sygnalizacja świetlna skrzyżowania: 6 stanów, czasy w impulsach tick, wybór kodowania stanów parametrem.
// Stany (indeks): 0 NS_G, 1 NS_Y, 2 R1 (wszystkie czerwone), 3 EW_G, 4 EW_Y, 5 R2 (wszystkie czerwone).
// Bezpieczny automat: stan nielegalny -> err = 1, wszystkie światła czerwone, następny stan R2 (jak po resecie).
// Wejście upset (XOR do rejestru stanu) symuluje przekłamanie bitu (SEU) w testach; w układzie podłącz 0.
// yosys-warianty: ENC=1; ENC=2
// (synteza w CI: domyślne ENC = 0 i dwa warianty z tej linii)
`default_nettype none

module traffic_fsm #(
    parameter ENC = 0                          // 0 — binarne, 1 — one-hot, 2 — Graya
) (
    input  wire                              clk,
    input  wire                              rst,
    input  wire                              tick,
    input  wire [((ENC == 1) ? 6 : 3) - 1:0] upset,
    output reg  [2:0]                        light_ns,     // {czerwone, żółte, zielone}, 1 = świeci
    output reg  [2:0]                        light_ew,
    output reg                               err
);
    localparam SW = (ENC == 1) ? 6 : 3;

    // kod stanu o indeksie i w wybranym kodowaniu; v ma 32 bity, używane są tylko najmłodsze SW
    /* verilator lint_off UNUSEDSIGNAL */
    function [SW-1:0] code;
        input integer i;
        integer v;
        begin
            if (ENC == 1)      v = 1 << i;        // one-hot
            else if (ENC == 2) v = i ^ (i >> 1);  // Graya
            else               v = i;             // binarne
            code = v[SW-1:0];
        end
    endfunction
    /* verilator lint_on UNUSEDSIGNAL */

    localparam [SW-1:0] NS_G = code(0), NS_Y = code(1), R1 = code(2),
                        EW_G = code(3), EW_Y = code(4), R2 = code(5);

    // fsm_encoding = "none": Yosys nie przekodowuje automatu — widać koszt wybranego kodowania
    (* fsm_encoding = "none" *) reg [SW-1:0] state = R2;
    reg [SW-1:0] state_next;
    reg [1:0]    timer = 2'd0, timer_next;    // takty tick w bieżącym stanie
    reg [1:0]    last;                         // czas trwania stanu - 1
    reg          legal;

    always @* begin
        light_ns    = 3'b100;
        light_ew    = 3'b100;
        last  = 2'd0;
        legal = 1'b1;
        case (state)
            NS_G:    begin light_ns = 3'b001; last = 2'd3; end
            NS_Y:    begin light_ns = 3'b010; last = 2'd1; end
            R1:      ;
            EW_G:    begin light_ew = 3'b001; last = 2'd3; end
            EW_Y:    begin light_ew = 3'b010; last = 2'd1; end
            R2:      ;
            default: legal = 1'b0;             // stan nielegalny: wszystko czerwone
        endcase
        err = ~legal;

        state_next = state;
        timer_next = timer;
        if (!legal) begin
            state_next = R2;                   // odzyskanie: stan bezpieczny
            timer_next = 2'd0;
        end else if (tick) begin
            if (timer >= last) begin           // >= zamiast ==: odporne na timer > last po przekłamaniu
                timer_next = 2'd0;
                case (state)
                    NS_G:    state_next = NS_Y;
                    NS_Y:    state_next = R1;
                    R1:      state_next = EW_G;
                    EW_G:    state_next = EW_Y;
                    EW_Y:    state_next = R2;
                    default: state_next = NS_G;    // R2
                endcase
            end else begin
                timer_next = timer + 2'd1;
            end
        end
    end

    always @(posedge clk)
        if (rst) begin
            state <= R2;
            timer <= 2'd0;
        end else begin
            state <= state_next ^ upset;
            timer <= timer_next;
        end
endmodule

`default_nettype wire
