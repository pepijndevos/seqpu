module testbench (
  input clk, rst,
  output [7:0] yval
);

  (* anyconst *) reg [7:0] ainit;
  (* anyconst *) reg [7:0] binit;
  (* anyconst *) reg [2:0] opcode;

  reg [7:0] aval;
  reg [7:0] bval;
  reg [7:0] yval = 0;

  reg a, b, y;

  assign a = aval[0];
  assign b = bval[0];

  alu dut (
    .clk(clk),
    .rst(rst),
    .opcode(opcode),
    .a(a),
    .b(b),
    .y(y)
  );

  reg [7:0] counter = 0;
  reg initial_reset = 0;

  always @(*) if (!initial_reset) assume(rst == 0);

  always @(posedge clk) begin
    initial_reset <= 1;
    if (rst == 0) begin
      counter <= 0;
      aval <= ainit;
      bval <= binit;
    end else begin
      if (counter == 8) begin
        if (opcode == 0) assert(yval == ainit + binit); 
        if (opcode == 1) assert(yval == ainit - binit); 
        if (opcode == 2) assert(yval == ainit | binit); 
        //if (opcode == 3) assert(yval == ainit & binit); 
        if (opcode == 4) assert(yval == ainit ^ binit); 
        if (opcode == 5) assert(yval == ~ainit); 
        if (opcode == 6) assert(yval == ainit ~^ binit); 
      end
      aval <= aval >> 1;
      bval <= bval >> 1;
      yval <= {y, yval[7:1]};
      counter <= counter + 1;
    end
  end
endmodule
