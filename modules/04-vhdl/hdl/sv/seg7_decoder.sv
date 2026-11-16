// Dekoder cyfry szesnastkowej na wskaźnik siedmiosegmentowy.
// seg[6:0] = g f e d c b a, 1 = segment świeci. Tablica stałych zamiast instrukcji case.
module seg7_decoder (
    input  logic [3:0] hex,
    output logic [6:0] seg
);
    localparam logic [6:0] TABLE [16] = '{
        7'h3F, 7'h06, 7'h5B, 7'h4F, 7'h66, 7'h6D, 7'h7D, 7'h07,
        7'h7F, 7'h6F, 7'h77, 7'h7C, 7'h39, 7'h5E, 7'h79, 7'h71
    };

    assign seg = TABLE[hex];                       // ROM opisany jako tablica
endmodule
