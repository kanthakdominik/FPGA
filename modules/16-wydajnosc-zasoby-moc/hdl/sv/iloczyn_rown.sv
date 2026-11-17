// Iloczyn skalarny czterech par liczb 8-bitowych bez znaku — wersja równoległa (16.02):
// cztery mnożarki i drzewo sumatorów, jeden wynik na takt, opóźnienie 2 takty.
module iloczyn_rown (
    input  logic        clk,
    input  logic        rst,
    input  logic        in_valid,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic        out_valid,
    output logic [17:0] y
);
    logic [31:0] a_r, b_r;
    logic        v_r;
    logic [15:0] p [4];

    always_ff @(posedge clk) begin
        a_r <= a;
        b_r <= b;
    end
    always_comb
        for (int i = 0; i < 4; i++) p[i] = 16'(a_r[8*i +: 8]) * 16'(b_r[8*i +: 8]);

    always_ff @(posedge clk) y <= (18'(p[0]) + 18'(p[1])) + (18'(p[2]) + 18'(p[3]));
    always_ff @(posedge clk)
        if (rst) {v_r, out_valid} <= 2'b00;
        else     {v_r, out_valid} <= {in_valid, v_r};
endmodule
