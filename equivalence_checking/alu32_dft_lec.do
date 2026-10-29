set log file reports/alu32_dft_lec.log -replace

read library @SIM_LIB_FUNC@ -verilog -both

read design ../rtl/alu_core.v ../rtl/alu_top.v -verilog -golden

read design ../synthesis/dft_run/outputs/alu_top_syn_dft.v -verilog -revised

add pin constraints 0 SE -revised
add ignored inputs scan_in -revised
add ignored outputs scan_out -revised

set system mode lec

add compared points -all
compare

report verification

exit
