library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
  port (
    clk_100 : in std_logic;
    rst_n : in std_logic;
    led : out std_logic_vector(7 downto 0);
    --P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10: out std_logic;
    P1B1, P1B2, P1B3, P1B4, P1B7, P1B8, P1B9, P1B10: out std_logic
  );
end top;

architecture behavior of top is
  signal clk_25 : std_logic;
  signal address : std_logic_vector(15 downto 0);
  signal memaddress : std_logic_vector(15 downto 0);
  signal vramwraddress : std_logic_vector(15 downto 0);
  signal data_in : std_logic_vector(15 downto 0);
  signal data_out : std_logic_vector(15 downto 0);
  signal wren_n : std_logic;
  signal oen_n : std_logic;
  signal mem_wren_n : std_logic;
  signal vram_wren_n : std_logic;


  signal disp_ena : std_logic;
  signal h_sync : std_logic;
  signal v_sync : std_logic;
  signal column : integer;
  signal row : integer;
  signal vramrdaddress : std_logic_vector(15 downto 0);
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
    twochars => twochars,
    vramaddress => vramrdaddress,
		disp_ena => disp_ena,
    pixel => pixel
  );

  mem_wren_n <= '0' when wren_n = '0' and address(13) = '0' else '1';
  memaddress <= "000" & address(12 downto 0);
  mem: bram port map (
    clk => clk_25,
    wren_n => mem_wren_n,
    oen_n => oen_n,
    rdaddress => memaddress,
    wraddress => memaddress,
    data_in => data_out,
    data_out => data_in
  );

  vram_wren_n <= '0' when wren_n = '0' and address(13) = '1' else '1';
  vramwraddress <= "000000" & address(9 downto 0);
  vram: bram port map (
    clk => clk_25,
    wren_n => vram_wren_n,
    oen_n => '0',
    rdaddress => vramrdaddress,
    wraddress => vramwraddress,
    data_in => data_out,
    data_out => twochars
  );

--3b for single-PMOD
--assign {P1A1,   P1A2,   P1A3,   P1A4,   P1A7,   P1A8,   P1A9,   P1A10} =
--       {g[7],   vga_ck, vga_hs, 1'b0,   r[7],   b[7],   vga_de, vga_vs};
--P1A1 <= pixel;
--P1A2 <= clk_25;
--P1A3 <= h_sync;
--P1A4 <= '0';
--P1A7 <= pixel;
--P1A8 <= pixel;
--P1A9 <= disp_ena;
--P1A10 <= v_sync;

-- vga
--assign {P1B1,   P1B2,   P1B3,   P1B4,   P1B7,   P1B8,   P1B9,   P1B10} =
--       {vga_vs, g[7],   r[6],   b[6],   vga_hs, r[7],   b[7],   g[6]};
P1B1 <= v_sync;
P1B2 <= pixel;
P1B3 <= pixel;
P1B4 <= pixel;
P1B7 <= h_sync;
P1B8 <= pixel;
P1B9 <= pixel;
P1B10 <= pixel;

  process(clk_25)
  begin
    if rising_edge(clk_25) then
      led <= address(7 downto 0);
    end if;
  end process;


end;
