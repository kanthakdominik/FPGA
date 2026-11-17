-- Blok rejestrów z interfejsem AXI4-Lite (podrzędny, dane 32 bity) — układ weryfikowany w module 11.
-- Kanały zapisu (AW, W) przyjmowane niezależnie, w dowolnej kolejności; zapis wykonywany, gdy oba są
-- w buforach, a odpowiedź B wolna. Odczyt: AR przyjmowany, gdy kanał R wolny; dane rejestrowane.
-- Jedna transakcja w toku na kierunek. Odpowiedź OKAY (00) albo SLVERR (10) dla adresu spoza mapy.
--
--   adres  nazwa    dostęp  pola
--   0x00   ID       RO      x"414C5531" ("ALU1")
--   0x04   CTRL     RW      [2:0] OP (kod operacji jak alu_hs z modułu 10), [8] IRQ_EN
--   0x08   OPA      RW      [7:0]
--   0x0C   OPB      RW      [7:0]
--   0x10   RESULT   RO      [7:0] RES, [8] CARRY, [9] ZERO, [10] ERR - liczone z OPA, OPB, OP
--   0x14   STATUS   W1C     [0] ERR - ustawiany zapisem CTRL z OP = 7, kasowany zapisem 1
--   0x18   SCRATCH  RW      [31:0] - z obsługą WSTRB (pozostałe rejestry RW: bajty 0 i 1)
--   0x1C   -                poza mapą: SLVERR, odczyt 0
--   irq = STATUS.ERR and CTRL.IRQ_EN
--
-- Generic BUG wstrzykuje błąd do ćwiczeń weryfikacji (0 = układ poprawny):
--   1 - SCRATCH ignoruje WSTRB (zapisuje wszystkie bajty),
--   2 - dowolny zapis STATUS kasuje ERR (bez sprawdzania bitu danych).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axil_regs is
  generic (
    BUG : natural := 0
  );
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    s_awvalid : in  std_logic;
    s_awready : out std_logic;
    s_awaddr  : in  std_logic_vector(4 downto 0);
    s_wvalid  : in  std_logic;
    s_wready  : out std_logic;
    s_wdata   : in  std_logic_vector(31 downto 0);
    s_wstrb   : in  std_logic_vector(3 downto 0);
    s_bvalid  : out std_logic;
    s_bready  : in  std_logic;
    s_bresp   : out std_logic_vector(1 downto 0);
    s_arvalid : in  std_logic;
    s_arready : out std_logic;
    s_araddr  : in  std_logic_vector(4 downto 0);
    s_rvalid  : out std_logic;
    s_rready  : in  std_logic;
    s_rdata   : out std_logic_vector(31 downto 0);
    s_rresp   : out std_logic_vector(1 downto 0);
    irq       : out std_logic
  );
end entity axil_regs;

architecture rtl of axil_regs is
  constant ID_VALUE : std_logic_vector(31 downto 0) := x"414C5531";
  constant OKAY     : std_logic_vector(1 downto 0)  := "00";
  constant SLVERR   : std_logic_vector(1 downto 0)  := "10";

  -- nowa wartość słowa z uwzględnieniem WSTRB
  function merge(old, data : std_logic_vector(31 downto 0); strb : std_logic_vector(3 downto 0))
    return std_logic_vector is
    variable v : std_logic_vector(31 downto 0) := old;
  begin
    for i in 0 to 3 loop
      if strb(i) = '1' then
        v(8 * i + 7 downto 8 * i) := data(8 * i + 7 downto 8 * i);
      end if;
    end loop;
    return v;
  end function merge;

  signal op        : std_logic_vector(2 downto 0) := "000";
  signal irq_en    : std_logic := '0';
  signal opa, opb  : std_logic_vector(7 downto 0) := (others => '0');
  signal st_err    : std_logic := '0';
  signal scratch   : std_logic_vector(31 downto 0) := (others => '0');
  signal result    : std_logic_vector(31 downto 0);

  signal aw_full, w_full : std_logic := '0';
  signal aw_idx          : unsigned(2 downto 0) := "000";
  signal w_data          : std_logic_vector(31 downto 0) := (others => '0');
  signal w_strb          : std_logic_vector(3 downto 0)  := (others => '0');
  signal bvalid, rvalid  : std_logic := '0';
  signal do_write        : std_logic;
  signal ctrl_q          : std_logic_vector(31 downto 0);
begin
  -- wynik ALU (jak alu_hs z modułu 10, bez handshake)
  process (all)
    variable s    : unsigned(8 downto 0);
    variable ua   : unsigned(7 downto 0);
    variable ub   : unsigned(7 downto 0);
    variable r    : unsigned(7 downto 0);
    variable c, e : std_logic;
    variable z    : std_logic;
  begin
    ua := unsigned(opa);
    ub := unsigned(opb);
    r  := (others => '0');
    c  := '0';
    e  := '0';
    case op is
      when "000" =>
        s := ('0' & ua) + ('0' & ub);
        r := s(7 downto 0);
        c := s(8);
      when "001" =>
        s := ('0' & ua) - ('0' & ub);
        r := s(7 downto 0);
        c := s(8);
      when "010"  => r := ua and ub;
      when "011"  => r := ua or ub;
      when "100"  => r := ua xor ub;
      when "101"  => r := shift_left(ua, to_integer(ub(2 downto 0)));
      when "110"  => r := shift_right(ua, to_integer(ub(2 downto 0)));
      when others => e := '1';
    end case;
    z := '1' when r = 0 else '0';
    result <= (31 downto 11 => '0') & e & z & c & std_logic_vector(r);
  end process;

  ctrl_q    <= (31 downto 9 => '0') & irq_en & "00000" & op;
  s_awready <= not aw_full;
  s_wready  <= not w_full;
  do_write  <= aw_full and w_full and not bvalid;
  s_bvalid  <= bvalid;

  write_p : process (clk)
    variable v : std_logic_vector(31 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        aw_full <= '0';
        w_full  <= '0';
        bvalid  <= '0';
        s_bresp <= OKAY;
        op      <= "000";
        irq_en  <= '0';
        opa     <= (others => '0');
        opb     <= (others => '0');
        st_err  <= '0';
        scratch <= (others => '0');
      else
        if s_awvalid = '1' and aw_full = '0' then
          aw_full <= '1';
          aw_idx  <= unsigned(s_awaddr(4 downto 2));
        end if;
        if s_wvalid = '1' and w_full = '0' then
          w_full <= '1';
          w_data <= s_wdata;
          w_strb <= s_wstrb;
        end if;
        if do_write = '1' then
          aw_full <= '0';
          w_full  <= '0';
          bvalid  <= '1';
          s_bresp <= SLVERR when aw_idx = 7 else OKAY;
          case to_integer(aw_idx) is
            when 1 =>
              v      := merge(ctrl_q, w_data, w_strb);
              op     <= v(2 downto 0);
              irq_en <= v(8);
              if v(2 downto 0) = "111" then
                st_err <= '1';
              end if;
            when 2 =>
              v   := merge(x"000000" & opa, w_data, w_strb);
              opa <= v(7 downto 0);
            when 3 =>
              v   := merge(x"000000" & opb, w_data, w_strb);
              opb <= v(7 downto 0);
            when 5 =>
              if BUG = 2 or (w_strb(0) = '1' and w_data(0) = '1') then
                st_err <= '0';
              end if;
            when 6 =>
              if BUG = 1 then
                scratch <= w_data;
              else
                scratch <= merge(scratch, w_data, w_strb);
              end if;
            when others => null;                              -- ID, RESULT: tylko odczyt; 0x1C: SLVERR
          end case;
        elsif bvalid = '1' and s_bready = '1' then
          bvalid <= '0';
        end if;
      end if;
    end if;
  end process write_p;

  s_arready <= not rvalid;
  s_rvalid  <= rvalid;

  read_p : process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        rvalid  <= '0';
        s_rdata <= (others => '0');
        s_rresp <= OKAY;
      elsif s_arvalid = '1' and rvalid = '0' then
        rvalid  <= '1';
        s_rresp <= SLVERR when s_araddr(4 downto 2) = "111" else OKAY;
        case s_araddr(4 downto 2) is
          when "000"  => s_rdata <= ID_VALUE;
          when "001"  => s_rdata <= ctrl_q;
          when "010"  => s_rdata <= x"000000" & opa;
          when "011"  => s_rdata <= x"000000" & opb;
          when "100"  => s_rdata <= result;
          when "101"  => s_rdata <= (31 downto 1 => '0') & st_err;
          when "110"  => s_rdata <= scratch;
          when others => s_rdata <= (others => '0');
        end case;
      elsif rvalid = '1' and s_rready = '1' then
        rvalid <= '0';
      end if;
    end if;
  end process read_p;

  irq <= st_err and irq_en;
end architecture rtl;
