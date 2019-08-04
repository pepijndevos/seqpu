module testbench (input clk, rst, miso_rom, miso_ram,
                  output reg mosi_rom, mosi_ram, cs_rom_n, cs_ram_n, hold_rom_n
                  );
 
  reg initial_reset = 1'b0;
  (* keep *) reg [2:0] mystate;

  always @(*) mystate = DUT.state;
 
  cpu DUT (
    .rst_n(rst),
    .clk(clk),
    .miso_rom(miso_rom),
    .miso_ram(miso_ram),
    .mosi_rom(mosi_rom),
    .mosi_ram(mosi_ram),
    .cs_rom_n(cs_rom_n),
    .cs_ram_n(cs_ram_n),
    .hold_rom_n(hold_rom_n)
  );
 
  always @(*) assume(rst == initial_reset);

  always @(posedge clk) begin
    initial_reset <= 1'b1;
  end

  sequence ROM_CMD;
    (hold_rom_n == 1 &&
     cs_rom_n == 0 &&
     cs_ram_n == 1) throughout (
        (mosi_rom == 1'b0)[*6] ##1
        (mosi_rom == 1'b1)[*2]) ##1
    ROM_ADDRESS;
  endsequence

  sequence ROM_ADDRESS;
    (hold_rom_n == 1 &&
     cs_rom_n == 0 &&
     cs_ram_n == 1) throughout (
        (mosi_rom == DUT.accumulator[0])[*24]) ##1
    ROM_OPCODE;
  endsequence

  sequence ROM_OPCODE;
    (hold_rom_n == 1 &&
     cs_rom_n == 0 &&
     cs_ram_n == 1) throughout (
        (1)[*8]) ##1
    RAM_CMD;
  endsequence

  sequence RAM_CMD;
    (hold_rom_n == 0 &&
     cs_rom_n == 0 &&
     cs_ram_n == 0) throughout (
        (mosi_rom == 1'b0)[*6] ##1
        (mosi_rom == 1'b1) ##1
        (mosi_rom == DUT.opcode[5]));
  endsequence

  assert property (
    @(posedge clk) $rose(rst) |=>  cs_rom_n == 1'b1 ##1 DUT.state == 1);

  assert property (
    @(posedge clk) DUT.state != 1 ##1 DUT.state == 1 |=> ROM_CMD);

  assert property (
    @(posedge clk) DUT.state != 4 ##1 DUT.state == 4 |=> RAM_CMD);

endmodule
