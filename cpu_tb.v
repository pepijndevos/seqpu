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

  function alu_carry([2:0] op, [15:0] a, [15:0] b);
    begin
      case (op)
        3'b000: alu_carry = (({1'b0,a} + {1'b0,b})>17'hffff);
        3'b001: alu_carry = (a>=b);
        3'b010: alu_carry = (|a);
        3'b011: alu_carry = (&a);
        3'b100: alu_carry = (^a);
        3'b101: alu_carry = (a==b);
        3'b110: alu_carry = (a>b);
        3'b111: alu_carry = 0;
      endcase
    end
  endfunction

  function [15:0] rotate([3:0] rot, [15:0] in, [15:0] res);
    begin
      case (rot) // a piece of me died writing this
        4'b0000: rotate = res;
        4'b0001: rotate = {res[14:0], in[15:15]};
        4'b0010: rotate = {res[13:0], in[15:14]};
        4'b0011: rotate = {res[12:0], in[15:13]};
        4'b0100: rotate = {res[11:0], in[15:12]};
        4'b0101: rotate = {res[10:0], in[15:11]};
        4'b0110: rotate = {res[9:0], in[15:10]};
        4'b0111: rotate = {res[8:0], in[15:9]};
        4'b1000: rotate = {res[7:0], in[15:8]};
        4'b1001: rotate = {res[6:0], in[15:7]};
        4'b1010: rotate = {res[5:0], in[15:6]};
        4'b1011: rotate = {res[4:0], in[15:5]};
        4'b1100: rotate = {res[3:0], in[15:4]};
        4'b1101: rotate = {res[2:0], in[15:3]};
        4'b1110: rotate = {res[1:0], in[15:2]};
        4'b1111: rotate = {res[0:0], in[15:1]};
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
  (* keep *) reg [15:0] mysp;
  always @(*) mysp = DUT.sp;
  (* keep *) reg [15:0] myop;
  always @(*) myop = DUT.op;
  (* keep *) reg [15:0] mypc;
  always @(*) mypc = DUT.pc;
  (* keep *) reg [3:0] mycounter;
  always @(*) mycounter = DUT.counter;
  (* keep *) reg mycarry;
  always @(*) mycarry = DUT.carry;

  reg [15:0] lasta;
  reg [15:0] lastb;
  reg [15:0] lastsp;
  reg [15:0] lastpc;
  reg lastcarry;

  (* keep *) reg [2:0] alu_op;
  always @(*) alu_op = DUT.op[11:9];
  (* keep *) reg [15:0] alu_res;
  always @(*) alu_res = DUT.op[15] == 1 ? alu(alu_op, lasta, lastb) : alu(alu_op, lastsp, lastb);
  (* keep *) reg alu_resc;
  always @(*) alu_resc = alu_carry(alu_op, lasta, lastb);
 
  always @(*) assume(rst == initial_reset);

  always @(posedge clk) begin
    initial_reset <= 1'b1;
    if (DUT.state == 3 && $past(DUT.state) != 3) begin
      lasta <= DUT.a;
      lastb <= DUT.b;
      lastsp <= DUT.sp;
      lastpc <= DUT.pc;
      lastcarry <= DUT.carry;
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

  assert property ( // EXECUTE ld A, [SP]
    @(posedge clk) DUT.state == 1 && DUT.op[15:13] == 3'b010 |->
    address == DUT.sp && // write address
    data_out == DUT.a &&
    wren_n == 0 &&
    oen_n == 1 ##1
    DUT.state == 3// ALU
  );

  assert property ( // EXECUTE ld [SP], B
    @(posedge clk) DUT.state == 1 && DUT.op[15:13] == 3'b011 |=>
    DUT.state == 2 && // LOAD
    address == DUT.sp && // read address
    wren_n == 1 &&
    oen_n == 0
  );

  assert property ( // EXECUTE op A lit R
    @(posedge clk) DUT.state == 1 && DUT.op[15:14] == 2'b11 |=>
    DUT.state == 3 && // ALU
    DUT.b == {{8{DUT.op[8]}}, DUT.op[7:0]} &&
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
    DUT.b == lastb && (
    (DUT.pc == lastpc+16'd1 && DUT.a == lasta && DUT.sp == lastsp) ||
    (DUT.pc == lastpc+16'd1 && DUT.a == lasta && DUT.sp == alu_res) ||
    (DUT.pc == lastpc+16'd1 && DUT.a == alu_res && DUT.sp == lastsp && DUT.carry == alu_resc) ||
    (DUT.pc == lastpc+16'd1 && DUT.a == rotate(DUT.op[3:0], lasta, alu_res) && DUT.sp == lastsp) ||
    (DUT.pc == alu_res && DUT.a == lasta && DUT.sp == lastsp)
    )
  );

  always @(*) assert (wren_n || oen_n);

endmodule
