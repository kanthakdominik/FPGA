-- Eliminacja drgań styków: wyjście zmienia stan dopiero, gdy wejście jest stabilne przez STABLE_CYCLES taktów.
library ieee;
use ieee.std_logic_1164.all;

entity debouncer is
  generic (STABLE_CYCLES : positive := 500000); -- 10 ms przy 50 MHz
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;                    -- synchroniczny
    noisy   : in  std_logic;
    clean   : out std_logic;
    changed : out std_logic                     -- impuls 1 takt przy zmianie clean
  );
end entity debouncer;

architecture rtl of debouncer is
  signal sync    : std_logic_vector(1 downto 0) := "00";
  signal state   : std_logic := '0';
  signal cnt     : natural range 0 to STABLE_CYCLES - 1 := 0;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      sync    <= sync(0) & noisy;
      changed <= '0';
      if rst = '1' then
        state <= '0';
        cnt   <= 0;
      elsif sync(1) = state then
        cnt <= 0;
      elsif cnt = STABLE_CYCLES - 1 then
        state   <= sync(1);
        changed <= '1';
        cnt     <= 0;
      else
        cnt <= cnt + 1;
      end if;
    end if;
  end process;

  clean <= state;
end architecture rtl;
