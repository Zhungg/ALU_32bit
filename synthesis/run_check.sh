#!/bin/bash
# Milestone A: elaborate RTL + read SDC in Genus (no synthesis)
source ../flow_config.sh
mkdir -p logs reports
genus -no_gui -batch -files check_rtl_sdc.tcl -log logs/check_rtl_sdc

echo "------------------------------------------------------------"
grep -E "LATCH_COUNT|CHECK_RTL_SDC_DONE" logs/check_rtl_sdc.log*
echo "Lines mentioning latch (expected: none):"
grep -i "latch" logs/check_rtl_sdc.log* | grep -vi "LATCH_COUNT" | head
echo "Errors/warnings in log:"
grep -E "^(Error|Warning)" logs/check_rtl_sdc.log* | sort | uniq -c | head -30
echo "Reports: reports/check_design.rpt  reports/check_timing_intent.rpt"
