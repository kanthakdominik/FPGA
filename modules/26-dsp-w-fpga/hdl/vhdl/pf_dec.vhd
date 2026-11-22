-- Decymator FIR przez M = 4 (26.04): liczy tylko co czwartą próbkę wyjściową filtru N = 32, jedną mnożarką
-- w N taktach (struktura wielofazowa w czasie). Próbki w buforze kołowym 64 pozycji; wymaga co najmniej
-- 9 taktów między próbkami we.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.dsp_pkg.all;

entity pf_dec is
  generic (N : positive := 32);
  port (
    clk, rst, we : in  std_logic;
    x            : in  signed(15 downto 0);
    wsp          : in  std_logic_vector(16 * N - 1 downto 0);
    y            : out signed(15 downto 0) := (others => '0');
    y_wazne      : out std_logic := '0'
  );
end entity pf_dec;

architecture rtl of pf_dec is
  type bufor_t is array (0 to 63) of signed(15 downto 0);
  signal bufor       : bufor_t := (others => (others => '0'));
  signal wp, baza    : unsigned(5 downto 0) := (others => '0');
  signal faza        : unsigned(1 downto 0) := (others => '0');
  signal k           : natural range 0 to N - 1 := 0;
  signal mac, koniec : std_logic := '0';
  signal acc         : signed(39 downto 0) := (others => '0');
begin
  process (clk)
    variable xs : signed(15 downto 0);
  begin
    if rising_edge(clk) then
      y_wazne <= '0';
      koniec  <= '0';
      if rst = '1' then
        wp <= (others => '0'); baza <= (others => '0'); faza <= (others => '0');
        k <= 0; mac <= '0'; acc <= (others => '0'); y <= (others => '0');
      else
        if we = '1' then
          bufor(to_integer(wp)) <= x;
          wp   <= wp + 1;
          faza <= faza + 1;
          if faza = 3 then                                           -- co czwarta próbka: start sumy
            baza <= wp;
            k    <= 0;
            acc  <= (others => '0');
            mac  <= '1';
          end if;
        end if;
        if mac = '1' then
          xs  := bufor(to_integer(baza - to_unsigned(k, 6)));
          acc <= acc + resize(wsp_h(wsp, k) * xs, 40);
          if k = N - 1 then
            mac <= '0'; koniec <= '1';
          else
            k <= k + 1;
          end if;
        end if;
        if koniec = '1' then
          y       <= nasyc(zaokr(acc, 15), 16);
          y_wazne <= '1';
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
