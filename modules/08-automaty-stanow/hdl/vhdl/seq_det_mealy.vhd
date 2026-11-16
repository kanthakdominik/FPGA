-- Detektor sekwencji 1011 (z nakładaniem) — automat Mealy'ego, styl dwuprocesowy z typem wyliczeniowym.
-- y = '1' w tym samym takcie, w którym na wejściu jest ostatni bit wzorca.
library ieee;
use ieee.std_logic_1164.all;

entity seq_det_mealy is
  port (
    clk : in  std_logic;
    rst : in  std_logic;
    x   : in  std_logic;
    y   : out std_logic
  );
end entity seq_det_mealy;

architecture rtl of seq_det_mealy is
  type state_t is (S0, S1, S10, S101);
  signal state      : state_t := S0;
  signal state_next : state_t;
begin
  p_reg : process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        state <= S0;
      else
        state <= state_next;
      end if;
    end if;
  end process p_reg;

  p_next : process (all)
  begin
    y <= '0';
    case state is
      when S0   => state_next <= S1 when x = '1' else S0;
      when S1   => state_next <= S1 when x = '1' else S10;
      when S10  => state_next <= S101 when x = '1' else S0;
      when S101 =>
        y          <= x;                                       -- wzorzec kończy się bieżącym bitem
        state_next <= S1 when x = '1' else S10;
    end case;
  end process p_next;
end architecture rtl;
