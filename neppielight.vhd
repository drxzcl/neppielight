library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity neppielight is
    Port ( clk50         : in  STD_LOGIC;
           hdmi_in_p     : in  STD_LOGIC_VECTOR(3 downto 0);
           hdmi_in_n     : in  STD_LOGIC_VECTOR(3 downto 0);
           hdmi_in_sclk  : inout  STD_LOGIC;
           hdmi_in_sdat  : inout  STD_LOGIC;

           hdmi_out_p : out  STD_LOGIC_VECTOR(3 downto 0);
           hdmi_out_n : out  STD_LOGIC_VECTOR(3 downto 0);
                      
           leds       : out std_logic_vector(7 downto 0);
			  spiout_mosi: out std_logic;
			  spiout_sck: out std_logic);
end neppielight;

architecture Behavioral of neppielight is

	
	COMPONENT dvid_out
	PORT(
      clk_pixel  : IN std_logic;
		red_p      : IN std_logic_vector(7 downto 0);
		green_p    : IN std_logic_vector(7 downto 0);
		blue_p     : IN std_logic_vector(7 downto 0);
		blank      : IN std_logic;
		hsync      : IN std_logic;
		vsync      : IN std_logic;          
		tmds_out_p : OUT std_logic_vector(3 downto 0);
		tmds_out_n : OUT std_logic_vector(3 downto 0)
		);
	END COMPONENT;

	COMPONENT averager
	PORT(
		clk_pixel : IN std_logic;
      --
		i_red     : IN std_logic_vector(7 downto 0);
		i_green   : IN std_logic_vector(7 downto 0);
		i_blue    : IN std_logic_vector(7 downto 0);
		i_blank   : IN std_logic;
		i_hsync   : IN std_logic;
		i_vsync   : IN std_logic;          
      --
		framebuffer: OUT std_logic_vector(0 to 24*25-1 );
		o_red     : OUT std_logic_vector(7 downto 0);
		o_green   : OUT std_logic_vector(7 downto 0);
		o_blue    : OUT std_logic_vector(7 downto 0);
		o_blank   : OUT std_logic;
		o_hsync   : OUT std_logic;
		o_vsync   : OUT std_logic        
		);
	END COMPONENT;


	COMPONENT dvid_in
	PORT(
      clk_pixel  : out std_logic;
      leds     : out std_logic_vector(7 downto 0) := (others => '0');
		red_p      : out std_logic_vector(7 downto 0);
		green_p    : out std_logic_vector(7 downto 0);
		blue_p     : out std_logic_vector(7 downto 0);
		blank      : out std_logic;
		hsync      : out std_logic;
		vsync      : out std_logic;          
		tmds_in_p  : in  std_logic_vector(3 downto 0);
		tmds_in_n  : in  std_logic_vector(3 downto 0)
		);
	END COMPONENT;


	COMPONENT spiout
	PORT(
		     clk50 : in  STD_LOGIC;
           data : in  STD_LOGIC_VECTOR (25*24-1 downto 0);
           MOSI : out  STD_LOGIC;
           SCK : out  STD_LOGIC
		);
	END COMPONENT;

	signal clk_pixel : std_logic;

   
   signal i_red     : std_logic_vector(7 downto 0);
   signal i_green   : std_logic_vector(7 downto 0);
   signal i_blue    : std_logic_vector(7 downto 0);
	signal i_blank   : std_logic;
	signal i_hsync   : std_logic;
	signal i_vsync   : std_logic;          

   signal o_red     : std_logic_vector(7 downto 0);
   signal o_green   : std_logic_vector(7 downto 0);
   signal o_blue    : std_logic_vector(7 downto 0);
	signal o_blank   : std_logic;
	signal o_hsync   : std_logic;
	signal o_vsync   : std_logic;          

	signal framebuffer : std_logic_vector(0 to 25*24-1) := (others => '0');
   
begin
   hdmi_in_sclk  <= 'Z';
   hdmi_in_sdat  <= 'Z';

	Inst_dvid_in: dvid_in PORT MAP(
		tmds_in_p => hdmi_in_p,
		tmds_in_n => hdmi_in_n,

      leds => leds,
      
		clk_pixel => clk_pixel,
		red_p     => i_red,
		green_p   => i_green,
		blue_p    => i_blue,
		blank     => i_blank,
		hsync     => i_hsync,
		vsync     => i_vsync
	);

	Inst_averager: averager PORT MAP(
		clk_pixel => clk_pixel,
		i_red     => i_red,
      i_green   => i_green,
      i_blue    => i_blue,
		i_blank   => i_blank,
		i_hsync   => i_hsync,
		i_vsync   => i_vsync,
      --
		framebuffer => framebuffer,
		o_red     => o_red,
      o_green   => o_green,
      o_blue    => o_blue,
		o_blank   => o_blank,
		o_hsync   => o_hsync,
		o_vsync   => o_vsync
	);
   
Inst_dvid_out: dvid_out PORT MAP(
		clk_pixel  => clk_pixel,
     
		red_p      => o_red,
		green_p    => o_green,
		blue_p     => o_blue,
		blank      => o_blank,
		hsync      => o_hsync,
		vsync      => o_vsync,
     
		tmds_out_p => hdmi_out_p,
		tmds_out_n => hdmi_out_n
	);
	
	Inst_spout: spiout PORT MAP(
		clk50 => clk50,
		data => framebuffer,
      MOSI => SPIOUT_MOSI,
      SCK => SPIOUT_SCK
	);


end Behavioral;

