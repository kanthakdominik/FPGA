// Moduł nadrzędny DECA — SystemVerilog. "Oddychające" diody z pamięci (moduł 18):
//   domena 50 MHz: rom_sinus (blok M9K, zawartość z pliku sinus.hex) daje jasność ośmiu diod przesuniętych
//                  w fazie o 1/8 okresu; wyniki zapisywane do ram_sdp (pamięć dwuportowa) pod adresy 0..7,
//   domena 10 MHz (ADC_CLK_10, niezależny oscylator): odczyt ram_sdp i PWM 8 bitów dla każdej diody —
//                  pamięć dwuportowa z dwoma zegarami przenosi tablicę jasności między domenami.
//   KEY[0] — reset, SW[0] w górze — animacja zatrzymana, SW[1] w górze — kierunek odwrócony.
module deca_top (
    input  logic       MAX10_CLK1_50,
    input  logic       ADC_CLK_10,
    input  logic [1:0] KEY,
    input  logic [1:0] SW,
    output logic [7:0] LED                     // 0 = świeci
);
    logic clk50, clk10;
    assign clk50 = MAX10_CLK1_50;
    assign clk10 = ADC_CLK_10;

    // reset z KEY[0], zdjęcie synchroniczne w każdej domenie
    logic [1:0] rs50 = 2'b00, rs10 = 2'b00;
    logic       rst50, rst10;
    always_ff @(posedge clk50 or negedge KEY[0]) if (!KEY[0]) rs50 <= 2'b00; else rs50 <= {rs50[0], 1'b1};
    always_ff @(posedge clk10 or negedge KEY[0]) if (!KEY[0]) rs10 <= 2'b00; else rs10 <= {rs10[0], 1'b1};
    assign rst50 = ~rs50[1];
    assign rst10 = ~rs10[1];

    // przełączniki zsynchronizowane z 50 MHz
    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    logic [1:0] sw1 = 2'b00, sw2 = 2'b00;
    always_ff @(posedge clk50) begin
        sw1 <= SW;
        sw2 <= sw1;
    end

    // ---- domena 50 MHz: faza animacji, ROM sinusa, zapis tablicy jasności ----
    logic [17:0] dzielnik = '0;
    logic [7:0]  faza = '0;
    logic [2:0]  idx = '0, idx_d = '0;
    always_ff @(posedge clk50)
        if (rst50) begin
            dzielnik <= 18'd0;
            faza     <= 8'd0;
            idx      <= 3'd0;
            idx_d    <= 3'd0;
        end else begin
            dzielnik <= dzielnik + 18'd1;
            if (dzielnik == 18'h3FFFF && !sw2[0]) faza <= sw2[1] ? faza - 8'd1 : faza + 8'd1;
            idx   <= idx + 3'd1;
            idx_d <= idx;
        end

    logic [7:0] jasnosc;
    rom_sinus #(.W(8), .AW(8), .PLIK("../../hdl/dane/sinus.hex")) u_rom (
        .clk(clk50), .en(1'b1), .addr(faza + {idx, 5'd0}), .dout(jasnosc));

    logic [7:0] jas_r;
    logic [2:0] idx_r = '0, idx_r_d = '0;
    ram_sdp #(.W(8), .AW(3)) u_tab (
        .clk_w(clk50), .we(!rst50), .addr_w(idx_d), .din(jasnosc),
        .clk_r(clk10), .re(1'b1), .addr_r(idx_r), .dout(jas_r));

    // ---- domena 10 MHz: odczyt tablicy i PWM ----
    logic [7:0] tab [8];
    logic [7:0] pwm = '0;
    logic [7:0] led_n = 8'hFF;
    always_ff @(posedge clk10)
        if (rst10) begin
            idx_r   <= 3'd0;
            idx_r_d <= 3'd0;
            pwm     <= 8'd0;
            led_n   <= 8'hFF;
        end else begin
            idx_r   <= idx_r + 3'd1;
            idx_r_d <= idx_r;
            tab[idx_r_d] <= jas_r;
            if (idx_r == 3'd7) pwm <= pwm + 8'd1;
            for (int i = 0; i < 8; i++) led_n[i] <= !(pwm < tab[i]);
        end
    assign LED = led_n;
endmodule

