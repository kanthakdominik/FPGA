// Maksimum z N liczb bez znaku — pętla: łańcuch N - 1 porównań, głębokość logiki rośnie liniowo z N.
`default_nettype none

module max_chain #(
    parameter N = 8,
    parameter W = 8
) (
    input  wire [N*W-1:0] x,                   // element i: x[i*W +: W]
    output reg  [W-1:0]   y
);
    integer i;

    always @* begin
        y = x[W-1:0];
        for (i = 1; i < N; i = i + 1)          // każdy obieg pętli = kolejny komparator i multiplekser
            if (x[i*W +: W] > y)
                y = x[i*W +: W];
    end
endmodule

`default_nettype wire
