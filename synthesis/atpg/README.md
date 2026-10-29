# ATPG results (Cadence Modus)

Stuck-at ATPG on the full-scan netlist `synthesis/dft_run/outputs/alu_top_syn_dft.v`
(test mode `FULLSCAN`, experiment `alu_top_atpg`), driven by
`synthesis/test_scripts/runmodus.atpg.tcl`.

| Metric | Value |
| :--- | :--- |
| Faults (static) | 8134 |
| Tested | 8131 |
| Redundant | 3 |
| Untested | 0 |
| **Test coverage (TCov)** | **99.96 %** |
| **Adjusted test coverage (ATCov)** | **100.00 %** |
| Test sequences | 109 (1 scan + 108 logic) |

## Logs (in flow order)

| Log | Step |
| :--- | :--- |
| `log_build_faultmodel.log` | Build the fault model |
| `log_verify_test_structures_FULLSCAN.log` | Verify scan structures / test mode |
| `log_report_test_structures_FULLSCAN.log` | Report scan chain structures |
| `log_create_logic_tests_FULLSCAN_alu_top_atpg.log` | Pattern generation and coverage |
| `log_commit_tests_FULLSCAN_alu_top_atpg.log` | Commit the generated tests |

Host paths are replaced by `<PROJ_ROOT>` / `<HOME>`. The generated patterns and Modus
work directory (`synthesis/dft_run/MODUS/`, ~10 MB) are git-ignored.
