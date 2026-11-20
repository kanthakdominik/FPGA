// Pierwiastek całkowity iteracyjny (19.03): pierw = floor(sqrt(x)) dla x o 2W bitach, jeden bit wyniku
// na takt (metoda „cyfra po cyfrze”, jak dzielenie pisemne): do reszty dopisywane są dwa kolejne bity x,
// a próbny odjemnik to 4·pierw + 1. W taktów, tylko dodawanie i przesunięcia; reszta = x - pierw².
`default_nettype none

module pierw_iter #(
    parameter W = 8                                    // bity wyniku; wejście ma 2W bitów
) (
    input  logic           clk,
    input  logic           rst,
    input  logic           start,
    input  logic [2*W-1:0] x,
    output logic            busy = 1'b0,
    output logic            done = 1'b0,
    output logic  [W-1:0]   pierw,
    output logic  [W:0]     reszta
);
    localparam CW = $clog2(W + 1);

    logic  [2*W-1:0] xs;                                 // x przesuwany o dwa bity w lewo
    logic  [W-1:0]   p;                                  // wynik częściowy
    /* verilator lint_off UNUSEDSIGNAL */
    logic  [W+1:0]   rr;                                 // reszta częściowa (W+2 bitów; najstarszy bit zawsze 0 po kroku)
    /* verilator lint_on UNUSEDSIGNAL */
    logic  [CW-1:0]  licz;

    logic [W+1:0]   r_przes;
    assign r_przes = {rr[W-1:0], xs[2*W-1:2*W-2]};
    logic [W+1:0]   proba;
    assign proba = {p, 2'b01};                // 4·p + 1
    logic [W+1:0]   roznica;
    assign roznica = r_przes - proba;
    logic           bit_p;
    assign bit_p = (r_przes >= proba);

    always_ff @(posedge clk) begin
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
