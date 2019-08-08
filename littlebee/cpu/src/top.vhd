library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
  port (
    clk : in std_logic;
    rst_n : in std_logic;
    led : out std_logic_vector(7 downto 0)
  );
end top;

architecture behavior of top is
  signal address : std_logic_vector(15 downto 0);
  signal data_in : std_logic_vector(15 downto 0);
  signal data_out : std_logic_vector(15 downto 0);
  signal wren_n : std_logic;
  signal oen_n : std_logic;


component bram
  port (
      clk : in std_logic;
      wren_n : in std_logic;
      oen_n : in std_logic;
      address : in std_logic_vector(15 downto 0);
      data_in : in std_logic_vector(15 downto 0);
      data_out : out std_logic_vector(15 downto 0)
);
end component;

begin

  dut: entity work.cpu port map (
    clk => clk,
    rst_n => rst_n,
    address => address,
    data_in => data_in,
    data_out => data_out,
    wren_n => wren_n,
    oen_n => oen_n
  );

  mem: bram port map (
    clk => clk,
    wren_n => wren_n,
    oen_n => oen_n,
    address => address,
    data_in => data_out,
    data_out => data_in
  );

  process(clk)
  begin
    if rising_edge(clk) and wren_n = '0' then
      led <= data_out(15 downto 8);
    end if;
  end process;


end;