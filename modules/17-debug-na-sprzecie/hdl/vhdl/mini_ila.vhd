-- Wbudowany analizator logiczny w miniaturze (17.02): bufor kołowy 2^AW próbek, warunek wyzwolenia
-- (wartość z maską, poziom albo zbocze warunku), pre próbek przed wyzwoleniem, odczyt po zakończeniu.
-- rd_addr = 0 - najstarsza próbka, rd_addr = pre - próbka wyzwolenia. Wyzwolenie jest ignorowane,
-- dopóki bufor nie zbierze pre próbek. trig_out - impuls w takcie po wyzwoleniu.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mini_ila is
  generic (
    W  : positive := 16;
    AW : positive := 8
  );
  port (
    clk         : in  std_logic;
    rst         : in  std_logic;
    probe       : in  std_logic_vector(W - 1 downto 0);
    arm         : in  std_logic;
    trig_val    : in  std_logic_vector(W - 1 downto 0);
    trig_mask   : in  std_logic_vector(W - 1 downto 0);
    trig_zbocze : in  std_logic;
    pre         : in  std_logic_vector(AW - 1 downto 0);
    rd_addr     : in  std_logic_vector(AW - 1 downto 0);
    rd_data     : out std_logic_vector(W - 1 downto 0);
    armed       : out std_logic;
    capturing   : out std_logic;
    done        : out std_logic;
    trig_out    : out std_logic
  );
end entity mini_ila;

architecture rtl of mini_ila is
  type stan_t is (S_IDLE, S_PRE, S_WAIT, S_POST);
  type mem_t is array (0 to 2 ** AW - 1) of std_logic_vector(W - 1 downto 0);
  constant OSTATNI : unsigned(AW - 1 downto 0) := (others => '1');
  constant ZERO_W  : std_logic_vector(W - 1 downto 0) := (others => '0');

  signal mem        : mem_t;
  signal stan       : stan_t := S_IDLE;
  signal zakonczony : std_logic := '0';
  signal arm_d      : std_logic := '0';
  signal war, war_d : std_logic := '0';
  signal wyzw, zapis : std_logic;
  signal wr_ptr, licz, trig_ptr : unsigned(AW - 1 downto 0) := (others => '0');
  signal p          : unsigned(AW - 1 downto 0);
begin
  p     <= unsigned(pre);
  war   <= '1' when ((probe xor trig_val) and trig_mask) = ZERO_W else '0';
  wyzw  <= war and ((not trig_zbocze) or (not war_d));
  zapis <= '0' when stan = S_IDLE else '1';

  process (clk)
  begin
    if rising_edge(clk) then
      if zapis = '1' then
        mem(to_integer(wr_ptr)) <= probe;
      end if;
      rd_data <= mem(to_integer(trig_ptr - p + unsigned(rd_addr)));
    end if;
  end process;

  process (clk)
  begin
    if rising_edge(clk) then
      arm_d    <= arm;
      war_d    <= war;
      trig_out <= '0';
      if rst = '1' then
        stan       <= S_IDLE;
        zakonczony <= '0';
        wr_ptr     <= (others => '0');
        licz       <= (others => '0');
        trig_ptr   <= (others => '0');
        arm_d      <= '0';
      else
        if zapis = '1' then
          wr_ptr <= wr_ptr + 1;
        end if;
        case stan is
          when S_IDLE =>
            if arm = '1' and arm_d = '0' then
              zakonczony <= '0';
              licz       <= (others => '0');
              if p = 0 then
                stan <= S_WAIT;
              else
                stan <= S_PRE;
              end if;
            end if;
          when S_PRE =>                                  -- próbki sprzed wyzwolenia
            licz <= licz + 1;
            if licz + 1 = p then
              stan <= S_WAIT;
            end if;
          when S_WAIT =>
            if wyzw = '1' then
              trig_ptr <= wr_ptr;                        -- próbka wyzwolenia zapisywana w tym takcie
              trig_out <= '1';
              licz     <= OSTATNI - p;
              if p = OSTATNI then
                stan       <= S_IDLE;
                zakonczony <= '1';
              else
                stan <= S_POST;
              end if;
            end if;
          when S_POST =>
            licz <= licz - 1;
            if licz = 1 then
              stan       <= S_IDLE;
              zakonczony <= '1';
            end if;
        end case;
      end if;
    end if;
  end process;

  armed     <= '1' when stan = S_PRE or stan = S_WAIT else '0';
  capturing <= '1' when stan = S_POST else '0';
  done      <= zakonczony;
end architecture rtl;
