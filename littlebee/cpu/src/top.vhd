library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
  port (
    clk_100 : in std_logic;
    rst_n : in std_logic;
    led : out std_logic_vector(7 downto 0);
    h_sync : out std_logic;
    v_sync : out std_logic
  );
end top;

architecture behavior of top is
  signal clk_25 : std_logic;
  signal address : std_logic_vector(15 downto 0);
  signal data_in : std_logic_vector(15 downto 0);
  signal data_out : std_logic_vector(15 downto 0);
  signal wren_n : std_logic;
  signal oen_n : std_logic;

  signal disp_ena : std_logic;
  signal column : integer;
  signal row : integer;
  signal vramaddress : std_logic_vector(15 downto 0);
  signal tileaddress : std_logic_vector(10 downto 0);
  signal twochars : std_logic_vector(15 downto 0);
  signal char : std_logic_vector(7 downto 0);
  signal char_row : std_logic_vector(7 downto 0);
  signal pixel : std_logic;


component bram
  port (
      clk : in std_logic;
      wren_n : in std_logic;
      oen_n : in std_logic;
      rdaddress : in std_logic_vector(15 downto 0);
      wraddress : in std_logic_vector(15 downto 0);
      data_in : in std_logic_vector(15 downto 0);
      data_out : out std_logic_vector(15 downto 0)
);
end component;

component Gowin_PLL
    port (
        clkout: out std_logic;
        clkin: in std_logic
    );
end component;

begin

mypll: Gowin_PLL
    port map (
        clkout => clk_25,
        clkin => clk_100
    );

  dut: entity work.cpu port map (
    clk => clk_25,
    rst_n => rst_n,
    address => address,
    data_in => data_in,
    data_out => data_out,
    wren_n => wren_n,
    oen_n => oen_n
  );

  disp: entity work.display port map (
		clk => clk_25,
		rst_n => rst_n,
		h_sync => h_sync,
		v_sync => v_sync,
		disp_ena => disp_ena,
        pixel => pixel,
  );

  mem: bram port map (
    clk => clk_25,
    wren_n => wren_n,
    oen_n => oen_n,
    rdaddress => address,
    wraddress => address,
    data_in => data_out,
    data_out => data_in
  );

  vram: bram port map (
    clk => clk_25,
    wren_n => wren_n,
    oen_n => oen_n,
    rdaddress => vramaddress,
    wraddress => address,
    data_in => data_out,
    data_out => twochars
  );

  process(clk_25)
  begin
    if rising_edge(clk_25) and wren_n = '0' then
      led <= data_out(15 downto 8);
    end if;
  end process;


end;