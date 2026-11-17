// Dwa stopnie potoku w osobnych instancjach (16.05): u_a liczy sumę ośmiu bajtów, u_b sumuje osiem
// obróconych kopii wyniku u_a. Jedyna ścieżka między instancjami to rejestr wyjściowy u_a ->
// rejestr wejściowy u_b — samo połączenie, bez logiki. Rozmieszczenie instancji (blisko / na
// przeciwnych krańcach układu) decyduje o długości tego połączenia.
`default_nettype none

module floorplan_demo (
    input  wire        clk,
    input  wire        rst,
    input  wire        in_valid,
    input  wire [63:0] x,
    output wire        out_valid,
    output wire [13:0] y
);
    wire        va;
    wire [10:0] ya;
    sumator_drzewo #(.W(8), .PIPE(2)) u_a (.clk(clk), .rst(rst), .in_valid(in_valid), .x(x),
                                           .out_valid(va), .y(ya));
    wire [87:0] xb = {ya, {ya[0], ya[10:1]}, {ya[1:0], ya[10:2]}, {ya[2:0], ya[10:3]},
                      {ya[3:0], ya[10:4]}, {ya[4:0], ya[10:5]}, {ya[5:0], ya[10:6]}, {ya[6:0], ya[10:7]}};
    sumator_drzewo #(.W(11), .PIPE(2)) u_b (.clk(clk), .rst(rst), .in_valid(va), .x(xb),
                                            .out_valid(out_valid), .y(y));
endmodule

`default_nettype wire
