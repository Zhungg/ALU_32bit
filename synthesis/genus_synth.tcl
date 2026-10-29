# ALU32 baseline synthesis using Genus Stylus Common UI

file mkdir outputs
file mkdir reports

# Library and RTL
set_db init_lib_search_path $env(GSCLIB)/timing
set_db init_hdl_search_path $env(PROJ_ROOT)/rtl
set_db hdl_error_on_blackbox true

read_libs $env(LIB_SLOW)
read_hdl {alu_core.v alu_top.v}
elaborate $env(DESIGN)

# Apply the functional timing constraints
read_sdc $env(PROJ_ROOT)/constraints/alu_top_func.sdc

# Pre-synthesis checks
check_design -all > reports/pre_synth_check_design.rpt
check_timing_intent -verbose > reports/pre_synth_timing_intent.rpt

# Baseline synthesis and technology mapping
set_db syn_generic_effort medium
set_db syn_map_effort high
set_db syn_opt_effort high

syn_generic
syn_map
syn_opt

# Post-synthesis checks and reports
check_design -all > reports/post_synth_check_design.rpt
report_area > reports/post_synth_area.rpt
report_timing > reports/post_synth_timing.rpt
report_qor > reports/post_synth_qor.rpt

# Export the mapped netlist and updated constraints
write_hdl > outputs/alu_top_syn.v
write_sdc > outputs/alu_top_syn.sdc

puts "SYNTHESIS_DONE"

