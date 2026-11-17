// Duży fanout (16.03): rejestr przesuwny N bitów z zezwoleniem. Sygnał zezwolenia en wchodzi
// do rejestru en_r, który steruje wejściami CE wszystkich N przerzutników (fanout N).
// NDUP > 1: en_r zduplikowany NDUP razy, każda kopia steruje N/NDUP przerzutnikami.
// Atrybut dont_merge (Quartus) chroni kopie przed scaleniem przez syntezę; Yosys scala je mimo atrybutów
// (eksperymenty.py e3) — w Vivado odpowiednikiem jest DONT_TOUCH albo MAX_FANOUT.
`default_nettype none

module rozgalezienie #(
    parameter N    = 256,
    parameter NDUP = 1               // dzielnik N
) (
    input  wire clk,
    input  wire en,
    input  wire d,
    output wire q
);
    localparam GRUPA = N / NDUP;

    (* keep, dont_merge *) reg [NDUP-1:0] en_r = {NDUP{1'b0}};
    always @(posedge clk) en_r <= {NDUP{en}};

    reg [N-1:0] sr = {N{1'b0}};
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : g_sr
            wire wej;
            if (i == 0) begin : g_pierwszy
                assign wej = d;
            end else begin : g_kolejny
                assign wej = sr[i-1];
            end
            always @(posedge clk)
                if (en_r[i / GRUPA]) sr[i] <= wej;
        end
    endgenerate
    assign q = sr[N-1];
endmodule

`default_nettype wire
