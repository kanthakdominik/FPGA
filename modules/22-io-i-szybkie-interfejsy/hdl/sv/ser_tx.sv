// Serializator N:1 (22.03): słowo pobierane co N taktów zegara bitowego (impuls pobierz), wysyłane od
// najstarszego bitu. W układzie z blokiem SERDES zegar bitowy i słowowy to dwa zegary z jednego PLL;
// tu jeden zegar bitowy z licznikiem, co pokazuje działanie bez prymitywów.
`default_nettype none

module ser_tx #(
    parameter integer N = 8
) (
    input  logic         clk,                  // zegar bitowy
    input  logic         rst,
    input  logic [N-1:0] slowo,
    output logic          pobierz,              // słowo przyjęte w tym takcie
    output logic         q
);
    localparam integer CW = $clog2(N);
    /* verilator lint_off WIDTHTRUNC */
    localparam [CW-1:0] OST = N - 1;
    /* verilator lint_on WIDTHTRUNC */
    logic [N-1:0]  sr;
    logic [CW-1:0] licz;

    assign q = sr[N-1];
    always_ff @(posedge clk) begin
        pobierz <= 1'b0;
        if (rst) begin
            licz <= {CW{1'b0}};
            sr   <= {N{1'b0}};
        end else begin
            licz <= (licz == OST) ? {CW{1'b0}} : licz + 1'b1;
            if (licz == OST) begin
                sr      <= slowo;
                pobierz <= 1'b1;
            end else
                sr <= {sr[N-2:0], 1'b0};
        end
    end
endmodule

`default_nettype wire
