// Licznik w potrójnej redundancji (TMR, 29.04). Trzy kopie rejestru, wynik z głosowania 2 z 3.
//   SPRZEZENIE = 1: każda kopia liczy od wyniku głosowania — kopia trafiona przez SEU wraca do zgodności
//                   w następnym takcie (TMR z resynchronizacją); zawodzi dopiero przy dwóch błędach w jednym takcie;
//   SPRZEZENIE = 0: kopie liczą niezależnie — błąd w kopii zostaje na zawsze, a drugi błąd w innej kopii
//                   (tego samego bitu) psuje wynik.
// wstrzyk[k] — wstrzyknięcie błędu (odwrócenie bitu wstrzyk_bit) w kopii k przy zapisie; port testowy
// do kampanii wstrzykiwania błędów, w układzie docelowym na stałe 0.
`default_nettype none

module licznik_tmr #(
    parameter integer W = 16,
    parameter integer SPRZEZENIE = 1
) (
    input  wire         clk,
    input  wire         rst,
    input  wire         en,
    input  wire [2:0]   wstrzyk,
    input  wire [3:0]   wstrzyk_bit,
    output wire [W-1:0] q,
    output wire         niezgodny
);
    reg  [W-1:0] k0, k1, k2;
    wire [W-1:0] g;
    tmr_glos #(.W(W)) u_glos (.a(k0), .b(k1), .c(k2), .y(g), .niezgodny(niezgodny));

    /* verilator lint_off WIDTHEXPAND */
    wire [W-1:0] maska = {{(W-1){1'b0}}, 1'b1} << wstrzyk_bit;
    wire [W-1:0] n0 = (SPRZEZENIE != 0 ? g : k0) + en;
    wire [W-1:0] n1 = (SPRZEZENIE != 0 ? g : k1) + en;
    wire [W-1:0] n2 = (SPRZEZENIE != 0 ? g : k2) + en;
    /* verilator lint_on WIDTHEXPAND */

    always @(posedge clk)
        if (rst) begin
            k0 <= {W{1'b0}}; k1 <= {W{1'b0}}; k2 <= {W{1'b0}};
        end else begin
            k0 <= n0 ^ (wstrzyk[0] ? maska : {W{1'b0}});
            k1 <= n1 ^ (wstrzyk[1] ? maska : {W{1'b0}});
            k2 <= n2 ^ (wstrzyk[2] ? maska : {W{1'b0}});
        end

    assign q = g;
endmodule

`default_nettype wire
