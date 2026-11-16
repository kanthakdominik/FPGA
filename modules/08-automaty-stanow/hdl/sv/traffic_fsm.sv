// Sygnalizacja świetlna skrzyżowania: 6 stanów, czasy w impulsach tick, wybór kodowania stanów parametrem.
// Stany (indeks): 0 NS_G, 1 NS_Y, 2 R1 (wszystkie czerwone), 3 EW_G, 4 EW_Y, 5 R2 (wszystkie czerwone).
// Bezpieczny automat: stan nielegalny -> err = 1, wszystkie światła czerwone, następny stan R2 (jak po resecie).
// Wejście upset (XOR do rejestru stanu) symuluje przekłamanie bitu (SEU) w testach; w układzie podłącz 0.
module traffic_fsm #(
    parameter int ENC = 0,                     // 0 — binarne, 1 — one-hot, 2 — Graya
    localparam int SW = (ENC == 1) ? 6 : 3
) (
    input  logic          clk,
    input  logic          rst,
    input  logic          tick,
    input  logic [SW-1:0] upset,
    output logic [2:0]    ns,                  // {czerwone, żółte, zielone}, 1 = świeci
    output logic [2:0]    ew,
    output logic          err
);
    function automatic logic [SW-1:0] code(int i);
        case (ENC)
            1:       return SW'(1 << i);       // one-hot
            2:       return SW'(i ^ (i >> 1)); // Graya
            default: return SW'(i);            // binarne
        endcase
    endfunction

    localparam logic [SW-1:0] NS_G = code(0), NS_Y = code(1), R1 = code(2),
                              EW_G = code(3), EW_Y = code(4), R2 = code(5);

    (* fsm_encoding = "none" *) logic [SW-1:0] state = R2;
    logic [SW-1:0] state_next;
    logic [1:0]    timer = '0, timer_next, last;
    logic          legal;

    always_comb begin
        ns    = 3'b100;
        ew    = 3'b100;
        last  = 2'd0;
        legal = 1'b1;
        case (state)
            NS_G:    begin ns = 3'b001; last = 2'd3; end
            NS_Y:    begin ns = 3'b010; last = 2'd1; end
            R1:      ;
            EW_G:    begin ew = 3'b001; last = 2'd3; end
            EW_Y:    begin ew = 3'b010; last = 2'd1; end
            R2:      ;
            default: legal = 1'b0;             // stan nielegalny: wszystko czerwone
        endcase
        err = ~legal;

        state_next = state;
        timer_next = timer;
        if (!legal) begin
            state_next = R2;                   // odzyskanie: stan bezpieczny
            timer_next = '0;
        end else if (tick) begin
            if (timer == last) begin
                timer_next = '0;
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

    always_ff @(posedge clk)
        if (rst) begin
            state <= R2;
            timer <= '0;
        end else begin
            state <= state_next ^ upset;
            timer <= timer_next;
        end
endmodule
