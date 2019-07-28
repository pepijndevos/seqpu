library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
  port (
    clk : in std_logic;
    rst : in std_logic;
    opcode : in std_logic_vector(2 downto 0);
    a : in std_logic;
    b : in std_logic;
    y : out std_logic
  );
end alu;

--architecture mux of alu is
--  signal ci : std_logic;
--  signal co : std_logic;
--  signal cr : std_logic; -- reset value
--  signal mux1, mux2: std_logic_vector(7 downto 0);
--begin
--
--  process(a, b, ci, mux1, mux2)
--    variable sel : unsigned(2 downto 0);
--  begin
--    sel := a & b & ci;
--    y <= mux1(to_integer(sel));
--    co <= mux2(to_integer(sel));
--  end process;
--
--  process(opcode)
--  begin
--    case opcode is
--      when "000" => -- add
--        mux1 <= "01101001";
--        mux2 <= "00010111";
--        cr <= '0';
--      when "001" => -- subtract
--        mux1 <= "01101001";
--        mux2 <= "01110001";
--        cr <= '1';
--      when "010" => -- or
--        mux1 <= "00111111";
--        mux2 <= "01111111"; -- reduce
--        cr <= '0';
--      when "011" => -- and
--        mux1 <= "00000011";
--        mux2 <= "00000001"; -- reduce
--        cr <= '1';
--      when "100" => -- xor
--        mux1 <= "00111100";
--        mux2 <= "01101001"; -- reduce
--        cr <= '0';
--      when "101" => -- not
--        mux1 <= "11110000"; -- a
--        mux2 <= "11001100"; -- b
--        cr <= '0';
--      when "110" =>
--        mux1 <= "11000011"; -- xnor
--        mux2 <= "01000001"; -- a=b
--        cr <= '1';
--      when others =>
--        mux1 <= "--------";
--        mux2 <= "--------";
--        cr <= '-';
--    end case;
--  end process;
--
--  process(clk, rst, cr)
--  begin
--    if(rst = '0') then
--      ci <= cr;
--    elsif(rising_edge(clk)) then
--      ci <= co;
--    end if;
--  end process;
--end mux;

architecture direct of alu is
  signal ci : std_logic;
  signal co : std_logic;
  signal cr : std_logic; -- reset value
begin

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
        co <= a or b or ci;
        cr <= '0';
      when "011" => -- and
        y <= a and b;
        co <= a and b and ci;
        cr <= '1';
      when "100" => -- xor
        y <= a xor b;
        co <= a xor b xor ci;
        cr <= '0';
      when "101" => -- not
        y <= not a; -- a
        co <= not b; -- b
        cr <= '0';
      when "110" =>
        y <= a xnor b; -- xnor
        co <= not (a xor b xor ci); -- a=b
        cr <= '1';
      when others =>
        y <= '-';
        co <= '-';
        cr <= '-';
    end case;
  end process;

  process(clk, rst, cr)
  begin
    if(rising_edge(clk)) then
      if(rst = '0') then
        ci <= cr;
      else
        ci <= co;
      end if;
    end if;
  end process;
end direct;
