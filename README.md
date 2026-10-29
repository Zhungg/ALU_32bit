# 32-bit RISC-V (RV32I) ALU: Complete RTL-to-GDSII ASIC Implementation

[![RISC-V](https://img.shields.io/badge/ISA-RISC--V%20RV32I-blue.svg)](https://riscv.org/)
[![Cadence](https://img.shields.io/badge/EDA-Cadence%20Digital%20Flow-red.svg)](https://www.cadence.com/)
[![Process](https://img.shields.io/badge/PDK-45nm%20GPDK-green.svg)](https://www.eda.ncsu.edu/wiki/FreePDK45)
[![DRC/LVS](https://img.shields.io/badge/Signoff-DRC%20%26%20LVS%20Clean-success.svg)](#5-physical-layout--signoff-verification)
[![License](https://img.shields.io/badge/License-Apache%202.0-lightgrey.svg)](LICENSE)

An industrial-grade, signoff-verified 32-bit Arithmetic Logic Unit (ALU) supporting the complete **RISC-V (RV32I) Base Integer Instruction Set**. This repository contains the complete frontend-to-backend digital design flow implemented with Cadence EDA tools targeting a **45nm Standard Cell CMOS process**.

---

## 📌 Architecture & Design Specifications

The ALU core executes all 10 standard integer computational instructions specified in the RISC-V RV32I unprivileged ISA specification. The top module integrates input and output pipeline registers, flag generations, and full scan chain DFT (Design-for-Testability) insertion.

```
                  +-----------------------------------+
   clk ----------->                                   |
   rst_n --------->          alu_top                  |
                  |                                   |
   a[31:0] -------> [Reg A]                           |
   b[31:0] -------> [Reg B] ===> [ alu_core ] ====> [Reg Out] ===> result[31:0]
   alu_ctrl[3:0] -> [Reg Ctrl]                        |      ===> zero, ovf, cout
                  |                                   |
   scan_in -------> [DFT Scan Chain: 100 Regs] -------> scan_out
   scan_en ------->                                   |
                  +-----------------------------------+
```

### Supported Operations (`alu_ctrl[3:0]`)

| Operation Code | Instruction | Type | Operation Description |
| :---: | :---: | :---: | :--- |
| `4'b0000` | **ADD** | Arithmetic | `result = a + b` (Addition) |
| `4'b0001` | **SUB** | Arithmetic | `result = a - b` (Subtraction) |
| `4'b0010` | **SLL** | Shift | `result = a << b[4:0]` (Shift Left Logical) |
| `4'b0011` | **SLT** | Comparison | `result = ($signed(a) < $signed(b)) ? 1 : 0` (Set Less Than, Signed) |
| `4'b0100` | **SLTU** | Comparison | `result = (a < b) ? 1 : 0` (Set Less Than, Unsigned) |
| `4'b0101` | **XOR** | Logical | `result = a ^ b` (Bitwise XOR) |
| `4'b0110` | **SRL** | Shift | `result = a >> b[4:0]` (Shift Right Logical) |
| `4'b0111` | **SRA** | Shift | `result = $signed(a) >>> b[4:0]` (Shift Right Arithmetic) |
| `4'b1000` | **OR**  | Logical | `result = a \| b` (Bitwise OR) |
| `4'b1001` | **AND** | Logical | `result = a & b` (Bitwise AND) |

---

## 🚀 Cadence RTL-to-GDSII ASIC Flow Walkthrough

The design was carried out through an industry-standard Cadence digital implementation flow:

```
  +------------------+      +------------------+      +-------------------+
  |  RTL Simulation  | ---> | Logic Synthesis  | ---> |  DFT Scan & ATPG  |
  |  Xcelium/SimVis  |      |  Cadence Genus   |      |   Modus / Genus   |
  +------------------+      +------------------+      +-------------------+
                                                                |
  +------------------+      +------------------+                |
  | Signoff DRC/LVS  | <--- |  Place & Route   | <--------------+
  | Virtuoso/Assura  |      | Cadence Innovus  | (CTS + Timing Optimization)
  +------------------+      +------------------+
```

---

### 1. Functional Verification & Simulation Coverage

The design is rigorously verified using a self-checking testbench `tb_alu_top.v` executing over 20,000 randomized and corner-case vectors.

- **Cadence SimVision Waveform**:
  Full functional verification across arithmetic, shifts, logic, and comparison modes.
  ![SimVision Waveform](img/waveform.png)

- **Cadence Integrated Metrics Center (IMC)**:
  Code coverage report demonstrating comprehensive test coverage (> 98% overall coverage; 100% block and statement coverage on core logic).
  ![IMC Coverage Report](img/imc.png)

---

### 2. Logic Synthesis

Synthesized with **Cadence Genus Synthesis Solution** targeting the 45nm standard cell library (`gpdk045`).

- **Logic Synthesis Schematic**:
  Optimized gate-level logic netlist achieving zero setup/hold timing violations.
  ![Genus Logic Schematic](img/schematic.png)

---

### 3. Design for Testability (DFT) & Scan Insertion

Full-scan DFT architecture implemented with **Cadence Genus DFT** and **Cadence Modus ATPG**.

- **DFT Rule Checking & Scan Chain Configuration**:
  100% of internal registers (100 flip-flops) were successfully stitched into scan chains with **0 DFT rule violations**.
  ![DFT Synthesis Summary](img/dft_synthesis.png)

- **Schematic After DFT Insertion**:
  Scan-stitched flip-flops with scan-enable (`scan_en`), scan-in (`scan_in`), and scan-out (`scan_out`) multiplexing paths.
  ![Schematic After DFT](img/schematic_after_dft.png)

---

### 4. Clock Tree Synthesis (CTS)

Clock tree synthesis and routing executed using **Cadence Innovus CCOpt**.

- **Clock Tree Debugger**:
  Symmetric, low-skew clock distribution across all sequential pipeline stages and DFT scan chains.
  ![Clock Tree Debugger](img/cts.png)

---

### 5. Physical Layout & Signoff Verification

Physical implementation and signoff performed with **Cadence Innovus Implementation System**, **Cadence Virtuoso**, and **Cadence Assura**.

- **GDSII Full Chip Layout**:
  Optimized standard cell placement, power mesh distribution (VDD/VSS rails), and detailed signal routing across metal layers.
  ![Innovus Full Layout](img/gds.png)

- **Design Rule Check (DRC)**:
  Virtuoso physical verification confirmed **0 DRC violations**.
  ![DRC Clean Check](img/check_drc.png)

- **Layout Versus Schematic (LVS)**:
  Assura LVS report confirming 100% match between schematic netlist and physical layout:
  - 0 Net mismatches
  - 0 Device mismatches
  - 0 Pin mismatches
  - 0 Parameter mismatches
  ![Assura LVS Clean](img/check_lvs.png)

---

## 📂 Repository Structure

```plaintext
alu32_rv32i_45nm/
├── constraints/              # Timing and design constraints (SDC)
│   ├── alu_top_func.sdc      # Functional mode timing constraints
│   ├── alu_top_func_dft.sdc  # Functional mode with DFT constraints
│   └── alu_top_scan.sdc      # Shift/scan mode timing constraints
├── env_check/                # Environment validation utilities
│   └── check_paths.sh        # Tool and library path checker
├── img/                      # Extracted ASIC flow demonstration figures
│   ├── imc.png               # IMC code coverage report
│   ├── waveform.png          # SimVision simulation waveform
│   ├── schematic.png         # Genus synthesis schematic
│   ├── dft_synthesis.png     # DFT scan insertion summary
│   ├── schematic_after_dft.png # Scan chain schematic
│   ├── check_drc.png         # Virtuoso DRC clean verification
│   ├── check_lvs.png         # Assura LVS match report
│   ├── gds.png               # Innovus physical GDSII layout
│   └── cts.png               # Clock tree synthesis structure
├── physical_design/          # P&R scripts & configurations
│   ├── scripts/              # Innovus TCL scripts (import, mmmc, CTS)
│   ├── results/              # Post-route databases & netlists
│   └── reports/              # Signoff timing, power & rail reports
├── rtl/                      # synthesizable Verilog source code
│   ├── alu_core.v            # Pure combinational 32-bit RV32I ALU
│   └── alu_top.v             # Registered top-level with DFT pins
├── simulation/               # Simulation scripts & test harness
│   ├── clean.sh              # Cleanup simulation artifacts
│   ├── run_cov.sh            # Coverage-enabled simulation run
│   └── run_rtl.sh            # Functional verification run
├── synthesis/                # Cadence Genus synthesis & DFT
│   ├── genus_synth.tcl       # Logic synthesis flow script
│   ├── genus_dft.tcl         # DFT insertion and ATPG flow script
│   ├── check_rtl_sdc.tcl     # RTL and SDC rule checks
│   └── test_scripts/         # ATPG pattern simulation scripts
├── tb/                       # Testbenches
│   └── tb_alu_top.v          # Self-checking randomized testbench
├── flow_config.sh            # Master environment configuration script
├── .gitignore                # Cadence flow file exclusion rules
└── README.md                 # Complete project documentation
```

---

## ⚙️ How to Reproduce

### 1. Environment Configuration
Ensure Cadence tool environment variables (`CADENCE_DIR`, `GENUS_HOME`, `INNOVUS_HOME`, `XC_HOME`, `PDK_DIR`) are configured:
```bash
source flow_config.sh
./env_check/check_paths.sh
```

### 2. Functional Simulation (Xcelium)
Run the RTL functional simulation:
```bash
cd simulation
./run_rtl.sh
```
To generate coverage metrics with IMC:
```bash
./run_cov.sh
```

### 3. Logic Synthesis & DFT (Genus)
Run RTL synthesis and scan insertion:
```bash
cd synthesis
./run_synth.sh      # Logic synthesis
./run_synth_dft.sh  # DFT insertion & ATPG
```

### 4. Physical Design (Innovus)
Run floorplanning, placement, CTS, and detailed routing:
```bash
cd physical_design
innovus -files scripts/import.tcl
```

---

## 📜 License

This project is licensed under the [Apache 2.0 License](LICENSE).
