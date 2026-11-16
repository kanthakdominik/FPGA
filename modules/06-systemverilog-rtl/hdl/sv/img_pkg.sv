// Pakiet typów i funkcji przetwarzania obrazu, wspólny dla modułów 06.02 i 06.03.
package img_pkg;
    // piksel RGB 8:8:8 jako struktura spakowana: r w bitach [23:16], g [15:8], b [7:0]
    typedef struct packed {
        logic [7:0] r;
        logic [7:0] g;
        logic [7:0] b;
    } rgb_t;

    // ten sam piksel widziany jako surowe 24 bity albo jako struktura
    typedef union packed {
        logic [23:0] raw;
        rgb_t        c;
    } pixel_u;

    typedef enum logic [1:0] {
        GRAY_AVG  = 2'd0,                          // (r + 2g + b) / 4
        GRAY_LUMA = 2'd1,                          // (77r + 150g + 29b) / 256, przybliżenie ITU-R BT.601
        GRAY_RED  = 2'd2                           // tylko składowa czerwona
    } gray_mode_t;

    function automatic logic [7:0] luma(rgb_t p);
        logic [15:0] s;
        s = 16'd77 * p.r + 16'd150 * p.g + 16'd29 * p.b;
        return s[15:8];
    endfunction
endpackage
