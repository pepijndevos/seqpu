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
    wren_n : out std_logic;
    oen_n : out std_logic
  );
end cpu;

architecture rtl of cpu is
  type state_type is (FETCH, EXECUTE, ALU_OP, LOAD);
  signal state : state_type;
  signal counter : unsigned(3 downto 0);
  signal op, a, b, pc, sp, spp: std_logic_vector(15 downto 0);
  signal c, y, alu_a, pcinc, carry: std_logic;
  signal alu_rst_n : std_logic;
  signal a0, b0, pc0, sp0 : std_logic;
  signal bspp0 : std_logic_vector(2 downto 0);
begin

  alu1: entity work.alu port map (
    clk => clk,
    rst_n => alu_rst_n,
    opcode => op(11 downto 9),
    a => alu_a,
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

  alu_rst_n <= '1' when state = ALU_OP else '0';
  alu_a <= a(0) when op(15) = '1' else sp(0); -- A for ALU, SP for loads
  address <= pc when state = FETCH else sp;
  data_out <= a;
  oen_n <= '0' when state = FETCH or state = LOAD else '1';
  wren_n <= '0' when state = EXECUTE and op(15 downto 12)  = "0110" else '1';

  -- exchange
  with op(15 downto 12) select bspp0 <=
    b(0) & spp(0) & sp(0) when "0100",
    sp(0) & b(0) & spp(0) when "0101",
    b(0) & sp(0) & spp(0) when others;

  -- op(15) => ALU
  -- "00" => A = A op B
  -- "01" => B = A op B
  -- "10" => PC = A op B
  -- "11" => PC = A op B when carry else PC
  a0 <= y when op(15) = '1'
           and op(13 downto 12) = "00"
          else a(0);
  b0 <= y when op(15) = '1'
           and op(13 downto 12) = "01"
          else bspp0(2);
  sp0 <= y when op(15 downto 13) = "011" -- push/pop
           else bspp0(1);
  pc0 <= y when op(15) = '1'
            and (op(13 downto 12) = "10"
             or (op(13 downto 12) = "11" and carry = '1'))
           else pcinc;

  -- "00" & lit         ld lit, B
  -- "0100"             xch SP SP'
  -- "0101"             xch SP B
  -- "0110" & op & lit  push A, [SP]; op SP lit SP
  -- "0111" & op & lit  op SP lit SP; pop [SP], B
  -- "1000" & op & rol  op A, B, A
  -- "1001" & op &      op A, B, B
  -- "1010" & op &      op A, B, PC
  -- "1011" & op &      op A, B, PC (if carry)
  -- "1100" & op & lit  op A, lit, A
  -- "1101" & op & lit  op A, lit, B
  -- "1110" & op & lit  op A, lit, PC
  -- "1111" & op & lit  op A, lit, PC (if carry)
  process(clk, rst_n)
  begin
    if (rst_n = '0') then
      pc <= x"0000";
      sp <= x"0000";
      spp <= x"0000";
      op <= x"0000";
      a <= x"0000";
      b <= x"0000";
      counter <= x"3";
      carry <= '0';
      state <= FETCH;
    elsif (rising_edge(clk)) then
      counter <= counter - 1;
      case state is
        when FETCH =>
          op <= data_in;
          if counter = 0 then
            state <= EXECUTE;
          end if;
        when EXECUTE =>
          if op(15 downto 14) = "11" or op(15 downto 13) = "011" then -- literal
            b <= (others => op(8)); -- sign extend
            b(8 downto 0) <= op(8 downto 0);
            counter <= x"f";
          end if;
          if op(15 downto 14) = "00" then -- literal load
            b <= "00" & op(13 downto 0);
          end if;
          counter <= x"f";
          state <= ALU_OP;
        when ALU_OP =>
          -- barrel shift
          if op(15 downto 12) /= "1000" or counter >= unsigned(op(3 downto 0)) then 
            a <= a0 & a(15 downto 1);
          end if;
          b <= b0 & b(15 downto 1);
          pc <= pc0 & pc(15 downto 1);
          sp <= sp0 & sp(15 downto 1);
          spp <= bspp0(0) & spp(15 downto 1);
          if counter = 0 then
            if op(15) = '1' then
              carry <= c;
            end if;
            if op(15 downto 12) = "0111" then
              state <= LOAD;
            else
              state <= FETCH;
            end if;
            counter <= x"3";
          end if;
        when LOAD =>
          if counter = 0 then -- maybe only check 2 bits?
            b <= data_in;
            state <= FETCH;
            counter <= x"3";
          end if;
      end case;
    end if;
  end process;
end rtl;
