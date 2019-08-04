library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity inc is
  port (
    clk : in std_logic;
    rst_n : in std_logic;
    a : in std_logic;
    y : out std_logic
  );
end inc;

architecture rtl of inc is
  signal ci : std_logic;
  signal co : std_logic;
begin

  process(a, ci)
  begin
    y <= a xor ci;
    co <= a and ci;
  end process;

  process(clk, rst_n)
  begin
    if(rising_edge(clk)) then
      if(rst_n = '0') then
        ci <= '1';
      else
        ci <= co;
      end if;
    end if;
  end process;
end rtl;
