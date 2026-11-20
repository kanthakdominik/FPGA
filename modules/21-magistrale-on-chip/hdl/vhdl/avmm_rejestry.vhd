-- Slave Avalon-MM (21.02) nad rejestry_rdzen: adresy słów, bez waitrequest, readLatency = 1,
-- response (00 OKAY, 10 SLAVEERROR) razem z readdata.
library ieee;
use ieee.std_logic_1164.all;

entity avmm_rejestry is
  generic (ID : std_logic_vector(31 downto 0) := x"21020001");
  port (
    clk        : in  std_logic;
    rst        : in  std_logic;
    address    : in  std_logic_vector(3 downto 0);
    read       : in  std_logic;
    write      : in  std_logic;
    writedata  : in  std_logic_vector(31 downto 0);
    byteenable : in  std_logic_vector(3 downto 0);
    readdata   : out std_logic_vector(31 downto 0);
    response   : out std_logic_vector(1 downto 0);
    ster       : out std_logic_vector(31 downto 0);
    stan       : in  std_logic_vector(31 downto 0);
    zdarz      : in  std_logic_vector(7 downto 0);
    irq        : out std_logic
  );
end entity avmm_rejestry;

architecture rtl of avmm_rejestry is
  signal odc_dane : std_logic_vector(31 downto 0);
  signal odc_blad : std_logic;
begin
  u_rdzen : entity work.rejestry_rdzen generic map (ID => ID)
    port map (clk => clk, rst => rst, zap => write, zap_adr => address, zap_dane => writedata, zap_str => byteenable,
              zap_blad => open, odc_adr => address, odc_dane => odc_dane, odc_blad => odc_blad,
              ster => ster, stan => stan, zdarz => zdarz, irq => irq);

  process (clk)
  begin
    if rising_edge(clk) then
      if read = '1' then
        readdata <= odc_dane;
        response <= "10" when odc_blad = '1' else "00";
      end if;
    end if;
  end process;
end architecture rtl;
