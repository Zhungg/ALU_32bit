//=============================================================================
// File    : alu_core.v
// Project : alu32_rv32i_45nm  (RV32I ALU, Cadence RTL-to-GDSII flow, gpdk045)
// Type    : PURELY COMBINATIONAL - no clock, no flip-flop in this module
//
// Purpose
//   Integer ALU of the RISC-V RV32I base ISA. It implements the 10 ALU
//   operations used by R-type (and I-type) arithmetic/logic instructions.
//   In a 5-stage pipeline this block sits in the EX stage, between the
//   ID/EX and EX/MEM pipeline registers (see alu_top.v).
//
// Control encoding
//   alu_ctrl = {funct7[5], funct3}. This is the natural RISC-V encoding:
//   the decoder can pass instruction bits [30] and [14:12] straight through.
//
//   alu_ctrl | op    | result                          | instruction
//   ---------+-------+---------------------------------+-------------
//     0000   | ADD   | a + b                           | add / addi
//     1000   | SUB   | a - b                           | sub
//     0001   | SLL   | a << b[4:0]                     | sll / slli
//     0010   | SLT   | (signed a < signed b) ? 1 : 0   | slt / slti
//     0011   | SLTU  | (unsigned a < b)      ? 1 : 0   | sltu / sltiu
//     0100   | XOR   | a ^ b                           | xor / xori
//     0101   | SRL   | a >> b[4:0]   (fill with 0)     | srl / srli
//     1101   | SRA   | a >>> b[4:0]  (fill with sign)  | sra / srai
//     0110   | OR    | a | b                           | or / ori
//     0111   | AND   | a & b                           | and / andi
//     others | -     | 32'h0 (illegal code, safe value)|
//
// Design notes
//   1. RISC-V has NO condition flags (no N/Z/C/V). Branches use a separate
//      comparator in the CPU, so this ALU only outputs a 32-bit result.
//   2. Resource sharing: ADD, SUB, SLT and SLTU use ONE 33-bit adder.
//      Subtraction is done as  a + (~b) + 1  (two's complement).
//      -> one adder instead of three -> less area, one well-defined
//         critical path for synthesis to optimise.
//   3. Only b[4:0] is used as the shift amount (RV32I spec: shamt is 5 bits,
//      upper bits of rs2 are ignored).
//   4. The case statement assigns 'result' in EVERY branch (with a default),
//      so synthesis infers pure combinational logic - no latch.
//=============================================================================
`timescale 1ns/1ps

module alu_core (
    input  wire [31:0] a,          // operand A (rs1)
    input  wire [31:0] b,          // operand B (rs2 or immediate)
    input  wire [3:0]  alu_ctrl,   // {funct7[5], funct3}
    output reg  [31:0] result      // ALU result (reg = assigned in always @*, NOT a flop)
);

    //-------------------------------------------------------------------------
    // Operation codes (localparam -> constants, no hardware)
    //-------------------------------------------------------------------------
    localparam [3:0] ALU_ADD  = 4'b0000;
    localparam [3:0] ALU_SUB  = 4'b1000;
    localparam [3:0] ALU_SLL  = 4'b0001;
    localparam [3:0] ALU_SLT  = 4'b0010;
    localparam [3:0] ALU_SLTU = 4'b0011;
    localparam [3:0] ALU_XOR  = 4'b0100;
    localparam [3:0] ALU_SRL  = 4'b0101;
    localparam [3:0] ALU_SRA  = 4'b1101;
    localparam [3:0] ALU_OR   = 4'b0110;
    localparam [3:0] ALU_AND  = 4'b0111;

    //-------------------------------------------------------------------------
    // 1) Shared adder / subtractor
    //-------------------------------------------------------------------------
    // sub_en = 1 for every operation that needs (a - b): SUB, SLT, SLTU.
    wire        sub_en = (alu_ctrl == ALU_SUB) |
                         (alu_ctrl == ALU_SLT) |
                         (alu_ctrl == ALU_SLTU);

    // XOR with sub_en inverts b only when subtracting (~b), else passes b.
    wire [31:0] b_inv  = b ^ {32{sub_en}};

    // 33-bit add so the carry-out is visible in bit 32.
    // The "+ sub_en" is the "+1" of two's complement.
    wire [32:0] sum33  = {1'b0, a} + {1'b0, b_inv} + {32'd0, sub_en};
    wire [31:0] sum    = sum33[31:0];   // a+b  or  a-b
    wire        carry  = sum33[32];     // when subtracting: carry = NOT borrow

    // Unsigned compare: a < b  <=>  (a - b) needs a borrow  <=>  carry == 0
    wire        lt_u   = ~carry;

    // Signed compare. Using only sum[31] is WRONG when (a - b) overflows,
    // e.g. a = 0x7FFFFFFF, b = 0x80000000. Correct rule:
    //   - signs differ  -> a < b exactly when a is negative  (a[31] = 1)
    //   - signs equal   -> no overflow possible, sign of (a - b) is correct
    wire        lt_s   = (a[31] ^ b[31]) ? a[31] : sum[31];

    //-------------------------------------------------------------------------
    // 2) Shifter (synthesis builds 5-level barrel shifters from these)
    //-------------------------------------------------------------------------
    wire [4:0]  shamt  = b[4:0];                 // RV32I: only 5 bits used
    wire [31:0] sll_r  = a << shamt;             // logical left
    wire [31:0] srl_r  = a >> shamt;             // logical right, fill 0
    wire [31:0] sra_r  = $signed(a) >>> shamt;   // arithmetic right, fill a[31]

    //-------------------------------------------------------------------------
    // 3) Result multiplexer
    //-------------------------------------------------------------------------
    always @(*) begin
        case (alu_ctrl)
            ALU_ADD,
            ALU_SUB  : result = sum;                  // same adder output
            ALU_SLL  : result = sll_r;
            ALU_SLT  : result = {31'd0, lt_s};        // zero-extend 1-bit flag
            ALU_SLTU : result = {31'd0, lt_u};
            ALU_XOR  : result = a ^ b;
            ALU_SRL  : result = srl_r;
            ALU_SRA  : result = sra_r;
            ALU_OR   : result = a | b;
            ALU_AND  : result = a & b;
            default  : result = 32'd0;                // illegal code -> 0 (no latch)
        endcase
    end

endmodule
