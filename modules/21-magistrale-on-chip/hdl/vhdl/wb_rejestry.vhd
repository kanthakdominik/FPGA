-- Slave Wishbone B4, tryb potokowy (21.04), nad rejestry_rdzen: STALL = 0, ACK albo ERR (adres spoza mapy)
-- w takcie po żądaniu.
library ieee;
use ieee.std_logic_1164.all;

entity wb_rejestry is
  generic (ID : std_logic_vector(31 downto 0) := x"21020001");
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    cyc   : in  std_logic;
    stb   : in  std_logic;
    we    : in  std_logic;
    adr   : in  std_logic_vector(3 downto 0);
    dat_i : in  std_logic_vector(31 downto 0);
    sel   : in  std_logic_vector(3 downto 0);
    dat_o : out std_logic_vector(31 downto 0);
    ack   : out std_logic;
    err   : out std_logic;
    stall : out std_logic;
    ster  : out std_logic_vector(31 downto 0);
    stan  : in  std_logic_vector(31 downto 0);
    zdarz : in  std_logic_vector(7 downto 0);
    irq   : out std_logic
  );
end entity wb_rejestry;

architecture rtl of wb_rejestry is
  signal zad, odc_blad : std_logic;
  signal odc_dane      : std_logic_vector(31 downto 0);
begin
  zad   <= cyc and stb;
  stall <= '0';

  u_rdzen : entity work.rejestry_rdzen generic map (ID => ID)
    port map (clk => clk, rst => rst, zap => zad and we, zap_adr => adr, zap_dane => dat_i, zap_str => sel,
              zap_blad => open, odc_adr => adr, odc_dane => odc_dane, odc_blad => odc_blad,
              ster => ster, stan => stan, zdarz => zdarz, irq => irq);

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' or cyc = '0' then                        -- koniec cyklu kasuje odpowiedzi w drodze
        ack <= '0';
        err <= '0';
      else
        ack   <= zad and not odc_blad;
        err   <= zad and odc_blad;
        dat_o <= odc_dane;
      end if;
    end if;
  end process;
end architecture rtl;
