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
    tckc_i    : in  std_ulogic;
    tmsc_i    : in  std_ulogic;
    tmsc_o    : out std_ulogic;
    tmsc_oe_o : out std_ulogic;
    -- JTAG --
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
    tckc_i    => cjtag.tckc,
    tmsc_i    => cjtag.tmsc,
    tmsc_o    => cjtag.tmsc_rd,
    tmsc_oe_o => open,
    -- JTAG --
    tck_o     => open,
    tdi_o     => open,
    tdo_i     => '0',
    tms_o     => open
  );


  -- Stimulus -------------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  stimulus: process
  begin
    cjtag.tckc <= '0';
    cjtag.tmsc <= '0';
    wait for 200 ns;

    -- WriteEscapeSeq(10); --
    -- protocol reset: 10 TMSC edges while TCKC is kept high --
    cjtag.tckc <= '1';
    cjtag.tmsc <= '0';
    wait for 100 ns;
    for i in 0 to 9 loop
      cjtag.tmsc <= not cjtag.tmsc;
      wait for 100 ns;
    end loop;

    -- WriteTMS(0xFFFFFFFF, xx); --
    -- send >= 22 dummy clocks to reset 4-wire JTAG --
    cjtag.tmsc <= '1';
    wait for 100 ns;
    for i in 0 to 22*2 loop
      cjtag.tckc <= not cjtag.tckc;
      wait for 100 ns;
    end loop;

    -- WriteTMS(0x00, 1); --
    -- TAP reset --
    cjtag.tckc <= '0';
    cjtag.tmsc <= '0';
    wait for 100 ns;
    cjtag.tckc <= '1'; cjtag.tmsc <= '0';
    wait for 100 ns;
    cjtag.tckc <= '0'; cjtag.tmsc <= '0';
    wait for 100 ns;

    -- WriteEscapeSeq(7); --
    -- escape sequence selection --
    cjtag.tckc <= '1';
    cjtag.tmsc <= '0';
    wait for 100 ns;
    for i in 0 to 6 loop
      cjtag.tmsc <= not cjtag.tmsc;
      wait for 100 ns;
    end loop;

    -- WriteTMS(0x0C, 4); --
    -- write 4-bit OAC --
    cjtag.tckc <= '0';
    cjtag.tmsc <= '0';
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

    cjtag.tckc <= '1'; cjtag.tmsc <= '1';
    wait for 100 ns;
    cjtag.tckc <= '0'; cjtag.tmsc <= '1';
    wait for 100 ns;

    -- WriteTMS(0x08, 4); --
    -- write 4-bit EC --
    cjtag.tckc <= '0';
    cjtag.tmsc <= '0';
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

    cjtag.tckc <= '1'; cjtag.tmsc <= '1';
    wait for 100 ns;
    cjtag.tckc <= '0'; cjtag.tmsc <= '1';
    wait for 100 ns;

    -- WriteTMS(0x00, 4); --
    -- write 4-bit CP --
    cjtag.tckc <= '0';
    cjtag.tmsc <= '0';
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

    cjtag.tckc <= '1'; cjtag.tmsc <= '0';
    wait for 100 ns;
    cjtag.tckc <= '0'; cjtag.tmsc <= '0';
    wait for 100 ns;

    wait for 200 ns;

    -- JTAG transmission --
    --  TDI=1, TMS=1
    cjtag.tmsc <= '0';
    wait for 100 ns;
    cjtag.tckc <= '1';
    wait for 100 ns;
    cjtag.tckc <= '0'; cjtag.tmsc <= '1';
    wait for 100 ns;
    cjtag.tckc <= '1';
    wait for 100 ns;
    cjtag.tckc <= '0'; cjtag.tmsc <= '0';
    wait for 100 ns;
    cjtag.tckc <= '1';
    wait for 100 ns;
    cjtag.tckc <= '0';
    wait for 100 ns;

    -- JTAG transmission --
    --  TDI=0, TMS=0
    cjtag.tmsc <= '1';
    wait for 100 ns;
    cjtag.tckc <= '1';
    wait for 100 ns;
    cjtag.tckc <= '0'; cjtag.tmsc <= '0';
    wait for 100 ns;
    cjtag.tckc <= '1';
    wait for 100 ns;
    cjtag.tckc <= '0'; cjtag.tmsc <= '0';
    wait for 100 ns;
    cjtag.tckc <= '1';
    wait for 100 ns;
    cjtag.tckc <= '0';
    wait for 100 ns;


    wait;
  end process stimulus;


end cjtag_bridge_tb_rtl;
