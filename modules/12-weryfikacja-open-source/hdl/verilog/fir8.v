// Filtr FIR, 8 współczynników, stałoprzecinkowy — układ weryfikowany w module 12.
// Wejście: 12 bitów ze znakiem, strumień z in_valid (bez wstrzymania). Współczynniki Q1.15, symetryczne,
// dolnoprzepustowe, suma = 32768 (wzmocnienie 1 dla składowej stałej):
//   h = {-763, 0, 4499, 12648, 12648, 4499, 0, -763}
// Wyjście: 16 bitów ze znakiem = nasycenie(zaokrąglenie(suma / 2^11)) — 4 bity ułamkowe więcej niż wejście.
// Zaokrąglenie „połówka w górę”: (suma + 1024) >>> 11. Potok 3 takty: iloczyny, suma, zaokrąglenie.
//
// Parametr BUG wstrzykuje błąd do ćwiczeń weryfikacji (0 = układ poprawny):
//   1 — obcięcie zamiast zaokrąglenia (różnica najwyżej 1 LSB),
//   2 — brak nasycenia (przepełnienie zawija wynik).
`default_nettype none

module fir8 #(
    parameter BUG = 0
) (
    input  wire               clk,
    input  wire               rst,
    input  wire               in_valid,
    input  wire signed [11:0] in_data,
    output reg                out_valid,
    output reg  signed [15:0] out_data
);
    function signed [27:0] coef;
        input integer i;
        begin
            case (i)
                0, 7:    coef = -28'sd763;
                2, 5:    coef = 28'sd4499;
                3, 4:    coef = 28'sd12648;
                default: coef = 28'sd0;
            endcase
        end
    endfunction

    reg signed [11:0] x [0:7];           // linia opóźniająca, x[0] — najnowsza próbka
    reg signed [27:0] p [0:7];           // iloczyny
    reg signed [30:0] acc;               // suma iloczynów
    reg        [2:0]  v;                 // ważność kolejnych stopni potoku
    integer           i;

    wire signed [30:0] rounded = (BUG == 1) ? acc : acc + 31'sd1024;
    /* verilator lint_off UNUSEDSIGNAL */            // górne bity po przesunięciu: kopie znaku
    wire signed [30:0] shifted = rounded >>> 11;
    /* verilator lint_on UNUSEDSIGNAL */
    wire signed [19:0] scaled  = shifted[19:0];

    reg signed [15:0] sat;
    always @* begin
        if (BUG == 2)                sat = scaled[15:0];
        else if (scaled > 20'sd32767)  sat = 16'sd32767;
        else if (scaled < -20'sd32768) sat = -16'sd32768;
        else                         sat = scaled[15:0];
    end

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 8; i = i + 1) x[i] <= 12'sd0;
            v         <= 3'd0;
            out_valid <= 1'b0;
        end else begin
            if (in_valid) begin
                x[0] <= in_data;
                for (i = 1; i < 8; i = i + 1) x[i] <= x[i-1];
            end
            v         <= {v[1:0], in_valid};
            out_valid <= v[2];
        end
        for (i = 0; i < 8; i = i + 1) p[i] <= {{16{x[i][11]}}, x[i]} * coef(i);
        acc      <= {{3{p[0][27]}}, p[0]} + {{3{p[1][27]}}, p[1]} + {{3{p[2][27]}}, p[2]} + {{3{p[3][27]}}, p[3]}
                  + {{3{p[4][27]}}, p[4]} + {{3{p[5][27]}}, p[5]} + {{3{p[6][27]}}, p[6]} + {{3{p[7][27]}}, p[7]};
        out_data <= sat;
    end
endmodule

`default_nettype wire
