
module tb;

reg  clk   = 0;
reg  rst_n = 0;

wire [15:0] address, data_out;
reg [15:0] data_in;
wire wren_n;

always #1 clk=~clk;

cpu DUT (
  .rst_n(rst_n),
  .clk(clk),
  .address(address),
  .data_out(data_out),
  .data_in(data_in),
  .wren_n(wren_n)
);

always @(*)
  case (address)
    16'd0: data_in <= 16'b1100101000000000; // B A 0 A
    16'd1: data_in <= 16'b1100000000000001; // add A 1 A
    16'd2: data_in <= 16'b0000000000000010; // ld B 0010
    16'd3: data_in <= 16'b0100000000000000; // ld A [B]
    16'd4: data_in <= 16'b0000000000000001; // ld B 0001
    16'd5: data_in <= 16'b1010101000000000; // jp B
    default: data_in <= 16'b0000000000000000;
  endcase

initial
begin
    $dumpfile("cpu_rtl.vcd");
    $dumpvars;

    #4 rst_n = 1'b1;
    #15400 $finish;
    
end

endmodule
