# ALU32 Genus synthesis with DFT patch

This patch adds the DFT synthesis stage to the ALU32 project, based on Cadence
RTL-to-GDSII Flow v7.0 Lab 5-2. It is tailored for this project's `alu_top`,
active-low asynchronous reset, 10 ns functional clock, and scan port names
`SE`, `scan_in`, `scan_out`.

## Install

Copy `synthesis/genus_dft.tcl` and `synthesis/run_synth_dft.sh` into the existing
project's `synthesis/` directory. Do not replace existing no-DFT scripts or
outputs.

## Run

From the project root or any directory:

```bash
cd /home/icer/projects/ALU_32bit/alu32_rv32i_45nm/synthesis
chmod +x run_synth_dft.sh
./run_synth_dft.sh
```

Outputs are isolated under `synthesis/dft_run/` so the previously generated
`outputs/alu_top_syn.v` remains unchanged.

## Expected checks

- `dft_run/reports/dft_rules_post_connect.rpt` has no failed DFT registers/rules.
- `dft_run/reports/scan_chains.rpt` shows exactly one chain (`top_chain`),
  with 100 scan bits expected from `alu_top` (68 input-side flops + 32 result flops).
- `dft_run/outputs/alu_top_syn_dft.v`, SDC, SDF and ScanDEF are created.
- `dft_run/test_scripts/` contains Genus-generated Modus ATPG handoff scripts.
- Timing intent report has no newly unconstrained ports in functional mode.

If the preflight fails because `SDFFRHQX1` is not present in the slow Liberty,
functional Verilog model, or LEF, stop and identify the matching scan-cell model
before running DFT. Do not bypass site authorization/license messages.

The `write_dft_atpg` command generates handoff files; Modus ATPG execution is a
separate next step.
