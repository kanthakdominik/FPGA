-- Generator NCO (26.03): akumulator fazy 32 bity, ćwiartka sinusa w ROM (sin_tab), wyjścia sin i cos.
-- Ćwiartka = bity 31..30 fazy, adres = 29..22 (w ćwiartkach 1 i 3 odwrócony), w ćwiartkach 2 i 3 znak minus;
-- cos = sin(faza + 90°). Próbka dla fazy sprzed dodania ftw, ważna 2 takty po we. f = ftw · f_we / 2^32.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity nco is
  port (
    clk, rst, we : in  std_logic;
    ftw          : in  unsigned(31 downto 0);
    sin_o, cos_o : out signed(15 downto 0) := (others => '0');
    wazne        : out std_logic := '0'
  );
end entity nco;

architecture rtl of nco is
  signal faza, faza_c   : unsigned(31 downto 0) := (others => '0');
  signal adr_s, adr_c   : unsigned(7 downto 0);
  signal rs, rc         : signed(15 downto 0);
  signal neg_s, neg_c, v1     : std_logic := '0';
begin
  faza_c <= faza + x"40000000";
  adr_s  <= not faza(29 downto 22) when faza(30) = '1' else faza(29 downto 22);
  adr_c  <= not faza_c(29 downto 22) when faza_c(30) = '1' else faza_c(29 downto 22);
  u_s : entity work.sin_tab port map (clk => clk, a => adr_s, q => rs);
  u_c : entity work.sin_tab port map (clk => clk, a => adr_c, q => rc);

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        faza <= (others => '0'); neg_s <= '0'; neg_c <= '0'; v1 <= '0'; wazne <= '0';
        sin_o <= (others => '0'); cos_o <= (others => '0');
      else
        v1 <= we;
        neg_s <= faza(31);
        neg_c <= faza_c(31);
        if we = '1' then
          faza <= faza + ftw;
        end if;
        wazne <= v1;
        sin_o <= -rs when neg_s = '1' else rs;
        cos_o <= -rc when neg_c = '1' else rc;
      end if;
    end if;
  end process;
end architecture rtl;
