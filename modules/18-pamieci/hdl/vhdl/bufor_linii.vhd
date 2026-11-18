-- Bufor dwóch linii obrazu (18.04): kolumna trzech pikseli (bieżąca linia i dwie poprzednie) dla każdego
-- piksela strumienia rastrowego. Jedna pamięć SZER x 2W: odczyt adresu x w takcie piksela, zapis
-- {linia-1, bieżący} pod ten sam adres w takcie następnym; przed dwiema pierwszymi liniami zera.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bufor_linii is
  generic (
    W    : positive := 8;
    SZER : positive := 16
  );
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    in_valid  : in  std_logic;
    piksel    : in  std_logic_vector(W - 1 downto 0);
    out_valid : out std_logic;
    p0        : out std_logic_vector(W - 1 downto 0);
    p1        : out std_logic_vector(W - 1 downto 0);
    p2        : out std_logic_vector(W - 1 downto 0)
  );
end entity bufor_linii;

architecture rtl of bufor_linii is
  type mem_t is array (0 to SZER - 1) of std_logic_vector(2 * W - 1 downto 0);
  signal mem      : mem_t := (others => (others => '0'));
  signal x, x_d   : natural range 0 to SZER - 1 := 0;
  signal piksel_d : std_logic_vector(W - 1 downto 0);
  signal stare    : std_logic_vector(2 * W - 1 downto 0);
  signal ov       : std_logic := '0';
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if in_valid = '1' then
        stare <= mem(x);
      end if;
      if ov = '1' then
        mem(x_d) <= stare(W - 1 downto 0) & piksel_d;
      end if;
      if rst = '1' then
        x  <= 0;
        ov <= '0';
      else
        ov <= in_valid;
        if in_valid = '1' then
          x_d      <= x;
          piksel_d <= piksel;
          if x = SZER - 1 then
            x <= 0;
          else
            x <= x + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  out_valid <= ov;
  p0        <= piksel_d;
  p1        <= stare(W - 1 downto 0);
  p2        <= stare(2 * W - 1 downto W);
end architecture rtl;
