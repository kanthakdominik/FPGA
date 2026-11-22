-- Zadanie 5: arbiter round-robin dla N zgłoszeń (przydział kombinacyjny, szukanie od ptr, ptr za zwycięzcę).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rr_arbiter is
  generic (N : positive := 4);
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    req   : in  std_logic_vector(N - 1 downto 0);
    grant : out std_logic_vector(N - 1 downto 0)
  );
end entity;

architecture rtl of rr_arbiter is
  signal ptr   : natural range 0 to N - 1 := 0;
  signal win   : natural range 0 to N - 1;
  signal found : std_logic;
begin
  process (req, ptr)
    variable idx : natural range 0 to N - 1;
    variable f   : boolean;
  begin
    f   := false;
    win <= ptr;
    for i in 0 to N - 1 loop
      idx := (ptr + i) mod N;
      if not f and req(idx) = '1' then
        f   := true;
        win <= idx;
      end if;
    end loop;
    if f then found <= '1'; else found <= '0'; end if;
  end process;

  process (win, found)
  begin
    grant <= (others => '0');
    if found = '1' then grant(win) <= '1'; end if;
  end process;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        ptr <= 0;
      elsif found = '1' then
        ptr <= (win + 1) mod N;
      end if;
    end if;
  end process;
end architecture;
