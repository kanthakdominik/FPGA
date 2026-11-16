-- Sygnalizacja świetlna skrzyżowania: 6 stanów, czasy w impulsach tick, wybór kodowania stanów generikiem.
-- Stany (indeks): 0 NS_G, 1 NS_Y, 2 R1 (wszystkie czerwone), 3 EW_G, 4 EW_Y, 5 R2 (wszystkie czerwone).
-- Bezpieczny automat: stan nielegalny -> err = '1', wszystkie światła czerwone, następny stan R2 (jak po resecie).
-- Wejście upset (XOR do rejestru stanu) symuluje przekłamanie bitu (SEU) w testach; w układzie podłącz zera.
-- Kody stanów są stałymi liczonymi funkcją — nie są „lokalnie statyczne”, więc VHDL nie pozwala użyć ich
-- jako wyborów w case; dekodowanie stanu to łańcuch if/elsif (wybory i tak się wykluczają).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fsm_pkg.all;

entity traffic_fsm is
  generic (
    ENC : natural := 0                                         -- 0 — binarne, 1 — one-hot, 2 — Graya
  );
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    tick  : in  std_logic;
    upset : in  std_logic_vector(state_width(ENC) - 1 downto 0);
    light_ns    : out std_logic_vector(2 downto 0);                  -- (czerwone, żółte, zielone), '1' = świeci
    light_ew    : out std_logic_vector(2 downto 0);
    err   : out std_logic
  );
end entity traffic_fsm;

architecture rtl of traffic_fsm is
  constant SW : positive := state_width(ENC);
  subtype code_t is std_logic_vector(SW - 1 downto 0);
  constant NS_G : code_t := state_code(ENC, 0, SW);
  constant NS_Y : code_t := state_code(ENC, 1, SW);
  constant R1   : code_t := state_code(ENC, 2, SW);
  constant EW_G : code_t := state_code(ENC, 3, SW);
  constant EW_Y : code_t := state_code(ENC, 4, SW);
  constant R2   : code_t := state_code(ENC, 5, SW);

  signal state                : code_t := R2;
  signal state_next           : code_t;
  signal timer, timer_next    : unsigned(1 downto 0) := "00";
begin
  p_next : process (all)
    variable last  : unsigned(1 downto 0);
    variable legal : boolean;
  begin
    light_ns    <= "100";
    light_ew    <= "100";
    last  := "00";
    legal := true;
    if state = NS_G then
      light_ns <= "001";  last := "11";
    elsif state = NS_Y then
      light_ns <= "010";  last := "01";
    elsif state = EW_G then
      light_ew <= "001";  last := "11";
    elsif state = EW_Y then
      light_ew <= "010";  last := "01";
    elsif state /= R1 and state /= R2 then
      legal := false;                                          -- stan nielegalny: wszystko czerwone
    end if;
    err <= '0' when legal else '1';

    state_next <= state;
    timer_next <= timer;
    if not legal then
      state_next <= R2;                                        -- odzyskanie: stan bezpieczny
      timer_next <= "00";
    elsif tick = '1' then
      if timer >= last then                                    -- >= zamiast =: odporne na timer > last po przekłamaniu
        timer_next <= "00";
        if    state = NS_G then state_next <= NS_Y;
        elsif state = NS_Y then state_next <= R1;
        elsif state = R1   then state_next <= EW_G;
        elsif state = EW_G then state_next <= EW_Y;
        elsif state = EW_Y then state_next <= R2;
        else                    state_next <= NS_G;            -- R2
        end if;
      else
        timer_next <= timer + 1;
      end if;
    end if;
  end process p_next;

  p_reg : process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        state <= R2;
        timer <= "00";
      else
        state <= state_next xor upset;
        timer <= timer_next;
      end if;
    end if;
  end process p_reg;
end architecture rtl;
