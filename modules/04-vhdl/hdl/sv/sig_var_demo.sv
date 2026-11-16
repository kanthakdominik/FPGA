// Przypisania nieblokujące (jak sygnały VHDL) i zmienne lokalne bloku (jak zmienne VHDL).
// Celowy przykład porównawczy: w always_ff wartości rejestrów przypisuje się tylko przez <=.
module sig_var_demo (
    input  logic clk,
    input  logic d,
    output logic q_sig,                            // d opóźnione o 2 takty
    output logic q_var                             // d opóźnione o 1 takt
);
    logic s1 = 1'b0, s2 = 1'b0;

    always_ff @(posedge clk) begin
        logic v1, v2;                              // zmienne lokalne bloku — nie są rejestrami
        s1 <= d;
        s2 <= s1;
        v1 = d;
        v2 = v1;
        q_var <= v2;
    end

    assign q_sig = s2;
endmodule
