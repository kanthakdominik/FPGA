-- Dekoder komunikatów MIDI (31.03): Note On/Off, running status, bajty czasu rzeczywistego, CC 120/123,
-- zmiana programu. Jak w wersjach Verilog i SystemVerilog.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity midi_parser is
  port (
    clk, rst     : in  std_logic;
    dane         : in  std_logic_vector(7 downto 0);
    wazne        : in  std_logic;
    ev_on, ev_off, ev_wszystkie, ev_prog : out std_logic := '0';
    nuta, vel    : out unsigned(6 downto 0) := (others => '0');
    prog         : out unsigned(1 downto 0) := (others => '0')
  );
end entity midi_parser;

architecture rtl of midi_parser is
  signal status : std_logic_vector(7 downto 0) := (others => '0');
  signal drugi  : std_logic := '0';
  signal d1     : unsigned(6 downto 0) := (others => '0');
begin
  process (clk)
    variable typ : std_logic_vector(3 downto 0);
    variable dwa : boolean;
  begin
    if rising_edge(clk) then
      ev_on <= '0'; ev_off <= '0'; ev_wszystkie <= '0'; ev_prog <= '0';
      typ := status(7 downto 4);
      dwa := typ = x"8" or typ = x"9" or typ = x"A" or typ = x"B" or typ = x"E";
      if rst = '1' then
        status <= (others => '0'); drugi <= '0';
      elsif wazne = '1' then
        if unsigned(dane) >= 16#F8# then
          null;                                   -- czas rzeczywisty
        elsif dane(7) = '1' then
          if unsigned(dane) >= 16#F0# then status <= (others => '0'); else status <= dane; end if;
          drugi <= '0';
        elsif status /= x"00" then
          if dwa and drugi = '0' then
            d1 <= unsigned(dane(6 downto 0));
            drugi <= '1';
          else
            drugi <= '0';
            case typ is
              when x"9" =>
                nuta <= d1;
                vel  <= unsigned(dane(6 downto 0));
                if dane(6 downto 0) /= "0000000" then ev_on <= '1'; else ev_off <= '1'; end if;
              when x"8" =>
                nuta <= d1; ev_off <= '1';
              when x"B" =>
                if d1 = 123 or d1 = 120 then ev_wszystkie <= '1'; end if;
              when x"C" =>
                prog <= unsigned(dane(1 downto 0)); ev_prog <= '1';
              when others => null;
            end case;
          end if;
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
