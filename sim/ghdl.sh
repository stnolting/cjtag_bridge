#!/usr/bin/env bash

set -e

# Analyse sources
ghdl -a ../rtl/cjtag_bridge.vhd
ghdl -a cjtag_bridge_tb.vhd

# Elaborate top entity
ghdl -e cjtag_bridge_tb

# Run simulation
ghdl -e cjtag_bridge_tb
ghdl -r cjtag_bridge_tb --stop-time=1ms --wave=cjtag_bridge.ghw
