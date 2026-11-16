// Licznik kredytów kontroli przepływu: take zużywa kredyt, give oddaje.
// Asercje natychmiastowe pilnują reguł protokołu w symulacji; synteza je pomija.
module credit_counter #(
    parameter int MAX = 8
) (
    input  logic                   clk,
    input  logic                   rst,
    input  logic                   take,
    input  logic                   give,
    output logic [$clog2(MAX+1)-1:0] credits,
    output logic                     can_take
);
    localparam int CW = $clog2(MAX + 1);
    localparam logic [CW-1:0] FULL = CW'(MAX);
    assign can_take = (credits != '0);

    always_ff @(posedge clk) begin
        if (rst)
            credits <= FULL;
        else begin
            // reguły protokołu: nie bierz bez kredytu, nie oddawaj ponad MAX
            assert (!(take && credits == '0))
                else $error("credit_counter: take bez dostepnego kredytu");
            assert (!(give && !take && credits == FULL))
                else $error("credit_counter: give ponad MAX");

            if (take && !give)      credits <= credits - 1'b1;
            else if (give && !take) credits <= credits + 1'b1;
        end
    end
endmodule
