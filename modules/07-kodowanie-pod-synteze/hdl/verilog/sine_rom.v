// Tablica ćwiartki sinusa: data = round(255 * sin(pi/2 * (addr + 0.5) / 64)), addr = 0..63.
// Odczyt synchroniczny (rejestr na wyjściu) — syntezator może umieścić tablicę w bloku pamięci jako ROM.
// Wartości wygenerowane skryptem; testbench liczy je niezależnie funkcją sinus.
`default_nettype none

module sine_rom (
    input  wire       clk,
    input  wire [5:0] addr,
    output reg  [7:0] data
);
    always @(posedge clk)
        case (addr)
            6'd0 : data <= 8'd3  ;  6'd1 : data <= 8'd9  ;  6'd2 : data <= 8'd16 ;  6'd3 : data <= 8'd22 ;
            6'd4 : data <= 8'd28 ;  6'd5 : data <= 8'd34 ;  6'd6 : data <= 8'd41 ;  6'd7 : data <= 8'd47 ;
            6'd8 : data <= 8'd53 ;  6'd9 : data <= 8'd59 ;  6'd10: data <= 8'd65 ;  6'd11: data <= 8'd71 ;
            6'd12: data <= 8'd77 ;  6'd13: data <= 8'd83 ;  6'd14: data <= 8'd89 ;  6'd15: data <= 8'd95 ;
            6'd16: data <= 8'd100;  6'd17: data <= 8'd106;  6'd18: data <= 8'd112;  6'd19: data <= 8'd117;
            6'd20: data <= 8'd123;  6'd21: data <= 8'd128;  6'd22: data <= 8'd134;  6'd23: data <= 8'd139;
            6'd24: data <= 8'd144;  6'd25: data <= 8'd149;  6'd26: data <= 8'd154;  6'd27: data <= 8'd159;
            6'd28: data <= 8'd164;  6'd29: data <= 8'd169;  6'd30: data <= 8'd174;  6'd31: data <= 8'd178;
            6'd32: data <= 8'd183;  6'd33: data <= 8'd187;  6'd34: data <= 8'd191;  6'd35: data <= 8'd195;
            6'd36: data <= 8'd199;  6'd37: data <= 8'd203;  6'd38: data <= 8'd207;  6'd39: data <= 8'd210;
            6'd40: data <= 8'd214;  6'd41: data <= 8'd217;  6'd42: data <= 8'd220;  6'd43: data <= 8'd223;
            6'd44: data <= 8'd226;  6'd45: data <= 8'd229;  6'd46: data <= 8'd232;  6'd47: data <= 8'd234;
            6'd48: data <= 8'd237;  6'd49: data <= 8'd239;  6'd50: data <= 8'd241;  6'd51: data <= 8'd243;
            6'd52: data <= 8'd245;  6'd53: data <= 8'd247;  6'd54: data <= 8'd248;  6'd55: data <= 8'd249;
            6'd56: data <= 8'd251;  6'd57: data <= 8'd252;  6'd58: data <= 8'd253;  6'd59: data <= 8'd253;
            6'd60: data <= 8'd254;  6'd61: data <= 8'd255;  6'd62: data <= 8'd255;  6'd63: data <= 8'd255;
            default: data <= 8'd0;
        endcase
endmodule

`default_nettype wire
