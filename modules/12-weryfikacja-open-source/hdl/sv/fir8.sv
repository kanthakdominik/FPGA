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
module fir8 #(
    parameter int BUG = 0
) (
    input  logic               clk,
    input  logic               rst,
    input  logic               in_valid,
    input  logic signed [11:0] in_data,
    output logic               out_valid,
    output logic signed [15:0] out_data
);
    localparam int N = 8;
    localparam logic signed [15:0] H [N] = '{-16'sd763, 16'sd0, 16'sd4499, 16'sd12648,
                                            16'sd12648, 16'sd4499, 16'sd0, -16'sd763};

    logic signed [11:0] x [N];          // linia opóźniająca, x[0] — najnowsza próbka
    logic signed [27:0] p [N];          // iloczyny
    logic signed [30:0] acc;            // suma iloczynów
    logic         [2:0] v;              // ważność kolejnych stopni potoku

    // zaokrąglenie i nasycenie
    logic signed [30:0] rounded;
    logic signed [19:0] scaled;
    assign rounded = (BUG == 1) ? acc : acc + 31'sd1024;
    assign scaled  = 20'(rounded >>> 11);

    function automatic logic signed [15:0] saturate(logic signed [19:0] s);
        if (BUG == 2)          return 16'(s);
        if (s > 20'sd32767)    return 16'sd32767;
        if (s < -20'sd32768)   return -16'sd32768;
        return 16'(s);
    endfunction

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < N; i++) x[i] <= '0;
            v         <= '0;
            out_valid <= 1'b0;
        end else begin
            if (in_valid) begin
                x[0] <= in_data;
                for (int i = 1; i < N; i++) x[i] <= x[i-1];
            end
            v         <= {v[1:0], in_valid};
            out_valid <= v[2];
        end
        for (int i = 0; i < N; i++) p[i] <= 28'(x[i]) * 28'(H[i]);
        acc      <= 31'(p[0]) + 31'(p[1]) + 31'(p[2]) + 31'(p[3]) + 31'(p[4]) + 31'(p[5]) + 31'(p[6]) + 31'(p[7]);
        out_data <= saturate(scaled);
    end
endmodule
