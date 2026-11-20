-- Pamięć RAM ze slave'em AXI4 (21.03): bursty FIXED, INCR i WRAP, WSTRB, identyfikatory w BID/RID.
-- Kanał zapisu i odczytu niezależne, w każdym jedna transakcja naraz; adresy bajtowe, dane 32 bity.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_ram is
  generic (
    AW  : positive := 12;
    IDW : positive := 4
  );
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    s_awid    : in  std_logic_vector(IDW - 1 downto 0);
    s_awaddr  : in  std_logic_vector(AW - 1 downto 0);
    s_awlen   : in  std_logic_vector(7 downto 0);
    s_awsize  : in  std_logic_vector(2 downto 0);
    s_awburst : in  std_logic_vector(1 downto 0);
    s_awvalid : in  std_logic;
    s_awready : out std_logic;
    s_wdata   : in  std_logic_vector(31 downto 0);
    s_wstrb   : in  std_logic_vector(3 downto 0);
    s_wlast   : in  std_logic;
    s_wvalid  : in  std_logic;
    s_wready  : out std_logic;
    s_bid     : out std_logic_vector(IDW - 1 downto 0);
    s_bresp   : out std_logic_vector(1 downto 0);
    s_bvalid  : out std_logic;
    s_bready  : in  std_logic;
    s_arid    : in  std_logic_vector(IDW - 1 downto 0);
    s_araddr  : in  std_logic_vector(AW - 1 downto 0);
    s_arlen   : in  std_logic_vector(7 downto 0);
    s_arsize  : in  std_logic_vector(2 downto 0);
    s_arburst : in  std_logic_vector(1 downto 0);
    s_arvalid : in  std_logic;
    s_arready : out std_logic;
    s_rid     : out std_logic_vector(IDW - 1 downto 0);
    s_rdata   : out std_logic_vector(31 downto 0);
    s_rresp   : out std_logic_vector(1 downto 0);
    s_rlast   : out std_logic;
    s_rvalid  : out std_logic;
    s_rready  : in  std_logic
  );
end entity axi_ram;

architecture rtl of axi_ram is
  type mem_t is array (0 to 2 ** (AW - 2) - 1) of std_logic_vector(31 downto 0);
  signal mem : mem_t;

  -- adres następnego taktu burstu (bajtowy)
  function nast(a : unsigned; typ : std_logic_vector(1 downto 0); size : std_logic_vector(2 downto 0);
                len : std_logic_vector(7 downto 0)) return unsigned is
    variable krok, rozm, n : unsigned(AW - 1 downto 0);
  begin
    krok := shift_left(to_unsigned(1, AW), to_integer(unsigned(size)));
    n    := a + krok;
    rozm := resize(krok * (resize(unsigned(len), AW) + 1), AW);   -- rozmiar okna WRAP w bajtach
    if typ = "00" then
      return a;
    elsif typ = "10" and (n and (rozm - 1)) = 0 then
      return n - rozm;                                              -- zawinięcie na granicy okna
    else
      return n;
    end if;
  end function;

  signal w_akt, bv, r_akt, rv : std_logic := '0';
  signal w_adr, r_adr   : unsigned(AW - 1 downto 0);
  signal w_len, r_len, r_zost : std_logic_vector(7 downto 0);
  signal w_size, r_size : std_logic_vector(2 downto 0);
  signal w_typ, r_typ   : std_logic_vector(1 downto 0);
  signal w_id, r_id     : std_logic_vector(IDW - 1 downto 0);
  signal awr, wr        : std_logic;
begin
  awr       <= not w_akt and not bv;
  wr        <= w_akt;
  s_awready <= awr;
  s_wready  <= wr;
  s_arready <= not r_akt;
  s_bvalid  <= bv;
  s_rvalid  <= rv;
  s_bresp   <= "00";
  s_rresp   <= "00";

  process (clk)
  begin
    if rising_edge(clk) then
      if s_wvalid = '1' and wr = '1' then
        for b in 0 to 3 loop
          if s_wstrb(b) = '1' then
            mem(to_integer(w_adr(AW - 1 downto 2)))(b * 8 + 7 downto b * 8) <= s_wdata(b * 8 + 7 downto b * 8);
          end if;
        end loop;
      end if;
    end if;
  end process;

  -- zapis
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        w_akt <= '0';
        bv    <= '0';
      else
        if s_awvalid = '1' and awr = '1' then
          w_akt  <= '1';
          w_adr  <= unsigned(s_awaddr);
          w_len  <= s_awlen;
          w_size <= s_awsize;
          w_typ  <= s_awburst;
          w_id   <= s_awid;
        end if;
        if bv = '1' and s_bready = '1' then bv <= '0'; end if;
        if s_wvalid = '1' and wr = '1' then
          w_adr <= nast(w_adr, w_typ, w_size, w_len);
          if s_wlast = '1' then
            w_akt <= '0';
            bv    <= '1';
            s_bid <= w_id;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- odczyt
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        r_akt <= '0';
        rv    <= '0';
      else
        if s_arvalid = '1' and r_akt = '0' then
          r_akt  <= '1';
          r_adr  <= unsigned(s_araddr);
          r_len  <= s_arlen;
          r_zost <= s_arlen;
          r_size <= s_arsize;
          r_typ  <= s_arburst;
          r_id   <= s_arid;
        end if;
        if r_akt = '1' and (rv = '0' or s_rready = '1') then   -- kolejne słowo, gdy poprzednie odebrane
          s_rdata <= mem(to_integer(r_adr(AW - 1 downto 2)));
          rv      <= '1';
          s_rid   <= r_id;
          s_rlast <= '1' when unsigned(r_zost) = 0 else '0';
          r_adr   <= nast(r_adr, r_typ, r_size, r_len);
          if unsigned(r_zost) = 0 then r_akt <= '0'; end if;
          r_zost  <= std_logic_vector(unsigned(r_zost) - 1);
        elsif rv = '1' and s_rready = '1' then
          rv <= '0';
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
