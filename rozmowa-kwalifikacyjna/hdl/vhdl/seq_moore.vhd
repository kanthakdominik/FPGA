-- Zadanie 4a: detektor sekwencji 1011 (z nakładaniem), automat Moore'a — det takt po ostatnim bicie wzorca.
library ieee;
use ieee.std_logic_1164.all;

entity seq_moore is
  port (
    clk : in  std_logic;
    rst : in  std_logic;
    x   : in  std_logic;
    det : out std_logic
  );
end entity;

architecture rtl of seq_moore is
  type state_t is (ST_S0, ST_S1, ST_S2, ST_S3, ST_S4);
  signal st, st_next : state_t := ST_S0;
begin
  process (st, x)
  begin
    case st is
      when ST_S0 => if x = '1' then st_next <= ST_S1; else st_next <= ST_S0; end if;
      when ST_S1 => if x = '1' then st_next <= ST_S1; else st_next <= ST_S2; end if;
      when ST_S2 => if x = '1' then st_next <= ST_S3; else st_next <= ST_S0; end if;
      when ST_S3 => if x = '1' then st_next <= ST_S4; else st_next <= ST_S2; end if;
      when ST_S4 => if x = '1' then st_next <= ST_S1; else st_next <= ST_S2; end if;
    end case;
  end process;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then st <= ST_S0; else st <= st_next; end if;
    end if;
  end process;

  det <= '1' when st = ST_S4 else '0';
end architecture;
