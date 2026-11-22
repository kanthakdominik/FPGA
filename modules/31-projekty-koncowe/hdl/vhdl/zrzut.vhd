-- Akwizycja oscyloskopu (31.02), domena zegara ADC: historia PRZED próbek, wyzwolenie zboczem narastającym
-- albo po AUTO próbkach (tryb auto), N - PRZED - 1 próbek po wyzwoleniu, przekazanie banku przełącznikiem
-- gotowy_t z potwierdzeniem potw_t. Jak w wersjach Verilog i SystemVerilog.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity zrzut is
  generic (AW : positive := 9; PRZED : positive := 64; AUTO : positive := 4096);
  port (
    clk, rst    : in  std_logic;
    we          : in  std_logic;
    probka      : in  std_logic_vector(11 downto 0);
    poziom      : in  std_logic_vector(11 downto 0);
    dziel       : in  unsigned(7 downto 0);
    tryb_auto   : in  std_logic;
    ram_we      : out std_logic := '0';
    ram_adr     : out unsigned(AW downto 0) := (others => '0');
    ram_dane    : out std_logic_vector(7 downto 0) := (others => '0');
    bank_gotowy : out std_logic := '0';
    poczatek    : out unsigned(AW - 1 downto 0) := (others => '0');
    wyzwolony   : out std_logic := '0';
    gotowy_t    : out std_logic := '0';
    potw_t      : in  std_logic;
    zajety      : out std_logic
  );
end entity zrzut;

architecture rtl of zrzut is
  type stan_t is (S_PRZED, S_CZEKA, S_PO, S_GOTOWE);
  constant N : positive := 2 ** AW;
  signal stan     : stan_t := S_PRZED;
  signal s_potw   : std_logic_vector(1 downto 0) := "00";
  signal bank     : std_logic := '0';
  signal wp       : unsigned(AW - 1 downto 0) := (others => '0');
  signal licz     : natural range 0 to N := 0;
  signal czekanie : natural range 0 to AUTO := 0;
  signal fd       : unsigned(7 downto 0) := (others => '0');
  signal poprz    : unsigned(11 downto 0) := (others => '0');
  signal got      : std_logic := '0';
  signal bierz, zbocze : boolean;

  attribute altera_attribute : string;
  attribute altera_attribute of s_potw : signal is "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS";
begin
  gotowy_t <= got;
  zajety <= '0' when stan = S_GOTOWE else '1';
  bierz  <= we = '1' and fd = 0;
  zbocze <= poprz < unsigned(poziom) and unsigned(probka) >= unsigned(poziom);

  process (clk)
  begin
    if rising_edge(clk) then
      s_potw <= s_potw(0) & potw_t;
      ram_we <= '0';
      if rst = '1' then
        stan <= S_PRZED; bank <= '0'; wp <= (others => '0'); licz <= 0; fd <= (others => '0');
        czekanie <= 0; got <= '0';
      else
        if we = '1' then
          if fd + 1 >= dziel then fd <= (others => '0'); else fd <= fd + 1; end if;
        end if;
        if bierz and stan /= S_GOTOWE then
          ram_we   <= '1';
          ram_adr  <= bank & wp;
          ram_dane <= probka(11 downto 4);
          wp       <= wp + 1;
          poprz    <= unsigned(probka);
        end if;
        case stan is
          when S_PRZED =>
            if bierz then
              licz <= licz + 1;
              if licz = PRZED - 1 then
                stan <= S_CZEKA;
                czekanie <= 0;
              end if;
            end if;
          when S_CZEKA =>
            if bierz then
              if czekanie < AUTO then czekanie <= czekanie + 1; end if;
              if zbocze or (tryb_auto = '1' and czekanie = AUTO) then
                poczatek <= wp - PRZED;
                if zbocze then wyzwolony <= '1'; else wyzwolony <= '0'; end if;
                licz <= 0;
                stan <= S_PO;
              end if;
            end if;
          when S_PO =>
            if bierz then
              licz <= licz + 1;
              if licz = N - PRZED - 2 then
                bank_gotowy <= bank;
                got <= not got;
                stan <= S_GOTOWE;
              end if;
            end if;
          when S_GOTOWE =>
            if s_potw(1) = got then
              bank <= not bank;
              licz <= 0;
              stan <= S_PRZED;
            end if;
        end case;
      end if;
    end if;
  end process;
end architecture rtl;
