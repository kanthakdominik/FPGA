-- Rysowanie odcinka algorytmem Bresenhama (24.03), wszystkie oktanty, błąd e = dx + dy (dy ≤ 0): jeden punkt
-- na takt. start (przy gotowy = '1') przyjmuje końce; punkty na (px, py) z pwazny; dalej = '0' wstrzymuje;
-- koniec — razem z ostatnim punktem.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity linia_bres is
  port (
    clk    : in  std_logic;
    rst    : in  std_logic;
    start  : in  std_logic;
    x0, y0 : in  unsigned(11 downto 0);
    x1, y1 : in  unsigned(11 downto 0);
    dalej  : in  std_logic;
    gotowy : out std_logic := '1';
    px, py : out unsigned(11 downto 0) := (others => '0');
    pwazny : out std_logic := '0';
    koniec : out std_logic := '0'
  );
end entity linia_bres;

architecture rtl of linia_bres is
  signal dx, dy, e : integer range -8192 to 8191 := 0;
  signal xp, yp, xk, yk : unsigned(11 downto 0) := (others => '0');
  signal sx, sy, praca : std_logic := '0';
begin
  px <= xp;
  py <= yp;

  process (clk)
    variable e2     : integer range -16384 to 16383;
    variable nx, ny : unsigned(11 downto 0);
    variable ne     : integer range -16384 to 16383;
    variable adx, ady : integer range 0 to 4095;
  begin
    if rising_edge(clk) then
      if rst = '1' then
        gotowy <= '1'; praca <= '0'; pwazny <= '0'; koniec <= '0';
        xp <= (others => '0'); yp <= (others => '0'); xk <= (others => '0'); yk <= (others => '0');
        dx <= 0; dy <= 0; e <= 0; sx <= '0'; sy <= '0';
      elsif praca = '0' then
        pwazny <= '0';
        koniec <= '0';
        if start = '1' then
          adx := abs (to_integer(x1) - to_integer(x0));
          ady := abs (to_integer(y1) - to_integer(y0));
          xp <= x0; yp <= y0; xk <= x1; yk <= y1;
          if x1 < x0 then sx <= '1'; else sx <= '0'; end if;
          if y1 < y0 then sy <= '1'; else sy <= '0'; end if;
          dx <= adx;
          dy <= -ady;
          e  <= adx - ady;
          praca  <= '1';
          gotowy <= '0';
          pwazny <= '1';
          if x0 = x1 and y0 = y1 then koniec <= '1'; else koniec <= '0'; end if;
        end if;
      elsif dalej = '1' then
        if xp = xk and yp = yk then                        -- ostatni punkt właśnie przyjęty
          praca <= '0'; gotowy <= '1'; pwazny <= '0'; koniec <= '0';
        else
          e2 := 2 * e;
          nx := xp; ny := yp; ne := e;
          if e2 >= dy then
            ne := ne + dy;
            if sx = '1' then nx := xp - 1; else nx := xp + 1; end if;
          end if;
          if e2 <= dx then
            ne := ne + dx;
            if sy = '1' then ny := yp - 1; else ny := yp + 1; end if;
          end if;
          xp <= nx; yp <= ny; e <= ne;
          pwazny <= '1';
          if nx = xk and ny = yk then koniec <= '1'; else koniec <= '0'; end if;
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
