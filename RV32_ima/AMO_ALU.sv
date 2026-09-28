import risc_v_pkg::*;

module AMO_ALU(
    input  logic [4:0] amo_op,
    input  logic [31:0] mem_data,
    input  logic [31:0] rs2_data,
    output logic [31:0] amo_new_data
);

    always_comb begin

        unique case (amo_op)

            AMO_ADD:
                amo_new_data = mem_data + rs2_data;

            AMO_SWAP:
                amo_new_data = rs2_data;

            AMO_XOR:
                amo_new_data = mem_data ^ rs2_data;

            AMO_OR:
                amo_new_data = mem_data | rs2_data;

            AMO_AND:
                amo_new_data = mem_data & rs2_data;

            AMO_MIN:
                begin
                    if ($signed(mem_data) < $signed(rs2_data))
                        amo_new_data = mem_data;
                    else
                        amo_new_data = rs2_data;
                end

            AMO_MAX:
                begin
                    if ($signed(mem_data) > $signed(rs2_data))
                        amo_new_data = mem_data;
                    else
                        amo_new_data = rs2_data;
                end

            AMO_MINU:
                begin
                    if ($unsigned(mem_data) < $unsigned(rs2_data))
                        amo_new_data = mem_data;
                    else
                        amo_new_data = rs2_data;
                end

            AMO_MAXU:
                begin
                    if ($unsigned(mem_data) > $unsigned(rs2_data))
                        amo_new_data = mem_data;
                    else
                        amo_new_data = rs2_data;
                end

            default:
                amo_new_data = 32'h00000000;

        endcase

    end

endmodule
