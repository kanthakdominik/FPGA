// Miernik częstotliwości (17.01): liczba taktów zegara mierzonego clk_mier w oknie BRAMKA taktów
// zegara odniesienia clk_ref. W domenie mierzonej działa licznik w kodzie Graya (przechodzi przez
// synchronizator bez ryzyka niespójnych bitów, 15.04); w domenie odniesienia — różnica stanów
// licznika na końcu kolejnych okien. Wynik = f_mier · BRAMKA / f_ref, dokładność ±1.
// Pierwszy wynik po resecie jest pomijany (brak poprzedniego stanu).
`default_nettype none

module pomiar_czestotliwosci #(
    parameter CW     = 24,
    parameter BRAMKA = 50000             // takty clk_ref na okno (50 MHz -> 1 ms)
) (
    input  wire          clk_ref,
    input  wire          rst,            // synchroniczny z clk_ref
    input  wire          clk_mier,
    output reg  [CW-1:0] wynik = {CW{1'b0}},
    output reg           wynik_valid = 1'b0
);
    // --- domena mierzona: licznik binarny i jego postać Graya w rejestrze ---
    reg [CW-1:0] cnt_m  = {CW{1'b0}};
    reg [CW-1:0] gray_m = {CW{1'b0}};
    always @(posedge clk_mier) begin
        cnt_m  <= cnt_m + 1'b1;
        gray_m <= cnt_m ^ (cnt_m >> 1);
    end

    // --- domena odniesienia: synchronizator 2FF, konwersja do binarnego, okno pomiarowe ---
    (* ASYNC_REG = "TRUE", altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    reg [CW-1:0] sync1 = {CW{1'b0}}, sync2 = {CW{1'b0}};
    always @(posedge clk_ref) begin
        sync1 <= gray_m;
        sync2 <= sync1;
    end

    reg [CW-1:0] bin_now;
    integer k;
    always @(*) begin
        bin_now[CW-1] = sync2[CW-1];
        for (k = CW - 2; k >= 0; k = k - 1) bin_now[k] = bin_now[k+1] ^ sync2[k];
    end

    reg [31:0]   okno = 32'd0;
    reg [CW-1:0] bin_prev = {CW{1'b0}};
    reg          pierwszy = 1'b1;
    always @(posedge clk_ref) begin
        wynik_valid <= 1'b0;
        if (rst) begin
            okno     <= 32'd0;
            pierwszy <= 1'b1;
        end else if (okno == BRAMKA - 1) begin
            okno     <= 32'd0;
            bin_prev <= bin_now;
            pierwszy <= 1'b0;
            if (!pierwszy) begin
                wynik       <= bin_now - bin_prev;
                wynik_valid <= 1'b1;
            end
        end else begin
            okno <= okno + 32'd1;
        end
    end
endmodule

`default_nettype wire
