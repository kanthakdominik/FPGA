-- Wyrównanie danych pamięci RV32I (27.07): zapis — powielenie bajtu/półsłowa na pasy i maska bajtów;
-- odczyt — wybór pasa i rozszerzenie znaku (LB, LH) albo zerami (LBU, LHU).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rv_wyrownanie is
  port (
    z_f3   : in  std_logic_vector(2 downto 0);
    z_adr  : in  std_logic_vector(1 downto 0);
    z_dane : in  std_logic_vector(31 downto 0);
    z_wy   : out std_logic_vector(31 downto 0);
    z_strb : out std_logic_vector(3 downto 0);
    o_f3   : in  std_logic_vector(2 downto 0);
    o_adr  : in  std_logic_vector(1 downto 0);
    o_dane : in  std_logic_vector(31 downto 0);
    o_wy   : out std_logic_vector(31 downto 0)
  );
end entity rv_wyrownanie;

architecture rtl of rv_wyrownanie is
begin
  process (all)
  begin
    case z_f3(1 downto 0) is
      when "00" =>
        z_wy   <= z_dane(7 downto 0) & z_dane(7 downto 0) & z_dane(7 downto 0) & z_dane(7 downto 0);
        z_strb <= std_logic_vector(shift_left(to_unsigned(1, 4), to_integer(unsigned(z_adr))));
      when "01" =>
        z_wy   <= z_dane(15 downto 0) & z_dane(15 downto 0);
        z_strb <= "1100" when z_adr(1) = '1' else "0011";
      when others =>
        z_wy   <= z_dane;
        z_strb <= "1111";
    end case;
  end process;

  process (all)
    variable p : std_logic_vector(31 downto 0);
  begin
    p := std_logic_vector(shift_right(unsigned(o_dane), 8 * to_integer(unsigned(o_adr))));
    case o_f3 is
      when "000"  => o_wy <= std_logic_vector(resize(signed(p(7 downto 0)), 32));
      when "001"  => o_wy <= std_logic_vector(resize(signed(p(15 downto 0)), 32));
      when "100"  => o_wy <= std_logic_vector(resize(unsigned(p(7 downto 0)), 32));
      when "101"  => o_wy <= std_logic_vector(resize(unsigned(p(15 downto 0)), 32));
      when others => o_wy <= o_dane;
    end case;
  end process;
end architecture rtl;
