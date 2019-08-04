library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu is
  port (
    clk : in std_logic;
    rst_n : in std_logic;
    address : out std_logic_vector(15 downto 0);
    data_in : in std_logic_vector(15 downto 0);
    data_out : out std_logic_vector(15 downto 0);
    wren_n : out std_logic
  );
end cpu;

architecture rtl of cpu is
  type state_type is (FETCH, EXECUTE, LOAD, ALU_OP);
  signal state : state_type;
  signal counter : unsigned(3 downto 0);
  signal op, a, b : std_logic_vector(15 downto 0);
  signal pc : unsigned(15 downto 0);
  signal c, y, pcinc, carry: std_logic;
  signal alu_rst_n : std_logic;

begin

  alu1: entity work.alu port map (
    clk => clk,
    rst_n => alu_rst_n,
    opcode => op(12 downto 10),
    a => a(0),
    b => b(0),
    y => y,
    c => c
  );

  inc1: entity work.inc port map (
    clk => clk,
    rst_n => alu_rst_n,
    a => pc(0),
    y => pcinc
  );

  -- "00" & addr        ld [addr], a
  -- "01" & addr        ld a, [addr]
  -- "10" & op & lit    op lit, B, A
  -- "11" & op & '00'   op A, B, A
  -- "11" & op & '01'   op A, B, B
  -- "11" & op & '10'   op A, B, void
  -- "11" & op & '11'   op A, B, PC (if carry)
  process(clk, rst_n)
    variable alu_out : std_logic_vector(2 downto 0);
    variable a0, b0, pc0 : std_logic;
  begin
    if (rst_n = '0') then
      pc <= x"0000";
      wren_n <= '1';
      state <= FETCH;
    elsif (rising_edge(clk)) then
      counter <= counter - 1;
      case state is
        when FETCH =>
          wren_n <= '1';
          address <= std_logic_vector(pc);
          state <= EXECUTE;
        when EXECUTE =>
          op <= data_in;
          if data_in(15) = '0' then -- load
            state <= LOAD;
            address <= "00" & data_in(13 downto 0);
            if data_in(14) = '1' then -- ld [addr], a
              data_out <= a;
              wren_n <= '0';
              state <= FETCH;
            else -- ld a, [addr]
              wren_n <= '1';
              state <= LOAD;
            end if;
          else -- alu
            wren_n <= '1';
            counter <= x"f";
            state <= ALU_OP;
            if data_in(14) = '0' then -- literal
              a <= "00000" & data_in(10 downto 0);
            end if;
          end if;
        when LOAD =>
          a <= data_in;
          wren_n <= '1';
          address <= std_logic_vector(pc);
          state <= EXECUTE;
        when ALU_OP =>
          alu_out := op(14) & op(10 downto 9);
          case alu_out is
            when "000" | "001" | "010" | "011" | "100" => -- op A, B, A
              a0 := y;
              b0 := b(0);
              pc0 := pcinc;
            when "101" => -- op A, B, B
              a0 := a(0);
              b0 := y;
              pc0 := pcinc;
            when "110" => -- op A, B, void
              a0 := a(0);
              b0 := b(0);
              pc0 := pcinc;
            when "111" => -- op A, B, PC (if carry)
              a0 := a(0);
              b0 := b(0);
              pc0 := y when carry else pcinc;
            when others =>
          end case;
          a <= a0 & a(15 downto 1);
          b <= b0 & b(15 downto 1);
          pc <= pc0 & pc(15 downto 1);
          if counter = 0 then
            carry <= c;
            state <= FETCH;
          end if;
      end case;
    end if;
  end process;
end rtl;
