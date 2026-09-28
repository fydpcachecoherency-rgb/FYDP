`timescale 1ns/1ps

module tb_verif;

    // ============================================================
    // DUT
    // ============================================================

    logic clk;
    logic rst;

    RV32I_Core DUT (
        .clk(clk),
        .rst(rst)
    );

    // ============================================================
    // FILE HANDLES
    // ============================================================

    integer retire_file;
    integer memory_file;
    integer control_file;
    integer performance_file;

    // ============================================================
    // PERFORMANCE COUNTERS
    // ============================================================

    integer cycle_count;
    integer retired_arch_count;
    integer retirement_trace_count;

    integer memory_count;
    integer load_count;
    integer store_count;

    integer branch_count;
    integer taken_branch_count;
    integer jump_count;

    integer mul_count;
    integer atomic_count;
    integer lr_count;
    integer sc_count;

    integer stall_count;
    integer flush_count;

    integer halt_repeat_count;

    logic simulation_finished;

    // ============================================================
    // RETIREMENT TRACE TEMPORARY VARIABLES
    // ============================================================

    logic [31:0] trace_rd_data;
    logic [4:0]  trace_rd;
    logic        trace_rd_we;
    logic        is_real_instruction;

    // ============================================================
    // INSTRUCTION DECODER
    // ============================================================

    function automatic [127:0] decode_instr(
        input logic [31:0] instruction
    );

        logic [6:0] opcode;
        logic [2:0] funct3;
        logic       bit30;
        logic [6:0] funct7;
        logic [4:0] funct5;

        begin

            opcode = instruction[6:0];
            funct3 = instruction[14:12];
            bit30  = instruction[30];
            funct7 = instruction[31:25];
            funct5 = instruction[31:27];

            case (opcode)

                // ------------------------------------------------
                // U-type
                // ------------------------------------------------

                7'b0110111:
                    decode_instr = "LUI";

                7'b0010111:
                    decode_instr = "AUIPC";

                // ------------------------------------------------
                // Jumps
                // ------------------------------------------------

                7'b1101111:
                    decode_instr = "JAL";

                7'b1100111:
                    decode_instr = "JALR";

                // ------------------------------------------------
                // Branches
                // ------------------------------------------------

                7'b1100011: begin

                    case (funct3)

                        3'b000:
                            decode_instr = "BEQ";

                        3'b001:
                            decode_instr = "BNE";

                        3'b100:
                            decode_instr = "BLT";

                        3'b101:
                            decode_instr = "BGE";

                        3'b110:
                            decode_instr = "BLTU";

                        3'b111:
                            decode_instr = "BGEU";

                        default:
                            decode_instr = "BRANCH";

                    endcase

                end

                // ------------------------------------------------
                // Loads
                // ------------------------------------------------

                7'b0000011: begin

                    case (funct3)

                        3'b000:
                            decode_instr = "LB";

                        3'b001:
                            decode_instr = "LH";

                        3'b010:
                            decode_instr = "LW";

                        3'b100:
                            decode_instr = "LBU";

                        3'b101:
                            decode_instr = "LHU";

                        default:
                            decode_instr = "LOAD";

                    endcase

                end

                // ------------------------------------------------
                // Stores
                // ------------------------------------------------

                7'b0100011: begin

                    case (funct3)

                        3'b000:
                            decode_instr = "SB";

                        3'b001:
                            decode_instr = "SH";

                        3'b010:
                            decode_instr = "SW";

                        default:
                            decode_instr = "STORE";

                    endcase

                end

                // ------------------------------------------------
                // Immediate ALU
                // ------------------------------------------------

                7'b0010011: begin

                    case (funct3)

                        3'b000:
                            decode_instr = "ADDI";

                        3'b010:
                            decode_instr = "SLTI";

                        3'b011:
                            decode_instr = "SLTIU";

                        3'b100:
                            decode_instr = "XORI";

                        3'b110:
                            decode_instr = "ORI";

                        3'b111:
                            decode_instr = "ANDI";

                        3'b001:
                            decode_instr = "SLLI";

                        3'b101: begin

                            if (bit30)
                                decode_instr = "SRAI";
                            else
                                decode_instr = "SRLI";

                        end

                        default:
                            decode_instr = "OP-IMM";

                    endcase

                end

                // ------------------------------------------------
                // Register-register ALU (RV32I) and RV32M
                // ------------------------------------------------

                7'b0110011: begin

                    if (funct7 == 7'b0000001) begin

                        // ------------ RV32M ------------

                        case (funct3)

                            3'b000:
                                decode_instr = "MUL";

                            3'b001:
                                decode_instr = "MULH";

                            3'b010:
                                decode_instr = "MULHSU";

                            3'b011:
                                decode_instr = "MULHU";

                            3'b100:
                                decode_instr = "DIV";

                            3'b101:
                                decode_instr = "DIVU";

                            3'b110:
                                decode_instr = "REM";

                            3'b111:
                                decode_instr = "REMU";

                        endcase

                    end
                    else begin

                        // ------------ RV32I ------------

                        case (funct3)

                            3'b000: begin

                                if (bit30)
                                    decode_instr = "SUB";
                                else
                                    decode_instr = "ADD";

                            end

                            3'b001:
                                decode_instr = "SLL";

                            3'b010:
                                decode_instr = "SLT";

                            3'b011:
                                decode_instr = "SLTU";

                            3'b100:
                                decode_instr = "XOR";

                            3'b101: begin

                                if (bit30)
                                    decode_instr = "SRA";
                                else
                                    decode_instr = "SRL";

                            end

                            3'b110:
                                decode_instr = "OR";

                            3'b111:
                                decode_instr = "AND";

                            default:
                                decode_instr = "R-TYPE";

                        endcase

                    end

                end

                // ------------------------------------------------
                // RV32A atomics (AMO opcode, funct3 = 010 = .W)
                // ------------------------------------------------

                7'b0101111: begin

                    if (funct3 == 3'b010) begin

                        case (funct5)

                            5'b00010:
                                decode_instr = "LR.W";

                            5'b00011:
                                decode_instr = "SC.W";

                            5'b00001:
                                decode_instr = "AMOSWAP.W";

                            5'b00000:
                                decode_instr = "AMOADD.W";

                            5'b00100:
                                decode_instr = "AMOXOR.W";

                            5'b01100:
                                decode_instr = "AMOAND.W";

                            5'b01000:
                                decode_instr = "AMOOR.W";

                            5'b10000:
                                decode_instr = "AMOMIN.W";

                            5'b10100:
                                decode_instr = "AMOMAX.W";

                            5'b11000:
                                decode_instr = "AMOMINU.W";

                            5'b11100:
                                decode_instr = "AMOMAXU.W";

                            default:
                                decode_instr = "AMO";

                        endcase

                    end
                    else
                        decode_instr = "AMO";

                end

                // ------------------------------------------------
                // FENCE / MISC-MEM
                // ------------------------------------------------

                7'b0001111: begin

                    case (funct3)

                        3'b000:
                            decode_instr = "FENCE";

                        3'b001:
                            decode_instr = "FENCE.I";

                        default:
                            decode_instr = "MISC-MEM";

                    endcase

                end

                default:
                    decode_instr = "UNKNOWN";

            endcase

        end

    endfunction

    // ============================================================
    // HALT / FINISH
    // ============================================================

    task automatic finish_simulation(
        input logic timeout
    );

        real cpi_value;
        real ipc_value;

        begin

            if (simulation_finished)
                return;

            simulation_finished = 1'b1;

            // ----------------------------------------------------
            // Performance calculations
            // ----------------------------------------------------

            if (retired_arch_count > 0)

                cpi_value =
                    real'(cycle_count) /
                    real'(retired_arch_count);

            else

                cpi_value = 0.0;

            if (cycle_count > 0)

                ipc_value =
                    real'(retired_arch_count) /
                    real'(cycle_count);

            else

                ipc_value = 0.0;

            // ----------------------------------------------------
            // Final console performance matrix
            // ----------------------------------------------------

            $display("");
            $display("================================================================");
            $display("                    RV32IMA PERFORMANCE MATRIX");
            $display("================================================================");

            $display("+------------------------------+------------------------------+");
            $display("| Metric                       | Value                        |");
            $display("+------------------------------+------------------------------+");

            $display("| Total cycles                 | %-28d |",
                     cycle_count);

            $display("| Architectural instructions   | %-28d |",
                     retired_arch_count);

            $display("| Retirement trace entries     | %-28d |",
                     retirement_trace_count);

            $display("| Memory operations            | %-28d |",
                     memory_count);

            $display("| Loads                        | %-28d |",
                     load_count);

            $display("| Stores                       | %-28d |",
                     store_count);

            $display("| Branches                     | %-28d |",
                     branch_count);

            $display("| Taken branches               | %-28d |",
                     taken_branch_count);

            $display("| Jumps                        | %-28d |",
                     jump_count);

            $display("| M-ext (MUL*) instructions    | %-28d |",
                     mul_count);

            $display("| A-ext (atomic) instructions  | %-28d |",
                     atomic_count);

            $display("|   LR.W                       | %-28d |",
                     lr_count);

            $display("|   SC.W                       | %-28d |",
                     sc_count);

            $display("| Stall cycles                 | %-28d |",
                     stall_count);

            $display("| Flush events                 | %-28d |",
                     flush_count);

            $display("| CPI                          | %-28.4f |",
                     cpi_value);

            $display("| IPC                          | %-28.4f |",
                     ipc_value);

            $display("+------------------------------+------------------------------+");

            if (timeout)

                $display("| STATUS                       | %-28s |", "TIMEOUT");

            else

                $display("| STATUS                       | %-28s |", "COMPLETED");

            $display("+------------------------------+------------------------------+");

            $display("================================================================");
            $display("");

            // ----------------------------------------------------
            // Performance CSV
            // ----------------------------------------------------

            $fwrite(
                performance_file,
                "metric,value\n"
            );

            $fwrite(
                performance_file,
                "cycles,%0d\n",
                cycle_count
            );

            $fwrite(
                performance_file,
                "architectural_instructions,%0d\n",
                retired_arch_count
            );

            $fwrite(
                performance_file,
                "retirement_trace_entries,%0d\n",
                retirement_trace_count
            );

            $fwrite(
                performance_file,
                "memory_operations,%0d\n",
                memory_count
            );

            $fwrite(
                performance_file,
                "loads,%0d\n",
                load_count
            );

            $fwrite(
                performance_file,
                "stores,%0d\n",
                store_count
            );

            $fwrite(
                performance_file,
                "branches,%0d\n",
                branch_count
            );

            $fwrite(
                performance_file,
                "taken_branches,%0d\n",
                taken_branch_count
            );

            $fwrite(
                performance_file,
                "jumps,%0d\n",
                jump_count
            );

            $fwrite(
                performance_file,
                "mul_instructions,%0d\n",
                mul_count
            );

            $fwrite(
                performance_file,
                "atomic_instructions,%0d\n",
                atomic_count
            );

            $fwrite(
                performance_file,
                "lr_w,%0d\n",
                lr_count
            );

            $fwrite(
                performance_file,
                "sc_w,%0d\n",
                sc_count
            );

            $fwrite(
                performance_file,
                "stall_cycles,%0d\n",
                stall_count
            );

            $fwrite(
                performance_file,
                "flush_events,%0d\n",
                flush_count
            );

            $fwrite(
                performance_file,
                "CPI,%f\n",
                cpi_value
            );

            $fwrite(
                performance_file,
                "IPC,%f\n",
                ipc_value
            );

            if (timeout)

                $fwrite(
                    performance_file,
                    "status,TIMEOUT\n"
                );

            else

                $fwrite(
                    performance_file,
                    "status,COMPLETED\n"
                );

            // ----------------------------------------------------
            // Close files
            // ----------------------------------------------------

            $fclose(retire_file);
            $fclose(memory_file);
            $fclose(control_file);
            $fclose(performance_file);

            $display("Trace files generated:");
            $display("  rtl_retire.csv");
            $display("  rtl_memory.csv");
            $display("  rtl_control.csv");
            $display("  rtl_performance.csv");
            $display("");

            $finish;

        end

    endtask

    // ============================================================
    // CLOCK
    // ============================================================

    initial begin

        clk = 1'b0;

        forever
            #5 clk = ~clk;

    end

    // ============================================================
    // INSTRUCTION MEMORY
    // ============================================================

    initial begin

        $readmemh(
            "MY_CODE.HEX",
            DUT.IM.imem
        );

    end

    // ============================================================
    // FILE OPEN / INITIALIZATION
    // ============================================================

    initial begin

        retire_file =
            $fopen(
                "rtl_retire.csv",
                "w"
            );

        memory_file =
            $fopen(
                "rtl_memory.csv",
                "w"
            );

        control_file =
            $fopen(
                "rtl_control.csv",
                "w"
            );

        performance_file =
            $fopen(
                "rtl_performance.csv",
                "w"
            );

        if (retire_file == 0 ||
            memory_file == 0 ||
            control_file == 0 ||
            performance_file == 0) begin

            $display(
                "ERROR: Could not open trace files."
            );

            $finish;

        end

        // --------------------------------------------------------
        // CSV headers
        // --------------------------------------------------------

        $fwrite(
            retire_file,
            "index,cycle,pc,instr,mnemonic,rd,rd_we,rd_data\n"
        );

        $fwrite(
            memory_file,
            "index,cycle,pc,instr,mnemonic,read,write,address,data_in,data_out\n"
        );

        $fwrite(
            control_file,
            "index,cycle,pc,instr,mnemonic,type,taken,target\n"
        );

        // --------------------------------------------------------
        // Counters
        // --------------------------------------------------------

        cycle_count =
            0;

        retired_arch_count =
            0;

        retirement_trace_count =
            0;

        memory_count =
            0;

        load_count =
            0;

        store_count =
            0;

        branch_count =
            0;

        taken_branch_count =
            0;

        jump_count =
            0;

        mul_count =
            0;

        atomic_count =
            0;

        lr_count =
            0;

        sc_count =
            0;

        stall_count =
            0;

        flush_count =
            0;

        halt_repeat_count =
            0;

        simulation_finished =
            1'b0;

    end

    // ============================================================
    // RESET
    // ============================================================

    initial begin

        rst = 1'b1;

        repeat (5)
            @(posedge clk);

        rst = 1'b0;

        $display("");
        $display("======================================================");
        $display("      RV32IMA SPIKE vs RTL VERIFICATION");
        $display("======================================================");
        $display("");

    end
    // ============================================================
    // CYCLE COUNTER
    // ============================================================

    always @(posedge clk) begin

        if (!rst &&
            !simulation_finished)

            cycle_count =
                cycle_count + 1;

    end

    // ============================================================
    // RETIREMENT MONITOR
    // ============================================================

    always @(negedge clk) begin

        if (!rst &&
            !simulation_finished &&
            DUT.retire_valid) begin

            // ----------------------------------------------------
            // Determine whether this is a real instruction
            // ----------------------------------------------------

            is_real_instruction =
                (DUT.retire_instr != 32'h00000000);

            // ----------------------------------------------------
            // Architectural register write
            //
            // rd is meaningful ONLY when rd_we is true.
            // For stores, branches, etc. report rd=0.
            // ----------------------------------------------------

            trace_rd_we =
                DUT.retire_rd_we &&
                (DUT.retire_rd != 5'd0);

            if (trace_rd_we) begin

                trace_rd =
                    DUT.retire_rd;

                trace_rd_data =
                    DUT.retire_rd_data;

            end
            else begin

                trace_rd =
                    5'd0;

                trace_rd_data =
                    32'h00000000;

            end

            // ----------------------------------------------------
            // Write architectural retirement trace
            // ----------------------------------------------------

            $fwrite(
                retire_file,

                "%0d,%0d,%08h,%08h,%s,%0d,%0d,%08h\n",

                retirement_trace_count,

                cycle_count,

                DUT.retire_pc,

                DUT.retire_instr,

                decode_instr(
                    DUT.retire_instr
                ),

                trace_rd,

                trace_rd_we,

                trace_rd_data
            );

            retirement_trace_count =
                retirement_trace_count + 1;

            // ----------------------------------------------------
            // Architectural instruction count
            // ----------------------------------------------------

            if (is_real_instruction)

                retired_arch_count =
                    retired_arch_count + 1;

            // ----------------------------------------------------
            // RV32M / RV32A retirement counters
            // ----------------------------------------------------

            if (is_real_instruction) begin

                if (DUT.retire_instr[6:0]   == 7'b0110011 &&
                    DUT.retire_instr[31:25] == 7'b0000001)

                    mul_count =
                        mul_count + 1;

                if (DUT.retire_instr[6:0] == 7'b0101111) begin

                    atomic_count =
                        atomic_count + 1;

                    if (DUT.retire_instr[31:27] == 5'b00010)
                        lr_count =
                            lr_count + 1;

                    if (DUT.retire_instr[31:27] == 5'b00011)
                        sc_count =
                            sc_count + 1;

                end

            end

            // ----------------------------------------------------
            // Terminal JAL x0,0
            // Wait for two retirements.
            // ----------------------------------------------------

            if (DUT.retire_instr == 32'h0000006F) begin

                halt_repeat_count =
                    halt_repeat_count + 1;

                if (halt_repeat_count >= 2)

                    finish_simulation(
                        1'b0
                    );

            end

        end

    end

    // ============================================================
    // CONTROL MONITOR
    // ============================================================

    always @(negedge clk) begin

        logic [31:0] control_target;

        if (!rst &&
            !simulation_finished) begin

            // ----------------------------------------------------
            // Conditional branch
            // ----------------------------------------------------

            if (DUT.EX_MEM_valid &&
                DUT.EX_MEM_branch) begin

                control_target =
                    DUT.EX_MEM_pc +
                    DUT.EX_MEM_imm;

                $fwrite(
                    control_file,

                    "%0d,%0d,%08h,%08h,%s,BRANCH,%0d,%08h\n",

                    branch_count,

                    cycle_count,

                    DUT.EX_MEM_pc,

                    DUT.EX_MEM_instr,

                    decode_instr(
                        DUT.EX_MEM_instr
                    ),

                    DUT.EX_MEM_branch_taken,

                    control_target
                );

                branch_count =
                    branch_count + 1;

                if (DUT.EX_MEM_branch_taken)

                    taken_branch_count =
                        taken_branch_count + 1;

            end

            // ----------------------------------------------------
            // JAL
            // ----------------------------------------------------

            if (DUT.EX_MEM_valid &&
                DUT.EX_MEM_jump &&
                (DUT.EX_MEM_instr[6:0] ==
                 7'b1101111)) begin

                control_target =
                    DUT.EX_MEM_pc +
                    DUT.EX_MEM_imm;

                $fwrite(
                    control_file,

                    "%0d,%0d,%08h,%08h,%s,JUMP,1,%08h\n",

                    jump_count,

                    cycle_count,

                    DUT.EX_MEM_pc,

                    DUT.EX_MEM_instr,

                    decode_instr(
                        DUT.EX_MEM_instr
                    ),

                    control_target
                );

                jump_count =
                    jump_count + 1;

            end

            // ----------------------------------------------------
            // JALR
            //
            // Architectural target:
            // (forwarded rs1 + imm) with bit 0 cleared.
            // ----------------------------------------------------

            if (DUT.ID_EX_valid &&
                (DUT.ID_EX_instr[6:0] ==
                 7'b1100111)) begin

                control_target =
                    (DUT.forwarded_op_a +
                     DUT.ID_EX_imm) &
                    32'hFFFFFFFE;

                $fwrite(
                    control_file,

                    "%0d,%0d,%08h,%08h,%s,JUMP,1,%08h\n",

                    jump_count,

                    cycle_count,

                    DUT.ID_EX_pc,

                    DUT.ID_EX_instr,

                    decode_instr(
                        DUT.ID_EX_instr
                    ),

                    control_target
                );

                jump_count =
                    jump_count + 1;

            end

        end

    end

    // ============================================================
    // MEMORY MONITOR
    // ============================================================

    always @(negedge clk) begin

        if (!rst &&
            !simulation_finished &&
            DUT.EX_MEM_valid &&
            (DUT.EX_MEM_mem_we ||
             DUT.EX_MEM_mem_re)) begin

            $fwrite(
                memory_file,

                "%0d,%0d,%08h,%08h,%s,%0d,%0d,%08h,%08h,%08h\n",

                memory_count,

                cycle_count,

                DUT.EX_MEM_pc,

                DUT.EX_MEM_instr,

                decode_instr(
                    DUT.EX_MEM_instr
                ),

                DUT.EX_MEM_mem_re,

                DUT.EX_MEM_mem_we,

                DUT.EX_MEM_result,

                DUT.EX_MEM_reg_out_2,

                DUT.d_mem_d_out
            );

            if (DUT.EX_MEM_mem_re)

                load_count =
                    load_count + 1;

            if (DUT.EX_MEM_mem_we)

                store_count =
                    store_count + 1;

            memory_count =
                memory_count + 1;

        end

    end

    // ============================================================
    // STALL COUNTER
    // ============================================================

    always @(negedge clk) begin

        if (!rst &&
            !simulation_finished &&
            DUT.stall)

            stall_count =
                stall_count + 1;

    end

    // ============================================================
    // FLUSH COUNTER
    // ============================================================

    always @(negedge clk) begin

        if (!rst &&
            !simulation_finished &&
            (DUT.IF_ID_flush ||
             DUT.ID_EX_flush))

            flush_count =
                flush_count + 1;

    end

    // ============================================================
    // SAFETY TIMEOUT
    // ============================================================

    initial begin

        repeat (20000)
            @(posedge clk);

        if (!simulation_finished) begin

            finish_simulation(
                1'b1
            );

        end

    end

    // ============================================================
    // WAVEFORM
    // ============================================================

    initial begin

        $dumpfile(
            "rv32ima_verification.vcd"
        );

        $dumpvars(
            0,
            tb_verif
        );

    end

endmodule
