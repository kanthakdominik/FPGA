-- Konwersja piksela RGB na odcień szarości — rekord i typ wyliczeniowy z pakietu img_pkg.
-- Porty jako std_logic_vector (zgodne z wersjami Verilog i SV); typy użytkownika wewnątrz.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.img_pkg.all;

entity rgb_to_gray is
  port (
    pix_raw : in  std_logic_vector(23 downto 0);
    mode    : in  std_logic_vector(1 downto 0);
    y       : out std_logic_vector(7 downto 0)
  );
end entity rgb_to_gray;

architecture rtl of rgb_to_gray is
  signal pix : rgb_t;
  signal sum : unsigned(9 downto 0);
begin
  pix <= to_rgb(pix_raw);
  sum <= resize(pix.r, 10) + shift_left(resize(pix.g, 10), 1) + resize(pix.b, 10);

  process (all)
  begin
    case mode is
      when "00"   => y <= std_logic_vector(sum(9 downto 2));
      when "01"   => y <= std_logic_vector(luma(pix));
      when "10"   => y <= std_logic_vector(pix.r);
      when others => y <= (others => '0');
    end case;
  end process;
end architecture rtl;
