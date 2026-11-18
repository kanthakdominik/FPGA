-- Bufor ping-pong (18.04): dwa banki po 2^AW słów; nadawca zapisuje kolejne słowa, po zapełnieniu banku
-- odbiorca dostaje blok do odczytu w dowolnej kolejności i zwalnia go impulsem rd_zwolnij; nadawca czeka
-- (wr_ready = '0'), dopóki odbiorca trzyma poprzedni blok.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pingpong is
  generic (
    W  : positive := 16;
    AW : positive := 4
  );
  port (
    clk        : in  std_logic;
    rst        : in  std_logic;
    wr_en      : in  std_logic;
    din        : in  std_logic_vector(W - 1 downto 0);
    wr_ready   : out std_logic;
    rd_gotowy  : out std_logic;
    rd_addr    : in  std_logic_vector(AW - 1 downto 0);
    dout       : out std_logic_vector(W - 1 downto 0);
    rd_zwolnij : in  std_logic
  );
end entity pingpong;

architecture rtl of pingpong is
  type mem_t is array (0 to 2 ** (AW + 1) - 1) of std_logic_vector(W - 1 downto 0);
  signal mem    : mem_t;
  signal wbank, pelny, zajety : std_logic := '0';
  signal waddr  : unsigned(AW - 1 downto 0) := (others => '0');
  signal do_wr, ostatni, wolny, zamien : std_logic;
begin
  wr_ready  <= not pelny;
  rd_gotowy <= zajety;
  do_wr     <= wr_en and not pelny;
  ostatni   <= do_wr when waddr = 2 ** AW - 1 else '0';
  wolny     <= (not zajety) or rd_zwolnij;
  zamien    <= (ostatni or pelny) and wolny;

  process (clk)
  begin
    if rising_edge(clk) then
      if do_wr = '1' then
        mem(to_integer(wbank & waddr)) <= din;
      end if;
      dout <= mem(to_integer((not wbank) & unsigned(rd_addr)));
      if rst = '1' then
        wbank  <= '0';
        waddr  <= (others => '0');
        pelny  <= '0';
        zajety <= '0';
      else
        if do_wr = '1' then
          waddr <= waddr + 1;
        end if;
        if zamien = '1' then
          wbank  <= not wbank;
          pelny  <= '0';
          zajety <= '1';
        else
          if ostatni = '1' then
            pelny <= '1';
          end if;
          if rd_zwolnij = '1' then
            zajety <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
