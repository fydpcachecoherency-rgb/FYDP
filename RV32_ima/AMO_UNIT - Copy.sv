
import risc_v_pkg::*;

module AMO_UNIT(

    input logic clk,
    input logic rst,

    input logic        amo_en,
    input logic [4:0]  amo_op,

    input logic [31:0] addr,
    input logic [31:0] rs2_data,
    input logic [31:0] mem_data,
    input logic [31:0] amo_new_data,

    input logic        normal_store_we,
    input logic [31:0] normal_store_addr,

    output logic        atomic_mem_we,
    output logic [31:0] atomic_mem_wdata,
    output logic [31:0] atomic_wb_data

);

    logic reservation_valid;
    logic [31:0] reservation_addr;

    logic [31:0] atomic_result_comb;

    logic is_lr;
    logic is_sc;
    logic reservation_match;

    assign is_lr = (amo_op == AMO_LR);
    assign is_sc = (amo_op == AMO_SC);

    assign reservation_match =
            reservation_valid &&
            (reservation_addr == addr);

    // ============================================================
    // Atomic transaction control
    // ============================================================

    always_comb begin

        atomic_mem_we     = 1'b0;
        atomic_mem_wdata  = 32'h00000000;
        atomic_result_comb = 32'h00000000;

        if (amo_en) begin

            // ----------------------------------------------------
            // LR.W
            // ----------------------------------------------------
            if (is_lr) begin

                atomic_result_comb = mem_data;

                atomic_mem_we =
                    1'b0;

            end

            // ----------------------------------------------------
            // SC.W
            // ----------------------------------------------------
            else if (is_sc) begin

                if (reservation_match) begin

                    // Store succeeds
                    atomic_mem_we    = 1'b1;
                    atomic_mem_wdata = rs2_data;

                    // SC success code
                    atomic_result_comb = 32'h00000000;

                end
                else begin

                    // Store fails
                    atomic_mem_we    = 1'b0;
                    atomic_mem_wdata = 32'h00000000;

                    // SC failure code
                    atomic_result_comb = 32'h00000001;

                end

            end

            // ----------------------------------------------------
            // Normal AMO read-modify-write
            // ----------------------------------------------------
            else begin

                atomic_mem_we    = 1'b1;
                atomic_mem_wdata = amo_new_data;

                // rd receives OLD memory value
                atomic_result_comb = mem_data;

            end

        end

    end

    // ============================================================
    // Reservation + atomic result
    // ============================================================

    always_ff @(negedge clk or posedge rst) begin

        if (rst) begin

            reservation_valid <= 1'b0;
            reservation_addr  <= 32'h00000000;

            atomic_wb_data    <= 32'h00000000;

        end

        else begin

            // Capture architectural result before memory changes.
            if (amo_en)
                atomic_wb_data <= atomic_result_comb;

            // ----------------------------------------------------
            // LR.W establishes reservation
            // ----------------------------------------------------
            if (amo_en && is_lr) begin

                reservation_valid <= 1'b1;
                reservation_addr  <= addr;

            end

            // ----------------------------------------------------
            // SC.W always destroys reservation
            // ----------------------------------------------------
            else if (amo_en && is_sc) begin

                reservation_valid <= 1'b0;

            end

            // ----------------------------------------------------
            // Normal store to reserved address invalidates
            // reservation
            // ----------------------------------------------------
            else if (normal_store_we) begin

                if (reservation_valid &&
                    reservation_addr == normal_store_addr) begin

                    reservation_valid <= 1'b0;

                end

            end

            // ----------------------------------------------------
            // Other AMO store to reserved address invalidates it
            // ----------------------------------------------------
            else if (amo_en && atomic_mem_we) begin

                if (reservation_valid &&
                    reservation_addr == addr) begin

                    reservation_valid <= 1'b0;

                end

            end

        end

    end

endmodule