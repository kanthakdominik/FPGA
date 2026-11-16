-- Linia opóźniająca o DEPTH taktów zbudowana z rejestrów dff_reg (for-generate),
-- z przypadkiem szczególnym DEPTH = 0 (if-generate: zwykłe połączenie).
library ieee;
use ieee.std_logic_1164.all;

entity pipe_delay is
  generic (
    W     : positive := 8;
    DEPTH : natural  := 3
  );
  port (
    clk : in  std_logic;
    x   : in  std_logic_vector(W - 1 downto 0);
    y   : out std_logic_vector(W - 1 downto 0)
  );
end entity pipe_delay;

architecture structural of pipe_delay is
  -- deklaracja komponentu: styl klasyczny (VHDL-87/93); alternatywa to "entity work.dff_reg" bez deklaracji
  component dff_reg is
    generic (W : positive);
    port (
      clk : in  std_logic;
      d   : in  std_logic_vector(W - 1 downto 0);
      q   : out std_logic_vector(W - 1 downto 0)
    );
  end component dff_reg;
begin
  g_wire : if DEPTH = 0 generate
    y <= x;
  end generate g_wire;

  g_regs : if DEPTH > 0 generate
    type stage_array is array (0 to DEPTH) of std_logic_vector(W - 1 downto 0);
    signal stage : stage_array;              -- stage(0) = wejście, stage(DEPTH) = wyjście
  begin
    stage(0) <= x;

    g_stage : for i in 0 to DEPTH - 1 generate
      u_reg : component dff_reg
        generic map (W => W)
        port map (clk => clk, d => stage(i), q => stage(i + 1));
    end generate g_stage;

    y <= stage(DEPTH);
  end generate g_regs;
end architecture structural;
