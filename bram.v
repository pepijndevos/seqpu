module bram(input clk, wren_n, oen_n,
            input [15:0] rdaddress, wraddress, data_in,
            output reg [15:0] data_out);

parameter bits = 12;

reg [15:0] memory [0:(1<<bits)-1];
// fuck Gowin FPGA Designer software
initial $readmemb("/home/pepijn/code/74xx-liberty/seqpu/rom.mem", memory);

always @(posedge clk)
  if (wren_n == 1'b0)
    memory[wraddress] <= data_in;

always @(posedge clk)
  if (oen_n == 1'b0)
    data_out <= memory[rdaddress];


endmodule
