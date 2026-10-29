# Open-source quick check (no Cadence licenses needed).
#   make sim [NRAND=20000] [SEED=1]   compile + run the self-checking testbench
#   make lint                         Verilator lint of the RTL
#   make clean
# The sign-off flow itself uses the Cadence scripts described in README.md.

NRAND ?= 20000
SEED  ?= 1
RTL   := rtl/alu_core.v rtl/alu_top.v
TB    := tb/tb_alu_top.v
BUILD := build

.PHONY: sim lint clean

sim: $(BUILD)/tb_alu_top.vvp
	vvp $< +NRAND=$(NRAND) +SEED=$(SEED) | tee $(BUILD)/sim.log
	@grep -q "\*\*\* TEST PASSED \*\*\*" $(BUILD)/sim.log

$(BUILD)/tb_alu_top.vvp: $(RTL) $(TB)
	@mkdir -p $(BUILD)
	iverilog -g2012 -Wall -s tb_alu_top -o $@ $(RTL) $(TB)

lint:
	verilator --lint-only --top-module alu_top $(RTL)

clean:
	rm -rf $(BUILD)
