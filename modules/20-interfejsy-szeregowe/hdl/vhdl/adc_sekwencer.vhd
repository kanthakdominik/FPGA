-- Sekwencer dla rdzenia ADC MAX 10 „ADC Control Core Only” (20.06): obieg LICZBA kanałów z listy KANALY
-- (po 5 bitów, kanał 0 w najmłodszych bitach; 17 — termodioda), interfejs rozkazów Avalon-ST (ready latency 0),
-- odpowiedzi bez przeciwciśnienia; ostatnia próbka każdego kanału w wyniki i na wyjściu (nowy, kanal, dane).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adc_sekwencer is
  generic (
    LICZBA : positive := 2;
    KANALY : std_logic_vector(39 downto 0) := x"0000000221"   -- {17, 1}: 17·32 + 1
  );
  port (
    clk                   : in  std_logic;
    rst                   : in  std_logic;
    wlacz                 : in  std_logic;
    command_valid         : out std_logic := '0';
    command_channel       : out std_logic_vector(4 downto 0) := (others => '0');
    command_startofpacket : out std_logic;
    command_endofpacket   : out std_logic;
    command_ready         : in  std_logic;
    response_valid        : in  std_logic;
    response_channel      : in  std_logic_vector(4 downto 0);
    response_data         : in  std_logic_vector(11 downto 0);
    wyniki                : out std_logic_vector(LICZBA * 12 - 1 downto 0) := (others => '0');
    nowy                  : out std_logic := '0';
    kanal                 : out std_logic_vector(4 downto 0) := (others => '0');
    dane                  : out std_logic_vector(11 downto 0) := (others => '0')
  );
end entity adc_sekwencer;

architecture rtl of adc_sekwencer is
  signal idx     : natural range 0 to LICZBA - 1 := 0;
  signal valid_r : std_logic := '0';

  function kan(i : natural) return std_logic_vector is
  begin
    return KANALY(i * 5 + 4 downto i * 5);
  end function;
begin
  command_startofpacket <= '0';                                -- nieużywane w „Control Core Only”
  command_endofpacket   <= '0';
  command_valid         <= valid_r;

  process (clk)
    variable nast : natural range 0 to LICZBA - 1;
  begin
    if rising_edge(clk) then
      nowy <= '0';
      if rst = '1' then
        valid_r <= '0';
        idx     <= 0;
      else
        valid_r         <= wlacz;
        command_channel <= kan(idx);
        if valid_r = '1' and command_ready = '1' then          -- rozkaz przyjęty: następny kanał
          nast := 0 when idx = LICZBA - 1 else idx + 1;
          idx             <= nast;
          command_channel <= kan(nast);
        end if;
        if response_valid = '1' then
          nowy  <= '1';
          kanal <= response_channel;
          dane  <= response_data;
          for i in 0 to LICZBA - 1 loop
            if kan(i) = response_channel then
              wyniki(i * 12 + 11 downto i * 12) <= response_data;
            end if;
          end loop;
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
