-- Rdzeń RV32I z potokiem pięciostopniowym (27.07): IF, ID, EX, MEM, WB; pamięci z odczytem synchronicznym
-- (i_dane takt po i_adr, d_rdane takt po d_adr). Przekazywanie MEM -> EX i WB -> EX, zapis do rejestrów
-- widoczny w ID w tym samym takcie, 1 takt czekania przy load-use, skoki rozstrzygane w EX (2 takty kary).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rv_potok is
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
end entity rv_potok;

architecture rtl of rv_potok is
  constant NOP : std_logic_vector(31 downto 0) := x"00000013";            -- addi x0, x0, 0
  subtype slowo is std_logic_vector(31 downto 0);
  subtype nr_rej is std_logic_vector(4 downto 0);

  signal przekieruj, stoj : std_logic;
  signal cel, adr_nast    : slowo;
  -- IF i IF/ID
  signal pc_f             : slowo := START;
  signal pc_d             : slowo := (others => '0');
  signal ins_d            : slowo := NOP;
  signal v_d              : std_logic := '0';
  -- ID
  signal rd_d, rs1_d, rs2_d : nr_rej;
  signal f3_d             : std_logic_vector(2 downto 0);
  signal imm_d, v1_d, v2_d : slowo;
  signal alu_op_d         : std_logic_vector(3 downto 0);
  signal a_pc_d, a_zero_d, b_imm_d, zapis_rd_d, odczyt_d, zapis_d, galaz_d, jal_d, jalr_d : std_logic;
  signal uzywa_rs1_d, uzywa_rs2_d, nielegalna_d, ok_d : std_logic;
  -- ID/EX
  signal pc_e, a_e, b_e, imm_e : slowo := (others => '0');
  signal rs1_e, rs2_e, rd_e    : nr_rej := (others => '0');
  signal f3_e                  : std_logic_vector(2 downto 0) := "000";
  signal alu_op_e              : std_logic_vector(3 downto 0) := "0000";
  signal v_e, a_pc_e, a_zero_e, b_imm_e, zapis_rd_e, odczyt_e, zapis_e, galaz_e, jal_e, jalr_e : std_logic := '0';
  -- EX
  signal fa, fb, alu_a, alu_b, y, wynik_e : slowo;
  signal warunek               : std_logic;
  -- EX/MEM
  signal wynik_m, adr_m, sdane_m : slowo := (others => '0');
  signal rd_m                  : nr_rej := (others => '0');
  signal f3_m                  : std_logic_vector(2 downto 0) := "000";
  signal v_m, zapis_rd_m, odczyt_m, zapis_m : std_logic := '0';
  -- MEM/WB
  signal wynik_w               : slowo := (others => '0');
  signal rd_w                  : nr_rej := (others => '0');
  signal f3_w                  : std_logic_vector(2 downto 0) := "000";
  signal adr_w                 : std_logic_vector(1 downto 0) := "00";
  signal v_w, zapis_rd_w, odczyt_w, we_w : std_logic := '0';
  signal z_wy, o_wy, wynik_wb  : slowo;
  signal z_strb                : std_logic_vector(3 downto 0);
  signal z_m_1, z_w_1          : boolean;
begin
  -- ---------------------------------------------------------------- IF
  adr_nast <= START when rst = '1' else cel when przekieruj = '1' else pc_f when stoj = '1'
              else std_logic_vector(unsigned(pc_f) + 4);
  i_adr <= adr_nast;

  process (clk)
  begin
    if rising_edge(clk) then
      pc_f <= adr_nast;
      if rst = '1' or przekieruj = '1' then
        v_d <= '0'; ins_d <= NOP; pc_d <= (others => '0');
      elsif stoj = '0' then
        v_d <= '1'; ins_d <= i_dane; pc_d <= pc_f;
      end if;
    end if;
  end process;

  -- ---------------------------------------------------------------- ID
  u_dek : entity work.rv_dekoder port map (
    ins => ins_d, rd => rd_d, rs1 => rs1_d, rs2 => rs2_d, f3 => f3_d, imm => imm_d, alu_op => alu_op_d,
    a_pc => a_pc_d, a_zero => a_zero_d, b_imm => b_imm_d, zapis_rd => zapis_rd_d, odczyt => odczyt_d,
    zapis => zapis_d, galaz => galaz_d, jal => jal_d, jalr => jalr_d, uzywa_rs1 => uzywa_rs1_d,
    uzywa_rs2 => uzywa_rs2_d, nielegalna => nielegalna_d);
  ok_d <= v_d and not nielegalna_d;

  u_rej : entity work.rv_rejestry generic map (PRZEZ => true)
    port map (clk => clk, we => we_w, wa => rd_w, wd => wynik_wb, ra1 => rs1_d, ra2 => rs2_d, rd1 => v1_d, rd2 => v2_d);

  stoj <= '1' when v_e = '1' and odczyt_e = '1' and rd_e /= "00000" and v_d = '1' and
                   ((uzywa_rs1_d = '1' and rs1_d = rd_e) or (uzywa_rs2_d = '1' and rs2_d = rd_e)) else '0';

  process (clk)
  begin
    if rising_edge(clk) then
      pc_e <= pc_d; a_e <= v1_d; b_e <= v2_d; imm_e <= imm_d;
      rs1_e <= rs1_d; rs2_e <= rs2_d; rd_e <= rd_d; f3_e <= f3_d; alu_op_e <= alu_op_d;
      a_pc_e <= a_pc_d; a_zero_e <= a_zero_d; b_imm_e <= b_imm_d;
      if rst = '1' or przekieruj = '1' or stoj = '1' then                       -- bąbelek
        v_e <= '0'; zapis_rd_e <= '0'; odczyt_e <= '0'; zapis_e <= '0';
        galaz_e <= '0'; jal_e <= '0'; jalr_e <= '0';
      else
        v_e <= v_d; zapis_rd_e <= zapis_rd_d and ok_d; odczyt_e <= odczyt_d and ok_d;
        zapis_e <= zapis_d and ok_d; galaz_e <= galaz_d and ok_d; jal_e <= jal_d and ok_d;
        jalr_e <= jalr_d and ok_d;
      end if;
    end if;
  end process;

  -- ---------------------------------------------------------------- EX
  z_m_1 <= v_m = '1' and zapis_rd_m = '1' and odczyt_m = '0' and rd_m /= "00000";
  z_w_1 <= we_w = '1' and rd_w /= "00000";
  fa <= wynik_m when z_m_1 and rd_m = rs1_e else wynik_wb when z_w_1 and rd_w = rs1_e else a_e;
  fb <= wynik_m when z_m_1 and rd_m = rs2_e else wynik_wb when z_w_1 and rd_w = rs2_e else b_e;
  alu_a <= x"00000000" when a_zero_e = '1' else pc_e when a_pc_e = '1' else fa;
  alu_b <= imm_e when b_imm_e = '1' else fb;
  u_alu : entity work.rv_alu port map (a => alu_a, b => alu_b, op => alu_op_e, y => y);

  process (all)
  begin
    case f3_e is
      when "000"  => warunek <= '1' when fa = fb else '0';
      when "001"  => warunek <= '1' when fa /= fb else '0';
      when "100"  => warunek <= '1' when signed(fa) < signed(fb) else '0';
      when "101"  => warunek <= '1' when signed(fa) >= signed(fb) else '0';
      when "110"  => warunek <= '1' when unsigned(fa) < unsigned(fb) else '0';
      when others => warunek <= '1' when unsigned(fa) >= unsigned(fb) else '0';
    end case;
  end process;

  przekieruj <= v_e and (jal_e or jalr_e or (galaz_e and warunek));
  cel        <= y(31 downto 1) & '0' when jalr_e = '1' else std_logic_vector(unsigned(pc_e) + unsigned(imm_e));
  wynik_e    <= std_logic_vector(unsigned(pc_e) + 4) when (jal_e or jalr_e) = '1' else y;

  -- ---------------------------------------------------------------- EX/MEM, MEM
  process (clk)
  begin
    if rising_edge(clk) then
      wynik_m <= wynik_e; rd_m <= rd_e; adr_m <= y; sdane_m <= fb; f3_m <= f3_e;
      if rst = '1' then
        v_m <= '0'; zapis_rd_m <= '0'; odczyt_m <= '0'; zapis_m <= '0';
      else
        v_m <= v_e; zapis_rd_m <= zapis_rd_e; odczyt_m <= odczyt_e; zapis_m <= zapis_e;
      end if;
    end if;
  end process;

  u_wyr : entity work.rv_wyrownanie port map (
    z_f3 => f3_m, z_adr => adr_m(1 downto 0), z_dane => sdane_m, z_wy => z_wy, z_strb => z_strb,
    o_f3 => f3_w, o_adr => adr_w, o_dane => d_rdane, o_wy => o_wy);
  d_adr    <= adr_m(31 downto 2) & "00";
  d_wdane  <= z_wy;
  d_wstrb  <= z_strb when v_m = '1' and zapis_m = '1' else "0000";
  d_odczyt <= v_m and odczyt_m;

  -- ---------------------------------------------------------------- MEM/WB, WB
  process (clk)
  begin
    if rising_edge(clk) then
      wynik_w <= wynik_m; rd_w <= rd_m; f3_w <= f3_m; adr_w <= adr_m(1 downto 0);
      if rst = '1' then
        v_w <= '0'; zapis_rd_w <= '0'; odczyt_w <= '0';
      else
        v_w <= v_m; zapis_rd_w <= zapis_rd_m; odczyt_w <= odczyt_m;
      end if;
    end if;
  end process;
  we_w     <= v_w and zapis_rd_w;
  wynik_wb <= o_wy when odczyt_w = '1' else wynik_w;
  wycofana <= v_w;
end architecture rtl;
