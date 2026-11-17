-- Iloczyn skalarny czterech par liczb 8-bitowych bez znaku - wersja szeregowa (16.02):
-- jedna mnożarka i akumulator, cztery takty na wynik; start przyjmowany, gdy ready = '1'
-- (także w ostatnim takcie poprzedniego obliczenia).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity iloczyn_szer is
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    start : in  std_logic;
    a     : in  std_logic_vector(31 downto 0);
    b     : in  std_logic_vector(31 downto 0);
    ready : out std_logic;
    done  : out std_logic;
    y     : out std_logic_vector(17 downto 0)
  );
end entity iloczyn_szer;

architecture rtl of iloczyn_szer is
  signal a_r, b_r     : std_logic_vector(31 downto 0);
  signal idx          : unsigned(1 downto 0) := (others => '0');
  signal busy, done_r : std_logic := '0';
  signal last, rdy    : std_logic;
  signal acc          : unsigned(17 downto 0);
  signal prod         : unsigned(15 downto 0);
  signal ma, mb       : unsigned(7 downto 0);
begin
  -- jedna mnożarka: argumenty wybierane multiplekserem według idx
  ma   <= unsigned(a_r(8 * to_integer(idx) + 7 downto 8 * to_integer(idx)));
  mb   <= unsigned(b_r(8 * to_integer(idx) + 7 downto 8 * to_integer(idx)));
  prod <= ma * mb;
  last <= '1' when busy = '1' and idx = 3 else '0';
  rdy  <= (not busy) or last;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        busy   <= '0';
        done_r <= '0';
        idx    <= (others => '0');
      else
        done_r <= last;
        if busy = '1' then
          idx <= idx + 1;
        end if;
        if start = '1' and rdy = '1' then
          busy <= '1';
          idx  <= (others => '0');
        elsif last = '1' then
          busy <= '0';
        end if;
      end if;
      if start = '1' and rdy = '1' then
        a_r <= a;
        b_r <= b;
      end if;
      if busy = '1' then
        if idx = 0 then
          acc <= resize(prod, 18);
        else
          acc <= acc + resize(prod, 18);
        end if;
      end if;
      if last = '1' then
        y <= std_logic_vector(acc + resize(prod, 18));
      end if;
    end if;
  end process;

  ready <= rdy;
  done  <= done_r;
end architecture rtl;
