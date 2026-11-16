// Sumator opisany behawioralnie: syntezator sam zbuduje go na łańcuchu przeniesień.
`default_nettype none

module adder #(
    parameter integer W = 8
) (
    input  wire [W-1:0] a, b,
    input  wire         cin,
    output wire [W-1:0] s,
    output wire         cout
);
    // lewa strona ma W+1 bitów, więc dodawanie wykonuje się na W+1 bitach — przeniesienie nie ginie
    assign {cout, s} = a + b + cin;
endmodule

`default_nettype wire
