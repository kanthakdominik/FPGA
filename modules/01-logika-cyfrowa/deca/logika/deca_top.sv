// Moduł nadrzędny dla płytki DECA — SystemVerilog. Czysta logika kombinacyjna, bez zegara.
// a = SW[1:0] (przełącznik w dół = 0), b = odwrócone KEY[1:0] (wciśnięty przycisk = 1).
// LED[3:0] — dekoder a (kod 1 z 4), LED[5:4] — suma a + b, LED[6] — przeniesienie, LED[7] — a > b.
// Diody DECA świecą przy stanie niskim, więc wyjścia są odwrócone.
module deca_top (
    input  logic [1:0] SW,             // przełączniki, w dół = 0
    input  logic [1:0] KEY,            // przyciski, wciśnięty = 0
    output logic [7:0] LED             // diody, 0 = świeci
);
    logic [1:0] a, b, sum;
    logic [3:0] dec;
    logic       cout, gt;

    assign a = SW;
    assign b = ~KEY;                   // wciśnięty przycisk = jedynka logiczna

    decoder    #(.N(2)) u_dec (.a, .y(dec));
    rca_adder  #(.W(2)) u_add (.a, .b, .cin(1'b0), .s(sum), .cout);
    comparator #(.W(2)) u_cmp (.a, .b, .eq(), .lt(), .gt);

    // 1 = świeci w naszej logice, 0 = świeci na płytce
    assign LED = ~{gt, cout, sum, dec};
endmodule
