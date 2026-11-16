// Tablica ćwiartki sinusa: data = round(255 * sin(pi/2 * (addr + 0.5) / 64)), addr = 0..63.
// Stała tablica spakowana, odczyt synchroniczny — syntezator może umieścić tablicę w bloku pamięci jako ROM.
// Wartości wygenerowane skryptem; testbench liczy je niezależnie funkcją sinus.
module sine_rom (
    input  logic       clk,
    input  logic [5:0] addr,
    output logic [7:0] data
);
    // Element 63 pierwszy: w tablicy spakowanej najstarszy indeks stoi po lewej stronie.
    localparam logic [63:0][7:0] SINE = {
        8'd255, 8'd255, 8'd255, 8'd254, 8'd253, 8'd253, 8'd252, 8'd251,
        8'd249, 8'd248, 8'd247, 8'd245, 8'd243, 8'd241, 8'd239, 8'd237,
        8'd234, 8'd232, 8'd229, 8'd226, 8'd223, 8'd220, 8'd217, 8'd214,
        8'd210, 8'd207, 8'd203, 8'd199, 8'd195, 8'd191, 8'd187, 8'd183,
        8'd178, 8'd174, 8'd169, 8'd164, 8'd159, 8'd154, 8'd149, 8'd144,
        8'd139, 8'd134, 8'd128, 8'd123, 8'd117, 8'd112, 8'd106, 8'd100,
        8'd95, 8'd89, 8'd83, 8'd77, 8'd71, 8'd65, 8'd59, 8'd53,
        8'd47, 8'd41, 8'd34, 8'd28, 8'd22, 8'd16, 8'd9, 8'd3
    };

    always_ff @(posedge clk)
        data <= SINE[addr];
endmodule
