#=============================================================================
# alu_top_func.sdc - FUNCTIONAL mode constraints (100 MHz)
#
# Used by : Genus synthesis (only file read there - scan ports do not exist yet)
#           Innovus / Tempus  "func" constraint mode (+ alu_top_func_dft.sdc)
# Units   : time = ns, capacitance = pF  (gsclib045 liberty: time_unit 1ns,
#           capacitive_load_unit 1pf)
#
# Fixes vs. the lab SDC
#   * uncertainty is set on the CLOCK object (lab used get_ports clk)
#   * separate setup / hold uncertainty
#   * every I/O has BOTH -max (setup) and -min (hold) delay. The lab gave only
#     -max, which is the reason for the many hold "violations" on SE / rst in
#     lab 9.
#   * input driving cell + output load -> realistic input slew / output cap
#=============================================================================

#---------------- clock: 10 ns = 100 MHz, 50 % duty cycle --------------------
create_clock -name clk -period 10.0 -waveform {0.0 5.0} [get_ports clk]

# Before CTS the clock is "ideal": tools need an assumed clock slew.
# (After CTS Innovus uses the real propagated clock automatically.)
set_clock_transition 0.10 [get_clocks clk]

# Setup margin: jitter + skew estimate before the clock tree exists.
# Hold margin : small, skew is computed for real after CTS.
set_clock_uncertainty -setup 0.20 [get_clocks clk]
set_clock_uncertainty -hold  0.05 [get_clocks clk]

#---------------- inputs ------------------------------------------------------
# External logic uses 20 % of the period before our input (max = 2.0 ns),
# and its fastest path arrives 0.5 ns after the clock edge (min, hold check).
# rst_n is also timed -> STA checks recovery/removal on the async reset pins.
set_input_delay -max 2.0 -clock clk [get_ports {a[*] b[*] alu_ctrl[*] rst_n}]
set_input_delay -min 0.5 -clock clk [get_ports {a[*] b[*] alu_ctrl[*] rst_n}]

# Inputs are driven by a BUFX2 (realistic slew instead of an ideal step).
set_driving_cell -lib_cell BUFX2 -pin Y [get_ports {a[*] b[*] alu_ctrl[*] rst_n}]

#---------------- outputs -----------------------------------------------------
# The receiving block needs the data 2.0 ns before its clock edge (setup) and
# has 0 ns hold requirement.
set_output_delay -max 2.0 -clock clk [get_ports {result[*]}]
set_output_delay -min 0.0 -clock clk [get_ports {result[*]}]

# Each output drives 10 fF (~ a few gate inputs + short wire).
set_load 0.010 [get_ports {result[*]}]
