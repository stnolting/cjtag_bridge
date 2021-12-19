-- #################################################################################################
-- # <<cjtag_bridge>> cJTAG to 4-Wire JTAG Bridge                                                  #
-- # ********************************************************************************************* #
-- # Converts a debugger probe's compact JTAG (cJTAG) port into a 4-wire IEEE 1149.1 JTAG port.    #
-- # This bridge only supports "OScan1" cJTAG format.                                              #
-- #                                                                                               #
-- # IMPORTANT                                                                                     #
-- # * TCKC (tckc_i) input frequency must not exceed 1/5 of clk_i frequency                        #
-- # * all 4-wire JTAG signals are expected to be sync to clk_i                                    #
-- # ********************************************************************************************* #
-- # BSD 3-Clause License                                                                          #
-- #                                                                                               #
-- # Copyright (c) 2021, Stephan Nolting. All rights reserved.                                     #
-- #                                                                                               #
-- # Redistribution and use in source and binary forms, with or without modification, are          #
-- # permitted provided that the following conditions are met:                                     #
-- #                                                                                               #
-- # 1. Redistributions of source code must retain the above copyright notice, this list of        #
-- #    conditions and the following disclaimer.                                                   #
-- #                                                                                               #
-- # 2. Redistributions in binary form must reproduce the above copyright notice, this list of     #
-- #    conditions and the following disclaimer in the documentation and/or other materials        #
-- #    provided with the distribution.                                                            #
-- #                                                                                               #
-- # 3. Neither the name of the copyright holder nor the names of its contributors may be used to  #
-- #    endorse or promote products derived from this software without specific prior written      #
-- #    permission.                                                                                #
-- #                                                                                               #
-- # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS   #
-- # OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF               #
-- # MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE    #
-- # COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,     #
-- # EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE #
-- # GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED    #
-- # AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING     #
-- # NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED  #
-- # OF THE POSSIBILITY OF SUCH DAMAGE.                                                            #
-- # ********************************************************************************************* #
-- # https://github.com/stnolting/cjtag_bridge                                 (c) Stephan Nolting #
-- #################################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cjtag_bridge is
  port (
    -- global control --
    clk_i     : in  std_ulogic; -- main clock
    rstn_i    : in  std_ulogic; -- main reset, async, low-active
    -- cJTAG (from debug probe) --
    tckc_i    : in  std_ulogic; -- tap clock
    tmsc_i    : in  std_ulogic; -- tap data input
    tmsc_o    : out std_ulogic; -- tap data output
    tmsc_oe_o : out std_ulogic; -- tap data output enable (tri-state driver)
    -- JTAG (to device) --
    tck_o     : out std_ulogic; -- tap clock
    tdi_o     : out std_ulogic; -- tap data input
    tdo_i     : in  std_ulogic; -- tap data output
    tms_o     : out std_ulogic  -- tap mode select
  );
end cjtag_bridge;

architecture cjtag_bridge_rtl of cjtag_bridge is

  -- activation sequence commands --
  -- NOTE: these are bit-reversed as the LSB is sent first!! --
  constant cmd_oac_c : std_ulogic_vector(3 downto 0) := "0011"; -- online activation code
  constant cmd_ec_c  : std_ulogic_vector(3 downto 0) := "0001"; -- extension code
  constant cmd_cp_c  : std_ulogic_vector(3 downto 0) := "0000"; -- check packet

  -- I/O synchronization --
  type io_sync_t is record
    tckc_ff : std_ulogic_vector(2 downto 0);
    tmsc_ff : std_ulogic_vector(2 downto 0);
    --
    tckc_rising  : std_ulogic;
    tckc_falling : std_ulogic;
    tmsc_rising  : std_ulogic;
    tmsc_falling : std_ulogic;
  end record;
  signal io_sync : io_sync_t;

  -- reset --
  type reset_t is record
    cnt  : std_ulogic_vector(2 downto 0);
    sreg : std_ulogic_vector(1 downto 0);
    fire : std_ulogic;
  end record;
  signal reset : reset_t;

  -- status --
  type status_t is record
    online : std_ulogic;
    sreg   : std_ulogic_vector(11 downto 0);
  end record;
  signal status : status_t;

  -- control fsm --
  type ctrl_state_t is (S_NTDI, S_TMS, S_TDO);
  type ctrl_t is record
    state : ctrl_state_t;
    tck   : std_ulogic;
    tdi   : std_ulogic;
    tms   : std_ulogic;
  end record;
  signal ctrl : ctrl_t;

begin

  -- cJTAG Input Signal Synchronizer --------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  input_synchronizer: process(clk_i)
  begin
    if rising_edge(clk_i) then
      io_sync.tckc_ff <= io_sync.tckc_ff(1 downto 0) & tckc_i;
      io_sync.tmsc_ff <= io_sync.tmsc_ff(1 downto 0) & tmsc_i;
    end if;
  end process input_synchronizer;

  -- clock --
  io_sync.tckc_rising  <= '1' when (io_sync.tckc_ff(2 downto 1) = "01") else '0';
  io_sync.tckc_falling <= '1' when (io_sync.tckc_ff(2 downto 1) = "10") else '0';

  -- data --
  io_sync.tmsc_rising  <= '1' when (io_sync.tmsc_ff(2 downto 1) = "01") else '0';
  io_sync.tmsc_falling <= '1' when (io_sync.tmsc_ff(2 downto 1) = "10") else '0';


  -- Reset Controller -----------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  bridge_reset: process(rstn_i, clk_i)
  begin
    if (rstn_i = '0') then
      reset.cnt  <= (others => '0');
      reset.sreg <= "01"; -- internal reset after bitstream upload
    elsif rising_edge(clk_i) then
      -- edge counter --
      if (io_sync.tckc_rising = '1') or (io_sync.tckc_falling = '1') then -- reset on any TCKC edge
        reset.cnt <= (others => '0');
      elsif (reset.cnt /= "111") and -- saturate
            ((io_sync.tmsc_rising = '1') or (io_sync.tmsc_falling = '1')) then -- increment on any TMSC edge
        reset.cnt <= std_ulogic_vector(unsigned(reset.cnt) + 1);
      end if;
      -- reset edge detector --
      reset.sreg(1) <= reset.sreg(0);
      if (reset.cnt = "111") then
        reset.sreg(0) <= '1';
      else
        reset.sreg(0) <= '0';
      end if;
    end if;
  end process bridge_reset;

  -- fire reset *once* --
  reset.fire <= '1' when (reset.sreg = "01") else '0';


  -- Bridge Activation Control --------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  bridge_status: process(rstn_i, clk_i)
  begin
    if (rstn_i = '0') then
      status.online <= '0';
      status.sreg   <= (others => '0');
    elsif rising_edge(clk_i) then
      if (reset.fire = '1') then -- sync reset
        status.online <= '0';
        status.sreg   <= (others => '0');
      elsif (status.online = '0') then
        if (io_sync.tckc_rising = '1') then
          status.sreg <= status.sreg(status.sreg'left-1 downto 0) & io_sync.tmsc_ff(1); -- data is transmitted LSB-first
        end if;
        if (status.sreg(11 downto 08) = cmd_oac_c) and -- check activation code
           (status.sreg(07 downto 04) = cmd_ec_c) and
           (status.sreg(03 downto 00) = cmd_cp_c) and
           (io_sync.tckc_falling = '1') then
          status.online <= '1';
        end if;
      end if;
    end if;
  end process bridge_status;


  -- Bridge Transmission Control ------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  bridge_control: process(rstn_i, clk_i)
  begin
    if (rstn_i = '0') then
      ctrl.state <= S_NTDI;
      ctrl.tck   <= '0';
      ctrl.tdi   <= '0';
      ctrl.tms   <= '0';
    elsif rising_edge(clk_i) then
      if (status.online = '0') then -- reset while offline
        ctrl.state <= S_NTDI;
        ctrl.tck   <= '0';
        ctrl.tdi   <= '0';
        ctrl.tms   <= '0';
      else
        case ctrl.state is

          when S_NTDI => -- sample inverse TDI and clear clock
            if (io_sync.tckc_rising = '1') then
              ctrl.tck <= '0';
              ctrl.tdi <= not io_sync.tmsc_ff(1);
            end if;
            if (io_sync.tckc_falling = '1') then
              ctrl.state <= S_TMS;
            end if;

          when S_TMS => -- sample TMS
            if (io_sync.tckc_rising = '1') then
              ctrl.tms <= io_sync.tmsc_ff(1);
            end if;
            if (io_sync.tckc_falling = '1') then
              ctrl.state <= S_TDO;
            end if;

          when S_TDO => -- output TDO and set clock
            if (io_sync.tckc_rising = '1') then
              ctrl.tck <= '1';
            end if;
            if (io_sync.tckc_falling = '1') then
              ctrl.state <= S_NTDI;
            end if;

          when others =>
            ctrl.state <= S_NTDI;
        end case;
      end if;
    end if;
  end process bridge_control;

  -- IO control --
  tck_o <= io_sync.tckc_ff(1) when (status.online = '0') else ctrl.tck;
  tms_o <= io_sync.tmsc_ff(1) when (status.online = '0') else ctrl.tms;
  tdi_o <= '0'                when (status.online = '0') else ctrl.tdi;

  -- tri-state control --
  tmsc_o    <= tdo_i; -- FIXME: synchronize tdo_i?
  tmsc_oe_o <= '1' when (ctrl.state = S_TDO) else '0';


end cjtag_bridge_rtl;
