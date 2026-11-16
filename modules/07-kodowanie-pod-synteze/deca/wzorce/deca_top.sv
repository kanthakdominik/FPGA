// Moduł nadrzędny DECA — SystemVerilog. Wzorce RTL z modułu 07 na jednej płytce:
//   KEY[0]   — reset przez synchronizator resetu (reset_sync),
//   KEY[1]   — wciśnięty: pauza stopera,
//   SW[1:0]  — wzmocnienie jasności 32, 64, 128 albo 255 (mnożenie przez stałą z tablicy),
//   LED[3:0] — „oddychająca” fala: jasność z tablicy sinusa (sine_rom), przemnożona przez wzmocnienie
//              i opóźniona liniami opóźniającymi (delay_line) o 0,16 s na każdą kolejną diodę,
//   LED[7:4] — sekundy stopera 0–9 w kodzie dwójkowym (bcd_counter z zezwoleniem 100 Hz z tick_gen).
// Jeden zegar 50 MHz w całym projekcie; wolne zdarzenia wyznaczają impulsy zezwolenia, nie dzielone zegary.
module deca_top (
    input  logic       MAX10_CLK1_50,
    input  logic [1:0] KEY,                    // 0 = wciśnięty
    input  logic [1:0] SW,                     // 0 = w dół
    output logic [7:0] LED = '1                // 0 = świeci
);
    logic clk, rst, tick;
    assign clk = MAX10_CLK1_50;

    reset_sync #(.STAGES(2)) u_rst (.clk, .arst_n(KEY[0]), .rst);

    // KEY[1] i SW zmieniają się niezależnie od zegara — dwa przerzutniki synchronizujące (moduł 15)
    logic [2:0] in_meta, in_sync;
    always_ff @(posedge clk) begin
        in_meta <= {KEY[1], SW};
        in_sync <= in_meta;
    end

    tick_gen #(.DIV(500_000)) u_tick (.clk, .rst, .tick);            // 50 MHz / 500 000 = 100 Hz

    // stoper 0,00–9,99 s; bcd[2] to cyfra sekund
    logic [2:0][3:0] bcd;
    logic            carry;
    bcd_counter #(.DIGITS(3)) u_bcd (.clk, .rst, .en(tick & in_sync[2]), .bcd, .carry);

    // faza 0..127 co 10 ms: pierwsza połowa — rosnąca ćwiartka sinusa, druga — ta sama ćwiartka wstecz
    logic [6:0] phase;
    always_ff @(posedge clk)
        if (rst)       phase <= '0;
        else if (tick) phase <= phase + 7'd1;

    logic [5:0] addr;
    logic [7:0] sine;
    assign addr = phase[6] ? ~phase[5:0] : phase[5:0];
    sine_rom u_rom (.clk, .addr, .data(sine));

    // wzmocnienie: mnożenie 8 x 8 bitów (w MAX 10 — blok mnożarki 9 x 9)
    logic [7:0]  gain;
    logic [15:0] prod;
    always_comb
        unique case (in_sync[1:0])
            2'd0: gain = 8'd32;
            2'd1: gain = 8'd64;
            2'd2: gain = 8'd128;
            2'd3: gain = 8'd255;
        endcase
    always_ff @(posedge clk)
        prod <= sine * gain;

    // fala: każda kolejna dioda dostaje jasność sprzed 16 impulsów (0,16 s)
    logic [7:0] lvl0, lvl1, lvl2, lvl3;
    assign lvl0 = prod[15:8];
    delay_line #(.W(8), .DEPTH(16)) u_dl1 (.clk, .ce(tick), .din(lvl0), .dout(lvl1));
    delay_line #(.W(8), .DEPTH(16)) u_dl2 (.clk, .ce(tick), .din(lvl1), .dout(lvl2));
    delay_line #(.W(8), .DEPTH(16)) u_dl3 (.clk, .ce(tick), .din(lvl2), .dout(lvl3));

    // PWM 8-bitowy (ok. 195 kHz) i rejestr na wyjściach — bez szpilek na diodach
    logic [7:0] pwm_cnt = '0;
    always_ff @(posedge clk) begin
        pwm_cnt <= pwm_cnt + 8'd1;
        LED     <= ~{bcd[2], lvl3 > pwm_cnt, lvl2 > pwm_cnt, lvl1 > pwm_cnt, lvl0 > pwm_cnt};
    end
endmodule
