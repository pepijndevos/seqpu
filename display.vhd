library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity display is
  port (
    clk : in std_logic;
    rst_n : in std_logic;
    h_sync : out std_logic;
    v_sync : out std_logic;
    vramaddress : out std_logic_vector(15 downto 0);
    twochars : in std_logic_vector(15 downto 0);
    pixel : out std_logic
  );
end display;

architecture behavior of display is
  signal disp_ena : std_logic;
  signal column : integer;
  signal row : integer;
  signal col2x : unsigned(9 downto 0);
  signal row2x : unsigned(9 downto 0);
  signal tileaddress : std_logic_vector(10 downto 0);
  signal char : std_logic_vector(7 downto 0);
  signal char_row : std_logic_vector(7 downto 0);

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

component tilerom
  port (
      clk : in std_logic;
      oen_n : in std_logic;
      address : in std_logic_vector(10 downto 0);
      data_out : out std_logic_vector(7 downto 0)
);
end component;

COMPONENT vga_controller
	GENERIC(
		h_pulse 	:	INTEGER := 96;    	--horiztonal sync pulse width in pixels
		h_bp	 	:	INTEGER := 48;		--horiztonal back porch width in pixels
		h_pixels	:	INTEGER := 640;		--horiztonal display width in pixels
		h_fp	 	:	INTEGER := 16;		--horiztonal front porch width in pixels
		h_pol		:	STD_LOGIC := '0';		--horizontal sync pulse polarity (1 = positive, 0 = negative)
		v_pulse 	:	INTEGER := 2;			--vertical sync pulse width in rows
		v_bp	 	:	INTEGER := 33;			--vertical back porch width in rows
		v_pixels	:	INTEGER := 480;		--vertical display width in rows
		v_fp	 	:	INTEGER := 10;			--vertical front porch width in rows
		v_pol		:	STD_LOGIC := '0');	--vertical sync pulse polarity (1 = positive, 0 = negative)
	PORT(
		pixel_clk	:	IN		STD_LOGIC;	--pixel clock at frequency of VGA mode being used
		reset_n		:	IN		STD_LOGIC;	--active low asycnchronous reset
		h_sync		:	OUT	STD_LOGIC;	--horiztonal sync pulse
		v_sync		:	OUT	STD_LOGIC;	--vertical sync pulse
		disp_ena		:	OUT	STD_LOGIC;	--display enable ('1' = display time, '0' = blanking time)
		column		:	OUT	INTEGER;		--horizontal pixel coordinate
		row			:	OUT	INTEGER;		--vertical pixel coordinate
		n_blank		:	OUT	STD_LOGIC;	--direct blacking output to DAC
		n_sync		:	OUT	STD_LOGIC); --sync-on-green output to DAC
END COMPONENT;

begin

  disp: vga_controller port map (
		pixel_clk => clk,
		reset_n => rst_n,
		h_sync => h_sync,
		v_sync => v_sync,
		disp_ena => disp_ena,
		column => column,
		row => row,
		n_blank => open,
		n_sync => open
  );

  -- 8x8 bitmap is upscaled 2x
  col2x <= to_unsigned(column/2, 10);
  row2x <= to_unsigned(row/2, 10);
  -- 640/16=40
  -- 480/16=30
  -- tile size = 8x8
  -- two chars per word
  vramaddress <= std_logic_vector(resize((row2x/8)*40 + col2x/16, 16));

  -- col2x(2 downto 0) = char col, col(3) = high/low byte
  char <= twochars(7 downto 0) when col2x(3) = '1' else twochars(15 downto 8);
  -- row(2 downto 0) = char row
  tileaddress <= char & std_logic_vector(row2x(2 downto 0));

  rom: tilerom port map (
    clk => clk,
    oen_n => '0',
    address => tileaddress,
    data_out => char_row
  );

  pixel <= char_row(to_integer(col2x(2 downto 0)));

end;
