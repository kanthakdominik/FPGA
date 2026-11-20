-- Slave AXI4-Lite (21.02) nad rejestry_rdzen: AW i W przyjmowane niezależnie, zapis po zebraniu obu,
-- gdy kanał B wolny; odczyt z rejestrem danych; ready z przerzutników; adres spoza mapy - SLVERR.
library ieee;
use ieee.std_logic_1164.all;

entity axil_rejestry is
  generic (ID : std_logic_vector(31 downto 0) := x"21020001");
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    s_awaddr  : in  std_logic_vector(5 downto 0);
    s_awvalid : in  std_logic;
    s_awready : out std_logic;
    s_wdata   : in  std_logic_vector(31 downto 0);
    s_wstrb   : in  std_logic_vector(3 downto 0);
    s_wvalid  : in  std_logic;
    s_wready  : out std_logic;
    s_bresp   : out std_logic_vector(1 downto 0);
    s_bvalid  : out std_logic;
    s_bready  : in  std_logic;
    s_araddr  : in  std_logic_vector(5 downto 0);
    s_arvalid : in  std_logic;
    s_arready : out std_logic;
    s_rdata   : out std_logic_vector(31 downto 0);
    s_rresp   : out std_logic_vector(1 downto 0);
    s_rvalid  : out std_logic;
    s_rready  : in  std_logic;
    ster      : out std_logic_vector(31 downto 0);
    stan      : in  std_logic_vector(31 downto 0);
    zdarz     : in  std_logic_vector(7 downto 0);
    irq       : out std_logic
  );
end entity axil_rejestry;

architecture rtl of axil_rejestry is
  constant OKAY   : std_logic_vector(1 downto 0) := "00";
  constant SLVERR : std_logic_vector(1 downto 0) := "10";
  signal aw_ok, w_ok, bv, rv, zap, zap_blad, odc_blad : std_logic := '0';
  signal aw_adr   : std_logic_vector(3 downto 0);
  signal w_dane   : std_logic_vector(31 downto 0);
  signal w_str    : std_logic_vector(3 downto 0);
  signal odc_dane : std_logic_vector(31 downto 0);
begin
  s_awready <= not aw_ok;
  s_wready  <= not w_ok;
  s_arready <= not rv;
  s_bvalid  <= bv;
  s_rvalid  <= rv;
  zap       <= aw_ok and w_ok and (not bv or s_bready);

  u_rdzen : entity work.rejestry_rdzen generic map (ID => ID)
    port map (clk => clk, rst => rst, zap => zap, zap_adr => aw_adr, zap_dane => w_dane, zap_str => w_str,
              zap_blad => zap_blad, odc_adr => s_araddr(5 downto 2), odc_dane => odc_dane, odc_blad => odc_blad,
              ster => ster, stan => stan, zdarz => zdarz, irq => irq);

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        aw_ok <= '0';
        w_ok  <= '0';
        bv    <= '0';
        rv    <= '0';
      else
        if s_awvalid = '1' and aw_ok = '0' then
          aw_ok  <= '1';
          aw_adr <= s_awaddr(5 downto 2);
        end if;
        if s_wvalid = '1' and w_ok = '0' then
          w_ok   <= '1';
          w_dane <= s_wdata;
          w_str  <= s_wstrb;
        end if;
        if bv = '1' and s_bready = '1' then bv <= '0'; end if;
        if zap = '1' then                                   -- adres i dane zebrane, odpowiedź może wyjść
          aw_ok   <= '0';
          w_ok    <= '0';
          bv      <= '1';
          s_bresp <= SLVERR when zap_blad = '1' else OKAY;
        end if;
        if rv = '1' and s_rready = '1' then rv <= '0'; end if;
        if s_arvalid = '1' and rv = '0' then
          rv      <= '1';
          s_rdata <= odc_dane;
          s_rresp <= SLVERR when odc_blad = '1' else OKAY;
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
