-- Dekoder instrukcji RV32I (27.07): pola rejestrów, stała natychmiastowa (I, S, B, U, J) i sygnały sterujące.
-- FENCE, ECALL i EBREAK jak NOP; nieznany kod -> nielegalna = '1' (rdzeń wykonuje NOP).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rv_dekoder is
  port (
    ins                         : in  std_logic_vector(31 downto 0);
    rd, rs1, rs2                : out std_logic_vector(4 downto 0);
    f3                          : out std_logic_vector(2 downto 0);
    imm                         : out std_logic_vector(31 downto 0);
    alu_op                      : out std_logic_vector(3 downto 0);
    a_pc, a_zero, b_imm         : out std_logic;
    zapis_rd, odczyt, zapis     : out std_logic;
    galaz, jal, jalr            : out std_logic;
    uzywa_rs1, uzywa_rs2        : out std_logic;
    nielegalna                  : out std_logic
  );
end entity rv_dekoder;

architecture rtl of rv_dekoder is
  signal imm_i, imm_s, imm_b, imm_u, imm_j : std_logic_vector(31 downto 0);
  signal fn3 : std_logic_vector(2 downto 0);
begin
  rd    <= ins(11 downto 7);
  rs1   <= ins(19 downto 15);
  rs2   <= ins(24 downto 20);
  fn3   <= ins(14 downto 12);
  f3    <= fn3;
  imm_i <= (31 downto 11 => ins(31)) & ins(30 downto 20);
  imm_s <= (31 downto 11 => ins(31)) & ins(30 downto 25) & ins(11 downto 7);
  imm_b <= (31 downto 12 => ins(31)) & ins(7) & ins(30 downto 25) & ins(11 downto 8) & '0';
  imm_u <= ins(31 downto 12) & x"000";
  imm_j <= (31 downto 20 => ins(31)) & ins(19 downto 12) & ins(20) & ins(30 downto 21) & '0';

  process (all)
  begin
    imm <= imm_i; alu_op <= "0000"; a_pc <= '0'; a_zero <= '0'; b_imm <= '0';
    zapis_rd <= '0'; odczyt <= '0'; zapis <= '0'; galaz <= '0'; jal <= '0'; jalr <= '0';
    uzywa_rs1 <= '0'; uzywa_rs2 <= '0'; nielegalna <= '0';
    case ins(6 downto 0) is
      when "0110111" =>                                                     -- LUI
        imm <= imm_u; a_zero <= '1'; b_imm <= '1'; zapis_rd <= '1';
      when "0010111" =>                                                     -- AUIPC
        imm <= imm_u; a_pc <= '1'; b_imm <= '1'; zapis_rd <= '1';
      when "1101111" =>                                                     -- JAL
        imm <= imm_j; jal <= '1'; zapis_rd <= '1';
      when "1100111" =>                                                     -- JALR
        if fn3 = "000" then
          b_imm <= '1'; jalr <= '1'; zapis_rd <= '1'; uzywa_rs1 <= '1';
        else
          nielegalna <= '1';
        end if;
      when "1100011" =>                                                     -- BRANCH
        if fn3 /= "010" and fn3 /= "011" then
          imm <= imm_b; galaz <= '1'; uzywa_rs1 <= '1'; uzywa_rs2 <= '1';
        else
          nielegalna <= '1';
        end if;
      when "0000011" =>                                                     -- LOAD
        if fn3 /= "011" and fn3 /= "110" and fn3 /= "111" then
          b_imm <= '1'; odczyt <= '1'; zapis_rd <= '1'; uzywa_rs1 <= '1';
        else
          nielegalna <= '1';
        end if;
      when "0100011" =>                                                     -- STORE
        if unsigned(fn3) <= 2 then
          imm <= imm_s; b_imm <= '1'; zapis <= '1'; uzywa_rs1 <= '1'; uzywa_rs2 <= '1';
        else
          nielegalna <= '1';
        end if;
      when "0010011" =>                                                     -- OP-IMM
        b_imm <= '1'; zapis_rd <= '1'; uzywa_rs1 <= '1';
        if fn3 = "101" then
          alu_op <= ins(30) & fn3;
        else
          alu_op <= '0' & fn3;
        end if;
      when "0110011" =>                                                     -- OP
        zapis_rd <= '1'; uzywa_rs1 <= '1'; uzywa_rs2 <= '1';
        alu_op <= ins(30) & fn3;
      when "0001111" | "1110011" => null;                                   -- FENCE, SYSTEM
      when others => nielegalna <= '1';
    end case;
  end process;
end architecture rtl;
