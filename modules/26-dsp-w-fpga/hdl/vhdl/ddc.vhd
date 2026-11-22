-- Przemiana w dół (DDC, 26.06): x · cos i x · (-sin) z NCO (nośna ftw) daje I i Q pasma podstawowego
-- (iloczyny zaokrąglone do 16 bitów), potem decymacja CIC przez 8 w każdej gałęzi. Próbka x opóźniona
-- o 2 takty, żeby spotkać się z próbką NCO dla tej samej fazy.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.dsp_pkg.all;

entity ddc is
  port (
    clk, rst, we : in  std_logic;
    x            : in  signed(15 downto 0);
    ftw          : in  unsigned(31 downto 0);
    i_wy, q_wy   : out signed(15 downto 0);
    wy_wazne     : out std_logic
  );
end entity ddc;

architecture rtl of ddc is
  signal s, c                 : signed(15 downto 0);
  signal nw, mw               : std_logic := '0';
  signal x1, x2, m_i, m_q     : signed(15 downto 0) := (others => '0');
begin
  u_nco : entity work.nco port map (clk => clk, rst => rst, we => we, ftw => ftw, sin_o => s, cos_o => c, wazne => nw);

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        x1 <= (others => '0'); x2 <= (others => '0'); m_i <= (others => '0'); m_q <= (others => '0'); mw <= '0';
      else
        x1  <= x;
        x2  <= x1;
        mw  <= nw;
        m_i <= nasyc(zaokr(resize(x2 * c, 32), 15), 16);
        m_q <= nasyc(zaokr(-resize(x2 * s, 32), 15), 16);
      end if;
    end if;
  end process;

  u_ci : entity work.cic_dec generic map (R => 8)
    port map (clk => clk, rst => rst, we => mw, x => m_i, y => i_wy, y_wazne => wy_wazne);
  u_cq : entity work.cic_dec generic map (R => 8)
    port map (clk => clk, rst => rst, we => mw, x => m_q, y => q_wy, y_wazne => open);
end architecture rtl;
