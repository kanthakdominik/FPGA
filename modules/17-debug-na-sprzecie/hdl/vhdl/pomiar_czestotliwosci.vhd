-- Miernik częstotliwości (17.01): liczba taktów clk_mier w oknie BRAMKA taktów clk_ref. Licznik Graya
-- w domenie mierzonej, synchronizator 2FF i różnica stanów w domenie odniesienia; dokładność ±1,
-- pierwszy wynik po resecie pominięty.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pomiar_czestotliwosci is
  generic (
    CW     : positive := 24;
    BRAMKA : positive := 50000
  );
  port (
    clk_ref     : in  std_logic;
    rst         : in  std_logic;
    clk_mier    : in  std_logic;
    wynik       : out std_logic_vector(CW - 1 downto 0);
    wynik_valid : out std_logic
  );
end entity pomiar_czestotliwosci;

architecture rtl of pomiar_czestotliwosci is
  signal cnt_m, gray_m  : unsigned(CW - 1 downto 0) := (others => '0');
  signal sync1, sync2   : unsigned(CW - 1 downto 0) := (others => '0');
  signal bin_now        : unsigned(CW - 1 downto 0);
  signal bin_prev       : unsigned(CW - 1 downto 0) := (others => '0');
  signal okno           : natural range 0 to BRAMKA - 1 := 0;
  signal pierwszy       : std_logic := '1';
  signal wynik_r        : unsigned(CW - 1 downto 0) := (others => '0');
  signal valid_r        : std_logic := '0';

  attribute ASYNC_REG : string;
  attribute ASYNC_REG of sync1, sync2 : signal is "TRUE";
  attribute altera_attribute : string;
  attribute altera_attribute of sync1, sync2 : signal is "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS";
begin
  -- domena mierzona
  process (clk_mier)
  begin
    if rising_edge(clk_mier) then
      cnt_m  <= cnt_m + 1;
      gray_m <= cnt_m xor shift_right(cnt_m, 1);
    end if;
  end process;

  -- domena odniesienia
  process (clk_ref)
  begin
    if rising_edge(clk_ref) then
      sync1 <= gray_m;
      sync2 <= sync1;
    end if;
  end process;

  process (sync2)
    variable b : unsigned(CW - 1 downto 0);
  begin
    b(CW - 1) := sync2(CW - 1);
    for k in CW - 2 downto 0 loop
      b(k) := b(k + 1) xor sync2(k);
    end loop;
    bin_now <= b;
  end process;

  process (clk_ref)
  begin
    if rising_edge(clk_ref) then
      valid_r <= '0';
      if rst = '1' then
        okno     <= 0;
        pierwszy <= '1';
      elsif okno = BRAMKA - 1 then
        okno     <= 0;
        bin_prev <= bin_now;
        pierwszy <= '0';
        if pierwszy = '0' then
          wynik_r <= bin_now - bin_prev;
          valid_r <= '1';
        end if;
      else
        okno <= okno + 1;
      end if;
    end if;
  end process;

  wynik       <= std_logic_vector(wynik_r);
  wynik_valid <= valid_r;
end architecture rtl;
