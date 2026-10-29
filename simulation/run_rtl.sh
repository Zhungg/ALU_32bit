#!/bin/bash
#=============================================================================
# run_rtl.sh - RTL simulation with the self-checking testbench (Xcelium)
#   ./run_rtl.sh                  batch, 20000 random vectors
#   ./run_rtl.sh -gui             open SimVision (press Run)
#   NRAND=100000 SEED=7 ./run_rtl.sh
#=============================================================================
source ../flow_config.sh
NRAND=${NRAND:-20000}
SEED=${SEED:-1}

xrun -64bit -access +rwc -coverage all -gui -timescale 1ns/1ps \
     $PROJ_ROOT/rtl/alu_core.v $PROJ_ROOT/rtl/alu_top.v $PROJ_ROOT/tb/tb_alu_top.v \
     -top tb_alu_top \
     +NRAND=$NRAND +SEED=$SEED \
     -l xrun_rtl.log "$@"

echo "------------------------------------------------------------"
grep -E "TEST (PASSED|FAILED)" xrun_rtl.log
