-- Zadanie 10: slave AXI4-Lite z czterema rejestrami 32-bitowymi i maską bajtów; kanały AW i W niezależne.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axil_regs is
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    awaddr  : in  std_logic_vector(3 downto 0);
    awvalid : in  std_logic;
    awready : out std_logic;
    wdata   : in  std_logic_vector(31 downto 0);
    wstrb   : in  std_logic_vector(3 downto 0);
    wvalid  : in  std_logic;
    wready  : out std_logic;
    bresp   : out std_logic_vector(1 downto 0);
    bvalid  : out std_logic;
    bready  : in  std_logic;
    araddr  : in  std_logic_vector(3 downto 0);
    arvalid : in  std_logic;
    arready : out std_logic;
    rdata   : out std_logic_vector(31 downto 0);
    rresp   : out std_logic_vector(1 downto 0);
    rvalid  : out std_logic;
    rready  : in  std_logic;
    reg0    : out std_logic_vector(31 downto 0);
    reg1    : out std_logic_vector(31 downto 0);
    reg2    : out std_logic_vector(31 downto 0);
    reg3    : out std_logic_vector(31 downto 0)
  );
end entity;

architecture rtl of axil_regs is
  type regs_t is array (0 to 3) of std_logic_vector(31 downto 0);
  signal regs    : regs_t := (others => (others => '0'));
  signal aw_full : std_logic := '0';
  signal aw_idx  : natural range 0 to 3 := 0;
  signal w_full  : std_logic := '0';
  signal w_data  : std_logic_vector(31 downto 0) := (others => '0');
  signal w_strb  : std_logic_vector(3 downto 0) := (others => '0');
  signal b_v     : std_logic := '0';
  signal r_v     : std_logic := '0';
  signal r_d     : std_logic_vector(31 downto 0) := (others => '0');
begin
  awready <= not aw_full and not b_v;
  wready  <= not w_full and not b_v;
  bresp   <= "00";
  bvalid  <= b_v;
  arready <= not r_v;
  rresp   <= "00";
  rvalid  <= r_v;
  rdata   <= r_d;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        aw_full <= '0'; w_full <= '0'; b_v <= '0';
        regs <= (others => (others => '0'));
      else
        if awvalid = '1' and aw_full = '0' and b_v = '0' then
          aw_full <= '1';
          aw_idx  <= to_integer(unsigned(awaddr(3 downto 2)));
        end if;
        if wvalid = '1' and w_full = '0' and b_v = '0' then
          w_full <= '1';
          w_data <= wdata;
          w_strb <= wstrb;
        end if;
        if aw_full = '1' and w_full = '1' then
          for b in 0 to 3 loop
            if w_strb(b) = '1' then
              regs(aw_idx)(8 * b + 7 downto 8 * b) <= w_data(8 * b + 7 downto 8 * b);
            end if;
          end loop;
          aw_full <= '0';
          w_full  <= '0';
          b_v     <= '1';
        end if;
        if b_v = '1' and bready = '1' then b_v <= '0'; end if;
      end if;
    end if;
  end process;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        r_v <= '0';
      elsif arvalid = '1' and r_v = '0' then
        r_d <= regs(to_integer(unsigned(araddr(3 downto 2))));
        r_v <= '1';
      elsif r_v = '1' and rready = '1' then
        r_v <= '0';
      end if;
    end if;
  end process;

  reg0 <= regs(0);
  reg1 <= regs(1);
  reg2 <= regs(2);
  reg3 <= regs(3);
end architecture;
