// Moduł nadrzędny dla płytki DECA — Verilog. Czysta logika kombinacyjna, bez zegara.
// a = SW[1:0] (przełącznik w dół = 0), b = odwrócone KEY[1:0] (wciśnięty przycisk = 1).
// LED[3:0] — dekoder a (kod 1 z 4), LED[5:4] — suma a + b, LED[6] — przeniesienie, LED[7] — a > b.
// Diody DECA świecą przy stanie niskim, więc wyjścia są odwrócone.
`default_nettype none

module deca_top (
    input  wire [1:0] SW,              // przełączniki, w dół = 0
    input  wire [1:0] KEY,             // przyciski, wciśnięty = 0
    output wire [7:0] LED              // diody, 0 = świeci
);
    wire [1:0] a = SW;
    wire [1:0] b = ~KEY;               // wciśnięty przycisk = jedynka logiczna

    wire [3:0] dec;
    wire [1:0] sum;
    wire       cout, gt;

    decoder #(.N(2)) u_dec (.a(a), .y(dec));

    rca_adder #(.W(2)) u_add (.a(a), .b(b), .cin(1'b0), .s(sum), .cout(cout));

    comparator #(.W(2)) u_cmp (.a(a), .b(b), .eq(), .lt(), .gt(gt));

    // 1 = świeci w naszej logice, 0 = świeci na płytce
    assign LED = ~{gt, cout, sum, dec};
endmodule

`default_nettype wire
