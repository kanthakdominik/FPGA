// Filtr FIR symetryczny (26.01), N nieparzyste: h_i = h_{N-1-i}, więc przed mnożeniem dodaje się pary próbek
// (p_i = x[n-i] + x[n-N+1+i]) — (N+1)/2 mnożeń zamiast N. Struktura bezpośrednia z potokiem:
// linia opóźniająca -> sumatory wstępne -> mnożenia -> suma -> zaokrąglenie i nasycenie; opóźnienie 4 takty,
// jedna próbka na takt. Współczynniki h_0..h_{(N-1)/2} z wejścia wsp (format jak w fir_transp).
`default_nettype none

module fir_sym #(
    parameter integer N = 31
) (
    input  logic               clk,
    input  logic               rst,
    input  logic               we,
    input  logic signed [15:0] x,
    /* verilator lint_off UNUSEDSIGNAL */            // używane tylko h_0..h_(N-1)/2
    input  logic [16*N-1:0]    wsp,
    /* verilator lint_on UNUSEDSIGNAL */
    output logic  signed [15:0] y,
    output logic                y_wazne
);
    localparam integer P = (N + 1) / 2;
    logic signed [15:0] lin [0:N-1];
    logic signed [16:0] p [0:P-1];
    logic signed [32:0] m [0:P-1];
    logic signed [39:0] s;
    logic        [3:0]  v;
    integer i, j;

    logic signed [39:0] suma;
    always_comb begin
        suma = 40'sd0;
        for (j = 0; j < P; j = j + 1) suma = suma + m[j];
    end
    logic signed [39:0] zaokr;
    assign zaokr = s + 40'sd16384;
    /* verilator lint_off UNUSEDSIGNAL */
    logic signed [24:0] w;
    assign w = zaokr[39:15];
    /* verilator lint_on UNUSEDSIGNAL */

    always_ff @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) lin[i] <= 16'sd0;
            v <= 4'd0;
        end else begin
            v <= {v[2:0], we};
            if (we) begin
                lin[0] <= x;
                for (i = 1; i < N; i = i + 1) lin[i] <= lin[i-1];
            end
        end
        for (i = 0; i < P - 1; i = i + 1) p[i] <= lin[i] + lin[N-1-i];               // stopień 1: sumy par
        p[P-1] <= {lin[P-1][15], lin[P-1]};                                           // środkowy współczynnik
        for (i = 0; i < P; i = i + 1) m[i] <= $signed(wsp[16*i +: 16]) * p[i];       // stopień 2: mnożenia
        s       <= suma;                                                              // stopień 3: suma
        y       <= (w > 25'sd32767) ? 16'sh7FFF : (w < -25'sd32768) ? 16'sh8000 : w[15:0];   // stopień 4
        y_wazne <= v[3];
    end
endmodule

`default_nettype wire
