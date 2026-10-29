#!/bin/bash
#=============================================================================
# check_paths.sh - verify every path of flow_config.sh + tool availability.
# Run once after copying the project:   cd env_check && ./check_paths.sh
#=============================================================================
source ../flow_config.sh

fail=0
echo "== Files from flow_config.sh =="
for v in LIB_SLOW LIB_FAST LEF_TECH LEF_MACRO QRC_TCH QRC_RCWORST QRC_RCBEST \
         CAPTBL STREAM_MAP STD_GDS STD_CDL SIM_LIB_TIMING SIM_LIB_FUNC; do
    p=${!v}
    if [ -f "$p" ]; then
        printf "  OK       %-15s %s\n" "$v" "$p"
    else
        printf "  MISSING  %-15s %s\n" "$v" "$p"; fail=1
    fi
done

echo "== Tools on PATH =="
for t in xrun imc genus lec modus innovus tempus voltus; do
    if command -v $t >/dev/null 2>&1; then
        printf "  OK       %-8s %s\n" "$t" "$(command -v $t)"
    else
        printf "  MISSING  %-8s\n" "$t"; fail=1
    fi
done

echo "== Lab copy vs PDK master (identical = safe to compare with lab results) =="
cmpf() { if cmp -s "$1" "$2"; then echo "  SAME     $(basename $1)";
         else echo "  DIFFERENT $(basename $1)  (lab: $1)"; fi; }
cmpf $LAB_DB/lib/slow_vdd1v0_basicCells.lib  $LIB_SLOW
cmpf $LAB_DB/lib/fast_vdd1v0_basicCells.lib  $LIB_FAST
cmpf $LAB_DB/lef/gsclib045_tech.lef          $LEF_TECH
cmpf $LAB_DB/lef/gsclib045_macro.lef         $LEF_MACRO
cmpf $LAB_DB/QRC_Tech/gpdk045.tch            $QRC_TCH

echo "== Cells used by the flow scripts (must exist in macro LEF) =="
for c in BUFX2 CLKBUFX2 CLKINVX2 TIEHI TIELO FILL1 FILL64 SDFFRHQX1 DFFRHQX1; do
    if grep -q "^MACRO $c\$" "$LEF_MACRO"; then echo "  OK       $c"; else echo "  MISSING  $c"; fail=1; fi
done

[ $fail -eq 0 ] && echo "RESULT: ALL OK" || echo "RESULT: SOMETHING MISSING - send this output"
