-- Detektor sekwencji 1011 (z nakładaniem) — automat Moore'a, styl dwuprocesowy z typem wyliczeniowym.
-- y = '1' w takcie PO ostatnim bicie wzorca.
library ieee;
use ieee.std_logic_1164.all;

entity seq_det_moore is
  port (
    clk : in  std_logic;
    rst : in  std_logic;
    x   : in  std_logic;
    y   : out std_logic
  );
end entity seq_det_moore;

architecture rtl of seq_det_moore is
  type state_t is (S0, S1, S10, S101, S1011);           -- kodowanie wybiera syntezator
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
    state_next <= state;
    y          <= '0';
    case state is
      when S0    => state_next <= S1    when x = '1' else S0;
      when S1    => state_next <= S1    when x = '1' else S10;
      when S10   => state_next <= S101  when x = '1' else S0;
      when S101  => state_next <= S1011 when x = '1' else S10;
      when S1011 =>
        y          <= '1';                                     -- wyjście zależy tylko od stanu
        state_next <= S1 when x = '1' else S10;               -- nakładanie: końcówka „1” albo „10”
    end case;
  end process p_next;
end architecture rtl;
