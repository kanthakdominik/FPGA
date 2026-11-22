-- Rdzeń RV32I jednocyklowy (27.07): każda instrukcja w jednym takcie, pamięć z odczytem kombinacyjnym.
-- Zapis do pamięci: d_wstrb /= "0000", dane powielone na pasy, adres wyrównany do słowa.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rv_jedno is
  generic (START : std_logic_vector(31 downto 0) := x"00000000");
  port (
    clk, rst : in  std_logic;
    i_adr    : out std_logic_vector(31 downto 0);
    i_dane   : in  std_logic_vector(31 downto 0);
    d_adr    : out std_logic_vector(31 downto 0);
    d_wdane  : out std_logic_vector(31 downto 0);
    d_wstrb  : out std_logic_vector(3 downto 0);
    d_odczyt : out std_logic;
    d_rdane  : in  std_logic_vector(31 downto 0);
    wycofana : out std_logic
  );
end entity rv_jedno;

architecture rtl of rv_jedno is
  signal pc                                   : std_logic_vector(31 downto 0) := START;
  signal rd, rs1, rs2                         : std_logic_vector(4 downto 0);
  signal f3                                   : std_logic_vector(2 downto 0);
  signal imm, v1, v2, a, b, y, wynik, pc4     : std_logic_vector(31 downto 0);
  signal z_wy, o_wy                           : std_logic_vector(31 downto 0);
  signal z_strb                               : std_logic_vector(3 downto 0);
  signal alu_op                               : std_logic_vector(3 downto 0);
  signal a_pc, a_zero, b_imm, zapis_rd, odczyt, zapis, galaz, jal, jalr : std_logic;
  signal we_rej, warunek                      : std_logic;
begin
  i_adr <= pc;
  u_dek : entity work.rv_dekoder port map (
    ins => i_dane, rd => rd, rs1 => rs1, rs2 => rs2, f3 => f3, imm => imm, alu_op => alu_op,
    a_pc => a_pc, a_zero => a_zero, b_imm => b_imm, zapis_rd => zapis_rd, odczyt => odczyt, zapis => zapis,
    galaz => galaz, jal => jal, jalr => jalr, uzywa_rs1 => open, uzywa_rs2 => open, nielegalna => open);

  we_rej <= zapis_rd and not rst;
  u_rej : entity work.rv_rejestry generic map (PRZEZ => false)
    port map (clk => clk, we => we_rej, wa => rd, wd => wynik, ra1 => rs1, ra2 => rs2, rd1 => v1, rd2 => v2);

  a <= x"00000000" when a_zero = '1' else pc when a_pc = '1' else v1;
  b <= imm when b_imm = '1' else v2;
  u_alu : entity work.rv_alu port map (a => a, b => b, op => alu_op, y => y);

  process (all)
  begin
    case f3 is
      when "000"  => warunek <= '1' when v1 = v2 else '0';
      when "001"  => warunek <= '1' when v1 /= v2 else '0';
      when "100"  => warunek <= '1' when signed(v1) < signed(v2) else '0';
      when "101"  => warunek <= '1' when signed(v1) >= signed(v2) else '0';
      when "110"  => warunek <= '1' when unsigned(v1) < unsigned(v2) else '0';
      when others => warunek <= '1' when unsigned(v1) >= unsigned(v2) else '0';
    end case;
  end process;

  pc4 <= std_logic_vector(unsigned(pc) + 4);

  u_wyr : entity work.rv_wyrownanie port map (
    z_f3 => f3, z_adr => y(1 downto 0), z_dane => v2, z_wy => z_wy, z_strb => z_strb,
    o_f3 => f3, o_adr => y(1 downto 0), o_dane => d_rdane, o_wy => o_wy);
  d_adr    <= y(31 downto 2) & "00";
  d_wdane  <= z_wy;
  d_wstrb  <= z_strb when zapis = '1' and rst = '0' else "0000";
  d_odczyt <= odczyt and not rst;

  wynik    <= o_wy when odczyt = '1' else pc4 when (jal or jalr) = '1' else y;
  wycofana <= not rst;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        pc <= START;
      elsif jal = '1' then
        pc <= std_logic_vector(unsigned(pc) + unsigned(imm));
      elsif jalr = '1' then
        pc <= y(31 downto 1) & '0';
      elsif galaz = '1' and warunek = '1' then
        pc <= std_logic_vector(unsigned(pc) + unsigned(imm));
      else
        pc <= pc4;
      end if;
    end if;
  end process;
end architecture rtl;
