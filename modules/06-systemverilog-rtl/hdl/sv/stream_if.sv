// Interfejs strumienia z uzgadnianiem valid/ready (jak AXI4-Stream bez pól pobocznych).
// Przesłanie słowa następuje w takcie, w którym valid = 1 i ready = 1.
interface stream_if #(
    parameter int W = 8
);
    logic [W-1:0] data;
    logic         valid;
    logic         ready;

    modport source (output data, output valid, input  ready);   // nadawca
    modport sink   (input  data, input  valid, output ready);   // odbiorca
endinterface
