library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
  generic (
    formal : boolean := true
  );
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
  signal ci : std_logic; -- carry in
  signal co : std_logic; -- carry out
  signal cr : std_logic; -- reset value
begin
  
  c <= co;

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
        ci <= cr;
      else
        ci <= co;
      end if;
    end if;
  end process;

  formal_gen : if formal generate
    signal last_op : std_logic_vector(2 downto 0);
    signal a_sr : unsigned(7 downto 0);
    signal b_sr : unsigned(7 downto 0);
    signal y_sr : unsigned(7 downto 0);
    signal c_sr : std_logic;
  begin
    process(clk)
    begin
      if rising_edge(clk) then
        last_op <= opcode;
        a_sr <= a & a_sr(7 downto 1);
        b_sr <= b & b_sr(7 downto 1);
        y_sr <= y & y_sr(7 downto 1);
        c_sr <= c;
      end if;
    end process;

    -- set all declarations to run on clk
    default clock is rising_edge(clk);
    -- restrict reset to be a repeating sequence of 011111111011111111...
    restrict {{rst_n = '0'; (rst_n = '1')[*8]}[+]};
    -- assume that the opcode does not change while not in reset
    assume always {rst_n = '0'; rst_n = '1'} |->
      opcode = last_op until rst_n = '0';
    -- assert that after 8 cycles each ALU op produces the correct output
    assert always {opcode = "000" and rst_n = '1'; rst_n = '0'} |->
      y_sr = a_sr+b_sr;
    assert always {opcode = "001" and rst_n = '1'; rst_n = '0'} |->
      y_sr = a_sr-b_sr;
    assert always {opcode = "010" and rst_n = '1'; rst_n = '0'} |->
      y_sr = (a_sr or b_sr);
    assert always {opcode = "011" and rst_n = '1'; rst_n = '0'} |->
      y_sr = (a_sr and b_sr);
    assert always {opcode = "100" and rst_n = '1'; rst_n = '0'} |->
      y_sr = (a_sr xor b_sr);
    assert always {opcode = "101" and rst_n = '1'; rst_n = '0'} |->
      y_sr = b_sr and (c_sr = '1') = (a_sr = b_sr);
    assert always {opcode = "110" and rst_n = '1'; rst_n = '0'} |->
      y_sr = a_sr and (c_sr = '1') = (a_sr > b_sr);
    assert always {opcode = "111" and rst_n = '1'; rst_n = '0'} |->
      y_sr = 0 and c_sr = '0';
  end generate;
end rtl;
