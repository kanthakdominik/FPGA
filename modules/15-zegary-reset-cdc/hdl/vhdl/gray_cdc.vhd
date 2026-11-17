-- Licznik przesyłany między domenami w kodzie Graya (15.04): w domenie źródłowej licznik binarny
-- i jego kod Graya gray_r (rejestr - bez logiki między nim a synchronizatorem); w domenie docelowej
-- synchronizator wektorowy i konwersja z powrotem na binarny. Ponieważ kolejne wartości Graya różnią się
-- jednym bitem, odczyt w trakcie zmiany daje starą albo nową wartość - nigdy przypadkową.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gray_cdc is
  generic (
    W      : positive := 4;
    STAGES : positive := 2
  );
  port (
    clk_src   : in  std_logic;
    rst_src   : in  std_logic;
    inc       : in  std_logic;
    src_count : out unsigned(W - 1 downto 0);
    clk_dst   : in  std_logic;
    dst_count : out unsigned(W - 1 downto 0)
  );
end entity gray_cdc;

architecture rtl of gray_cdc is
  function bin2gray(b : unsigned) return std_logic_vector is
  begin
    return std_logic_vector(b xor shift_right(b, 1));
  end function;

  function gray2bin(g : std_logic_vector) return unsigned is
    variable b : unsigned(g'range);
  begin
    b(g'high) := g(g'high);
    for i in g'high - 1 downto g'low loop
      b(i) := b(i + 1) xor g(i);
    end loop;
    return b;
  end function;

  signal cnt      : unsigned(W - 1 downto 0) := (others => '0');
  signal gray_r   : std_logic_vector(W - 1 downto 0) := (others => '0');
  signal gray_dst : std_logic_vector(W - 1 downto 0);
begin
  process (clk_src)
  begin
    if rising_edge(clk_src) then
      if rst_src = '1' then
        cnt    <= (others => '0');
        gray_r <= (others => '0');
      elsif inc = '1' then
        cnt    <= cnt + 1;
        gray_r <= bin2gray(cnt + 1);
      end if;
    end if;
  end process;
  src_count <= cnt;

  u_sync : entity work.sync_bit
    generic map (STAGES => STAGES, W => W)
    port map (clk => clk_dst, d => gray_r, q => gray_dst);

  dst_count <= gray2bin(gray_dst);
end architecture rtl;
