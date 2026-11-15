// Migająca dioda: dzielnik częstotliwości z licznikiem.
// Wyjście led zmienia stan co CLK_HZ / (2 * BLINK_HZ) taktów zegara.
module blink #(
    parameter int unsigned CLK_HZ   = 50_000_000,  // częstotliwość zegara wejściowego
    parameter int unsigned BLINK_HZ = 1            // częstotliwość migania diody
) (
    input  logic clk,
    input  logic rst,                              // reset synchroniczny, aktywny wysoki
    output logic led
);
    localparam int unsigned HALF = CLK_HZ / (2 * BLINK_HZ);  // takty na pół okresu
    localparam int unsigned W    = (HALF > 1) ? $clog2(HALF) : 1;

    logic [W-1:0] cnt_q;

    always_ff @(posedge clk) begin
        if (rst) begin
            cnt_q <= '0;
            led   <= 1'b0;
        end else if (cnt_q == W'(HALF - 1)) begin
            cnt_q <= '0;
            led   <= ~led;
        end else begin
            cnt_q <= cnt_q + 1'b1;
        end
    end
endmodule
