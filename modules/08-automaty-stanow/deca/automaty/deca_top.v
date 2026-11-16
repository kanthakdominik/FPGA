// Moduł nadrzędny DECA — Verilog. Automaty z modułu 08 na płytce:
//   KEY[0]  — reset (ustawienie asynchroniczne, zdjęcie synchroniczne),
//   KEY[1]  — przycisk przez debounce_fsm (10 ms),
//   SW[0]   — 0: procesor tiny_cpu wykonuje 4 kroki na sekundę; 1: jeden krok na każde naciśnięcie KEY[1],
//   SW[1]   — 0: LED[7:0] = ostatnia wartość OUT procesora (ciąg Fibonacciego modulo 256, dwójkowo);
//             1: LED[7:4] = liczba zboczy KEY[1] bez filtra, LED[3:0] = liczba naciśnięć po filtracji.
`default_nettype none

module deca_top (
    input  wire       MAX10_CLK1_50,
    input  wire [1:0] KEY,                     // 0 = wciśnięty
    input  wire [1:0] SW,                      // 0 = w dół
    output reg  [7:0] LED = 8'hFF              // 0 = świeci
);
    wire clk = MAX10_CLK1_50;

    // reset z KEY[0] — synchronizator resetu (07.02)
    reg [1:0] rst_sync = 2'b00;
    always @(posedge clk or negedge KEY[0])
        if (!KEY[0]) rst_sync <= 2'b00;
        else         rst_sync <= {rst_sync[0], 1'b1};
    wire rst = ~rst_sync[1];

    // przełączniki — dwa przerzutniki synchronizujące
    reg [1:0] sw_meta, sw;
    always @(posedge clk) begin
        sw_meta <= SW;
        sw      <= sw_meta;
    end

    // KEY[1]: synchronizacja i filtr drgań w debounce_fsm
    wire key_raw, key_level, key_rise, key_fall;
    debounce_fsm #(.N(500000)) u_key (.clk(clk), .rst(rst), .btn(~KEY[1]), .raw(key_raw), .level(key_level),
                                      .rise(key_rise), .fall(key_fall));

    // impuls 4 Hz do pracy ciągłej (07.04)
    reg [23:0] div = 24'd0;
    reg        tick4 = 1'b0;
    always @(posedge clk) begin
        tick4 <= (div == 24'd12499999);
        div   <= (div == 24'd12499999) ? 24'd0 : div + 24'd1;
    end

    // procesor sekwencyjny z programem domyślnym (ciąg Fibonacciego)
    wire       step = sw[0] ? key_rise : tick4;
    wire [7:0] fib;
    wire       out_valid, halted;
    wire [3:0] pc;
    tiny_cpu u_cpu (.clk(clk), .rst(rst), .step(step), .out_data(fib), .out_valid(out_valid),
                    .halted(halted), .pc_o(pc));

    // liczniki: zbocza wejścia bez filtra (widać drgania) i naciśnięcia po filtracji
    reg       key_raw_d = 1'b0;
    reg [3:0] raw_cnt = 4'd0, deb_cnt = 4'd0;
    always @(posedge clk) begin
        key_raw_d <= key_raw;
        if (rst) begin
            raw_cnt <= 4'd0;
            deb_cnt <= 4'd0;
        end else begin
            if (key_raw && !key_raw_d) raw_cnt <= raw_cnt + 4'd1;
            if (key_rise)              deb_cnt <= deb_cnt + 4'd1;
        end
    end

    always @(posedge clk)
        LED <= ~(sw[1] ? {raw_cnt, deb_cnt} : fib);
endmodule

`default_nettype wire
