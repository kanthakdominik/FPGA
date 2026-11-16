// Testbench konwersji RGB -> szarość: przypadki brzegowe i 300 pikseli pseudolosowych we wszystkich trybach.
`timescale 1ns / 1ps

module tb_rgb_to_gray;
    logic [23:0] pix_raw;
    logic [1:0]  mode;
    logic [7:0]  y;

    rgb_to_gray dut (.*);

    int errors = 0;

    task automatic check_pixel(logic [23:0] p);
        int r, g, b, e;
        r = p[23:16]; g = p[15:8]; b = p[7:0];
        for (int md = 0; md < 4; md++) begin
            pix_raw = p; mode = 2'(md); #1;
            case (md)
                0: e = (r + 2 * g + b) / 4;
                1: e = (77 * r + 150 * g + 29 * b) / 256;
                2: e = r;
                default: e = 0;
            endcase
            if (int'(y) != e) begin
                $display("piksel %h, tryb %0d: y=%0d, oczekiwano %0d", p, md, y, e); errors++;
            end
        end
    endtask

    initial begin
        logic [23:0] lfsr = 24'h123456;
        check_pixel(24'h000000);
        check_pixel(24'hFFFFFF);
        check_pixel(24'hFF0000);
        check_pixel(24'h00FF00);
        check_pixel(24'h0000FF);
        repeat (300) begin
            lfsr = lfsr[0] ? ((lfsr >> 1) ^ 24'hE10000) : (lfsr >> 1);   // x^24 + x^23 + x^22 + x^17 + 1
            check_pixel(lfsr);
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
