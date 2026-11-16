-- Testbench sumy kontrolnej Internetu: przykład z RFC 1071 (wynik 0x220D) i słowa pseudolosowe.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_inet_checksum is
end entity tb_inet_checksum;

architecture sim of tb_inet_checksum is
  type words_t is array (natural range <>) of std_logic_vector(15 downto 0);
  constant RFC  : words_t := (x"0001", x"F203", x"F4F5", x"F6F7");
  signal clk    : std_logic := '0';
  signal done   : boolean   := false;
  signal clear  : std_logic := '1';
  signal valid  : std_logic := '0';
  signal word   : std_logic_vector(15 downto 0) := (others => '0');
  signal sum, checksum : std_logic_vector(15 downto 0);
begin
  clk <= not clk after 5 ns when not done;

  dut : entity work.inet_checksum
    port map (clk => clk, clear => clear, valid => valid, word => word, sum => sum, checksum => checksum);

  stim : process
    variable errors : natural := 0;
    variable l      : line;
    variable model  : natural := 0;
    variable lfsr_v : unsigned(15 downto 0) := x"ACE1";
    procedure check(ok : boolean; msg : string) is
    begin
      if not ok then
        errors := errors + 1;
        report msg severity warning;
      end if;
    end procedure;
  begin
    wait until falling_edge(clk);
    clear <= '0';
    valid <= '1';
    for k in RFC'range loop
      word <= RFC(k);
      wait until falling_edge(clk);
    end loop;
    valid <= '0';
    check(sum = x"DDF2" and checksum = x"220D", "przyklad z RFC 1071");

    clear <= '1';
    wait until falling_edge(clk);
    clear <= '0';
    valid <= '1';
    for k in 0 to 299 loop
      if lfsr_v(0) = '1' then
        lfsr_v := shift_right(lfsr_v, 1) xor x"B400";
      else
        lfsr_v := shift_right(lfsr_v, 1);
      end if;
      word  <= std_logic_vector(lfsr_v);
      model := model + to_integer(lfsr_v);
      wait until falling_edge(clk);
    end loop;
    valid <= '0';
    while model > 16#FFFF# loop
      model := (model mod 65536) + model / 65536;
    end loop;
    check(to_integer(unsigned(sum)) = model, "suma rozna od modelu");

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
