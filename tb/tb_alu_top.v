//=============================================================================
// File    : tb_alu_top.v
// Project : alu32_rv32i_45nm
// Type    : SELF-CHECKING testbench for alu_top (RTL and gate-level netlists)
//
// "Self-checking" = the testbench computes the expected result itself and
// prints PASS/FAIL. No need to inspect waveforms by eye.
//
// Verification strategy
//   1. Reference model  : ref_alu() - behavioural, written DIFFERENTLY from
//                         the RTL (uses $signed compares, not a shared adder),
//                         so a bug in the RTL is not copied into the model.
//   2. KAT              : Known-Answer Tests - hand-computed golden values
//                         check the reference model itself at time 0.
//   3. Directed tests   : corner cases (overflow, signed vs unsigned compare,
//                         shamt = b[4:0], SRA sign fill, illegal codes).
//   4. Random tests     : constrained-random operands biased towards
//                         0, 1, -1, 0x7FFFFFFF, 0x80000000 and small values.
//   5. Scoreboard       : expected values are delayed by 2 clock cycles to
//                         match the latency of alu_top.
//   6. Async reset test : rst_n asserted BETWEEN clock edges in mid-run;
//                         result must clear immediately.
//   7. Functional coverage: every legal op must be checked at least once.
//
// Timing discipline (important for gate-level simulation with SDF)
//   * Inputs are driven at the FALLING edge of clk  -> half a period of setup
//     margin before the next rising edge, no hold race.
//   * Outputs are checked at the FALLING edge too   -> result has had half a
//     period after the rising edge to settle (clk->Q + wire delay).
//
// Compile-time macros (xrun +define+NAME)
//   GLS : DUT is the scan-inserted netlist from Genus/Innovus, which has
//         3 extra ports SE, scan_in, scan_out. Tied to functional mode SE=0.
//   SDF : back-annotate delays from "dut.sdf" (the run script links the
//         right SDF file - post-synthesis or post-route, wc or bc).
//   VCD : dump a VCD file (for non-Cadence viewers). With Xcelium use
//         -access +rwc and SimVision instead.
//
// Run-time plusargs
//   +NRAND=<n> : number of random vectors   (default 20000)
//   +SEED=<n>  : random seed                (default 1)
//
// Final verdict line (grep it in the log):
//   *** TEST PASSED ***   or   *** TEST FAILED ***
//=============================================================================
`timescale 1ns/1ps

module tb_alu_top;

    localparam integer HALF_PERIOD = 5;     // 5 ns half period -> 10 ns -> 100 MHz
    localparam integer N_DIR_MAX   = 64;    // size of the directed-vector table

    //-------------------------------------------------------------------------
    // DUT connections
    //-------------------------------------------------------------------------
    reg         clk;
    reg         rst_n;
    reg  [31:0] a;
    reg  [31:0] b;
    reg  [3:0]  alu_ctrl;
    wire [31:0] result;

`ifdef GLS
    // Gate-level netlist after DFT: extra scan ports exist.
    // SE = 0 -> every scan flop takes its D input (functional mode).
    wire scan_out;
    alu_top dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .a        (a),
        .b        (b),
        .alu_ctrl (alu_ctrl),
        .result   (result),
        .SE       (1'b0),
        .scan_in  (1'b0),
        .scan_out (scan_out)
    );
`else
    // RTL: only functional ports.
    alu_top dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .a        (a),
        .b        (b),
        .alu_ctrl (alu_ctrl),
        .result   (result)
    );
`endif

`ifdef SDF
    // Annotate cell + interconnect delays. "MAXIMUM" picks the max value of
    // each (min:typ:max) triplet in the SDF file.
    initial $sdf_annotate("dut.sdf", tb_alu_top.dut, , "sdf.log", "MAXIMUM");
`endif

`ifdef VCD
    initial begin
        $dumpfile("tb_alu_top.vcd");
        $dumpvars(0, tb_alu_top);
    end
`endif

    //-------------------------------------------------------------------------
    // Clock generator: 10 ns period
    //-------------------------------------------------------------------------
    initial clk = 1'b0;
    always #(HALF_PERIOD) clk = ~clk;

    //-------------------------------------------------------------------------
    // Reference model (golden model). Intentionally different style from RTL.
    //-------------------------------------------------------------------------
    function [31:0] ref_alu;
        input [31:0] x;
        input [31:0] y;
        input [3:0]  op;
        reg signed [31:0] xs, ys;          // signed copies for SLT / SRA
        begin
            xs = x;
            ys = y;
            case (op)
                4'b0000: ref_alu = x + y;                          // ADD
                4'b1000: ref_alu = x - y;                          // SUB
                4'b0001: ref_alu = x << y[4:0];                    // SLL
                4'b0010: ref_alu = (xs < ys) ? 32'd1 : 32'd0;      // SLT  (signed)
                4'b0011: ref_alu = (x  < y ) ? 32'd1 : 32'd0;      // SLTU (unsigned)
                4'b0100: ref_alu = x ^ y;                          // XOR
                4'b0101: ref_alu = x >> y[4:0];                    // SRL
                4'b1101: ref_alu = xs >>> y[4:0];                  // SRA
                4'b0110: ref_alu = x | y;                          // OR
                4'b0111: ref_alu = x & y;                          // AND
                default: ref_alu = 32'd0;                          // illegal
            endcase
        end
    endfunction

    // Operation name for messages
    function [8*4-1:0] op_name;
        input [3:0] op;
        begin
            case (op)
                4'b0000: op_name = "ADD ";
                4'b1000: op_name = "SUB ";
                4'b0001: op_name = "SLL ";
                4'b0010: op_name = "SLT ";
                4'b0011: op_name = "SLTU";
                4'b0100: op_name = "XOR ";
                4'b0101: op_name = "SRL ";
                4'b1101: op_name = "SRA ";
                4'b0110: op_name = "OR  ";
                4'b0111: op_name = "AND ";
                default: op_name = "ILLG";
            endcase
        end
    endfunction

    //-------------------------------------------------------------------------
    // Scoreboard: 2-stage delay line of expected values, clocked exactly like
    // the DUT (same edge, same async reset) -> automatically aligned.
    //   stage 1 (exp1) ~ DUT input registers
    //   stage 2 (exp2) ~ DUT output register  -> compare exp2 with result
    //-------------------------------------------------------------------------
    reg [31:0] exp1, exp2, a1, a2, b1, b2;
    reg [3:0]  op1, op2;
    reg        v1, v2;                     // "stage holds a valid vector"

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            v1 <= 1'b0;
            v2 <= 1'b0;
        end else begin
            exp1 <= ref_alu(a, b, alu_ctrl);
            a1   <= a;
            b1   <= b;
            op1  <= alu_ctrl;
            v1   <= 1'b1;
            exp2 <= exp1;
            a2   <= a1;
            b2   <= b1;
            op2  <= op1;
            v2   <= v1;
        end
    end

    //-------------------------------------------------------------------------
    // Counters / statistics
    //-------------------------------------------------------------------------
    integer n_checks, n_err, n_kat_err, n_rst_err;
    integer op_cnt [0:15];                 // checks per alu_ctrl code
    integer i, k, n_rand, n_dir, seed, r;

    // Directed-vector table: operation, operands, hand-computed golden result
    reg [3:0]  d_op  [0:N_DIR_MAX-1];
    reg [31:0] d_a   [0:N_DIR_MAX-1];
    reg [31:0] d_b   [0:N_DIR_MAX-1];
    reg [31:0] d_exp [0:N_DIR_MAX-1];

    task add_vec;
        input [3:0]  op;
        input [31:0] x;
        input [31:0] y;
        input [31:0] e;
        begin
            d_op[n_dir]  = op;
            d_a[n_dir]   = x;
            d_b[n_dir]   = y;
            d_exp[n_dir] = e;
            n_dir        = n_dir + 1;
        end
    endtask

    //-------------------------------------------------------------------------
    // check_output: compare DUT with scoreboard. Called only at negedge.
    // "!==" (case inequality) also flags X/Z -> catches unknowns in GLS.
    //-------------------------------------------------------------------------
    task check_output;
        begin
            if (!rst_n) begin
                if (result !== 32'd0) begin
                    n_rst_err = n_rst_err + 1;
                    $display("[%0t] ERROR reset: result=%h (expected 0)", $time, result);
                end
            end else if (v2) begin
                n_checks    = n_checks + 1;
                op_cnt[op2] = op_cnt[op2] + 1;
                if (result !== exp2) begin
                    n_err = n_err + 1;
                    if (n_err <= 20)       // limit log size
                        $display("[%0t] ERROR %s a=%h b=%h : got %h exp %h",
                                 $time, op_name(op2), a2, b2, result, exp2);
                end
            end
        end
    endtask

    //-------------------------------------------------------------------------
    // step: one clock cycle = check current output, then apply next vector.
    // Both happen at the falling edge -> no race with DUT flops (rising edge).
    //-------------------------------------------------------------------------
    task step;
        input [3:0]  op;
        input [31:0] x;
        input [31:0] y;
        begin
            @(negedge clk);
            check_output;
            alu_ctrl = op;
            a        = x;
            b        = y;
        end
    endtask

    // Biased operand generator: special values are much more likely than in
    // a uniform random distribution -> corner cases are hit often.
    function [31:0] pick_operand;
        input integer sel;
        input [31:0]  rnd;
        begin
            case (sel)
                0: pick_operand = 32'h0000_0000;
                1: pick_operand = 32'h0000_0001;
                2: pick_operand = 32'hFFFF_FFFF;           // -1
                3: pick_operand = 32'h7FFF_FFFF;           // max positive
                4: pick_operand = 32'h8000_0000;           // min negative
                5: pick_operand = {27'd0, rnd[4:0]};       // small value / shamt
                default: pick_operand = rnd;               // full random
            endcase
        end
    endfunction

    reg [3:0] legal_ops [0:9];

    //-------------------------------------------------------------------------
    // Main test sequence
    //-------------------------------------------------------------------------
    initial begin
        n_checks = 0; n_err = 0; n_kat_err = 0; n_rst_err = 0; n_dir = 0;
        for (i = 0; i < 16; i = i + 1) op_cnt[i] = 0;
        if (!$value$plusargs("NRAND=%d", n_rand)) n_rand = 20000;
        if (!$value$plusargs("SEED=%d",  seed))   seed   = 1;
        $display("[TB] NRAND=%0d SEED=%0d", n_rand, seed);

        legal_ops[0] = 4'b0000; legal_ops[1] = 4'b1000; legal_ops[2] = 4'b0001;
        legal_ops[3] = 4'b0010; legal_ops[4] = 4'b0011; legal_ops[5] = 4'b0100;
        legal_ops[6] = 4'b0101; legal_ops[7] = 4'b1101; legal_ops[8] = 4'b0110;
        legal_ops[9] = 4'b0111;

        //---------------- directed corner cases (golden values by hand) -----
        // ADD
        add_vec(4'b0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000);
        add_vec(4'b0000, 32'h7FFF_FFFF, 32'h0000_0001, 32'h8000_0000); // signed overflow
        add_vec(4'b0000, 32'hFFFF_FFFF, 32'h0000_0001, 32'h0000_0000); // carry out lost
        add_vec(4'b0000, 32'h8000_0000, 32'h8000_0000, 32'h0000_0000);
        add_vec(4'b0000, 32'h1234_5678, 32'h9ABC_DEF0, 32'hACF1_3568);
        // SUB
        add_vec(4'b1000, 32'h0000_0000, 32'h0000_0001, 32'hFFFF_FFFF); // 0 - 1 = -1
        add_vec(4'b1000, 32'h8000_0000, 32'h0000_0001, 32'h7FFF_FFFF); // overflow
        add_vec(4'b1000, 32'h0000_0005, 32'h0000_0005, 32'h0000_0000);
        // SLL - only b[4:0] counts
        add_vec(4'b0001, 32'h0000_0001, 32'h0000_001F, 32'h8000_0000); // << 31
        add_vec(4'b0001, 32'h0000_0001, 32'h0000_0020, 32'h0000_0001); // b=32 -> shamt 0
        add_vec(4'b0001, 32'hFFFF_FFFF, 32'h0000_0004, 32'hFFFF_FFF0);
        add_vec(4'b0001, 32'h0000_0003, 32'hFFFF_FFE1, 32'h0000_0006); // shamt = 1
        // SLT - signed
        add_vec(4'b0010, 32'h8000_0000, 32'h0000_0000, 32'h0000_0001); // min_neg < 0
        add_vec(4'b0010, 32'h0000_0000, 32'h8000_0000, 32'h0000_0000);
        add_vec(4'b0010, 32'hFFFF_FFFF, 32'h0000_0001, 32'h0000_0001); // -1 < 1
        add_vec(4'b0010, 32'h0000_0005, 32'h0000_0005, 32'h0000_0000); // equal
        add_vec(4'b0010, 32'h7FFF_FFFF, 32'h8000_0000, 32'h0000_0000); // a-b overflows!
        add_vec(4'b0010, 32'h8000_0000, 32'h7FFF_FFFF, 32'h0000_0001); // a-b overflows!
        // SLTU - unsigned
        add_vec(4'b0011, 32'h8000_0000, 32'h0000_0000, 32'h0000_0000);
        add_vec(4'b0011, 32'h0000_0000, 32'hFFFF_FFFF, 32'h0000_0001);
        add_vec(4'b0011, 32'h0000_0005, 32'h0000_0005, 32'h0000_0000);
        add_vec(4'b0011, 32'hFFFF_FFFE, 32'hFFFF_FFFF, 32'h0000_0001);
        // XOR / OR / AND
        add_vec(4'b0100, 32'hAAAA_AAAA, 32'h5555_5555, 32'hFFFF_FFFF);
        add_vec(4'b0100, 32'hFFFF_FFFF, 32'hFFFF_FFFF, 32'h0000_0000);
        add_vec(4'b0110, 32'hAAAA_0000, 32'h0000_5555, 32'hAAAA_5555);
        add_vec(4'b0111, 32'hAAAA_FFFF, 32'h5555_FFFF, 32'h0000_FFFF);
        // SRL - fill with 0
        add_vec(4'b0101, 32'h8000_0000, 32'h0000_001F, 32'h0000_0001);
        add_vec(4'b0101, 32'hFFFF_FFFF, 32'h0000_0021, 32'h7FFF_FFFF); // shamt = 1
        // SRA - fill with sign bit
        add_vec(4'b1101, 32'h8000_0000, 32'h0000_001F, 32'hFFFF_FFFF);
        add_vec(4'b1101, 32'h7FFF_FFFF, 32'h0000_0001, 32'h3FFF_FFFF);
        add_vec(4'b1101, 32'hF000_0000, 32'h0000_0004, 32'hFF00_0000);
        add_vec(4'b1101, 32'h8000_0000, 32'h0000_0020, 32'h8000_0000); // shamt = 0
        // illegal codes -> 0
        add_vec(4'b1001, 32'hFFFF_FFFF, 32'hFFFF_FFFF, 32'h0000_0000);
        add_vec(4'b1010, 32'hFFFF_FFFF, 32'hFFFF_FFFF, 32'h0000_0000);
        add_vec(4'b1011, 32'hFFFF_FFFF, 32'hFFFF_FFFF, 32'h0000_0000);
        add_vec(4'b1100, 32'hFFFF_FFFF, 32'hFFFF_FFFF, 32'h0000_0000);
        add_vec(4'b1110, 32'hFFFF_FFFF, 32'hFFFF_FFFF, 32'h0000_0000);
        add_vec(4'b1111, 32'hFFFF_FFFF, 32'hFFFF_FFFF, 32'h0000_0000);

        //---------------- KAT: is the reference model itself correct? -------
        for (i = 0; i < n_dir; i = i + 1) begin
            if (ref_alu(d_a[i], d_b[i], d_op[i]) !== d_exp[i]) begin
                n_kat_err = n_kat_err + 1;
                $display("KAT ERROR #%0d %s a=%h b=%h : model %h golden %h", i,
                         op_name(d_op[i]), d_a[i], d_b[i],
                         ref_alu(d_a[i], d_b[i], d_op[i]), d_exp[i]);
            end
        end
        $display("[TB] KAT: %0d vectors, %0d model errors", n_dir, n_kat_err);

        //---------------- reset for 3 cycles (result must stay 0) -----------
        rst_n = 1'b0; a = 32'd0; b = 32'd0; alu_ctrl = 4'd0;
        repeat (3) begin @(negedge clk); check_output; end
        rst_n = 1'b1;                       // released at negedge -> safe recovery

        //---------------- directed phase ------------------------------------
        for (i = 0; i < n_dir; i = i + 1)
            step(d_op[i], d_a[i], d_b[i]);

        //---------------- random phase (+ async reset in the middle) --------
        for (k = 0; k < n_rand; k = k + 1) begin
            if (k == n_rand / 2) begin
                @(negedge clk); check_output;
                #(HALF_PERIOD/2);           // 2 ns after negedge: NOT on a clock edge
                rst_n = 1'b0;
                #1;                         // allow reset->Q delay (GLS with SDF)
                if (result !== 32'd0) begin
                    n_rst_err = n_rst_err + 1;
                    $display("[%0t] ERROR async reset did not clear result (%h)", $time, result);
                end
                @(negedge clk); check_output;
                rst_n = 1'b1;
                $display("[%0t] [TB] async reset test done", $time);
            end
            r = $random(seed);
            // ~87% legal ops (r[3:0] < 14), the rest any 4-bit code incl. illegal
            step( (r[3:0] < 4'd14) ? legal_ops[{$random(seed)} % 10] : r[7:4],
                  pick_operand({$random(seed)} % 10, $random(seed)),
                  pick_operand({$random(seed)} % 10, $random(seed)) );
        end

        //---------------- flush the 2-stage pipeline ------------------------
        repeat (3) begin @(negedge clk); check_output; end

        //---------------- report --------------------------------------------
        $display("--------------------------------------------------------");
        $display(" alu_top self-checking testbench summary");
        $display("--------------------------------------------------------");
        for (i = 0; i < 16; i = i + 1)
            if (op_cnt[i] > 0)
                $display("   %s (%b) : %0d checks", op_name(i[3:0]), i[3:0], op_cnt[i]);
        for (i = 0; i < 10; i = i + 1)
            if (op_cnt[legal_ops[i]] == 0) begin
                n_err = n_err + 1;
                $display("   COVERAGE HOLE: %s never checked", op_name(legal_ops[i]));
            end
        $display("   total checks : %0d", n_checks);
        $display("   data errors  : %0d", n_err);
        $display("   reset errors : %0d", n_rst_err);
        $display("   KAT errors   : %0d", n_kat_err);
        if (n_err == 0 && n_rst_err == 0 && n_kat_err == 0 && n_checks > 0)
            $display("*** TEST PASSED ***");
        else
            $display("*** TEST FAILED ***");
        $display("--------------------------------------------------------");
        $finish;
    end

    //-------------------------------------------------------------------------
    // Watchdog: stop a hung simulation (supports NRAND up to ~200000)
    //-------------------------------------------------------------------------
    initial begin
        #(64'd2 * HALF_PERIOD * (64'd200000 + 1000));
        $display("*** TEST FAILED *** (watchdog timeout)");
        $finish;
    end

endmodule
