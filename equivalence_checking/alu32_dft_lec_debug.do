set log file reports/alu32_dft_lec_debug.log -replace

read library /home/icer/LAB/RTLtoGDSII/counter_design_database_45nm/lib/slow_vdd1v0_basiccells.v -verilog -both

read design ../rtl/alu_core.v ../rtl/alu_top.v -verilog -golden

read design ../synthesis/dft_run/outputs/alu_top_syn_dft.v -verilog -revised

add pin constraints 0 SE -revised
add ignored inputs scan_in -revised
add ignored outputs scan_out -revised

set system mode lec

add compared points -all
compare

report unmapped points -extra
report statistics
report verification

exit -force
