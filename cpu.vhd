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
    opcode => op(11 downto 9),
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

  -- "00" & lit         ld lit, b
  -- "010"              ld a, [b]
  -- "011"              ld [b], a
  -- "1000" & op        op A, B, A
  -- "1001" & op        op A, B, B
  -- "1010" & op        op A, B, PC
  -- "1011" & op        op A, B, PC (if carry)
  -- "1100" & op & lit  op A, lit, A
  -- "1101" & op & lit  op A, lit, B
  -- "1110" & op & lit  op A, lit, PC
  -- "1111" & op & lit  op A, lit, PC (if carry)
  process(clk, rst_n)
    variable a0, b0, pc0 : std_logic;
  begin
    if (rst_n = '0') then
      pc <= x"0000";
      op <= x"0000";
      a <= x"0000";
      b <= x"0000";
      data_out <= x"0000";
      address <= x"0000";
      counter <= x"0";
      alu_rst_n <= '0';
      wren_n <= '1';
      carry <= '0';
      state <= FETCH;
    elsif (rising_edge(clk)) then
      counter <= counter - 1;
      case state is
        when FETCH =>
          alu_rst_n <= '0';
          wren_n <= '1';
          address <= std_logic_vector(pc);
          state <= EXECUTE;
        when EXECUTE =>
          op <= data_in;
          if data_in(15) = '0' then -- load
            if data_in(14) = '0' then -- literal load
              b <= "00" & data_in(13 downto 0);
              wren_n <= '1';
              --address <= (others => '-');
              --data_out <= (others => '-');
              counter <= x"f";
              alu_rst_n <= '1';
              state <= ALU_OP;
            else -- indirect load
              address <= b;
              data_out <= a;
              if data_in(13) = '0' then -- ld a, [b]
                wren_n <= '0';
                counter <= x"f";
                alu_rst_n <= '1';
                state <= ALU_OP;
              else -- ld [b], a
                address <= b;
                wren_n <= '1';
                state <= LOAD;
              end if;
            end if;
          else -- alu
            wren_n <= '1';
            --address <= (others => '-');
            --data_out <= (others => '-');
            if data_in(14) = '1' then -- literal
              b <= (others => data_in(7)); -- sign extend
              b(7 downto 0) <= data_in(7 downto 0);
            end if;
            counter <= x"f";
            alu_rst_n <= '1';
            state <= ALU_OP;
          end if;
        when LOAD =>
          a <= data_in;
          wren_n <= '1';
          counter <= x"f";
          alu_rst_n <= '1';
          state <= ALU_OP;
        when ALU_OP =>
          wren_n <= '1';
          if op(15) = '0' then -- load
            a0 := a(0);
            b0 := b(0);
            pc0 := pcinc;
          else
            case op(13 downto 12) is
              when "00" => -- op A, B, A
                a0 := y;
                b0 := b(0);
                pc0 := pcinc;
              when "01" => -- op A, B, B
                a0 := a(0);
                b0 := y;
                pc0 := pcinc;
              when "10" => -- op A, B, PC
                a0 := a(0);
                b0 := b(0);
                pc0 := y;
              when "11" => -- op A, B, PC (if carry)
                a0 := a(0);
                b0 := b(0);
                if carry = '1' then
                  pc0 := y;
                else
                  pc0 := pcinc;
                end if;
              when others =>
            end case;
          end if;
          a <= a0 & a(15 downto 1);
          b <= b0 & b(15 downto 1);
          pc <= pc0 & pc(15 downto 1);
          if counter = 0 then
            carry <= c;
            state <= FETCH;
            alu_rst_n <= '0';
          end if;
      end case;
    end if;
  end process;
end rtl;
