// Master I2S (25.01): z zegara clk (np. MCLK = 12,5 MHz) wytwarza BCLK = clk/4 i WCLK = clk/256 (64 bity na ramkę,
// 32 na kanał; fs = clk/256 = 48,83 kHz przy 12,5 MHz). Format I2S: WCLK = 0 — kanał lewy, 1 — prawy; najstarszy bit
// próbki jeden takt BCLK po zmianie WCLK. Nadawanie (dout) zmienia się przy opadającym BCLK, odbiór (din) próbkowany
// po narastającym. Próbki 24-bitowe ze znakiem, wyrównane do lewej w 32-bitowym slocie.
// Impuls ramka: przyjęto tx_l/tx_p do wysłania w tej ramce i podano rx_l/rx_p odebrane w poprzedniej.
`default_nettype none

module i2s_master (
    input  logic        clk,
    input  logic        rst,
    input  logic [23:0] tx_l,
    input  logic [23:0] tx_p,
    output logic  [23:0] rx_l,
    output logic  [23:0] rx_p,
    output logic         ramka,
    output logic         bclk,
    output logic         wclk,
    output logic         dout,
    input  logic        din
);
    logic  [7:0]  cnt;                            // pozycja w ramce: n = cnt[7:2] (takt BCLK), faza = cnt[1:0]
    logic  [63:0] wy;                             // ramka nadawana: {L, 8'b0, P, 8'b0}
    /* verilator lint_off UNUSEDSIGNAL */       // we[39:32], we[7:0] — bity uzupełnienia slotów
    logic  [63:0] we;                             // bity odebrane
    /* verilator lint_on UNUSEDSIGNAL */
    logic [5:0]  n;
    assign n = cnt[7:2];

    always_ff @(posedge clk) begin
        if (rst) begin
            cnt <= 8'd0; wy <= 64'd0; we <= 64'd0;
            rx_l <= 24'd0; rx_p <= 24'd0; ramka <= 1'b0;
            bclk <= 1'b0; wclk <= 1'b0; dout <= 1'b0;
        end else begin
            cnt   <= cnt + 1'b1;
            ramka <= 1'b0;
            if (cnt == 8'd255) begin                // początek następnej ramki: nowe próbki
                wy    <= {tx_l, 8'd0, tx_p, 8'd0};
                rx_l  <= we[63:40];
                rx_p  <= we[31:8];
                ramka <= 1'b1;
            end
            // wyjścia dla pozycji cnt (rejestrowane razem)
            bclk <= cnt[1];
            wclk <= cnt[7];
            // bit nadawany w takcie n to bit n-1 ramki (opóźnienie I2S o jeden takt BCLK)
            if (cnt[1:0] == 2'd0)
                dout <= (n == 6'd0) ? 1'b0 : wy[6'd63 - (n - 6'd1)];
            // odbiór: po narastającym BCLK (faza 3); bit n-1 ramki
            if (cnt[1:0] == 2'd3 && n != 6'd0)
                we[6'd63 - (n - 6'd1)] <= din;
        end
    end
endmodule

`default_nettype wire
