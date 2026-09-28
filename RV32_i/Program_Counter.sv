module Program_Counter(input logic clk, input logic rst, input logic [31: 0] next_pc, 
output logic [31: 0] pc );

  always_ff @(posedge clk or posedge rst) begin
	if (rst) begin
          pc <= 0;
        end
        else begin
          pc <= next_pc;
        end
  end
endmodule
