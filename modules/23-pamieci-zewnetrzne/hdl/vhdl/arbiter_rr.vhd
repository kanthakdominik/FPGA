-- Arbiter round-robin N masterów do jednego slave'a Avalon-MM (23.04): przydział po każdym przyjętym transferze,
-- kolejka numerów masterów kieruje readdatavalid do właściwego mastera.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity arbiter_rr is
  generic (
    N   : positive := 3;
    AW  : positive := 12;
    KOL : positive := 8
  );
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    m_adr    : in  std_logic_vector(N * AW - 1 downto 0);
    m_read   : in  std_logic_vector(N - 1 downto 0);
    m_write  : in  std_logic_vector(N - 1 downto 0);
    m_wdata  : in  std_logic_vector(N * 32 - 1 downto 0);
    m_wait   : out std_logic_vector(N - 1 downto 0);
    m_rvalid : out std_logic_vector(N - 1 downto 0);
    m_rdata  : out std_logic_vector(31 downto 0);
    s_adr    : out std_logic_vector(AW - 1 downto 0);
    s_read   : out std_logic;
    s_write  : out std_logic;
    s_wdata  : out std_logic_vector(31 downto 0);
    s_wait   : in  std_logic;
    s_rvalid : in  std_logic;
    s_rdata  : in  std_logic_vector(31 downto 0)
  );
end entity arbiter_rr;

architecture rtl of arbiter_rr is
  type kol_t is array (0 to KOL - 1) of natural range 0 to N - 1;
  signal kolejka    : kol_t := (others => 0);
  signal ost, wyb : natural range 0 to N - 1 := 0;
  signal znal, pelna, sr_i, sw_i, przyj : std_logic;
  signal wz, wo : natural range 0 to KOL - 1 := 0;
  signal ile    : natural range 0 to KOL := 0;
begin
  process (all)
    variable i : natural;
  begin
    wyb  <= ost;
    znal <= '0';
    for k in N downto 1 loop                                  -- od końca: wygrywa najbliższy po ost
      i := (ost + k) mod N;
      if m_read(i) = '1' or m_write(i) = '1' then
        wyb  <= i;
        znal <= '1';
      end if;
    end loop;
  end process;

  pelna   <= '1' when ile = KOL else '0';
  s_adr   <= m_adr(wyb * AW + AW - 1 downto wyb * AW);
  s_wdata <= m_wdata(wyb * 32 + 31 downto wyb * 32);
  sr_i    <= znal and m_read(wyb) and not pelna;
  sw_i    <= znal and m_write(wyb);
  s_read  <= sr_i;
  s_write <= sw_i;
  przyj   <= (sr_i or sw_i) and not s_wait;

  process (all)
  begin
    m_wait <= (others => '1');
    if przyj = '1' then m_wait(wyb) <= '0'; end if;
  end process;

  g_rv : for g in 0 to N - 1 generate
    m_rvalid(g) <= '1' when s_rvalid = '1' and kolejka(wo) = g else '0';
  end generate;
  m_rdata <= s_rdata;

  process (clk)
    variable nile : integer;
  begin
    if rising_edge(clk) then
      if rst = '1' then
        ost <= 0;
        wz  <= 0;
        wo  <= 0;
        ile <= 0;
      else
        nile := ile;
        if przyj = '1' then ost <= wyb; end if;
        if przyj = '1' and sr_i = '1' then
          kolejka(wz) <= wyb;
          wz      <= (wz + 1) mod KOL;
          nile    := nile + 1;
        end if;
        if s_rvalid = '1' then
          wo <= (wo + 1) mod KOL;
          nile := nile - 1;
        end if;
        ile <= nile;
      end if;
    end if;
  end process;
end architecture rtl;
