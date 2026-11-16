-- Kody stanów dla automatów z wybieranym kodowaniem: 0 — binarne, 1 — one-hot, 2 — Graya.
-- Funkcje liczone przy elaboracji (stałe), więc nie dają logiki.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package fsm_pkg is
  -- szerokość rejestru stanu dla automatu o 6 stanach
  function state_width(enc : natural) return positive;
  -- kod stanu o indeksie i na w bitach
  function state_code(enc : natural; i : natural; w : positive) return std_logic_vector;
end package fsm_pkg;

package body fsm_pkg is
  function state_width(enc : natural) return positive is
  begin
    if enc = 1 then
      return 6;
    end if;
    return 3;
  end function state_width;

  function state_code(enc : natural; i : natural; w : positive) return std_logic_vector is
    variable u : unsigned(w - 1 downto 0);
  begin
    if enc = 1 then
      u := shift_left(to_unsigned(1, w), i);                   -- one-hot
    elsif enc = 2 then
      u := to_unsigned(i, w) xor shift_right(to_unsigned(i, w), 1);   -- Graya
    else
      u := to_unsigned(i, w);                                  -- binarne
    end if;
    return std_logic_vector(u);
  end function state_code;
end package body fsm_pkg;
