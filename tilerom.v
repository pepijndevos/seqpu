module tilerom(input clk, oen_n,
            input [10:0] address,
            output reg [7:0] data_out);

parameter bits = 11;

reg [7:0] memory [0:(1<<bits)-1];
// fuck Gowin FPGA Designer software
initial $readmemb("/home/pepijn/code/74xx-liberty/seqpu/tilerom.mem", memory);

always @(posedge clk)
  if (oen_n == 1'b0)
    data_out <= memory[address];


endmodule
