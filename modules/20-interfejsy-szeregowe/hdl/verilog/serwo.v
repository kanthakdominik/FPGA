// Sterownik serwomechanizmu modelarskiego (20.04): impuls co 20 ms (50 Hz), szerokość 1,000 … 2,000 ms
// proporcjonalna do pozycji 0 … 255 (środek 1,5 ms). Pozycja pobierana na początku okresu.
// Podstawa czasu: takt 1 µs z dzielnika CLK_HZ / 1 MHz.
`default_nettype none

module serwo #(
    parameter CLK_HZ = 50_000_000
) (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] pozycja,
    output reg        impuls = 1'b0
);
    localparam DZ = CLK_HZ / 1_000_000;          // takty na mikrosekundę
    localparam CW = (DZ > 1) ? $clog2(DZ) : 1;
    /* verilator lint_off WIDTHTRUNC */
    localparam [CW-1:0] DZ_1 = DZ - 1;
    /* verilator lint_on WIDTHTRUNC */

    reg [CW-1:0] dz = {CW{1'b0}};
    reg [14:0]   us = 15'd0;                     // 0 … 19 999 µs
    reg [10:0]   szer = 11'd1500;                // szerokość impulsu w µs

    wire tick_us = (dz == DZ_1);
    // 1000 + pozycja·1000/255 ≈ 1000 + (pozycja·1004) >> 8  (błąd < 1 µs)
    /* verilator lint_off UNUSEDSIGNAL */
    wire [17:0] iloczyn = {10'd0, pozycja} * 18'd1004;
    /* verilator lint_on UNUSEDSIGNAL */

    always @(posedge clk) begin
        if (rst) begin
            dz     <= {CW{1'b0}};
            us     <= 15'd0;
            impuls <= 1'b0;
        end else begin
            dz <= tick_us ? {CW{1'b0}} : dz + 1'b1;
            if (tick_us) begin
                if (us == 15'd19_999) begin
                    us   <= 15'd0;
                    szer <= 11'd1000 + {1'b0, iloczyn[17:8]};
                end else
                    us <= us + 1'b1;
            end
            impuls <= (us < {4'd0, szer});
        end
    end
endmodule

`default_nettype wire
