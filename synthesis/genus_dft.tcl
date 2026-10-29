#=============================================================================
# genus_dft.tcl -- ALU32 baseline synthesis with muxed-scan DFT
# Adapted from Cadence RTL-to-GDSII Flow v7.0, Lab 5-2
# Target: Genus Stylus Common UI 20.10, gsclib045 / gpdk045
# Run from synthesis/dft_run using run_synth_dft.sh.
#=============================================================================

file mkdir outputs
file mkdir reports

# 1. Read timing library and RTL, elaborate top.
set_db init_lib_search_path $env(GSCLIB)/timing
set_db init_hdl_search_path $env(PROJ_ROOT)/rtl
set_db hdl_error_on_blackbox true

read_libs $env(LIB_SLOW)
read_hdl {alu_core.v alu_top.v}
elaborate $env(DESIGN)

# 2. Functional timing intent before scan ports are created.
read_sdc $env(PROJ_ROOT)/constraints/alu_top_func.sdc

# 3. DFT setup -- muxed scan, using the SE name used by project SDCs.
set_db dft_scan_style muxed_scan
set_db dft_prefix dft_
define_test_signal -function shift_enable -name SE -active high -create_port SE

# Cadence recommends checking DFT rules multiple times through the flow.
check_dft_rules > reports/dft_rules_pre_synthesis.rpt

# 4. Generic synthesis and mapping. Keep the same effort policy as the
#    project's no-DFT baseline and the Cadence Lab 5-2 example.
set_db syn_generic_effort medium
syn_generic
set_db syn_map_effort medium
syn_map
set_db syn_opt_effort medium

check_dft_rules > reports/dft_rules_post_mapping.rpt

# 5. Create one scan chain for the 100 architectural flops (68 input-side
#    registers + 32 result registers).
set_db design:$env(DESIGN) .dft_min_number_of_scan_chains 1
define_scan_chain -name top_chain -sdi scan_in -sdo scan_out -create_ports
connect_scan_chains -auto_create_chains

# The add-on constraints reference SE/scan_in/scan_out, so read them only
# after those ports are created. This keeps the synthesized netlist timed in
# functional mode (SE=0). Do NOT read alu_top_scan.sdc here; that is the
# separate scan-shift mode for Innovus/Tempus.
read_sdc $env(PROJ_ROOT)/constraints/alu_top_func_dft.sdc

# 6. Incremental optimization after scan insertion and reports.
syn_opt
check_dft_rules > reports/dft_rules_post_connect.rpt
report_scan_chains > reports/scan_chains.rpt
check_design -all > reports/post_dft_check_design.rpt
check_timing_intent -verbose > reports/post_dft_timing_intent.rpt
report_area > reports/post_dft_area.rpt
report_timing > reports/post_dft_timing.rpt
report_qor > reports/post_dft_qor.rpt

# 7. Write DFT netlist, SDF, functional-mode SDC and ScanDEF.
write_hdl > outputs/alu_top_syn_dft.v
write_sdc > outputs/alu_top_syn_dft.sdc
write_scandef > outputs/alu_top_scanDEF.scandef
write_sdf -timescale ns -nonegchecks -recrem split -edges check_edge \
    -setuphold split > outputs/alu_top_dft_delays.sdf

# 8. Generate the Modus ATPG handoff files (the generated script is run in
#    Modus as a separate next stage; this command itself generates handoff).
write_dft_atpg -library $env(SIM_LIB_FUNC)

puts "SYNTHESIS_DFT_DONE"

