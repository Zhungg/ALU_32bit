//=============================================================================
// File    : alu_top.v
// Project : alu32_rv32i_45nm  (RV32I ALU, Cadence RTL-to-GDSII flow, gpdk045)
// Type    : TOP LEVEL for synthesis and place & route (reg-to-reg wrapper)
//
// Block diagram
//
//            +--------+      +-----------+      +--------+
//   a    --->| a_q    |----->|           |      |        |
//   b    --->| b_q    |----->| alu_core  |----->| result |---> result
//   ctrl --->| ctrl_q |----->| (comb.)   |      |  reg   |
//            +--------+      +-----------+      +--------+
//              68 FF        critical path         32 FF
//            (ID/EX reg)                        (EX/MEM reg)
//
// Why registers on both sides?
//   * It reproduces the EX stage of a pipelined RISC-V CPU.
//   * The critical path becomes a real reg-to-reg path
//     (clock -> a_q/b_q -> adder or shifter -> mux -> result reg),
//     which STA, CTS and hold fixing can work on.
//   * 100 flip-flops -> a real clock tree and a 100-bit scan chain for DFT.
//
// Timing behaviour
//   Latency = 2 clock cycles:
//     edge N   : a, b, alu_ctrl are captured into a_q, b_q, ctrl_q
//     edge N+1 : alu_core output is captured into result
//   A new operation can start every cycle (throughput = 1 op / cycle).
//
// Reset
//   Asynchronous, active-low (rst_n = 0 -> all 100 flops cleared at once,
//   without waiting for a clock edge). Synthesis maps these flops to
//   DFFRHQX* (and to SDFFRHQX* after scan insertion) of gsclib045.
//
// DFT
//   The scan ports SE, scan_in, scan_out are NOT written here. Genus creates
//   them during scan insertion (synthesis/genus_dft.tcl). The testbench
//   connects them only for gate-level simulation (+define+GLS).
//=============================================================================
`timescale 1ns/1ps

module alu_top (
    input  wire        clk,        // system clock, 100 MHz target (10 ns)
    input  wire        rst_n,      // asynchronous reset, active low
    input  wire [31:0] a,          // operand A
    input  wire [31:0] b,          // operand B
    input  wire [3:0]  alu_ctrl,   // operation select {funct7[5], funct3}
    output reg  [31:0] result      // registered result, valid 2 cycles later
);

    //-------------------------------------------------------------------------
    // Internal signals
    //-------------------------------------------------------------------------
    reg  [31:0] a_q;       // registered operand A
    reg  [31:0] b_q;       // registered operand B
    reg  [3:0]  ctrl_q;    // registered control
    wire [31:0] alu_y;     // combinational ALU output

    //-------------------------------------------------------------------------
    // Stage 1: input registers (equivalent to the ID/EX pipeline register)
    // "posedge clk or negedge rst_n" in the sensitivity list = ASYNC reset.
    //-------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_q    <= 32'd0;
            b_q    <= 32'd0;
            ctrl_q <= 4'd0;
        end else begin
            a_q    <= a;
            b_q    <= b;
            ctrl_q <= alu_ctrl;
        end
    end

    //-------------------------------------------------------------------------
    // Combinational ALU (all the logic depth lives here)
    //-------------------------------------------------------------------------
    alu_core u_alu_core (
        .a        (a_q),
        .b        (b_q),
        .alu_ctrl (ctrl_q),
        .result   (alu_y)
    );

    //-------------------------------------------------------------------------
    // Stage 2: output register (equivalent to the EX/MEM pipeline register)
    // Registered output -> clean, glitch-free output timing for the next block.
    //-------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            result <= 32'd0;
        else
            result <= alu_y;
    end

endmodule
