// Samosynchronizujący się kontroler PRBS7 (22.02, 22.03): każdy bit porównywany z przewidywaniem z 7 bitów
// poprzednich (x^7 + x^6 + 1); po 7 bitach od startu kontroler jest zsynchronizowany niezależnie od fazy.
// Jeden przekłamany bit daje 3 błędy (w nim i w dwóch przewidywaniach, które go używają).
`default_nettype none

module prbs7_spr #(
    parameter integer N = 2
) (
    input  wire         clk,
    input  wire         rst,
    input  wire         en,
    input  wire [N-1:0] d,                    // bit najstarszy odebrany pierwszy
    output reg  [15:0]  bledy,
    output reg          synch                 // co najmniej 7 bitów odebranych
);
    reg [6:0] s;
    reg [6:0] t;
    reg [3:0] nb;
    reg [15:0] e;
    integer   i;
    /* verilator lint_off WIDTHTRUNC */
    localparam [3:0] NL = N;
    /* verilator lint_on WIDTHTRUNC */
    always @(*) begin
        t = s;
        e = 16'd0;
        for (i = N - 1; i >= 0; i = i - 1) begin
            if (d[i] != (t[6] ^ t[5])) e = e + 16'd1;
            t = {t[5:0], d[i]};
        end
    end
    always @(posedge clk) begin
        if (rst) begin
            s     <= 7'd0;
            nb    <= 4'd0;
            bledy <= 16'd0;
            synch <= 1'b0;
        end else if (en) begin
            s <= t;
            if (!synch) begin
                nb <= nb + NL;
                if (nb + NL >= 4'd7) synch <= 1'b1;
            end else if (e != 16'd0 && bledy < 16'hFFF0)
                bledy <= bledy + e;
        end
    end
endmodule

`default_nettype wire
