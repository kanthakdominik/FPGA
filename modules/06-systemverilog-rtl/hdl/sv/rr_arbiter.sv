// Arbiter karuzelowy (round-robin) dla 4 zgłoszeń: pierwszeństwo ma pierwsze zgłoszenie
// po ostatnio obsłużonym. Przydział (grant) w kodzie 1 z n, numer — przez unique case.
module rr_arbiter (
    input  logic       clk,
    input  logic       rst,
    input  logic [3:0] req,
    output logic [3:0] grant,
    output logic [1:0] grant_idx,
    output logic       grant_valid
);
    localparam int N = 4;

    logic [1:0] last;                              // ostatnio obsłużony

    always_comb begin
        grant = '0;
        // przeszukanie od last + 1 cyklicznie: pierwsze trafienie wygrywa (priorytet przez warunek)
        for (int k = 1; k <= N; k++) begin
            int idx;
            idx = (int'(last) + k) % N;
            if (req[idx] && grant == '0)
                grant[idx] = 1'b1;
        end
    end

    assign grant_valid = |grant;

    // grant ma co najwyżej jedną jedynkę — unique mówi to narzędziom i symulatorowi
    always_comb begin
        grant_idx = '0;
        unique case (1'b1)
            grant[0]: grant_idx = 2'd0;
            grant[1]: grant_idx = 2'd1;
            grant[2]: grant_idx = 2'd2;
            grant[3]: grant_idx = 2'd3;
            default:  grant_idx = '0;              // brak przydziału
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst)              last <= 2'd3;        // po resecie pierwszeństwo ma zgłoszenie 0
        else if (grant_valid) last <= grant_idx;
    end
endmodule
