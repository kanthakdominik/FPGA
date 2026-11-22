-- Sterownik przełączenia obrazu w MAX 10 (29.02): master Avalon-MM dla Dual Configuration Intel FPGA IP.
-- start + obraz + obraz_ok: zapis offset 1 = (obraz, overwrite = 1), odczekanie CZAS taktów (rdzeń zajęty
-- najwyżej 531 taktów), zapis offset 0 = 1 (rekonfiguracja). obraz_ok = '0' -> odmowa. pies — zapis offset 0,
-- bit 1 (zerowanie licznika nadzorującego).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity aktualizacja is
  generic (CZAS : positive := 600);
  port (
    clk, rst, start, obraz, obraz_ok, pies : in std_logic;
    av_address   : out std_logic_vector(2 downto 0) := "000";
    av_write     : out std_logic := '0';
    av_writedata : out std_logic_vector(31 downto 0) := (others => '0');
    av_read      : out std_logic;
    zajety       : out std_logic;
    odmowa       : out std_logic := '0';
    wyzwolono    : out std_logic := '0'
  );
end entity aktualizacja;

architecture rtl of aktualizacja is
  type stan_t is (S_BEZCZ, S_CZEKAJ, S_KONIEC);
  signal stan : stan_t := S_BEZCZ;
  signal licz : natural range 0 to CZAS := 0;
begin
  av_read <= '0';
  zajety  <= '0' when stan = S_BEZCZ else '1';

  process (clk)
  begin
    if rising_edge(clk) then
      av_write  <= '0';
      odmowa    <= '0';
      wyzwolono <= '0';
      if rst = '1' then
        stan <= S_BEZCZ; licz <= 0; av_address <= "000"; av_writedata <= (others => '0');
      else
        case stan is
          when S_BEZCZ =>
            if start = '1' and obraz_ok = '0' then
              odmowa <= '1';
            elsif start = '1' then
              av_address   <= "001";
              av_writedata <= (31 downto 2 => '0') & obraz & '1';
              av_write     <= '1';
              licz         <= CZAS;
              stan         <= S_CZEKAJ;
            elsif pies = '1' then
              av_address   <= "000";
              av_writedata <= x"00000002";
              av_write     <= '1';
            end if;
          when S_CZEKAJ =>
            if licz = 0 then
              av_address   <= "000";
              av_writedata <= x"00000001";
              av_write     <= '1';
              wyzwolono    <= '1';
              stan         <= S_KONIEC;
            else
              licz <= licz - 1;
            end if;
          when S_KONIEC =>
            null;                                          -- układ się rekonfiguruje
        end case;
      end if;
    end if;
  end process;
end architecture rtl;
