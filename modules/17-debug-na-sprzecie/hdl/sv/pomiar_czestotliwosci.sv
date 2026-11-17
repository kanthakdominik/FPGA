// Miernik częstotliwości (17.01): liczba taktów clk_mier w oknie BRAMKA taktów clk_ref. Licznik Graya
// w domenie mierzonej, synchronizator 2FF i różnica stanów w domenie odniesienia; dokładność ±1,
// pierwszy wynik po resecie pominięty.
module pomiar_czestotliwosci #(
    parameter int CW     = 24,
    parameter int BRAMKA = 50000
) (
    input  logic          clk_ref,
    input  logic          rst,
    input  logic          clk_mier,
    output logic [CW-1:0] wynik = '0,
    output logic          wynik_valid = 1'b0
);
    logic [CW-1:0] cnt_m = '0, gray_m = '0;
    always_ff @(posedge clk_mier) begin
        cnt_m  <= cnt_m + 1'b1;
        gray_m <= cnt_m ^ (cnt_m >> 1);
    end

    (* ASYNC_REG = "TRUE", altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    logic [CW-1:0] sync1 = '0, sync2 = '0;
    always_ff @(posedge clk_ref) begin
        sync1 <= gray_m;
        sync2 <= sync1;
    end

    logic [CW-1:0] bin_now;
    always_comb begin
        bin_now[CW-1] = sync2[CW-1];
        for (int k = CW - 2; k >= 0; k--) bin_now[k] = bin_now[k+1] ^ sync2[k];
    end

    logic [31:0]   okno = '0;
    logic [CW-1:0] bin_prev = '0;
    logic          pierwszy = 1'b1;
    always_ff @(posedge clk_ref) begin
        wynik_valid <= 1'b0;
        if (rst) begin
            okno     <= '0;
            pierwszy <= 1'b1;
        end else if (okno == 32'(BRAMKA - 1)) begin
            okno     <= '0;
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
