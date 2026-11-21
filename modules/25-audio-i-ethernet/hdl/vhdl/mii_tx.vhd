-- Nadajnik MAC dla MII (25.03): preambuła (7 × 0x55), SFD (0xD5), dane ze strumienia bajtów, uzupełnienie do 60 B,
-- FCS (CRC-32, najmłodszy bajt pierwszy), przerwa 24 takty. 4 bity na takt, młodsza połówka pierwsza. Brak bajtu
-- w środku ramki kończy dane bajtem zerowym (przerwa = '1').
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mii_tx is
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    s_dane    : in  std_logic_vector(7 downto 0);
    s_wazne   : in  std_logic;
    s_ostatni : in  std_logic;
    s_gotowy  : out std_logic;
    txd       : out std_logic_vector(3 downto 0) := "0000";
    tx_en     : out std_logic := '0';
    przerwa   : out std_logic := '0'
  );
end entity mii_tx;

architecture rtl of mii_tx is
  function crc_bajt(c : std_logic_vector(31 downto 0); d : std_logic_vector(7 downto 0)) return std_logic_vector is
    variable r : std_logic_vector(31 downto 0);
  begin
    r := c xor (x"000000" & d);
    for i in 0 to 7 loop
      if r(0) = '1' then r := ('0' & r(31 downto 1)) xor x"EDB88320"; else r := '0' & r(31 downto 1); end if;
    end loop;
    return r;
  end function;

  type stan_t is (S_BEZCZ, S_PREAMB, S_BAJTY, S_UZUP, S_FCS, S_IFG);
  signal stan : stan_t := S_BEZCZ;
  signal n    : natural range 0 to 31 := 0;
  signal h, ost : std_logic := '0';
  signal b    : std_logic_vector(7 downto 0) := (others => '0');
  signal dl   : natural range 0 to 2047 := 0;
  signal crc  : std_logic_vector(31 downto 0) := (others => '1');
  signal gotowy : std_logic;
begin
  gotowy   <= '1' when stan = S_BAJTY and h = '0' else '0';
  s_gotowy <= gotowy;

  process (clk)
    variable bajt : std_logic_vector(7 downto 0);
    variable fcs  : std_logic_vector(31 downto 0);
  begin
    if rising_edge(clk) then
      przerwa <= '0';
      if stan = S_BAJTY and s_wazne = '1' then bajt := s_dane; else bajt := x"00"; end if;
      fcs := not crc;
      if rst = '1' then
        stan <= S_BEZCZ; n <= 0; h <= '0'; b <= (others => '0'); dl <= 0; crc <= (others => '1'); ost <= '0';
        txd <= "0000"; tx_en <= '0';
      else
        case stan is
          when S_BEZCZ =>
            tx_en <= '0'; txd <= "0000";
            if s_wazne = '1' then stan <= S_PREAMB; n <= 0; end if;
          when S_PREAMB =>
            tx_en <= '1';
            if n = 15 then txd <= x"D"; else txd <= x"5"; end if;
            n <= n + 1;
            if n = 15 then stan <= S_BAJTY; h <= '0'; dl <= 0; crc <= (others => '1'); end if;
          when S_BAJTY | S_UZUP =>
            if h = '0' then
              b   <= bajt;
              txd <= bajt(3 downto 0);
              crc <= crc_bajt(crc, bajt);
              if dl < 2047 then dl <= dl + 1; end if;
              h   <= '1';
              if stan = S_BAJTY and s_wazne = '0' then
                przerwa <= '1';
                stan    <= S_UZUP;
                if dl >= 59 then ost <= '1'; else ost <= '0'; end if;
              elsif stan = S_UZUP then
                if dl >= 59 then ost <= '1'; else ost <= '0'; end if;
              else
                ost <= s_ostatni;
              end if;
            else
              txd <= b(7 downto 4);
              h   <= '0';
              if ost = '1' or (stan = S_BAJTY and dl = 2047) then
                if dl < 60 then stan <= S_UZUP; else stan <= S_FCS; end if;
                n   <= 0;
                ost <= '0';
              end if;
            end if;
          when S_FCS =>
            txd <= fcs(4 * (n mod 8) + 3 downto 4 * (n mod 8));
            n   <= n + 1;
            if n = 7 then stan <= S_IFG; n <= 0; end if;
          when S_IFG =>
            tx_en <= '0'; txd <= "0000";
            n <= n + 1;
            if n = 23 then stan <= S_BEZCZ; end if;
        end case;
      end if;
    end if;
  end process;
end architecture rtl;
