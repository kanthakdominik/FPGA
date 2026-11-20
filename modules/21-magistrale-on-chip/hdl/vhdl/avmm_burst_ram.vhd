-- Pamięć RAM ze slave'em Avalon-MM z burstami (21.03): adres i burstcount z pierwszego taktu zapisu,
-- kolejne takty pod kolejne adresy; odczyt: jeden rozkaz, potem burstcount słów z readdatavalid;
-- waitrequest = '1' w czasie oddawania danych.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity avmm_burst_ram is
  generic (
    AW : positive := 10;
    BW : positive := 5
  );
  port (
    clk           : in  std_logic;
    rst           : in  std_logic;
    address       : in  std_logic_vector(AW - 1 downto 0);
    read          : in  std_logic;
    write         : in  std_logic;
    writedata     : in  std_logic_vector(31 downto 0);
    byteenable    : in  std_logic_vector(3 downto 0);
    burstcount    : in  std_logic_vector(BW - 1 downto 0);
    waitrequest   : out std_logic;
    readdata      : out std_logic_vector(31 downto 0);
    readdatavalid : out std_logic
  );
end entity avmm_burst_ram;

architecture rtl of avmm_burst_ram is
  type mem_t is array (0 to 2 ** AW - 1) of std_logic_vector(31 downto 0);
  signal mem : mem_t;
  signal w_akt, r_akt   : std_logic := '0';
  signal w_adr, r_adr   : unsigned(AW - 1 downto 0) := (others => '0');
  signal w_zost, r_zost : unsigned(BW - 1 downto 0);
  signal w_gdzie        : unsigned(AW - 1 downto 0);
begin
  waitrequest <= r_akt;
  w_gdzie     <= w_adr when w_akt = '1' else unsigned(address);

  process (clk)
  begin
    if rising_edge(clk) then
      if write = '1' and r_akt = '0' then
        for b in 0 to 3 loop
          if byteenable(b) = '1' then
            mem(to_integer(w_gdzie))(b * 8 + 7 downto b * 8) <= writedata(b * 8 + 7 downto b * 8);
          end if;
        end loop;
      end if;
      readdata <= mem(to_integer(r_adr));
    end if;
  end process;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        w_akt         <= '0';
        r_akt         <= '0';
        readdatavalid <= '0';
      else
        if write = '1' and r_akt = '0' then
          w_adr <= w_gdzie + 1;
          if w_akt = '0' then
            w_akt  <= '1' when unsigned(burstcount) > 1 else '0';
            w_zost <= unsigned(burstcount) - 2;                 -- pozostałe takty po następnym
          else
            if w_zost = 0 then w_akt <= '0'; end if;
            w_zost <= w_zost - 1;
          end if;
        end if;
        readdatavalid <= r_akt;
        if r_akt = '1' then
          r_adr <= r_adr + 1;
          if r_zost = 0 then r_akt <= '0'; end if;
          r_zost <= r_zost - 1;
        elsif read = '1' then
          r_akt  <= '1';
          r_adr  <= unsigned(address);
          r_zost <= unsigned(burstcount) - 1;
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
