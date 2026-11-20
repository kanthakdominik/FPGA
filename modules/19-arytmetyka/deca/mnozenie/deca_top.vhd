-- Moduł nadrzędny DECA - VHDL. Test mnożarek na sprzęcie (moduł 19, 19.02): dwie realizacje mnożenia
-- 34 x 34 (mnoz_szeroki i mnoz_potok) i mnożenia zespolonego (cztery i trzy mnożenia) na danych z LFSR,
-- porównanie w każdym takcie. LED(7) - błąd, LED(6 downto 0) - licznik porównań.
-- KEY(0) - reset, SW(0) w górze - celowy błąd w operandzie jednej z mnożarek 34 x 34.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deca_top is
  port (
    MAX10_CLK1_50 : in  std_logic;
    KEY           : in  std_logic_vector(1 downto 0);
    SW            : in  std_logic_vector(1 downto 0);
    LED           : out std_logic_vector(7 downto 0)   -- '0' = świeci
  );
end entity deca_top;

architecture rtl of deca_top is
  signal clk, rst      : std_logic;
  signal rs, sw1, sw2  : std_logic_vector(1 downto 0) := "00";
  signal l1            : std_logic_vector(63 downto 0) := x"0123456789ABCDEF";
  signal l2            : std_logic_vector(63 downto 0) := x"FEDCBA9876543210";
  signal a, b, b_bl    : std_logic_vector(33 downto 0);
  signal p_sz, p_op    : std_logic_vector(67 downto 0);
  signal pr4, pi4, pr3, pi3 : std_logic_vector(32 downto 0);
  signal v_sz, v_op, v4, v3 : std_logic;
  signal blad          : std_logic := '0';
  signal licz          : unsigned(31 downto 0) := (others => '0');
  attribute altera_attribute : string;
  attribute altera_attribute of sw1 : signal is "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS";
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
      sw1 <= SW;
      sw2 <= sw1;
      -- LFSR 64 bity (x^64 + x^63 + x^61 + x^60 + 1)
      l1 <= l1(62 downto 0) & (l1(63) xor l1(62) xor l1(60) xor l1(59));
      l2 <= l2(62 downto 0) & (l2(63) xor l2(62) xor l2(60) xor l2(59));
    end if;
  end process;

  a    <= l1(33 downto 0);
  b    <= l2(33 downto 0);
  b_bl <= b(33 downto 1) & (b(0) xor sw2(0));                -- celowy błąd

  u_sz : entity work.mnoz_szeroki generic map (H => 17) port map (clk, '1', a, b, v_sz, p_sz);
  u_op : entity work.mnoz_potok generic map (WA => 34, WB => 34, ZNAK => true, LAT => 3)
    port map (clk, '1', a, b_bl, v_op, p_op);
  u_z4 : entity work.mnoz_zesp generic map (W => 16, TRZY => false)
    port map (clk, '1', l1(49 downto 34), l1(63 downto 48), l2(49 downto 34), l2(63 downto 48), v4, pr4, pi4);
  u_z3 : entity work.mnoz_zesp generic map (W => 16, TRZY => true)
    port map (clk, '1', l1(49 downto 34), l1(63 downto 48), l2(49 downto 34), l2(63 downto 48), v3, pr3, pi3);

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        blad <= '0';
        licz <= (others => '0');
      elsif v_sz = '1' and v_op = '1' and v4 = '1' and v3 = '1' then
        if p_sz /= p_op or pr4 /= pr3 or pi4 /= pi3 then
          blad <= '1';
        end if;
        licz <= licz + 1;
      end if;
    end if;
  end process;

  LED <= not (blad & std_logic_vector(licz(31 downto 25)));
end architecture rtl;
