-- Peryferium PWM ze slave'em Avalon-MM (27.03): rejestry STER (0), OKRES (1), WYPELN (2), STATUS (3, W1C),
-- odczyt z opóźnieniem 1 takt, tylko dostęp 32-bitowy, przerwanie poziomem irq = KONIEC and PRZ.
-- Nowe OKRES i WYPELN obowiązują od początku następnego okresu (rejestry cienia), przy wyłączonym PWM od razu.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pwm_avl is
  port (
    clk, rst  : in  std_logic;
    address   : in  std_logic_vector(1 downto 0);
    read      : in  std_logic;
    write     : in  std_logic;
    writedata : in  std_logic_vector(31 downto 0);
    readdata  : out std_logic_vector(31 downto 0) := (others => '0');
    irq       : out std_logic;
    pwm       : out std_logic := '0'
  );
end entity pwm_avl;

architecture rtl of pwm_avl is
  signal ster            : std_logic_vector(1 downto 0) := "00";
  signal okres_n, wyp_n  : unsigned(31 downto 0) := (others => '0');
  signal okres, wyp      : unsigned(31 downto 0) := (others => '0');
  signal licznik         : unsigned(31 downto 0) := (others => '0');
  signal koniec, pwm_r   : std_logic := '0';
begin
  process (clk)
    variable kasuj : boolean;
  begin
    if rising_edge(clk) then
      kasuj := write = '1' and address = "11" and writedata(0) = '1';
      if rst = '1' then
        ster <= "00"; okres_n <= (others => '0'); wyp_n <= (others => '0');
        okres <= (others => '0'); wyp <= (others => '0'); licznik <= (others => '0');
        koniec <= '0'; pwm_r <= '0';
      else
        if write = '1' then
          case address is
            when "00"   => ster    <= writedata(1 downto 0);
            when "01"   => okres_n <= unsigned(writedata);
            when "10"   => wyp_n   <= unsigned(writedata);
            when others => null;
          end case;
        end if;
        if ster(0) = '0' then
          licznik <= (others => '0');
          okres   <= okres_n;
          wyp     <= wyp_n;
          if kasuj then koniec <= '0'; end if;
        elsif licznik + 1 >= okres then
          licznik <= (others => '0');
          okres   <= okres_n;
          wyp     <= wyp_n;
          koniec  <= '1';                                  -- ustawienie ma pierwszeństwo przed kasowaniem
        else
          licznik <= licznik + 1;
          if kasuj then koniec <= '0'; end if;
        end if;
        pwm_r <= '1' when ster(0) = '1' and licznik < wyp else '0';
      end if;
      if read = '1' then
        case address is
          when "00"   => readdata <= (31 downto 2 => '0') & ster;
          when "01"   => readdata <= std_logic_vector(okres_n);
          when "10"   => readdata <= std_logic_vector(wyp_n);
          when others => readdata <= (31 downto 2 => '0') & pwm_r & koniec;
        end case;
      end if;
    end if;
  end process;

  pwm <= pwm_r;
  irq <= koniec and ster(1);
end architecture rtl;
