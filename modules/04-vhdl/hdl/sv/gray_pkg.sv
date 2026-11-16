// Pakiet z funkcjami do kodu Graya i parzystości.
// Funkcje działają na słowach 32-bitowych; krótsze słowa uzupełnia się zerami z przodu,
// co nie zmienia wyniku na młodszych bitach.
package gray_pkg;
    function automatic logic [31:0] bin2gray(input logic [31:0] b);
        return b ^ (b >> 1);
    endfunction

    function automatic logic [31:0] gray2bin(input logic [31:0] g);
        logic [31:0] b;
        b[31] = g[31];
        for (int i = 30; i >= 0; i--)
            b[i] = b[i+1] ^ g[i];                  // łańcuch XOR od najstarszego bitu
        return b;
    endfunction

    function automatic logic parity(input logic [31:0] v);
        return ^v;
    endfunction
endpackage
