library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu is
  port (
    clk : in std_logic;
    rst_n : in std_logic;
    miso_rom : in std_logic;
    miso_ram : in std_logic;
    mosi_rom : out std_logic;
    mosi_ram : out std_logic;
    cs_rom_n : out std_logic;
    cs_ram_n : out std_logic;
    hold_rom_n : out std_logic;
    sclk : out std_logic
  );
end cpu;

architecture rtl of cpu is
  type state_type is (RESET,ROM_CMD, ROM_ADDRESS, ROM_OPCODE, RAM_CMD, RAM_ADDRESS, RAM_DATA);
  signal accumulator : unsigned(23 downto 0);
  signal state : state_type;
  signal counter : unsigned(7 downto 0);
  signal opcode : std_logic_vector(7 downto 0);
  signal alu_rst_n : std_logic;
  signal alu_opcode : std_logic_vector(2 downto 0);
  signal a, b, c, y : std_logic;
  signal jump, immediate, write : std_logic;
begin

  with state select alu_rst_n <= '1' when RAM_DATA, '0' when others;
  alu_opcode <= opcode(2 downto 0);
  jump <= opcode(3);
  immediate <= opcode(4);
  write <= opcode(5);
  a <= accumulator(0);

  alu1: entity work.alu port map (
    clk => clk,
    rst_n => alu_rst_n,
    opcode => alu_opcode,
    a => a,
    b => b,
    y => y,
    c => c
  );

  process(clk, rst_n)
  begin
    if (rst_n = '0') then
      accumulator <= x"555555";
      state <= RESET;
    elsif (rising_edge(clk)) then
      counter <= counter - 1;
      case state is
        when RESET =>
          hold_rom_n <= '1';
          cs_rom_n <= '1';
          cs_ram_n <= '1';
          mosi_rom <= '-';
          mosi_ram <= '-';
          state <= ROM_CMD;
          counter <= to_unsigned(7, 8);
        when ROM_CMD => -- jump to acumulator
          hold_rom_n <= '1';
          cs_rom_n <= '0';
          cs_ram_n <= '1';
          mosi_ram <= '-';
          -- x"03" read
          if counter = 1 or counter = 0 then
            mosi_rom <= '1';
          else
            mosi_rom <= '0';
          end if;
          if counter = 0 then
            state <= ROM_ADDRESS;
            counter <= to_unsigned(23, 8);
          end if;
        when ROM_ADDRESS =>
          hold_rom_n <= '1';
          cs_rom_n <= '0';
          cs_ram_n <= '1';
          mosi_rom <= accumulator(23);
          mosi_ram <= '-';
          accumulator <= accumulator(22 downto 0) & accumulator(23);
          if counter = 0 then
            state <= ROM_OPCODE;
            counter <= to_unsigned(7, 8);
          end if;
        when ROM_OPCODE => -- continue from held address
          hold_rom_n <= '1';
          cs_rom_n <= '0';
          cs_ram_n <= '1';
          mosi_rom <= '-';
          mosi_ram <= '-';
          opcode <= opcode(6 downto 0) & miso_rom;
          if counter = 0 then
            if immediate = '1' and write = '0' then
              state <= RAM_DATA; -- don't actually use ram
              counter <= to_unsigned(23, 8);
            else
              state <= RAM_CMD;
              counter <= to_unsigned(7, 8);
            end if;
          end if;
        when RAM_CMD =>
          hold_rom_n <= '0';
          cs_rom_n <= '0';
          cs_ram_n <= '0';
          mosi_rom <= '-';
          -- x"03" read or x"02" write
          if counter = 1 then
            mosi_ram <= '1';
          elsif counter = 0 then
            mosi_ram <= not write;
          else
            mosi_ram <= '0';
          end if;
          if counter = 0 then
            state <= RAM_ADDRESS;
            counter <= to_unsigned(23, 8);
          end if;
        when RAM_ADDRESS =>
          hold_rom_n <= '1';
          cs_rom_n <= '0';
          cs_ram_n <= '0';
          mosi_rom <= '-';
          mosi_ram <= miso_rom; -- TODO probably off by one
          if counter = 0 then
            state <= RAM_DATA;
            counter <= to_unsigned(23, 8);
          end if;
        when RAM_DATA =>
          hold_rom_n <= '0';
          cs_rom_n <= '0';
          cs_ram_n <= '0';
          mosi_rom <= '-';
          mosi_ram <= y;
          accumulator <= y & accumulator(23 downto 1);
          if write = '1' then
            b <= '0';
          elsif immediate = '1' then
            b <= miso_rom;
          else
            b <= miso_ram;
          end if;
          if counter = 0 then
            if jump = '1' and c = '1' then
              state <= RESET;
            else
              state <= ROM_OPCODE;
            end if;
            counter <= to_unsigned(7, 8);
          end if;
      end case;
    end if;
  end process;
end rtl;
