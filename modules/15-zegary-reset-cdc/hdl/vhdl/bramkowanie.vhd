-- Trzy liczniki tego samego zegara z tym samym sygnałem zezwolenia en (15.01):
--   cnt_ce  - zezwolenie zegara (clock enable): zegar zawsze ten sam, en wybiera, czy rejestr się zmienia,
--   cnt_and - zegar bramkowany bramką AND: gclk = clk and en. en zmienia się tuż po zboczu (gdy clk = '1'),
--             więc gclk dostaje dodatkowe zbocze - licznik liczy o jeden za dużo w każdym oknie en = '1',
--   cnt_icg - bramkowanie z zatrzaskiem (ICG): en przechodzi przez zatrzask przezroczysty przy clk = '0',
--             gclk = clk and en_lat nie ma dodatkowych zboczy; wynik = cnt_ce.
-- W FPGA ani AND, ani zatrzask - zezwolenie zegara albo blok sterowania zegarem (ALTCLKCTRL, BUFGCE).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bramkowanie is
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    en      : in  std_logic;                   -- z przerzutnika taktowanego clk
    cnt_ce  : out unsigned(7 downto 0);
    cnt_and : out unsigned(7 downto 0);
    cnt_icg : out unsigned(7 downto 0)
  );
end entity bramkowanie;

architecture rtl of bramkowanie is
  signal c_ce, c_and, c_icg : unsigned(7 downto 0) := (others => '0');
  signal gclk_and, gclk_icg : std_logic;
  signal en_lat             : std_logic := '0';
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        c_ce <= (others => '0');
      elsif en = '1' then
        c_ce <= c_ce + 1;
      end if;
    end if;
  end process;

  -- ŹLE: zegar z logiki
  gclk_and <= clk and en;
  process (gclk_and, rst)
  begin
    if rst = '1' then
      c_and <= (others => '0');
    elsif rising_edge(gclk_and) then
      c_and <= c_and + 1;
    end if;
  end process;

  -- komórka bramkująca z zatrzaskiem (ICG), jak w układach ASIC
  process (clk, en)
  begin
    if clk = '0' then
      en_lat <= en;                            -- zatrzask przezroczysty przy clk = '0'
    end if;
  end process;
  gclk_icg <= clk and en_lat;
  process (gclk_icg, rst)
  begin
    if rst = '1' then
      c_icg <= (others => '0');
    elsif rising_edge(gclk_icg) then
      c_icg <= c_icg + 1;
    end if;
  end process;

  cnt_ce  <= c_ce;
  cnt_and <= c_and;
  cnt_icg <= c_icg;
end architecture rtl;
