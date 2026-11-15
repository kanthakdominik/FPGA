// Migająca dioda: dzielnik częstotliwości z licznikiem.
// Wyjście led zmienia stan co CLK_HZ / (2 * BLINK_HZ) taktów zegara.
`default_nettype none

module blink #(
    parameter integer CLK_HZ   = 50_000_000,  // częstotliwość zegara wejściowego
    parameter integer BLINK_HZ = 1            // częstotliwość migania diody
) (
    input  wire clk,
    input  wire rst,                          // reset synchroniczny, aktywny wysoki
    output wire led
);
    localparam integer HALF = CLK_HZ / (2 * BLINK_HZ);  // takty na pół okresu
    localparam integer W    = (HALF > 1) ? $clog2(HALF) : 1;

    reg [W-1:0] cnt_q;
    reg         led_q;

    always @(posedge clk) begin
        if (rst) begin
            cnt_q <= {W{1'b0}};
            led_q <= 1'b0;
        end else if (cnt_q == HALF - 1) begin
            cnt_q <= {W{1'b0}};
            led_q <= ~led_q;
        end else begin
            cnt_q <= cnt_q + 1'b1;
        end
    end

    assign led = led_q;
endmodule

`default_nettype wire
