-- Pamięć RAM ze slave'em Wishbone B4 w trybie potokowym (21.04): żądanie przyjęte, gdy CYC and STB and
-- not STALL, ACK w następnym takcie; STALL co CO-ty takt (CO = 0: nigdy).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wb_ram is
  generic (
    AW : positive := 9;
    CO : natural  := 0
  );
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    cyc   : in  std_logic;
    stb   : in  std_logic;
    we    : in  std_logic;
    adr   : in  std_logic_vector(AW - 1 downto 0);
    dat_i : in  std_logic_vector(31 downto 0);
    sel   : in  std_logic_vector(3 downto 0);
    dat_o : out std_logic_vector(31 downto 0);
    ack   : out std_logic;
    stall : out std_logic
  );
end entity wb_ram;

architecture rtl of wb_ram is
  type mem_t is array (0 to 2 ** AW - 1) of std_logic_vector(31 downto 0);
  signal mem       : mem_t := (others => (others => '0'));
  constant OST     : natural := maximum(CO, 1) - 1;
  signal licz      : natural range 0 to OST := 0;
  signal st, przyj : std_logic;
begin
  st    <= '1' when CO /= 0 and licz = OST else '0';
  stall <= st;
  przyj <= cyc and stb and not st;

  process (clk)
  begin
    if rising_edge(clk) then
      if przyj = '1' and we = '1' then
        for b in 0 to 3 loop
          if sel(b) = '1' then
            mem(to_integer(unsigned(adr)))(b * 8 + 7 downto b * 8) <= dat_i(b * 8 + 7 downto b * 8);
          end if;
        end loop;
      end if;
      dat_o <= mem(to_integer(unsigned(adr)));
    end if;
  end process;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        licz <= 0;
        ack  <= '0';
      else
        licz <= 0 when licz = OST else licz + 1;
        ack  <= przyj;
      end if;
    end if;
  end process;
end architecture rtl;
