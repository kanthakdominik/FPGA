// Odczyt czujnika temperatury LM71 (20.05): interfejs 3-przewodowy (SC, SI/O, CS) zgodny z SPI w trybie 0 —
// czujnik wystawia bit po zboczu opadającym SC, sterownik próbkuje na narastającym. Odczyt 16 bitów:
// 14-bitowa temperatura w kodzie U2 (bity 15:2, 0,03125 °C/LSB) i dwa bity stanu (11).
// Linia SI/O jest tu tylko wejściem (sterownik nie wysyła rozkazów do czujnika). Odczyty co OKRES taktów —
// odstęp musi być dłuższy niż czas przetwarzania czujnika.
`default_nettype none

module temp_lm71 #(
    parameter DIV   = 25,                            // SC = 1 MHz przy 50 MHz
    parameter OKRES = 25_000_000                     // 0,5 s
) (
    input  wire        clk,
    input  wire        rst,
    output wire        sc,
    input  wire        sio,
    output wire        cs_n,
    output reg  [13:0] temp = 14'd0,                 // 0,03125 °C/LSB
    output wire [8:0]  temp_c,                       // całe stopnie (U2, zaokrąglenie w dół)
    output reg         nowe = 1'b0
);
    reg         start = 1'b0;
    /* verilator lint_off UNUSEDSIGNAL */
    wire [15:0] rx;                                   // rx[1:0] — bity stanu czujnika (nieużywane)
    /* verilator lint_on UNUSEDSIGNAL */
    wire        zajety, gotowe;
    /* verilator lint_off PINCONNECTEMPTY */
    spi_master #(.N(16), .DIV(DIV)) u_spi (.clk(clk), .rst(rst), .cpol(1'b0), .cpha(1'b0), .start(start),
        .dalej(1'b0), .tx_dane(16'h0000), .rx_dane(rx), .zajety(zajety), .gotowe(gotowe), .sclk(sc), .mosi(),
        .miso(sio), .cs_n(cs_n));
    /* verilator lint_on PINCONNECTEMPTY */

    reg [31:0] licz = 32'd0;
    always @(posedge clk) begin
        start <= 1'b0;
        nowe  <= 1'b0;
        if (rst)
            licz <= 32'd0;
        else if (licz >= OKRES) begin
            if (!zajety) begin
                licz  <= 32'd0;
                start <= 1'b1;
            end
        end else
            licz <= licz + 1'b1;
        if (gotowe) begin
            temp <= rx[15:2];
            nowe <= 1'b1;
        end
    end

    assign temp_c = temp[13:5];                       // /32
endmodule

`default_nettype wire
