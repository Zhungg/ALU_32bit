#!/bin/bash
#=============================================================================
# run_cov.sh - Code coverage (Xcelium + IMC), equivalent of lab 4
# Coverage is collected only on the DUT (alu_top and below), not on the TB.
#=============================================================================
source ../flow_config.sh
NRAND=${NRAND:-20000}

xrun -64bit -access +rwc -timescale 1ns/1ps \
     $PROJ_ROOT/rtl/alu_core.v $PROJ_ROOT/rtl/alu_top.v $PROJ_ROOT/tb/tb_alu_top.v \
     -top tb_alu_top \
     -coverage all -covdut alu_top -covoverwrite -covtest alu_selfcheck \
     +NRAND=$NRAND \
     -l xrun_cov.log

echo "------------------------------------------------------------"
grep -E "TEST (PASSED|FAILED)" xrun_cov.log

# Text summary (batch). If this command errors in your IMC version,
# just use the GUI line below - it is the same as lab 4.
imc -batch -execcmd "load -run cov_work/scope/alu_selfcheck; report -summary -inst -out cov_summary.rpt tb_alu_top.dut...; exit" \
    > imc_report.log 2>&1 && echo "Coverage summary: cov_summary.rpt"

echo "GUI (via VNC): imc -load cov_work/scope/alu_selfcheck &"
