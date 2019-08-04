module testbench (
  input clk, rst
);

  (* anyconst *) reg [7:0] ainit;

  reg [7:0] aval;
  reg [7:0] yval = 0;

  reg a, y;

  assign a = aval[0];

  inc dut (
    .clk(clk),
    .rst_n(rst),
    .a(a),
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
    end else begin
      if (counter == 8) begin
        assert(yval == ainit + 8'b00000001); 
      end
      aval <= aval >> 1;
      yval <= {y, yval[7:1]};
      counter <= counter + 1;
    end
  end
endmodule
