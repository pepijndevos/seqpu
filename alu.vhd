library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
  port (
    clk : in std_logic;
    rst_n : in std_logic;
    opcode : in std_logic_vector(2 downto 0);
    a : in std_logic;
    b : in std_logic;
    y : out std_logic;
    c : out std_logic
  );
end alu;

architecture rtl of alu is
  signal ci, cip : std_logic; -- carry in
  signal co : std_logic; -- carry out
  signal cr : std_logic; -- reset value
  signal first : std_logic; -- ignore co on first clock
begin
  
  c <= ci;

  ci <= cr when first = '1' else cip;

  process(opcode, a, b, ci)
  begin
    case opcode is
      when "000" => -- add
        y <= a xor b xor ci;
        co <= (a and b) or (a and ci) or (b and ci);
        cr <= '0';
      when "001" => -- subtract
        y <= a xor (not b) xor ci;
        co <= (a and (not b)) or (a and ci) or ((not b) and ci);
        cr <= '1';
      when "010" => -- or
        y <= a or b;
        co <= a or ci;
        cr <= '0';
      when "011" => -- and
        y <= a and b;
        co <= a and ci;
        cr <= '1';
      when "100" => -- xor
        y <= a xor b;
        co <= a xor ci;
        cr <= '0';
      when "101" =>
        y <= b; -- b
        co <= (a xnor b) and ci; -- a=b
        cr <= '1';
      when "110" =>
        y <= a; -- a
        co <= (a and (not b)) or ((a xnor b) and ci); -- a > b
        cr <= '0';
      when "111" => -- clear
        y <= '0';
        co <= '0';
        cr <= '1';
      when others =>
        y <= '-';
        co <= '-';
        cr <= '-';
    end case;
  end process;

  process(clk, rst_n)
  begin
    if(rising_edge(clk)) then
      if(rst_n = '0') then
        first <= '1';
      else
        first <= '0';
        cip <= co;
      end if;
    end if;
  end process;
end rtl;
