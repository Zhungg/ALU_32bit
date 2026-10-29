# Architecture notes

## Modules

| Module | File | Description |
| :--- | :--- | :--- |
| `alu_core` | `rtl/alu_core.v` | Purely combinational RV32I ALU (10 ops). |
| `alu_top`  | `rtl/alu_top.v`  | Registered wrapper: input regs → `alu_core` → output reg. Synthesis / P&R top. |

## Timing behaviour

- Edge *N*: `a`, `b`, `alu_ctrl` are captured into `a_q`, `b_q`, `ctrl_q` (68 flops).
- Edge *N+1*: the `alu_core` output is captured into `result` (32 flops).
- Latency 2 cycles, throughput 1 op/cycle. Asynchronous active-low reset on all 100 flops.

The testbench therefore delays expected values by two cycles in its scoreboard and
drives/checks on the falling clock edge to leave half a period of margin
(important for SDF-annotated gate-level simulation).

## Datapath decisions

1. **One shared adder.** `ADD`, `SUB`, `SLT`, `SLTU` use one 33-bit adder:
   `sum33 = {1'b0,a} + {1'b0, b ^ {32{sub_en}}} + sub_en`.
   `carry = sum33[32]` is the inverse of borrow, so `SLTU = ~carry`.
2. **Signed compare without overflow bug.** `lt_s = (a[31]^b[31]) ? a[31] : sum[31]`.
   Using `sum[31]` alone is wrong for e.g. `0x7FFFFFFF < 0x80000000`.
3. **Shifts** use `b[4:0]` only (RV32I `shamt`); the synthesizer builds 5-level barrel shifters.
4. **No latches / no flags.** Every `case` branch assigns `result`; illegal `alu_ctrl` yields `0`.

## Design-for-test

Scan ports `SE`, `scan_in`, `scan_out` are *not* in the RTL; Genus adds them
(`synthesis/genus_dft.tcl`). Flops map to `DFFRHQX*` and become `SDFFRHQX*` after
insertion, stitched into a single 100-bit chain. Constraint files:

| SDC | Purpose |
| :--- | :--- |
| `constraints/alu_top_func.sdc` | Functional mode, 10 ns clock |
| `constraints/alu_top_func_dft.sdc` | Functional mode with scan pins constrained |
| `constraints/alu_top_scan.sdc` | Scan-shift mode, 50 ns clock |

## Gate-level simulation

Compile the testbench with `+define+GLS` (adds the `SE`/`scan_in`/`scan_out` ports,
`SE = 0`) and optionally `+define+SDF` to back-annotate `dut.sdf`.
