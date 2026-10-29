# Changelog

All notable changes are documented here. Format based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- Open-source `Makefile` (Icarus Verilog simulation, Verilator lint) and GitHub
  Actions CI.
- `NOTICE.md`, `CONTRIBUTING.md`, `docs/ARCHITECTURE.md`, issue / PR templates,
  `.gitattributes`, `.editorconfig`.
- `equivalence_checking/run_lec.sh` wrapper for Conformal LEC.

### Changed
- Added Modus ATPG results (`synthesis/atpg/`: logs + summary) and quoted them in the README.
- Redacted the remaining host ID in the two post-route netlist headers.
- Curated reports are now tracked: `synthesis/reports/`, `synthesis/dft_run/reports/`,
  `equivalence_checking/reports/`, `physical_design/signoff/`
  (host paths redacted). Added `physical_design/README.md` and the recorded
  `innovus_session_history.tcl`.
- Removed checksum files (`*.sha256`).
- Removed duplicate DFT netlist/SDF/SCANDEF/SDC from `synthesis/outputs/`
  (canonical copy: `synthesis/dft_run/outputs/`).
- `.gitignore`: also block `*.gds`, `*.gds.gz`, `*.oas` (embed PDK cell geometry).
- README rewritten: corrected operation encoding, ports and PDK badge; added a
  results table taken from the signoff reports.
- `flow_config.sh` paths can be overridden from the environment.
- Removed absolute host paths from LEC, CTS and checksum files.
- `synthesis/README_DFT.md` → `synthesis/README.md`.

### Removed
- Backup script `physical_design/scripts/mmmc.tcl.before_rc_fix`.

## [0.1.0]

- Initial RTL-to-GDSII implementation of the RV32I ALU: RTL, testbench, SDC,
  Genus synthesis + DFT, Innovus P&R, DRC/LVS-clean layout.
