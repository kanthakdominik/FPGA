-- Mały procesor sekwencyjny (FSMD): 4 rejestry 8-bitowe, program 16 instrukcji w generiku PROG.
-- Sterowanie: automat FETCH -> EXEC -> FETCH … (HALT), krok tylko przy step = '1'.
-- Ścieżka danych: rejestry R0..R3, licznik rozkazów pc, rejestr instrukcji ir, ALU, rejestr wyjściowy out_data.
--
-- Instrukcja 8-bitowa, bity 7..6 = kod:
--   00 LDI rd, imm4      rd = imm                   5..4 rd, 3..0 imm
--   01 ALU rd, rs, fn    fn: 00 ADD, 01 SUB, 10 MOV (rd = rs), 11 XOR    5..4 rd, 3..2 rs, 1..0 fn
--   10 JNZ rd, addr      jeśli rd /= 0: pc = addr   5..4 rd, 3..0 addr
--   11 SYS               5..4: 00 OUT rs (3..2), 01 JMP addr (3..0), 10 HALT, 11 NOP
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tiny_cpu is
  generic (
    -- instrukcja pod adresem i: PROG(8i + 7 downto 8i); domyślnie ciąg Fibonacciego (OUT R0 w pętli)
    PROG : std_logic_vector(127 downto 0) := x"E0E0E0E0E0E0E0E0D25A466462C01100"
  );
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    step      : in  std_logic;                                 -- zezwolenie: jeden krok automatu
    out_data  : out std_logic_vector(7 downto 0);
    out_valid : out std_logic;                                 -- impuls przy wykonaniu OUT
    halted    : out std_logic;
    pc_o      : out std_logic_vector(3 downto 0)
  );
end entity tiny_cpu;

architecture rtl of tiny_cpu is
  type state_t is (ST_FETCH, ST_EXEC, ST_HALT);
  type rom_t   is array (0 to 15) of std_logic_vector(7 downto 0);
  type regs_t  is array (0 to 3) of unsigned(7 downto 0);

  function to_rom(p : std_logic_vector(127 downto 0)) return rom_t is
    variable r : rom_t;
  begin
    for i in rom_t'range loop
      r(i) := p(8 * i + 7 downto 8 * i);
    end loop;
    return r;
  end function to_rom;

  constant ROM : rom_t := to_rom(PROG);

  -- ścieżka danych: rejestry
  signal state, state_next : state_t := ST_FETCH;
  signal pc                : unsigned(3 downto 0) := (others => '0');
  signal ir                : std_logic_vector(7 downto 0) := (others => '0');
  signal r                 : regs_t;
  signal out_q             : unsigned(7 downto 0) := (others => '0');
  signal out_v             : std_logic := '0';

  signal op, rd, rs, fn    : unsigned(1 downto 0);
  signal imm               : unsigned(3 downto 0);
  signal rd_val, rs_val    : unsigned(7 downto 0);
  signal wdata             : unsigned(7 downto 0);
  signal ir_load, pc_inc, pc_load, rf_we, out_load : std_logic;
begin
  op     <= unsigned(ir(7 downto 6));
  rd     <= unsigned(ir(5 downto 4));
  rs     <= unsigned(ir(3 downto 2));
  fn     <= unsigned(ir(1 downto 0));
  imm    <= unsigned(ir(3 downto 0));
  rd_val <= r(to_integer(rd));
  rs_val <= r(to_integer(rs));

  -- ścieżka danych: ALU
  p_alu : process (all)
  begin
    if op = 0 then
      wdata <= resize(imm, 8);                                 -- LDI
    else
      case to_integer(fn) is
        when 0      => wdata <= rd_val + rs_val;
        when 1      => wdata <= rd_val - rs_val;
        when 2      => wdata <= rs_val;
        when others => wdata <= rd_val xor rs_val;
      end case;
    end if;
  end process p_alu;

  -- sterowanie: automat i sygnały sterujące ścieżką danych
  p_ctrl : process (all)
  begin
    ir_load    <= '0';
    pc_inc     <= '0';
    pc_load    <= '0';
    rf_we      <= '0';
    out_load   <= '0';
    state_next <= state;
    case state is
      when ST_FETCH =>
        if step = '1' then
          ir_load    <= '1';
          pc_inc     <= '1';
          state_next <= ST_EXEC;
        end if;
      when ST_EXEC =>
        if step = '1' then
          state_next <= ST_FETCH;
          case to_integer(op) is
            when 0 | 1 => rf_we <= '1';                        -- LDI, ALU
            when 2     =>                                      -- JNZ
              if rd_val /= 0 then
                pc_load <= '1';
              end if;
            when others =>                                     -- SYS
              case to_integer(rd) is
                when 0      => out_load   <= '1';              -- OUT
                when 1      => pc_load    <= '1';              -- JMP
                when 2      => state_next <= ST_HALT;          -- HALT
                when others => null;                           -- NOP
              end case;
          end case;
        end if;
      when ST_HALT =>
        null;
    end case;
  end process p_ctrl;

  -- ścieżka danych: zapis rejestrów
  p_dp : process (clk)
  begin
    if rising_edge(clk) then
      out_v <= out_load;
      if ir_load = '1' then
        ir <= ROM(to_integer(pc));
      end if;
      if rf_we = '1' then
        r(to_integer(rd)) <= wdata;
      end if;
      if out_load = '1' then
        out_q <= rs_val;
      end if;
      if rst = '1' then
        state <= ST_FETCH;
        pc    <= (others => '0');
      else
        state <= state_next;
        if pc_load = '1' then
          pc <= imm;
        elsif pc_inc = '1' then
          pc <= pc + 1;
        end if;
      end if;
    end if;
  end process p_dp;

  out_data  <= std_logic_vector(out_q);
  out_valid <= out_v;
  halted    <= '1' when state = ST_HALT else '0';
  pc_o      <= std_logic_vector(pc);
end architecture rtl;
