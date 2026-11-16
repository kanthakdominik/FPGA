-- Dekoder sterowania bez zatrzasków: wartości domyślne na początku procesu kombinacyjnego.
-- op: 000 NOP, 001 READ, 010 WRITE, 011 RMW, 1xx — niedozwolony (err). Przy busy operacje czekają.
library ieee;
use ieee.std_logic_1164.all;

entity ctrl_decode is
  port (
    op    : in  std_logic_vector(2 downto 0);
    valid : in  std_logic;
    busy  : in  std_logic;
    rd_en : out std_logic;
    wr_en : out std_logic;
    sel   : out std_logic_vector(1 downto 0);
    err   : out std_logic
  );
end entity ctrl_decode;

architecture rtl of ctrl_decode is
begin
  process (all)
  begin
    rd_en <= '0';                                    -- wartości domyślne: każde wyjście jest przypisane
    wr_en <= '0';                                    -- w każdej ścieżce przez proces
    sel   <= "00";
    err   <= '0';
    if valid = '1' then
      case op is
        when "001" =>
          if busy = '0' then
            rd_en <= '1';
            sel   <= "01";
          end if;
        when "010" =>
          if busy = '0' then
            wr_en <= '1';
            sel   <= "10";
          end if;
        when "011" =>
          if busy = '0' then
            rd_en <= '1';
            wr_en <= '1';
            sel   <= "11";
          end if;
        when "100" | "101" | "110" | "111" =>
          err <= '1';
        when others =>                               -- 000: NOP
          null;
      end case;
    end if;
  end process;
end architecture rtl;
