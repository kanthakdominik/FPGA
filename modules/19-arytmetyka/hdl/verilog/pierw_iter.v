// Pierwiastek całkowity iteracyjny (19.03): pierw = floor(sqrt(x)) dla x o 2W bitach, jeden bit wyniku
// na takt (metoda „cyfra po cyfrze”, jak dzielenie pisemne): do reszty dopisywane są dwa kolejne bity x,
// a próbny odjemnik to 4·pierw + 1. W taktów, tylko dodawanie i przesunięcia; reszta = x - pierw².
`default_nettype none

module pierw_iter #(
    parameter W = 8                                    // bity wyniku; wejście ma 2W bitów
) (
    input  wire           clk,
    input  wire           rst,
    input  wire           start,
    input  wire [2*W-1:0] x,
    output reg            busy = 1'b0,
    output reg            done = 1'b0,
    output reg  [W-1:0]   pierw,
    output reg  [W:0]     reszta
);
    localparam CW = $clog2(W + 1);

    reg  [2*W-1:0] xs;                                 // x przesuwany o dwa bity w lewo
    reg  [W-1:0]   p;                                  // wynik częściowy
    /* verilator lint_off UNUSEDSIGNAL */
    reg  [W+1:0]   rr;                                 // reszta częściowa (W+2 bitów; najstarszy bit zawsze 0 po kroku)
    /* verilator lint_on UNUSEDSIGNAL */
    reg  [CW-1:0]  licz;

    wire [W+1:0]   r_przes = {rr[W-1:0], xs[2*W-1:2*W-2]};
    wire [W+1:0]   proba   = {p, 2'b01};                // 4·p + 1
    wire [W+1:0]   roznica = r_przes - proba;
    wire           bit_p   = (r_przes >= proba);

    always @(posedge clk) begin
        done <= 1'b0;
        if (rst) begin
            busy <= 1'b0;
        end else if (!busy) begin
            if (start) begin
                xs   <= x;
                p    <= {W{1'b0}};
                rr   <= {(W+2){1'b0}};
                licz <= W[CW-1:0];
                busy <= 1'b1;
            end
        end else if (licz != {CW{1'b0}}) begin
            xs   <= {xs[2*W-3:0], 2'b00};
            rr   <= bit_p ? roznica : r_przes;
            p    <= {p[W-2:0], bit_p};
            licz <= licz - 1'b1;
        end else begin
            busy   <= 1'b0;
            done   <= 1'b1;
            pierw  <= p;
            reszta <= rr[W:0];
        end
    end
endmodule

`default_nettype wire
