// Konwersja piksela RGB na odcień szarości — struktura, unia i typ wyliczeniowy z pakietu img_pkg.
module rgb_to_gray
    import img_pkg::*;
(
    input  logic [23:0] pix_raw,                   // surowe bity, np. z magistrali
    input  logic [1:0]  mode,
    output logic [7:0]  y
);
    pixel_u     pix;
    gray_mode_t m;
    logic [9:0] sum;

    assign pix.raw = pix_raw;                      // te same bity, dostęp przez pix.c.r, pix.c.g, pix.c.b
    assign m       = gray_mode_t'(mode);           // rzutowanie na typ wyliczeniowy
    assign sum     = 10'(pix.c.r) + 10'(pix.c.g) * 2 + 10'(pix.c.b);

    always_comb begin
        case (m)
            GRAY_AVG:  y = sum[9:2];
            GRAY_LUMA: y = luma(pix.c);
            GRAY_RED:  y = pix.c.r;
            default:   y = '0;                     // kod 3 nie jest wartością typu
        endcase
    end
endmodule
