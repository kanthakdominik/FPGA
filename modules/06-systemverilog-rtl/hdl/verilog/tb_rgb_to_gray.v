// Testbench konwersji RGB -> szarość: przypadki brzegowe i 300 pikseli pseudolosowych we wszystkich trybach.
`default_nettype none
`timescale 1ns / 1ps

module tb_rgb_to_gray;
    reg  [23:0] pix_raw;
    reg  [1:0]  mode;
    wire [7:0]  y;

    rgb_to_gray dut (.pix_raw(pix_raw), .mode(mode), .y(y));

    integer errors = 0, n, md, r, g, b, e;
    reg [23:0] lfsr = 24'h123456;

    task check_pixel(input [23:0] p);
        begin
            r = p[23:16]; g = p[15:8]; b = p[7:0];
            for (md = 0; md < 4; md = md + 1) begin
                pix_raw = p; mode = md; #1;
                case (md)
                    0: e = (r + 2 * g + b) / 4;
                    1: e = (77 * r + 150 * g + 29 * b) / 256;
                    2: e = r;
                    default: e = 0;
                endcase
                if (y !== e) begin
                    $display("piksel %h, tryb %0d: y=%0d, oczekiwano %0d", p, md, y, e); errors = errors + 1;
                end
            end
        end
    endtask

    initial begin
        check_pixel(24'h000000);
        check_pixel(24'hFFFFFF);
        check_pixel(24'hFF0000);
        check_pixel(24'h00FF00);
        check_pixel(24'h0000FF);
        for (n = 0; n < 300; n = n + 1) begin
            lfsr = lfsr[0] ? ((lfsr >> 1) ^ 24'hE10000) : (lfsr >> 1);
            check_pixel(lfsr);
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
