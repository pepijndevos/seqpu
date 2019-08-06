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
begin

  led <= data_out(15 downto 8);

  dut: entity work.cpu port map (
    clk => clk,
    rst_n => rst_n,
    address => address,
    data_in => data_in,
    data_out => data_out,
    wren_n => wren_n
  );

  process(address)
  begin
    case address is
      when x"0000" => data_in <= "1100101000000000"; -- B A 0 A  ;
      when x"0001" => data_in <= "1100000000000001"; -- add A 1 A;
      when x"0002" => data_in <= "0000000000000010"; -- ld B 0010;
      when x"0003" => data_in <= "0100000000000000"; -- ld A [B] ;
      when x"0004" => data_in <= "0000000000000001"; -- ld B 0001;
      when x"0005" => data_in <= "1010101000000000"; -- jp B     ;
      when others  => data_in <= "0000000000000000";
    end case;
  end process;

end;