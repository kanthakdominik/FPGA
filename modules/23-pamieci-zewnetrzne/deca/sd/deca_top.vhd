-- Moduł nadrzędny DECA - VHDL. Karta microSD w trybie SPI (23.05), tylko odczyt bloku 0 i sygnatury 0x55AA;
-- piny translatora i diody jak w deca_top.v. KEY(1) - odczyt ponownie, KEY(0) - reset.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deca_top is
  port (
    MAX10_CLK1_50 : in    std_logic;
    KEY           : in    std_logic_vector(1 downto 0);
    SW            : in    std_logic_vector(1 downto 0);
    LED           : out   std_logic_vector(7 downto 0);   -- '0' = świeci
    SD_CLK        : out   std_logic;
    SD_CMD        : inout std_logic;
    SD_DAT        : inout std_logic_vector(3 downto 0);
    SD_CMD_DIR    : out   std_logic;
    SD_D0_DIR     : out   std_logic;
    SD_D123_DIR   : out   std_logic;
    SD_SEL        : out   std_logic
  );
end entity deca_top;

architecture rtl of deca_top is
  signal clk, rst, nacisk, gotowy, sdhc, blad, dane_wazne, koniec, crc_ok, sclk, mosi, cs_n : std_logic;
  signal rs : std_logic_vector(1 downto 0) := "00";
  signal s_k : std_logic_vector(1 downto 0) := "11";
  signal k_pop, chce : std_logic := '1';
  signal odczyt, gotowe_ok, sygn : std_logic := '0';
  signal kod_bledu : std_logic_vector(3 downto 0);
  signal dane, b510, b511 : std_logic_vector(7 downto 0) := x"00";
  signal n : natural range 0 to 1023 := 0;
begin
  clk <= MAX10_CLK1_50;
  process (clk, KEY)
  begin
    if KEY(0) = '0' then
      rs <= "00";
    elsif rising_edge(clk) then
      rs <= rs(0) & '1';
    end if;
  end process;
  rst <= not rs(1);

  process (clk)
  begin
    if rising_edge(clk) then
      s_k   <= s_k(0) & KEY(1);
      k_pop <= s_k(1);
    end if;
  end process;
  nacisk <= k_pop and not s_k(1);

  u_sd : entity work.sd_spi generic map (DIV_WOLNY => 63, DIV_SZYBKI => 4)
    port map (clk => clk, rst => rst, odczyt => odczyt, blok => x"00000000", gotowy => gotowy, sdhc => sdhc,
              blad => blad, kod_bledu => kod_bledu, dane => dane, dane_wazne => dane_wazne, koniec => koniec,
              crc_ok => crc_ok, sclk => sclk, mosi => mosi, cs_n => cs_n, miso => SD_DAT(0));

  SD_CLK      <= sclk;
  SD_CMD      <= mosi;
  SD_DAT(3)   <= cs_n;
  SD_DAT(2)   <= '1';
  SD_DAT(1)   <= '1';
  SD_DAT(0)   <= 'Z';
  SD_CMD_DIR  <= '1';                                       -- FPGA -> karta
  SD_D123_DIR <= '1';
  SD_D0_DIR   <= '0';                                       -- karta -> FPGA
  SD_SEL      <= '0';

  process (clk)
  begin
    if rising_edge(clk) then
      odczyt <= '0';
      if rst = '1' then
        chce <= '1';
      else
        if nacisk = '1' then chce <= '1'; end if;
        if chce = '1' and gotowy = '1' then
          chce   <= '0';
          odczyt <= '1';
          n      <= 0;
        end if;
        if dane_wazne = '1' then
          n <= n + 1;
          if n = 510 then b510 <= dane; end if;
          if n = 511 then b511 <= dane; end if;
        end if;
        if gotowy = '1' then gotowe_ok <= '1'; end if;
      end if;
    end if;
  end process;

  sygn <= '1' when b510 = x"55" and b511 = x"AA" else '0';
  LED  <= not (sygn & crc_ok & gotowe_ok & sdhc & kod_bledu);
end architecture rtl;
