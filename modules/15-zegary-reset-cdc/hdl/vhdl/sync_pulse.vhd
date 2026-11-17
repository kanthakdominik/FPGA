-- Synchronizator impulsu przez przełącznik (toggle), 15.03: impuls src_pulse (1 takt clk_src) zmienia stan
-- przerzutnika tgl; poziom tgl przechodzi przez sync_bit, a zmiana stanu w domenie docelowej daje impuls
-- dst_pulse (1 takt clk_dst). Kolejny impuls wolno podać dopiero, gdy poprzedni dotarł: busy = '1' przez czas
-- przejścia tam i z powrotem (potwierdzenie zsynchronizowane z powrotem do clk_src).
library ieee;
use ieee.std_logic_1164.all;

entity sync_pulse is
  generic (
    STAGES : positive := 2
  );
  port (
    clk_src   : in  std_logic;
    rst_src   : in  std_logic;
    src_pulse : in  std_logic;               -- ignorowany, gdy busy
    busy      : out std_logic;
    clk_dst   : in  std_logic;
    rst_dst   : in  std_logic;
    dst_pulse : out std_logic
  );
end entity sync_pulse;

architecture rtl of sync_pulse is
  signal tgl, tgl_dst_d    : std_logic := '0';
  signal tgl_v, tgl_dst_v  : std_logic_vector(0 downto 0);
  signal ack_v, ack_src_v  : std_logic_vector(0 downto 0);
  signal busy_i            : std_logic;
begin
  process (clk_src)
  begin
    if rising_edge(clk_src) then
      if rst_src = '1' then
        tgl <= '0';
      elsif src_pulse = '1' and busy_i = '0' then
        tgl <= not tgl;
      end if;
    end if;
  end process;

  tgl_v(0) <= tgl;
  u_sync_dst : entity work.sync_bit
    generic map (STAGES => STAGES, W => 1)
    port map (clk => clk_dst, d => tgl_v, q => tgl_dst_v);

  process (clk_dst)
  begin
    if rising_edge(clk_dst) then
      if rst_dst = '1' then
        tgl_dst_d <= '0';
        dst_pulse <= '0';
      else
        tgl_dst_d <= tgl_dst_v(0);
        dst_pulse <= tgl_dst_v(0) xor tgl_dst_d;
      end if;
    end if;
  end process;

  ack_v(0) <= tgl_dst_d;
  u_sync_ack : entity work.sync_bit
    generic map (STAGES => STAGES, W => 1)
    port map (clk => clk_src, d => ack_v, q => ack_src_v);

  busy_i <= tgl xor ack_src_v(0);
  busy   <= busy_i;
end architecture rtl;
