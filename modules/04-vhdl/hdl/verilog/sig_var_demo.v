// Przypisania nieblokujące (jak sygnały VHDL) i blokujące (jak zmienne VHDL) w bloku taktowanym.
// Celowy przykład porównawczy: w kodzie produkcyjnym w bloku taktowanym używa się tylko <=.
`default_nettype none

module sig_var_demo (
    input  wire clk,
    input  wire d,
    output wire q_sig,                             // d opóźnione o 2 takty
    output reg  q_var                              // d opóźnione o 1 takt
);
    reg s1 = 1'b0, s2 = 1'b0;
    reg v1, v2;

    always @(posedge clk) begin
        // nieblokujące: prawe strony sprzed zbocza -> dwa rejestry
        s1 <= d;
        s2 <= s1;
        // blokujące: v1 i v2 dostają d od razu -> tylko połączenia, rejestrem jest q_var
        v1 = d;
        v2 = v1;
        q_var <= v2;
    end

    assign q_sig = s2;
endmodule

`default_nettype wire
