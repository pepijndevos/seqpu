module testbench (input clk, rst, [15:0]data_in,
                  output reg [15:0] data_out, [15:0] address
                  );
 
  cpu DUT (
    .rst_n(rst),
    .clk(clk),
    .address(address),
    .data_out(data_out),
    .data_in(data_in),
    .wren_n(wren_n),
    .oen_n(oen_n)
  );
 
  function [15:0] alu([2:0] op, [15:0] a, [15:0] b);
    begin
      case (op)
        3'b000: alu = a+b;
        3'b001: alu = a-b;
        3'b010: alu = a|b;
        3'b011: alu = a&b;
        3'b100: alu = a^b;
        3'b101: alu = b;
        3'b110: alu = a;
        3'b111: alu = 0;
      endcase
    end
  endfunction

  reg initial_reset = 1'b0;
  (* keep *) reg [2:0] mystate;
  always @(*) mystate = DUT.state;
  (* keep *) reg [15:0] mya;
  always @(*) mya = DUT.a;
  (* keep *) reg [15:0] myb;
  always @(*) myb = DUT.b;
  (* keep *) reg [15:0] myop;
  always @(*) myop = DUT.op;
  (* keep *) reg [15:0] mypc;
  always @(*) mypc = DUT.pc;
  (* keep *) reg [3:0] mycounter;
  always @(*) mycounter = DUT.counter;

  reg [15:0] lasta;
  reg [15:0] lastb;
  reg [15:0] lastpc;

  (* keep *) reg [2:0] alu_op;
  always @(*) alu_op = DUT.op[11:9];
  (* keep *) reg [15:0] alu_res;
  always @(*) alu_res = alu(alu_op, lasta, lastb);
 
  always @(*) assume(rst == initial_reset);

  always @(posedge clk) begin
    initial_reset <= 1'b1;
    if (DUT.state == 3 && $past(DUT.state) != 3) begin
      lasta <= DUT.a;
      lastb <= DUT.b;
      lastpc <= DUT.pc;
    end
  end

  assert property (
    @(posedge clk) $rose(rst) |-> DUT.state == 0);

  assert property ( // FETCH
    @(posedge clk) rst && DUT.state == 0 && DUT.counter == 0 |->
    address == DUT.pc &&
    wren_n == 1 &&
    oen_n == 0 ##1
    DUT.state == 1
  );

  assert property ( // EXECUTE ld lit, B
    @(posedge clk) DUT.state == 1 && DUT.op[15:14] == 2'b00 |=>
    DUT.state == 3 && // ALU
    DUT.B == DUT.op[13:0] && // read address
    wren_n == 1
  );

  assert property ( // EXECUTE ld A, [B]
    @(posedge clk) DUT.state == 1 && DUT.op[15:13] == 3'b010 |->
    address == DUT.b && // write address
    data_out == DUT.a &&
    wren_n == 0 &&
    oen_n == 1 ##1
    DUT.state == 3// ALU
  );

  assert property ( // EXECUTE ld [B], B
    @(posedge clk) DUT.state == 1 && DUT.op[15:13] == 3'b011 |=>
    DUT.state == 2 && // LOAD
    address == DUT.b && // read address
    wren_n == 1 &&
    oen_n == 0
  );

  assert property ( // EXECUTE op A lit R
    @(posedge clk) DUT.state == 1 && DUT.op[15:14] == 2'b11 |=>
    DUT.state == 3 && // ALU
    DUT.b == {{8{DUT.op[7]}}, DUT.op[7:0]} &&
    wren_n == 1 &&
    oen_n == 1
  );

  assert property ( // EXECUTE op A B R
    @(posedge clk) DUT.state == 1 && DUT.op[15:14] == 2'b10 |=>
    DUT.state == 3 && // ALU
    wren_n == 1 &&
    oen_n == 1
  );

  assert property ( // LOAD
    @(posedge clk) DUT.state == 2 && DUT.counter == 0 |->
    wren_n == 1 &&
    oen_n == 0 ##1
    DUT.state == 3 && // ALU
    DUT.b == $past(data_in)
  );

  assert property ( // ALU
    @(posedge clk) DUT.state == 3 && DUT.counter == 0 |->
    wren_n == 1 &&
    oen_n == 1 ##1
    DUT.state == 0 &&
    (DUT.pc == lastpc+16'd1 || DUT.pc == alu_res) &&
    (DUT.a == lasta || DUT.a == alu_res) &&
    (DUT.b == lastb || DUT.b == alu_res)
  );

  assume property ( // ALU
    @(posedge clk) DUT.state == 3 && DUT.counter == 0 && DUT.op[14] == 1'b0 |->
    DUT.op[3:0] == 0
  );
  // TODO test barrel shift, big pita

  always @(*) assert (wren_n || oen_n);

endmodule
