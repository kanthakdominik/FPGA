-- Koder TMDS (24.02) według DVI 1.0: minimalizacja zmian (XOR/XNOR, bit 8) i równoważenie składowej stałej
-- (inwersja, bit 9, licznik cnt). Przy de = '0' — znaki sterujące dla c = (C1, C0). Opóźnienie 2 takty;
-- q(0) wysyłany jako pierwszy.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tmds_kod is
  port (
    clk : in  std_logic;
    rst : in  std_logic;
    d   : in  std_logic_vector(7 downto 0);
    c   : in  std_logic_vector(1 downto 0);
    de  : in  std_logic;
    q   : out std_logic_vector(9 downto 0) := "1101010100"
  );
end entity tmds_kod;

architecture rtl of tmds_kod is
  function jedynki(v : std_logic_vector) return natural is
    variable n : natural := 0;
  begin
    for i in v'range loop
      if v(i) = '1' then n := n + 1; end if;
    end loop;
    return n;
  end function;

  signal qm  : std_logic_vector(8 downto 0) := (others => '0');
  signal c1  : std_logic_vector(1 downto 0) := "00";
  signal de1 : std_logic := '0';
  signal cnt : integer range -16 to 15 := 0;
begin
  -- stopień 1: minimalizacja zmian
  process (clk)
    variable n1 : natural;
    variable xn : boolean;
    variable m  : std_logic_vector(8 downto 0);
  begin
    if rising_edge(clk) then
      n1 := jedynki(d);
      xn := n1 > 4 or (n1 = 4 and d(0) = '0');
      m(0) := d(0);
      for k in 1 to 7 loop
        if xn then m(k) := not (m(k - 1) xor d(k)); else m(k) := m(k - 1) xor d(k); end if;
      end loop;
      if xn then m(8) := '0'; else m(8) := '1'; end if;
      qm  <= m;
      c1  <= c;
      de1 <= de;
    end if;
  end process;

  -- stopień 2: równoważenie; roz = (n1q - n0q) / 2
  process (clk)
    variable roz : integer range -4 to 4;
  begin
    if rising_edge(clk) then
      roz := jedynki(qm(7 downto 0)) - 4;
      if rst = '1' then
        q <= "1101010100"; cnt <= 0;
      elsif de1 = '0' then
        cnt <= 0;
        case c1 is
          when "00"   => q <= "1101010100";
          when "01"   => q <= "0010101011";
          when "10"   => q <= "0101010100";
          when others => q <= "1010101011";
        end case;
      elsif cnt = 0 or roz = 0 then
        if qm(8) = '1' then
          q <= '0' & qm(8) & qm(7 downto 0);
          cnt <= cnt + 2 * roz;
        else
          q <= '1' & qm(8) & not qm(7 downto 0);
          cnt <= cnt - 2 * roz;
        end if;
      elsif (cnt > 0 and roz > 0) or (cnt < 0 and roz < 0) then
        q <= '1' & qm(8) & not qm(7 downto 0);
        if qm(8) = '1' then cnt <= cnt + 2 - 2 * roz; else cnt <= cnt - 2 * roz; end if;
      else
        q <= '0' & qm(8) & qm(7 downto 0);
        if qm(8) = '1' then cnt <= cnt + 2 * roz; else cnt <= cnt - 2 + 2 * roz; end if;
      end if;
    end if;
  end process;
end architecture rtl;
