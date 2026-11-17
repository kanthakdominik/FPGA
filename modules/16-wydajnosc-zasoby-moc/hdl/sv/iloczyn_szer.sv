// Iloczyn skalarny czterech par liczb 8-bitowych bez znaku — wersja szeregowa (16.02):
// jedna mnożarka i akumulator, cztery takty na wynik; start przyjmowany, gdy ready = 1
// (także w ostatnim takcie poprzedniego obliczenia).
module iloczyn_szer (
    input  logic        clk,
    input  logic        rst,
    input  logic        start,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic        ready,
    output logic        done,
    output logic [17:0] y
);
    logic [31:0] a_r, b_r;
    logic [1:0]  idx;
    logic        busy, last;
    logic [17:0] acc;
    logic [15:0] prod;

    assign prod  = 16'(a_r[8*idx +: 8]) * 16'(b_r[8*idx +: 8]);     // jedna mnożarka
    assign last  = busy && (idx == 2'd3);
    assign ready = !busy || last;

    always_ff @(posedge clk) begin
        if (rst) begin
            busy <= 1'b0;
            done <= 1'b0;
            idx  <= '0;
        end else begin
            done <= last;
            if (busy) idx <= idx + 2'd1;
            if (start && ready) begin
                busy <= 1'b1;
                idx  <= '0;
            end else if (last) begin
                busy <= 1'b0;
            end
        end
        if (start && ready) begin
            a_r <= a;
            b_r <= b;
        end
        if (busy) acc <= (idx == 2'd0 ? 18'd0 : acc) + 18'(prod);
        if (last) y   <= acc + 18'(prod);
    end
endmodule
