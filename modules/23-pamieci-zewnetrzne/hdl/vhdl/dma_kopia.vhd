-- Silnik DMA kopiujący n słów (23.04), master Avalon-MM z odczytami potokowymi i kolejką GL słów; rozkaz
-- trzymany do przyjęcia, następny decydowany w takcie przyjęcia.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dma_kopia is
  generic (
    AW : positive := 12;
    GL : positive := 8
  );
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    start    : in  std_logic;
    zrodlo   : in  std_logic_vector(AW - 1 downto 0);
    cel      : in  std_logic_vector(AW - 1 downto 0);
    n        : in  std_logic_vector(AW - 1 downto 0);
    zajety   : out std_logic := '0';
    gotowe   : out std_logic := '0';
    m_adr    : out std_logic_vector(AW - 1 downto 0);
    m_read   : out std_logic := '0';
    m_write  : out std_logic := '0';
    m_wdata  : out std_logic_vector(31 downto 0);
    m_wait   : in  std_logic;
    m_rvalid : in  std_logic;
    m_rdata  : in  std_logic_vector(31 downto 0)
  );
end entity dma_kopia;

architecture rtl of dma_kopia is
  type kol_t is array (0 to GL - 1) of std_logic_vector(31 downto 0);
  signal kol    : kol_t;
  signal wz, wo : natural range 0 to GL - 1 := 0;
  signal wlocie, ile : natural range 0 to GL := 0;
  signal r_zr, r_cel, r_n, ri, wi : unsigned(AW - 1 downto 0) := (others => '0');
  signal zaj, rd, wr : std_logic := '0';
begin
  zajety  <= zaj;
  m_read  <= rd;
  m_write <= wr;

  process (clk)
    variable wl, il, il_dost : integer;
    variable nri, nwi : unsigned(AW - 1 downto 0);
    variable nwo : natural range 0 to GL - 1;
    variable przyj : boolean;
  begin
    if rising_edge(clk) then
      gotowe <= '0';
      if rst = '1' then
        zaj    <= '0';
        rd     <= '0';
        wr     <= '0';
        wz     <= 0;
        wo     <= 0;
        wlocie <= 0;
        ile    <= 0;
      elsif zaj = '0' then
        if start = '1' then
          zaj   <= '1';
          r_zr  <= unsigned(zrodlo);
          r_cel <= unsigned(cel);
          r_n   <= unsigned(n);
          ri    <= (others => '0');
          wi    <= (others => '0');
        end if;
      else
        wl := wlocie; il := ile; il_dost := ile; nri := ri; nwi := wi; nwo := wo;
        if m_rvalid = '1' then
          kol(wz) <= m_rdata;
          wz      <= (wz + 1) mod GL;
          wl      := wl - 1;
          il      := il + 1;
        end if;
        przyj := (rd = '1' or wr = '1') and m_wait = '0';
        if przyj and rd = '1' then
          nri := nri + 1;
          wl  := wl + 1;
        end if;
        if przyj and wr = '1' then
          nwi     := nwi + 1;
          il      := il - 1;
          il_dost := il_dost - 1;
          nwo     := (nwo + 1) mod GL;
        end if;
        if (rd = '0' and wr = '0') or przyj then                 -- można wystawić nowy rozkaz
          rd <= '0';
          wr <= '0';
          if il_dost /= 0 and (nri = r_n or wl + il >= GL) then
            wr      <= '1';
            m_adr   <= std_logic_vector(r_cel + nwi);
            m_wdata <= kol(nwo);
          elsif nri /= r_n and wl + il < GL then
            rd    <= '1';
            m_adr <= std_logic_vector(r_zr + nri);
          elsif il_dost /= 0 then
            wr      <= '1';
            m_adr   <= std_logic_vector(r_cel + nwi);
            m_wdata <= kol(nwo);
          end if;
        end if;
        wlocie <= wl;
        ile    <= il;
        ri     <= nri;
        wi     <= nwi;
        wo     <= nwo;
        if nwi = r_n then
          zaj    <= '0';
          gotowe <= '1';
          rd     <= '0';
          wr     <= '0';
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
