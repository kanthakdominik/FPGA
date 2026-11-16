-- Testbench bufora skid: losowe valid i ready; kolejność i komplet słów, stabilność danych
-- przy wstrzymaniu wyjścia, a przy ciągłym przepływie — jedno słowo na takt.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_skid_buffer is
end entity tb_skid_buffer;

architecture sim of tb_skid_buffer is
  constant W  : positive := 8;
  constant N  : positive := 200;
  signal clk  : std_logic := '0';
  signal done : boolean   := false;
  signal rst  : std_logic := '1';
  signal s_data  : std_logic_vector(W - 1 downto 0) := (others => '0');
  signal s_valid : std_logic := '0';
  signal m_ready : std_logic := '0';
  signal s_ready, m_valid : std_logic;
  signal m_data  : std_logic_vector(W - 1 downto 0);
begin
  clk <= not clk after 5 ns when not done;

  dut : entity work.skid_buffer
    generic map (W => W)
    port map (clk => clk, rst => rst, s_data => s_data, s_valid => s_valid, s_ready => s_ready,
              m_data => m_data, m_valid => m_valid, m_ready => m_ready);

  stim : process
    variable errors    : natural := 0;
    variable l         : line;
    variable next_in   : natural := 0;
    variable next_out  : natural := 0;
    variable cycles    : natural := 0;
    variable s_fire, m_fire, m_stall : boolean := false;
    variable data_prev : std_logic_vector(W - 1 downto 0) := (others => '0');
    variable v_valid, v_ready : std_logic;
    variable lfsr      : unsigned(15 downto 0) := x"1D0B";
    procedure check(ok : boolean; msg : string) is
    begin
      if not ok then
        errors := errors + 1;
        report msg severity warning;
      end if;
    end procedure;
  begin
    wait until falling_edge(clk);
    wait until falling_edge(clk);
    rst     <= '0';
    v_valid := '0';
    while next_out < N and cycles < 10 * N loop
      wait until falling_edge(clk);
      cycles := cycles + 1;
      if m_fire then
        check(to_integer(unsigned(data_prev)) = next_out mod 2 ** W,
              "odebrano " & integer'image(to_integer(unsigned(data_prev))) & ", oczekiwano " & integer'image(next_out));
        next_out := next_out + 1;
      end if;
      if m_stall then
        check(m_valid = '1' and m_data = data_prev, "zmiana wyjscia przy ready = 0");
      end if;
      if s_fire then
        next_in := next_in + 1;
      end if;
      if lfsr(0) = '1' then
        lfsr := shift_right(lfsr, 1) xor x"B400";
      else
        lfsr := shift_right(lfsr, 1);
      end if;
      if v_valid = '0' or s_fire then
        if next_in < N then
          v_valid := lfsr(0);
        else
          v_valid := '0';
        end if;
        s_data <= std_logic_vector(to_unsigned(next_in mod 2 ** W, W));
      end if;
      v_ready := lfsr(3) or lfsr(5);
      s_valid <= v_valid;
      m_ready <= v_ready;
      -- stan widoczny aż do następnego zbocza narastającego (s_ready, m_valid, m_data są z rejestrów)
      s_fire    := v_valid = '1' and s_ready = '1';
      m_fire    := m_valid = '1' and v_ready = '1';
      m_stall   := m_valid = '1' and v_ready = '0';
      data_prev := m_data;
    end loop;
    check(next_out = N, "odebrano " & integer'image(next_out) & " slow");

    s_valid <= '1';
    m_ready <= '1';
    for k in 1 to 3 loop
      wait until falling_edge(clk);
    end loop;
    cycles := 0;
    for k in 1 to 50 loop
      wait until falling_edge(clk);
      if m_valid = '1' and s_ready = '1' then
        cycles := cycles + 1;
      end if;
    end loop;
    check(cycles = 50, "przy ciaglym przeplywie " & integer'image(cycles) & " slow na 50 taktow");

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
