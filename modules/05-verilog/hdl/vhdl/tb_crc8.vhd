-- Testbench CRC-8: wartość kontrolna dla "123456789" (0xF4) i porównanie z modelem bit po bicie.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_crc8 is
end entity tb_crc8;

architecture sim of tb_crc8 is
  signal clk  : std_logic := '0';
  signal done : boolean   := false;
  signal rst  : std_logic := '1';
  signal en   : std_logic := '0';
  signal data : std_logic_vector(7 downto 0) := (others => '0');
  signal crc  : std_logic_vector(7 downto 0);
begin
  clk <= not clk after 5 ns when not done;

  dut : entity work.crc8
    port map (clk => clk, rst => rst, en => en, data => data, crc => crc);

  stim : process
    constant CHECK_STR : string := "123456789";
    variable errors : natural := 0;
    variable l      : line;
    variable model  : std_logic_vector(7 downto 0);
    variable byte   : std_logic_vector(7 downto 0);
    variable lfsr_v : unsigned(7 downto 0) := x"5A";
    procedure check(ok : boolean; msg : string) is
    begin
      if not ok then
        errors := errors + 1;
        report msg severity warning;
      end if;
    end procedure;
    -- model szeregowy: jeden bit danych na krok, od najstarszego
    procedure model_byte(d : std_logic_vector(7 downto 0)) is
      variable fb : std_logic;
    begin
      for b in 7 downto 0 loop
        fb    := model(7) xor d(b);
        model := model(6 downto 0) & '0';
        if fb = '1' then
          model := model xor x"07";
        end if;
      end loop;
    end procedure;
  begin
    wait until falling_edge(clk);
    rst   <= '0';
    en    <= '1';
    model := x"00";
    for k in CHECK_STR'range loop
      byte := std_logic_vector(to_unsigned(character'pos(CHECK_STR(k)), 8));
      data <= byte;
      model_byte(byte);
      wait until falling_edge(clk);
    end loop;
    check(crc = x"F4" and model = x"F4", "CRC(123456789) rozne od F4");

    rst <= '1';
    wait until falling_edge(clk);
    rst   <= '0';
    model := x"00";
    for k in 0 to 199 loop
      if lfsr_v(0) = '1' then
        lfsr_v := shift_right(lfsr_v, 1) xor x"B8";
      else
        lfsr_v := shift_right(lfsr_v, 1);
      end if;
      byte := std_logic_vector(lfsr_v);
      data <= byte;
      model_byte(byte);
      wait until falling_edge(clk);
      check(crc = model, "bajt " & integer'image(k));
    end loop;

    if errors = 0 then
      write(l, string'("PASS"));
    else
      write(l, "FAIL: " & integer'image(errors) & " bledow");
    end if;
    writeline(output, l);
    done <= true;
    std.env.finish;
    wait;
  end process stim;
end architecture sim;
