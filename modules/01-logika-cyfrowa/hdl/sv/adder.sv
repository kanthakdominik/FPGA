// Sumator opisany behawioralnie: syntezator sam zbuduje go na łańcuchu przeniesień.
module adder #(
    parameter int W = 8
) (
    input  logic [W-1:0] a, b,
    input  logic         cin,
    output logic [W-1:0] s,
    output logic         cout
);
    // lewa strona ma W+1 bitów, więc dodawanie wykonuje się na W+1 bitach — przeniesienie nie ginie
    assign {cout, s} = a + b + cin;
endmodule
