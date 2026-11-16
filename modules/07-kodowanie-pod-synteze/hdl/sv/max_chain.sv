// Maksimum z N liczb bez znaku — pętla: łańcuch N - 1 porównań, głębokość logiki rośnie liniowo z N.
module max_chain #(
    parameter int N = 8,
    parameter int W = 8
) (
    input  logic [N-1:0][W-1:0] x,
    output logic [W-1:0]        y
);
    always_comb begin
        y = x[0];
        for (int i = 1; i < N; i++)            // każdy obieg pętli = kolejny komparator i multiplekser
            if (x[i] > y)
                y = x[i];
    end
endmodule
