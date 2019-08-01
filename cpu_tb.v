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

  sequence READ(mosi);
    (hold_rom_n == 1) throughout (
      (cs_rom_n == 1'b1 && cs_ram_n == 1'b1) ##1
      (cs_rom_n == 1'b0 && cs_ram_n == 1'b1) throughout (
        (mosi == 1'b0)[*6] ##1
        (mosi == 1'b1)[*2] ##1
        (mosi == DUT.accumulator[0])[*24] ##1
        (1)[*8]));// ##1
    //(hold_rom_n == 0);
  endsequence

  assert property (
    @(posedge clk) !rst ##1 rst |-> READ(mosi_rom));

  assert property (
    @(posedge clk) DUT.state != 0 ##1 DUT.state == 0 |-> READ(mosi_rom));

endmodule
