// Zadanie 5: arbiter round-robin dla N zgłoszeń (N — potęga dwójki). Przydział kombinacyjny (jedna jedynka),
// szukanie od pozycji ptr; po przydziale ptr przechodzi za zwycięzcę, więc każde trwające zgłoszenie dostaje
// przydział najpóźniej po N - 1 innych. Przydział obowiązuje jeden takt.
`default_nettype none

module rr_arbiter #(
    parameter integer N = 4,
    parameter integer W = $clog2(N)
) (
    input  wire         clk,
    input  wire         rst,
    input  wire [N-1:0] req,
    output reg  [N-1:0] grant
);
    reg [W-1:0] ptr = {W{1'b0}};
    reg [W-1:0] idx;
    reg [W-1:0] win;
    reg         found;
    integer     i;

    always @(*) begin
        grant = {N{1'b0}};
        found = 1'b0;
        win   = ptr;
        for (i = 0; i < N; i = i + 1) begin
            idx = ptr + i[W-1:0];                       // zawija się modulo N
            if (!found && req[idx]) begin
                found = 1'b1;
                win   = idx;
            end
        end
        if (found) grant[win] = 1'b1;
    end

    always @(posedge clk)
        if (rst)        ptr <= {W{1'b0}};
        else if (found) ptr <= win + 1'b1;
endmodule

`default_nettype wire
