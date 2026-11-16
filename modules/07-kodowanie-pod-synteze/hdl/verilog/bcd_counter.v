// Licznik dziesiętny (BCD) z DIGITS cyfr: kaskada zezwoleń, jeden zegar dla wszystkich cyfr.
// Cyfra i liczy, gdy en = 1 i wszystkie młodsze cyfry są równe 9. carry = przepełnienie całego licznika.
`default_nettype none

module bcd_counter #(
    parameter DIGITS = 3
) (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  en,
    output wire [4*DIGITS-1:0]   bcd,          // cyfra i: bcd[4*i +: 4], cyfra 0 najmłodsza
    output wire                  carry
);
    // c[i] — zezwolenie dla cyfry i. split_var: Verilator rozdziela wektor na bity; bez tego zgłasza
    // UNOPTFLAT (pozorną pętlę: c zależy od c), bo traktuje cały wektor jako jeden sygnał.
    wire [DIGITS:0] c /* verilator split_var */;
    assign c[0] = en;

    genvar i;
    generate
        for (i = 0; i < DIGITS; i = i + 1) begin : g_digit
            reg [3:0] q = 4'd0;
            always @(posedge clk)
                if (rst)       q <= 4'd0;
                else if (c[i]) q <= (q == 4'd9) ? 4'd0 : q + 4'd1;
            assign c[i+1]       = c[i] & (q == 4'd9);
            assign bcd[4*i +: 4] = q;
        end
    endgenerate

    assign carry = c[DIGITS];
endmodule

`default_nettype wire
