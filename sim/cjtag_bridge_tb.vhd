library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cjtag_bridge_tb is
end cjtag_bridge_tb;

architecture cjtag_bridge_tb_rtl of cjtag_bridge_tb is

  -- output <cycles> bits on TMSC --
  procedure WriteEscapeSeq(cycles : natural) is
  begin
    for i in 0 to cycles-1 loop
    
    end loop;
  end procedure;

  -- dut --
  component cjtag_bridge
  port (
    -- global control --
    clk_i     : in  std_ulogic;
    rstn_i    : in  std_ulogic;
    -- cJTAG --
    trstn_i   : in  std_ulogic;
    tckc_i    : in  std_ulogic;
    tmsc_i    : in  std_ulogic;
    tmsc_o    : out std_ulogic;
    tmsc_oe_o : out std_ulogic;
    -- JTAG --
    trstn_o   : out std_ulogic;
    tck_o     : out std_ulogic;
    tdi_o     : out std_ulogic;
    tdo_i     : in  std_ulogic;
    tms_o     : out std_ulogic
  );
  end component;

  -- generators --
  signal clk_gen, rstn_gen : std_ulogic := '0';

  -- cJTAG interface --
  type cjtag_t is record
    trstn   : std_ulogic;
    tckc    : std_ulogic;
    tmsc    : std_ulogic;
    tmsc_rd : std_ulogic;
  end record;
  signal cjtag : cjtag_t;

begin

  -- Generators -----------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  clk_gen  <= not clk_gen after 10 ns;
  rstn_gen <= '0', '1' after 60 ns;


  -- Device-under-Test ----------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  cjtag_bridge_inst: cjtag_bridge
  port map (
    -- global control --
    clk_i     => clk_gen,
    rstn_i    => rstn_gen,
    -- cJTAG --
    trstn_i   => cjtag.trstn,
    tckc_i    => cjtag.tckc,
    tmsc_i    => cjtag.tmsc,
    tmsc_o    => cjtag.tmsc_rd,
    tmsc_oe_o => open,
    -- JTAG --
    trstn_o   => open,
    tck_o     => open,
    tdi_o     => open,
    tdo_i     => '-',
    tms_o     => open
  );


  -- Stimulus -------------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  stimulus: process
  begin
    -- hardware reset --
    cjtag.trstn <= '0';
    cjtag.tckc  <= '0';
    cjtag.tmsc  <= '0';
    wait for 100 ns;
    cjtag.trstn <= '1';
    wait for 100 ns;

    -- protocol reset: 8 TMSC edges while TCKC is kept high --
    cjtag.tckc <= '1';
    cjtag.tmsc <= '0';
    wait for 100 ns;
    cjtag.tmsc <= '1';
    wait for 100 ns;
    cjtag.tmsc <= '0';
    wait for 100 ns;
    cjtag.tmsc <= '1';
    wait for 100 ns;
    cjtag.tmsc <= '0';
    wait for 100 ns;
    cjtag.tmsc <= '1';
    wait for 100 ns;
    cjtag.tmsc <= '0';
    wait for 100 ns;
    cjtag.tmsc <= '1';
    wait for 100 ns;
    cjtag.tmsc <= '0';
    wait for 100 ns;

    -- activation sequence (each nibble is transmitted LSB-first) --
    cjtag.tckc <= '0';
    wait for 100 ns;

    -- OAC --
    cjtag.tckc <= '1'; cjtag.tmsc <= '0';
    wait for 100 ns;
    cjtag.tckc <= '0'; cjtag.tmsc <= '0';
    wait for 100 ns;

    cjtag.tckc <= '1'; cjtag.tmsc <= '0';
    wait for 100 ns;
    cjtag.tckc <= '0'; cjtag.tmsc <= '0';
    wait for 100 ns;

    cjtag.tckc <= '1'; cjtag.tmsc <= '1';
    wait for 100 ns;
    cjtag.tckc <= '0'; cjtag.tmsc <= '1';
    wait for 100 ns;

    cjtag.tckc <= '1'; cjtag.tmsc <= '1';
    wait for 100 ns;
    cjtag.tckc <= '0'; cjtag.tmsc <= '1';
    wait for 100 ns;

    -- EC --
    cjtag.tckc <= '1'; cjtag.tmsc <= '0';
    wait for 100 ns;
    cjtag.tckc <= '0'; cjtag.tmsc <= '0';
    wait for 100 ns;

    cjtag.tckc <= '1'; cjtag.tmsc <= '0';
    wait for 100 ns;
    cjtag.tckc <= '0'; cjtag.tmsc <= '0';
    wait for 100 ns;

    cjtag.tckc <= '1'; cjtag.tmsc <= '0';
    wait for 100 ns;
    cjtag.tckc <= '0'; cjtag.tmsc <= '0';
    wait for 100 ns;

    cjtag.tckc <= '1'; cjtag.tmsc <= '1';
    wait for 100 ns;
    cjtag.tckc <= '0'; cjtag.tmsc <= '1';
    wait for 100 ns;

    -- CP --
    cjtag.tckc <= '1'; cjtag.tmsc <= '0';
    wait for 100 ns;
    cjtag.tckc <= '0'; cjtag.tmsc <= '0';
    wait for 100 ns;

    cjtag.tckc <= '1'; cjtag.tmsc <= '0';
    wait for 100 ns;
    cjtag.tckc <= '0'; cjtag.tmsc <= '0';
    wait for 100 ns;

    cjtag.tckc <= '1'; cjtag.tmsc <= '0';
    wait for 100 ns;
    cjtag.tckc <= '0'; cjtag.tmsc <= '0';
    wait for 100 ns;

    cjtag.tckc <= '1'; cjtag.tmsc <= '0';
    wait for 100 ns;
    cjtag.tckc <= '0'; cjtag.tmsc <= '0';
    wait for 100 ns;
    wait for 100 ns;

    -- JTAG transmission - bit 0 --
    cjtag.tckc <= '1'; cjtag.tmsc <= '0';
    wait for 100 ns;
    cjtag.tckc <= '0'; cjtag.tmsc <= '0';
    wait for 100 ns;

    cjtag.tckc <= '1'; cjtag.tmsc <= '1';
    wait for 100 ns;
    cjtag.tckc <= '0'; cjtag.tmsc <= '1';
    wait for 100 ns;

    cjtag.tckc <= '1'; cjtag.tmsc <= '0';
    wait for 100 ns;
    cjtag.tckc <= '0'; cjtag.tmsc <= '0';
    wait for 100 ns;

    -- JTAG transmission - bit 1 --
    cjtag.tckc <= '1'; cjtag.tmsc <= '1';
    wait for 100 ns;
    cjtag.tckc <= '0'; cjtag.tmsc <= '1';
    wait for 100 ns;

    cjtag.tckc <= '1'; cjtag.tmsc <= '0';
    wait for 100 ns;
    cjtag.tckc <= '0'; cjtag.tmsc <= '0';
    wait for 100 ns;

    cjtag.tckc <= '1'; cjtag.tmsc <= '0';
    wait for 100 ns;
    cjtag.tckc <= '0'; cjtag.tmsc <= '0';
    wait for 100 ns;

    wait;
  end process stimulus;


end cjtag_bridge_tb_rtl;
