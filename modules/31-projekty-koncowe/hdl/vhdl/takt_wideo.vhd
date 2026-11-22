-- Generator taktowania wideo (24.01): liczniki poziomy i pionowy, synchronizacja, obszar aktywny.
-- Kolejność w linii i ramce: obszar aktywny, przedsionek (front porch), impuls synchronizacji, tylny próg.
-- Wyjścia rejestrowane i wzajemnie wyrównane. POL = '1' — impuls dodatni. Domyślnie 640×480 przy 60 Hz.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity takt_wideo is
  generic (
    H_AKT  : positive := 640;
    H_FP   : positive := 16;
    H_SYNC : positive := 96;
    H_BP   : positive := 48;
    V_AKT  : positive := 480;
    V_FP   : positive := 10;
    V_SYNC : positive := 2;
    V_BP   : positive := 33;
    H_POL  : std_logic := '0';
    V_POL  : std_logic := '0'
  );
  port (
    clk        : in  std_logic;
    rst        : in  std_logic;
    hs         : out std_logic := not H_POL;
    vs         : out std_logic := not V_POL;
    de         : out std_logic := '0';
    x          : out unsigned(11 downto 0) := (others => '0');
    y          : out unsigned(11 downto 0) := (others => '0');
    nowa_ramka : out std_logic := '0'
  );
end entity takt_wideo;

architecture rtl of takt_wideo is
  constant H_TOT : natural := H_AKT + H_FP + H_SYNC + H_BP;
  constant V_TOT : natural := V_AKT + V_FP + V_SYNC + V_BP;
  signal hc : natural range 0 to H_TOT - 1 := 0;
  signal vc : natural range 0 to V_TOT - 1 := 0;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        hc <= 0; vc <= 0;
        hs <= not H_POL; vs <= not V_POL; de <= '0';
        x <= (others => '0'); y <= (others => '0'); nowa_ramka <= '0';
      else
        if hc = H_TOT - 1 then
          hc <= 0;
          if vc = V_TOT - 1 then vc <= 0; else vc <= vc + 1; end if;
        else
          hc <= hc + 1;
        end if;
        if hc < H_AKT and vc < V_AKT then de <= '1'; else de <= '0'; end if;
        if hc >= H_AKT + H_FP and hc < H_AKT + H_FP + H_SYNC then hs <= H_POL; else hs <= not H_POL; end if;
        if vc >= V_AKT + V_FP and vc < V_AKT + V_FP + V_SYNC then vs <= V_POL; else vs <= not V_POL; end if;
        x <= to_unsigned(hc, 12);
        y <= to_unsigned(vc, 12);
        if hc = 0 and vc = 0 then nowa_ramka <= '1'; else nowa_ramka <= '0'; end if;
      end if;
    end if;
  end process;
end architecture rtl;
