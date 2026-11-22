// Zadanie 7: przeniesienie impulsu jednotaktowego z domeny A do domeny B. Impuls zmienia stan przełącznika
// w domenie A; przełącznik przechodzi przez synchronizator dwóch przerzutników w domenie B, a każda zmiana
// daje impuls o długości jednego taktu B. Warunek: odstęp między impulsami w A dłuższy niż ok. 3 takty B
// (inaczej dwie zmiany przełącznika mogą się „zlać”) — gdy nie da się go zagwarantować, potrzebny handshake.
`default_nettype none

module pulse_sync (
    input  wire clk_a,
    input  wire rst_a,
    input  wire pulse_a,
    input  wire clk_b,
    input  wire rst_b,
    output wire pulse_b
);
    reg       tog_a = 1'b0;
    reg [2:0] sync_b = 3'b000;      // [0], [1] — synchronizator, [2] — poprzednia wartość do wykrycia zmiany

    always @(posedge clk_a)
        if (rst_a)        tog_a <= 1'b0;
        else if (pulse_a) tog_a <= ~tog_a;

    always @(posedge clk_b)
        if (rst_b) sync_b <= 3'b000;
        else       sync_b <= {sync_b[1:0], tog_a};

    assign pulse_b = sync_b[2] ^ sync_b[1];
endmodule

`default_nettype wire
