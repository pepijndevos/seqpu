module bram(input clk, wren_n, oen_n,
            input [15:0] address, data_in,
            output reg [15:0] data_out);

parameter bits = 10;

reg [15:0] memory [0:(1<<bits)-1];
// fuck Gowin FPGA Designer software
initial $readmemb("/home/pepijn/code/74xx-liberty/cpu/rom.mem", memory);

always @(posedge clk)
  if (wren_n == 1'b0)
    memory[address] <= data_in;

always @(posedge clk)
  if (oen_n == 1'b0)
    data_out <= memory[address];

endmodule