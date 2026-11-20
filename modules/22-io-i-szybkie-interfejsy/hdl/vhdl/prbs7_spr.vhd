-- Samosynchronizujący się kontroler PRBS7 (22.02, 22.03): każdy bit porównywany z przewidywaniem
-- z 7 bitów poprzednich; po 7 bitach zsynchronizowany niezależnie od fazy.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity prbs7_spr is
  generic (N : positive := 2);
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    en    : in  std_logic;
    d     : in  std_logic_vector(N - 1 downto 0);          -- bit najstarszy odebrany pierwszy
    bledy : out std_logic_vector(15 downto 0);
    synch : out std_logic
  );
end entity prbs7_spr;

architecture rtl of prbs7_spr is
  signal s  : std_logic_vector(6 downto 0) := (others => '0');
  signal nb : natural range 0 to 7 + N := 0;
  signal bl : unsigned(15 downto 0) := (others => '0');
  signal sy : std_logic := '0';
begin
  bledy <= std_logic_vector(bl);
  synch <= sy;

  process (clk)
    variable t : std_logic_vector(6 downto 0);
    variable e : natural;
  begin
    if rising_edge(clk) then
      t := s;
      e := 0;
      for i in N - 1 downto 0 loop
        if d(i) /= (t(6) xor t(5)) then e := e + 1; end if;
        t := t(5 downto 0) & d(i);
      end loop;
      if rst = '1' then
        s  <= (others => '0');
        nb <= 0;
        bl <= (others => '0');
        sy <= '0';
      elsif en = '1' then
        s <= t;
        if sy = '0' then
          nb <= nb + N;
          if nb + N >= 7 then sy <= '1'; end if;
        elsif e /= 0 and bl < 16#FFF0# then
          bl <= bl + e;
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
