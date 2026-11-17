// "Bicie serca" (17.01): wyjście zmienia stan co POLOKRES taktów — dioda migająca z częstotliwością
// f_clk / (2 · POLOKRES). Pierwszy test każdego projektu na płytce: zegar działa, konfiguracja się
// załadowała, reset został zwolniony, pin diody jest dobrze przypisany.
`default_nettype none

module bicie_serca #(
    parameter POLOKRES = 25000000        // 50 MHz -> 1 Hz
) (
    input  wire clk,
    input  wire rst,
    output reg  led = 1'b0
);
    localparam CW = $clog2(POLOKRES);
    reg [CW-1:0] cnt = {CW{1'b0}};
    always @(posedge clk)
        if (rst) begin
            cnt <= {CW{1'b0}};
            led <= 1'b0;
        end else if (cnt == POLOKRES - 1) begin
            cnt <= {CW{1'b0}};
            led <= ~led;
        end else begin
            cnt <= cnt + 1'b1;
        end
endmodule

`default_nettype wire
