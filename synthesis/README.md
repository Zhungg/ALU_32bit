# Synthesis and DFT (Cadence Genus)

| Script | Purpose |
| :--- | :--- |
| `check_rtl_sdc.tcl`, `run_check.sh` | Pre-synthesis RTL + SDC sanity checks |
| `genus_synth.tcl`, `run_synth.sh` | Logic synthesis → `outputs/alu_top_syn.v` |
| `genus_dft.tcl`, `run_synth_dft.sh` | Synthesis + full-scan insertion → `dft_run/outputs/` |
| `test_scripts/` | Modus ATPG hand-off (`runmodus.atpg.tcl`, pin assignment, scan-sim scripts) |

## Run

```bash
cd synthesis
./run_synth.sh        # plain synthesis (kept unchanged by the DFT run)
./run_synth_dft.sh    # DFT run; everything is isolated under dft_run/
```

The DFT flow is based on the Cadence RTL-to-GDSII flow lab (Lab 5-2), adapted to
`alu_top` (async active-low reset, 10 ns functional clock, scan ports `SE`,
`scan_in`, `scan_out`).

## Expected checks

- `dft_run/reports/dft_rules_post_connect.rpt`: **0** DFT rule violations.
- `dft_run/reports/scan_chains.rpt`: exactly one chain (`top_chain`) with 100 scan
  bits (68 input-side flops + 32 result flops).
- `dft_run/outputs/`: `alu_top_syn_dft.v`, `.sdc`, SDF and ScanDEF are written.
- Timing-intent report shows no newly unconstrained ports in functional mode.

If the preflight reports that `SDFFRHQX1` is missing from the slow Liberty,
functional Verilog model or LEF, stop and identify the matching scan-cell model
before continuing; do not bypass site license messages.

`write_dft_atpg` only generates the hand-off files; running Modus ATPG is a
separate step.
