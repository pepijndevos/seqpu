
module tb;

reg  clk   = 0;
reg  rst_n = 0;

wire [15:0] address, data_out;
wire [15:0] data_in;
wire wren_n;
wire oen_n;

always #1 clk=~clk;

cpu DUT (
  .rst_n(rst_n),
  .clk(clk),
  .address(address),
  .data_out(data_out),
  .data_in(data_in),
  .wren_n(wren_n),
  .oen_n(oen_n)
);

bram mem (
  .clk(clk),
  .address(address),
  .data_out(data_in),
  .data_in(data_out),
  .wren_n(wren_n),
  .oen_n(oen_n)
);


initial
begin
    $dumpfile("cpu_rtl.vcd");
    $dumpvars;

    #4 rst_n = 1'b1;
    #50000 $finish;
    
end

endmodule
