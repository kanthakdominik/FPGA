// Moduł nadrzędny DECA — SystemVerilog. Automaty z modułu 08 na płytce:
//   KEY[0]  — reset (ustawienie asynchroniczne, zdjęcie synchroniczne),
//   KEY[1]  — przycisk przez debounce_fsm (10 ms),
//   SW[0]   — 0: procesor tiny_cpu wykonuje 4 kroki na sekundę; 1: jeden krok na każde naciśnięcie KEY[1],
//   SW[1]   — 0: LED[7:0] = ostatnia wartość OUT procesora (ciąg Fibonacciego modulo 256, dwójkowo);
//             1: LED[7:4] = liczba zboczy KEY[1] bez filtra, LED[3:0] = liczba naciśnięć po filtracji.
module deca_top (
    input  logic       MAX10_CLK1_50,
    input  logic [1:0] KEY,                    // 0 = wciśnięty
    input  logic [1:0] SW,                     // 0 = w dół
    output logic [7:0] LED = '1                // 0 = świeci
);
    logic clk;
    assign clk = MAX10_CLK1_50;

    // reset z KEY[0] — synchronizator resetu (07.02)
    logic [1:0] rst_sync = '0;
    logic       rst;
    always_ff @(posedge clk or negedge KEY[0])
        if (!KEY[0]) rst_sync <= '0;
        else         rst_sync <= {rst_sync[0], 1'b1};
    assign rst = ~rst_sync[1];

    // przełączniki — dwa przerzutniki synchronizujące
    logic [1:0] sw_meta, sw;
    always_ff @(posedge clk) begin
        sw_meta <= SW;
        sw      <= sw_meta;
    end

    // KEY[1]: synchronizacja i filtr drgań w debounce_fsm
    logic key_raw, key_level, key_rise, key_fall;
    debounce_fsm #(.N(500_000)) u_key (.clk, .rst, .btn(~KEY[1]), .raw(key_raw), .level(key_level),
                                       .rise(key_rise), .fall(key_fall));

    // impuls 4 Hz do pracy ciągłej (07.04)
    logic [23:0] div = '0;
    logic        tick4 = 1'b0;
    always_ff @(posedge clk) begin
        tick4 <= (div == 24'd12_499_999);
        div   <= (div == 24'd12_499_999) ? '0 : div + 24'd1;
    end

    // procesor sekwencyjny z programem domyślnym (ciąg Fibonacciego)
    logic       step, out_valid, halted;
    logic [7:0] fib;
    logic [3:0] pc;
    assign step = sw[0] ? key_rise : tick4;
    tiny_cpu u_cpu (.clk, .rst, .step, .out_data(fib), .out_valid, .halted, .pc_o(pc));

    // liczniki: zbocza wejścia bez filtra (widać drgania) i naciśnięcia po filtracji
    logic       key_raw_d = 1'b0;
    logic [3:0] raw_cnt = '0, deb_cnt = '0;
    always_ff @(posedge clk) begin
        key_raw_d <= key_raw;
        if (rst) begin
            raw_cnt <= '0;
            deb_cnt <= '0;
        end else begin
            if (key_raw && !key_raw_d) raw_cnt <= raw_cnt + 4'd1;
            if (key_rise)              deb_cnt <= deb_cnt + 4'd1;
        end
    end

    always_ff @(posedge clk)
        LED <= ~(sw[1] ? {raw_cnt, deb_cnt} : fib);
endmodule
