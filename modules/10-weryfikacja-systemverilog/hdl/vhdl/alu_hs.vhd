-- ALU z handshake valid/ready — układ weryfikowany w module 10. Operacja przyjęta, gdy in_valid = '1'
-- i in_ready = '1'; wynik w rejestrze wyjściowym w następnym takcie, trzymany bez zmian do odebrania
-- (out_valid = '1' i out_ready = '1'). in_ready = '1', gdy rejestr wyjściowy jest wolny albo zwalniany w tym takcie.
--
--   op: 0 ADD  carry & res = a + b           4 XOR  res = a xor b
--       1 SUB  carry & res = a - b (carry = pożyczka, a < b)
--       2 AND  res = a and b                 5 SHL  res = a sll b(SH-1 downto 0)
--       3 OR   res = a or b                  6 SHR  res = a srl b(SH-1 downto 0)
--       7 -    kod niedozwolony: err = '1', res = 0
--   carry = '0' poza ADD i SUB, zero = '1', gdy res = 0.
--
-- Generic BUG wstrzykuje błąd do ćwiczeń weryfikacji (0 = układ poprawny):
--   1 - pożyczka SUB liczona jako a <= b (błąd tylko dla a = b),
--   2 - in_ready = '1' zawsze (ignorowanie wstrzymania: nadpisanie nieodebranego wyniku).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_hs is
  generic (
    W   : positive := 8;
    BUG : natural  := 0
  );
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    in_valid  : in  std_logic;
    in_ready  : out std_logic;
    op        : in  std_logic_vector(2 downto 0);
    a         : in  std_logic_vector(W - 1 downto 0);
    b         : in  std_logic_vector(W - 1 downto 0);
    out_valid : out std_logic;
    out_ready : in  std_logic;
    res       : out std_logic_vector(W - 1 downto 0);
    carry     : out std_logic;
    zero      : out std_logic;
    err       : out std_logic
  );
end entity alu_hs;

architecture rtl of alu_hs is
  function clog2(n : positive) return natural is
    variable k : natural := 0;
  begin
    while 2 ** k < n loop
      k := k + 1;
    end loop;
    return k;
  end function clog2;

  constant SH : natural := clog2(W);

  signal valid_q : std_logic := '0';
  signal ready_i : std_logic;
  signal r       : unsigned(W - 1 downto 0);
  signal c, e    : std_logic;
begin
  process (all)
    variable s  : unsigned(W downto 0);
    variable ua : unsigned(W - 1 downto 0);
    variable ub : unsigned(W - 1 downto 0);
  begin
    ua := unsigned(a);
    ub := unsigned(b);
    r  <= (others => '0');
    c  <= '0';
    e  <= '0';
    case op is
      when "000" =>
        s := ('0' & ua) + ('0' & ub);
        r <= s(W - 1 downto 0);
        c <= s(W);
      when "001" =>
        s := ('0' & ua) - ('0' & ub);
        r <= s(W - 1 downto 0);
        if BUG = 1 then
          c <= '1' when ua <= ub else '0';
        else
          c <= s(W);
        end if;
      when "010"  => r <= ua and ub;
      when "011"  => r <= ua or ub;
      when "100"  => r <= ua xor ub;
      when "101"  => r <= shift_left(ua, to_integer(ub(SH - 1 downto 0)));
      when "110"  => r <= shift_right(ua, to_integer(ub(SH - 1 downto 0)));
      when others => e <= '1';
    end case;
  end process;

  ready_i   <= '1' when BUG = 2 or valid_q = '0' or out_ready = '1' else '0';
  in_ready  <= ready_i;
  out_valid <= valid_q;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        valid_q <= '0';
      elsif in_valid = '1' and ready_i = '1' then
        valid_q <= '1';
        res     <= std_logic_vector(r);
        carry   <= c;
        zero    <= '1' when r = 0 else '0';
        err     <= e;
      elsif out_ready = '1' then
        valid_q <= '0';
      end if;
    end if;
  end process;
end architecture rtl;
