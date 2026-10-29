# Contributing

Thanks for your interest! This is an educational, reference RTL-to-GDSII project;
improvements to the RTL, verification, scripts and documentation are welcome.

## Workflow

1. Fork and create a topic branch (`git switch -c feat/my-change`).
2. Make your change; keep it focused.
3. Run the open-source check locally:
   ```bash
   make lint
   make sim            # must end with *** TEST PASSED ***
   ```
4. Open a pull request using the template. CI runs the same checks.

## Guidelines

- **RTL / testbench:** synthesizable Verilog-2001, no latches (every `case` has a
  `default`), 4-space indent. If you change an op code or the latency, update
  `README.md`, `docs/ARCHITECTURE.md` and the reference model in `tb/tb_alu_top.v`.
- **Scripts:** no absolute host paths — use `flow_config.sh` variables (`$PROJ_ROOT`,
  `$PDK_ROOT`, …). Shell scripts must be executable and use LF line endings.
- **Flow results:** if a change affects timing/area/DFT/DRC/LVS, re-run the flow and
  update the table in the README with the new numbers and the tool versions.
- **Licensing:** never commit PDK content (Liberty, LEF, GDS, CDL, QRC, cell models) or
  large tool databases; see [NOTICE.md](NOTICE.md).
- **Commits:** [Conventional Commits](https://www.conventionalcommits.org/)
  (`feat:`, `fix:`, `docs:`, `chore:`, …).

## Reporting issues

Use the issue templates. For a failing test, include `NRAND`, `SEED` and the log
around `*** TEST FAILED ***`.
