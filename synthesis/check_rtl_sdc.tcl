#=============================================================================
# check_rtl_sdc.tcl - Milestone A sanity check in Genus (NO synthesis yet)
#   * RTL elaborates cleanly (no unresolved modules, no latches)
#   * SDC is read without errors and covers every port / path
# Run:  cd synthesis && ./run_check.sh      (log: logs/check_rtl_sdc.log)
#=============================================================================
set_db init_lib_search_path $env(GSCLIB)/timing
set_db init_hdl_search_path $env(PROJ_ROOT)/rtl
set_db hdl_error_on_blackbox true          ;# missing module -> hard error

read_libs $env(LIB_SLOW)
read_hdl  {alu_core.v alu_top.v}
elaborate alu_top

# Structural checks: unresolved refs, undriven/multidriven nets, etc.
check_design -all > reports/check_design.rpt

# Any latch inferred? (expected: 0). Wrapped in catch: attribute names can
# differ between Genus versions; run_check.sh also greps the log for "latch".
if {[catch {llength [get_db insts -if {.is_latch == true}]} n]} {
    puts "LATCH_COUNT = n/a (attribute not available, see log grep)"
} else {
    puts "LATCH_COUNT = $n"
}

# Constraints
read_sdc $env(PROJ_ROOT)/constraints/alu_top_func.sdc
if {[catch {check_timing_intent -verbose > reports/check_timing_intent.rpt}]} {
    check_timing_intent > reports/check_timing_intent.rpt
}

puts "CHECK_RTL_SDC_DONE"
exit
