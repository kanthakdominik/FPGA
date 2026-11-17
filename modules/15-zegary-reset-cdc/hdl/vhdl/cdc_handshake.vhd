-- Przesyłanie słowa między domenami z potwierdzeniem (protokół dwufazowy, 15.04).
-- Źródło: send = '1' (gdy ready) zapisuje słowo do data_r i zmienia req. Słowo NIE jest synchronizowane -
-- jest stałe, dopóki trwa transakcja; synchronizowany jest tylko req (sync_bit). Cel: zmiana req ->
-- zapis data_r do dst_data i impuls dst_valid, potem ack = req wraca do źródła. ready = (req = ack_src).
-- Ścieżka data_r -> dst_data jest więc wielotaktowa (zasada MCP): w SDC set_max_delay / set_false_path.
library ieee;
use ieee.std_logic_1164.all;

entity cdc_handshake is
  generic (
    W      : positive := 8;
    STAGES : positive := 2
  );
  port (
    clk_src   : in  std_logic;
    rst_src   : in  std_logic;
    send      : in  std_logic;               -- ignorowane, gdy ready = '0'
    src_data  : in  std_logic_vector(W - 1 downto 0);
    ready     : out std_logic;
    clk_dst   : in  std_logic;
    rst_dst   : in  std_logic;
    dst_valid : out std_logic;
    dst_data  : out std_logic_vector(W - 1 downto 0)
  );
end entity cdc_handshake;

architecture rtl of cdc_handshake is
  signal req, ack            : std_logic := '0';
  signal data_r              : std_logic_vector(W - 1 downto 0) := (others => '0');
  signal req_v, req_dst_v    : std_logic_vector(0 downto 0);
  signal ack_v, ack_src_v    : std_logic_vector(0 downto 0);
  signal ready_i             : std_logic;
begin
  process (clk_src)
  begin
    if rising_edge(clk_src) then
      if rst_src = '1' then
        req <= '0';
      elsif send = '1' and ready_i = '1' then
        data_r <= src_data;
        req    <= not req;
      end if;
    end if;
  end process;
  ready_i <= not (req xor ack_src_v(0));
  ready   <= ready_i;

  req_v(0) <= req;
  u_sync_req : entity work.sync_bit
    generic map (STAGES => STAGES, W => 1)
    port map (clk => clk_dst, d => req_v, q => req_dst_v);

  process (clk_dst)
  begin
    if rising_edge(clk_dst) then
      dst_valid <= '0';
      if rst_dst = '1' then
        ack <= '0';
      elsif req_dst_v(0) /= ack then
        dst_data  <= data_r;                 -- data_r stałe od co najmniej STAGES taktów clk_dst
        dst_valid <= '1';
        ack       <= req_dst_v(0);
      end if;
    end if;
  end process;

  ack_v(0) <= ack;
  u_sync_ack : entity work.sync_bit
    generic map (STAGES => STAGES, W => 1)
    port map (clk => clk_src, d => ack_v, q => ack_src_v);
end architecture rtl;
