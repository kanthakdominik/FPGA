-- Źródło obrazu RAW z mozaiką Bayera RGGB (31.05): pasy kolorów, gradient, przesuwany kwadrat; z piksela
-- zostaje składowa miejsca mozaiki. Jak w wersjach Verilog i SystemVerilog.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wzor_bayer is
  generic (W : positive := 640; H : positive := 480);
  port (
    clk, rst   : in  std_logic;
    ruch       : in  std_logic;
    de, hs, vs : in  std_logic;
    x, y       : in  unsigned(11 downto 0);
    nowa_ramka : in  std_logic;
    o_de       : out std_logic := '0';
    o_hs, o_vs : out std_logic := '1';
    raw        : out std_logic_vector(7 downto 0) := (others => '0')
  );
end entity wzor_bayer;

architecture rtl of wzor_bayer is
  constant BOK : positive := W / 8;
  signal kx, ky : natural range 0 to 4095 := 0;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        kx <= 0; ky <= 0;
      elsif nowa_ramka = '1' and ruch = '1' then
        if kx >= W - BOK then kx <= 0; else kx <= kx + 2; end if;
        if ky >= H / 2 - BOK then ky <= 0; else ky <= ky + 1; end if;
      end if;
    end if;
  end process;

  process (clk)
    variable xi, yi, pas : natural;
    variable r, g, b, grad : unsigned(7 downto 0);
    variable r_on, g_on, b_on : boolean;
  begin
    if rising_edge(clk) then
      xi := to_integer(x); yi := to_integer(y);
      pas := ((xi * 8) / W) mod 8;
      grad := to_unsigned(((xi * 256) / W) mod 256, 8);
      r_on := pas = 0 or pas = 1 or pas = 4 or pas = 5;
      g_on := pas <= 3;
      b_on := pas = 0 or pas = 2 or pas = 4 or pas = 6;
      if xi >= kx and xi < kx + BOK and yi >= ky + H / 2 and yi < ky + H / 2 + BOK then
        r := x"FF"; g := x"FF"; b := x"FF";
      elsif yi < H / 2 then
        if r_on then r := to_unsigned(220, 8); else r := to_unsigned(30, 8); end if;
        if g_on then g := to_unsigned(220, 8); else g := to_unsigned(30, 8); end if;
        if b_on then b := to_unsigned(220, 8); else b := to_unsigned(30, 8); end if;
      else
        r := grad; g := grad; b := grad;
      end if;
      o_de <= de; o_hs <= hs; o_vs <= vs;
      if y(0) = '0' and x(0) = '0' then raw <= std_logic_vector(r);
      elsif y(0) = '1' and x(0) = '1' then raw <= std_logic_vector(b);
      else raw <= std_logic_vector(g);
      end if;
    end if;
  end process;
end architecture rtl;
