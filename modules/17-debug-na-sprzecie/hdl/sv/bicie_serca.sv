// "Bicie serca" (17.01): wyjście zmienia stan co POLOKRES taktów — pierwszy test każdego projektu
// na płytce (zegar, konfiguracja, reset, pin diody).
module bicie_serca #(
    parameter int POLOKRES = 25_000_000
) (
    input  logic clk,
    input  logic rst,
    output logic led = 1'b0
);
    localparam int CW = $clog2(POLOKRES);
    logic [CW-1:0] cnt = '0;
    always_ff @(posedge clk)
        if (rst) begin
            cnt <= '0;
            led <= 1'b0;
        end else if (cnt == CW'(POLOKRES - 1)) begin
            cnt <= '0;
            led <= ~led;
        end else begin
            cnt <= cnt + 1'b1;
        end
endmodule
