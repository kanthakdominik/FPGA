// Moduł nadrzędny DECA — Verilog. Przejścia między domenami (moduł 15): dwa zegary bez wspólnej fazy —
// clk50 (MAX10_CLK1_50, 50 MHz) i clk10 (ADC_CLK_10, 10 MHz), w SDC jako grupy asynchroniczne.
//   domena clk50 (producent): licznik zapisywany do async_fifo, gdy nie jest pełna; przycisk KEY[1]
//     (synchronizator + wykrycie zbocza) -> sync_pulse; przełączniki SW -> cdc_handshake przy każdej zmianie;
//   domena clk10 (konsument): odczyt z FIFO w każdym takcie i sprawdzenie ciągłości licznika;
//   reset: rst_sekwencer — KEY[0] ustawia reset w obu domenach, zdejmowany najpierw w clk50, potem w clk10.
// Diody (0 = świeci): LED[3:0] — liczba naciśnięć KEY[1] odebranych w clk10, LED[5:4] — SW przesłane
// handshake'iem, LED[6] — miga ok. 1 Hz (clk10 pracuje), LED[7] — błąd ciągłości danych z FIFO (trwały).
`default_nettype none

module deca_top (
    input  wire       MAX10_CLK1_50,
    input  wire       ADC_CLK_10,
    input  wire [1:0] KEY,                     // 0 = wciśnięty
    input  wire [1:0] SW,                      // 0 = w dół
    output reg  [7:0] LED = 8'hFF              // 0 = świeci
);
    wire clk50 = MAX10_CLK1_50;
    wire clk10 = ADC_CLK_10;

    // ---- reset w kolejności: producent (clk50), potem konsument (clk10) ----
    wire rst50, rst10;
    rst_sekwencer u_rst (.arst_n(KEY[0]), .clk_a(clk50), .rst_a(rst50), .clk_b(clk10), .rst_b(rst10));

    // ---- domena clk50 ----
    // sygnały niezależne — każdy własnym synchronizatorem (szyny jednej wartości: Gray albo handshake);
    // bez logiki przed synchronizatorem — odwrócenie poziomu KEY dopiero po synchronizacji
    wire       key1_raw;
    wire [1:0] sw_s;
    sync_bit u_key  (.clk(clk50), .d(KEY[1]), .q(key1_raw));
    sync_bit u_sw0  (.clk(clk50), .d(SW[0]),  .q(sw_s[0]));
    sync_bit u_sw1  (.clk(clk50), .d(SW[1]),  .q(sw_s[1]));
    wire       key1 = ~key1_raw;

    reg  key1_d = 1'b0;
    reg  [1:0] sw_wyslane = 2'b00;
    reg  [7:0] prod = 8'd0;
    wire       full, p_busy, h_ready;
    always @(posedge clk50) begin
        key1_d <= key1;
        if (rst50) begin
            prod       <= 8'd0;
            sw_wyslane <= 2'b00;
        end else begin
            if (!full) prod <= prod + 8'd1;
            if (h_ready && sw_s != sw_wyslane) sw_wyslane <= sw_s;
        end
    end
    wire key_nacisk = key1 && !key1_d;     // zbocze naciśnięcia (bez filtra drgań — liczy też drgania)
    wire wyslij_sw  = h_ready && (sw_s != sw_wyslane);

    // ---- przejścia ----
    wire [7:0] dane;
    wire       empty, key_b, sw_valid;
    wire [1:0] sw_b;
    async_fifo #(.W(8), .AW(4)) u_fifo (
        .wr_clk(clk50), .wr_rst(rst50), .wr_en(!full), .wr_data(prod), .wr_full(full),
        .rd_clk(clk10), .rd_rst(rst10), .rd_en(1'b1), .rd_data(dane), .rd_empty(empty)
    );
    sync_pulse u_puls (.clk_src(clk50), .rst_src(rst50), .src_pulse(key_nacisk), .busy(p_busy),
                       .clk_dst(clk10), .rst_dst(rst10), .dst_pulse(key_b));
    cdc_handshake #(.W(2)) u_hs (.clk_src(clk50), .rst_src(rst50), .send(wyslij_sw), .src_data(sw_s),
                                 .ready(h_ready), .clk_dst(clk10), .rst_dst(rst10), .dst_valid(sw_valid),
                                 .dst_data(sw_b));

    // ---- domena clk10 ----
    reg [7:0]  oczek = 8'd0;
    reg        pierwszy = 1'b1, blad = 1'b0;
    reg [3:0]  n_key = 4'd0;
    reg [1:0]  sw_pokaz = 2'b00;
    reg [22:0] mig = 23'd0;
    always @(posedge clk10) begin
        mig <= mig + 23'd1;
        if (rst10) begin
            pierwszy <= 1'b1;
            blad     <= 1'b0;
            n_key    <= 4'd0;
            sw_pokaz <= 2'b00;
        end else begin
            if (!empty) begin
                if (!pierwszy && dane != oczek) blad <= 1'b1;
                oczek    <= dane + 8'd1;
                pierwszy <= 1'b0;
            end
            if (key_b) n_key <= n_key + 4'd1;
            if (sw_valid) sw_pokaz <= sw_b;
        end
        LED <= ~{blad, mig[22], sw_pokaz, n_key};
    end
endmodule

`default_nettype wire
