#=============================================================================
# alu_top_scan.sdc - SCAN SHIFT mode constraints (20 MHz shift clock)
#
# Used by : Innovus / Tempus "scan" constraint mode (stand-alone file)
#
# What happens in shift mode
#   SE = 1 -> every scan flop takes SI instead of D, so the 100 flops form
#   ONE shift register:  scan_in -> FF -> FF -> ... -> FF -> scan_out
#   Each SI path is just Q -> (short wire) -> SI: almost zero delay.
#   => setup is trivial, but HOLD is the real risk (data races through
#      before the next flop's clock arrives, especially with clock skew).
#
# Why a slower clock?
#   Testers shift slowly (here 20 MHz = 50 ns) to limit power and IR drop
#   while ~all flops toggle at once. Capture (SE = 0) at speed is covered by
#   the functional mode at 100 MHz, which is stricter.
#
# Note: SE itself is held constant here (case analysis). Timing the SE
# 1->0 transition before capture is a further refinement, not needed now.
#=============================================================================

create_clock -name clk -period 50.0 -waveform {0.0 25.0} [get_ports clk]
set_clock_transition 0.10 [get_clocks clk]
set_clock_uncertainty -setup 0.20 [get_clocks clk]
set_clock_uncertainty -hold  0.05 [get_clocks clk]

# Shift mode
set_case_analysis 1 [get_ports SE]

# Scan I/O: 10 % of the 50 ns period for external logic
set_input_delay  -max 5.0 -clock clk [get_ports {scan_in rst_n}]
set_input_delay  -min 0.5 -clock clk [get_ports {scan_in rst_n}]
set_driving_cell -lib_cell BUFX2 -pin Y [get_ports {scan_in rst_n SE}]

set_output_delay -max 5.0 -clock clk [get_ports scan_out]
set_output_delay -min 0.0 -clock clk [get_ports scan_out]
set_load 0.010 [get_ports {scan_out result[*]}]

# Functional data ports are meaningless while shifting
set_false_path -from [get_ports {a[*] b[*] alu_ctrl[*]}]
set_false_path -to   [get_ports {result[*]}]
