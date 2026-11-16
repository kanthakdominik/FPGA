// Licznik dziesiętny (BCD) z DIGITS cyfr: kaskada zezwoleń, jeden zegar dla wszystkich cyfr.
// Cyfra i liczy, gdy en = 1 i wszystkie młodsze cyfry są równe 9. carry = przepełnienie całego licznika.
module bcd_counter #(
    parameter int DIGITS = 3
) (
    input  logic                    clk,
    input  logic                    rst,
    input  logic                    en,
    output logic [DIGITS-1:0][3:0]  bcd,       // bcd[0] — cyfra najmłodsza
    output logic                    carry
);
    // c[i] — zezwolenie dla cyfry i. split_var: Verilator rozdziela wektor na bity; bez tego zgłasza
    // UNOPTFLAT (pozorną pętlę: c zależy od c), bo traktuje cały wektor jako jeden sygnał.
    logic [DIGITS:0] c /* verilator split_var */;
    assign c[0] = en;

    for (genvar i = 0; i < DIGITS; i++) begin : g_digit
        logic [3:0] q = 4'd0;                  // własny rejestr cyfry: jeden proces na zmienną
        always_ff @(posedge clk)
            if (rst)       q <= 4'd0;
            else if (c[i]) q <= (q == 4'd9) ? 4'd0 : q + 4'd1;
        assign c[i+1] = c[i] & (q == 4'd9);
        assign bcd[i] = q;
    end

    assign carry = c[DIGITS];
endmodule
