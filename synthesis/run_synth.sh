#!/bin/bash
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

source ../flow_config.sh || exit 1

mkdir -p logs reports outputs

genus -files genus_synth.tcl -log logs/genus_synth
rc=$?

if [ "$rc" -ne 0 ]; then
    echo "ERROR: Genus exited with status $rc"
    exit "$rc"
fi

if ! grep -q "SYNTHESIS_DONE" logs/genus_synth.log; then
    echo "ERROR: Synthesis completion marker not found"
    exit 1
fi

echo "RESULT: SYNTHESIS_SCRIPT_COMPLETED"
