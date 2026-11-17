// Duży fanout (16.03): rejestr przesuwny N bitów z zezwoleniem en_r (fanout N). NDUP > 1: en_r
// zduplikowany NDUP razy, każda kopia steruje N/NDUP przerzutnikami; dont_merge (Quartus) chroni kopie
// przed scaleniem — Yosys scala je mimo atrybutów (eksperymenty.py e3).
module rozgalezienie #(
    parameter int N    = 256,
    parameter int NDUP = 1
) (
    input  logic clk,
    input  logic en,
    input  logic d,
    output logic q
);
    localparam int GRUPA = N / NDUP;

    (* keep, dont_merge *) logic [NDUP-1:0] en_r = '0;
    logic [N-1:0] sr = '0;

    always_ff @(posedge clk) en_r <= {NDUP{en}};

    always_ff @(posedge clk)
        for (int i = 0; i < N; i++)
            if (en_r[i / GRUPA]) sr[i] <= (i == 0) ? d : sr[i == 0 ? 0 : i - 1];

    assign q = sr[N-1];
endmodule
