#=============================================================================
# alu_top_func_dft.sdc - ADD-ON for functional mode AFTER scan insertion
#
# Used by : Innovus / Tempus "func" constraint mode, together with
#           alu_top_func.sdc:   -sdc_files {alu_top_func.sdc alu_top_func_dft.sdc}
# Not used: in Genus (SE / scan_in / scan_out do not exist before DFT)
#
# In functional mode the chip never shifts: SE is tied 0 by the system.
# set_case_analysis propagates the constant -> the scan mux inside every
# SDFFRHQX cell selects D, and the SI (scan) paths are not timed in this mode.
# They are timed in the "scan" mode instead (alu_top_scan.sdc).
#=============================================================================

set_case_analysis 0 [get_ports SE]

# scan_in / scan_out still need I/O delays, otherwise STA reports them as
# unconstrained ports.
set_input_delay  -max 2.0 -clock clk [get_ports {SE scan_in}]
set_input_delay  -min 0.5 -clock clk [get_ports {SE scan_in}]
set_driving_cell -lib_cell BUFX2 -pin Y [get_ports {SE scan_in}]

set_output_delay -max 2.0 -clock clk [get_ports scan_out]
set_output_delay -min 0.0 -clock clk [get_ports scan_out]
set_load 0.010 [get_ports scan_out]
