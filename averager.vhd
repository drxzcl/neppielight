----------------------------------------------------------------------------------
-- Engineer: drxzclx@gmail.com
-- 
-- Create Date:    22:35:50 01/09/2015 
-- Design Name: 	HDMI block averager
-- Module Name:     - Behavioral 
-- Project Name: 	Neppielight
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity averager is
    Port ( 
      clk_pixel : IN std_logic;
      --
		i_red     : IN std_logic_vector(7 downto 0);
		i_green   : IN std_logic_vector(7 downto 0);
		i_blue    : IN std_logic_vector(7 downto 0);
		i_blank   : IN std_logic;
		i_hsync   : IN std_logic;
		i_vsync   : IN std_logic;          
      --
		framebuffer : OUT std_logic_vector(0 to 25*24-1);
		o_red     : OUT std_logic_vector(7 downto 0);
		o_green   : OUT std_logic_vector(7 downto 0);
		o_blue    : OUT std_logic_vector(7 downto 0);
		o_blank   : OUT std_logic;
		o_hsync   : OUT std_logic;
		o_vsync   : OUT std_logic);  
end averager;

architecture Behavioral of averager is

   -------------------------
   -- Part of the pipeline
   -------------------------
	signal a_red     : std_logic_vector(7 downto 0);
	signal a_green   : std_logic_vector(7 downto 0);
	signal a_blue    : std_logic_vector(7 downto 0);
	signal a_blank   : std_logic;
	signal a_hsync   : std_logic;
	signal a_vsync   : std_logic;  

   -------------------------------
   -- Counters for screen position   
   -------------------------------
   signal x : STD_LOGIC_VECTOR (10 downto 0);
   signal y : STD_LOGIC_VECTOR (10 downto 0);

	constant nblocks : integer := 25;	

   -- signal pixel : std_logic_vector(23 downto 0) := (others => '0'); 
   type accumulator_type is array (0 to nblocks-1,0 to 3) of std_logic_vector(21 downto 0);
   signal accumulator : accumulator_type; 
	--signal blocknr : integer range 0 to 10;
	
	type blockcoords_type is array (0 to nblocks-1) of integer;
	-- Due to the details of the construction, we start in the lower left corner
	-- and work our way clockwise.
	-- Laterally, we've got more leds than pixels, so we'll have partially verlapping boxes.
	constant startx : blockcoords_type := (  0,  0,  0,  0,  0,0,144,288,432,576,720,864,1008,1152,1152,1152,1152,1152,1152,987,823,658,494,329,164);
	constant starty : blockcoords_type := (592,472,356,238,118,0,  0,  0,  0,  0,  0,  0,   0,   0, 118, 238, 356, 472, 592,592,592,592,592,592,592);		
	
	type gamma_lut_type is array ( 0 to 255) of std_logic_vector(7 downto 0);
	constant gamma_lut : gamma_lut_type := (
		X"01", X"01", X"01", X"01", X"01", X"01", X"01", X"01", X"01", X"01", X"01", X"01", X"01", X"01",
		X"01", X"01", X"01", X"01", X"01", X"01", X"01", X"01", X"02", X"02", X"02", X"02", X"02", X"02",
		X"02", X"02", X"02", X"02", X"02", X"03", X"03", X"03", X"03", X"03", X"03", X"03", X"03", X"04",
		X"04", X"04", X"04", X"04", X"05", X"05", X"05", X"05", X"05", X"06", X"06", X"06", X"06", X"06",
		X"07", X"07", X"07", X"08", X"08", X"08", X"08", X"09", X"09", X"09", X"0A", X"0A", X"0A", X"0B",
		X"0B", X"0B", X"0C", X"0C", X"0D", X"0D", X"0D", X"0E", X"0E", X"0F", X"0F", X"0F", X"10", X"10",
		X"11", X"11", X"12", X"12", X"13", X"13", X"14", X"14", X"15", X"15", X"16", X"17", X"17", X"18",
		X"18", X"19", X"19", X"1A", X"1B", X"1B", X"1C", X"1D", X"1D", X"1E", X"1F", X"1F", X"20", X"21",
		X"21", X"22", X"23", X"24", X"24", X"25", X"26", X"27", X"28", X"28", X"29", X"2A", X"2B", X"2C",
		X"2D", X"2D", X"2E", X"2F", X"30", X"31", X"32", X"33", X"34", X"35", X"36", X"37", X"38", X"39",
		X"3A", X"3B", X"3C", X"3D", X"3E", X"3F", X"40", X"41", X"42", X"43", X"44", X"46", X"47", X"48",
		X"49", X"4A", X"4B", X"4D", X"4E", X"4F", X"50", X"51", X"53", X"54", X"55", X"57", X"58", X"59",
		X"5A", X"5C", X"5D", X"5F", X"60", X"61", X"63", X"64", X"66", X"67", X"68", X"6A", X"6B", X"6D",
		X"6E", X"70", X"71", X"73", X"74", X"76", X"78", X"79", X"7B", X"7C", X"7E", X"80", X"81", X"83",
		X"85", X"86", X"88", X"8A", X"8B", X"8D", X"8F", X"91", X"92", X"94", X"96", X"98", X"9A", X"9B",
		X"9D", X"9F", X"A1", X"A3", X"A5", X"A7", X"A9", X"AB", X"AD", X"AF", X"B1", X"B3", X"B5", X"B7",
		X"B9", X"BB", X"BD", X"BF", X"C1", X"C3", X"C5", X"C7", X"CA", X"CC", X"CE", X"D0", X"D2", X"D5",
		X"D7", X"D9", X"DB", X"DE", X"E0", X"E2", X"E4", X"E7", X"E9", X"EC", X"EE", X"F0", X"F3", X"F5",
		X"F8", X"FA", X"FD", X"FF");	

begin

process(clk_pixel)
	variable blockedge : std_logic := '0';
   begin
      if rising_edge(clk_pixel) then
				   					
			for bn in 0 to nblocks-1 loop
				if unsigned(x) >= startx(bn) and unsigned(x) < startx(bn)+128 and
						unsigned(y) >= starty(bn) and unsigned(y) < starty(bn)+128 then
					-- We are a part of block bn. Accumulate the color info.
					accumulator(bn,0) <= std_logic_vector(unsigned(accumulator(bn,0)) + unsigned(a_red));
					accumulator(bn,1) <= std_logic_vector(unsigned(accumulator(bn,1)) + unsigned(a_green));
					accumulator(bn,2) <= std_logic_vector(unsigned(accumulator(bn,2)) + unsigned(a_blue));
				end if;
			end loop;
		

			-- debug, mark the block corners in red
--			blockedge := '0';
--			for bn in 0 to nblocks-1 loop
--				if (unsigned(x) = startx(bn) or unsigned(x) = startx(bn)+128) and
--						(unsigned(y) = starty(bn) or unsigned(y) = starty(bn)+128) then
--					blockedge := '1';
--				end if;
--			end loop;
--         
--			if blockedge = '0' then
				o_red     <= a_red;
				o_green   <= a_green;
				o_blue    <= a_blue;
--			else
--				o_red     <= X"FF";
--				o_green   <= X"00";
--				o_blue    <= X"00";
--			end if;
			
         o_blank   <= a_blank;
         o_hsync   <= a_hsync;
         o_vsync   <= a_vsync;

         a_red     <= i_red;
         a_green   <= i_green;
         a_blue    <= i_blue;
         a_blank   <= i_blank;
         a_hsync   <= i_hsync;
         a_vsync   <= i_vsync;


         -- Working out where we are in the screen..
         if i_vsync /= a_vsync then
            y <= (others => '0');
							
				if i_vsync = '1' then
					for i in 0 to nblocks-1 loop
						for c in 0 to 2 loop
							framebuffer(c * 8 + i * 24 to i * 24 + c * 8 + 7) <= gamma_lut(to_integer(unsigned(accumulator(i,c)(21 downto 14))));
							accumulator(i,c) <= (others => '0');
						end loop;
					end loop;
				end if;						
         end if;

         if i_blank = '0' then
            x <= std_logic_vector(unsigned(x) + 1);
         end if;

         -- Start of the blanking interval?
         if a_blank = '0' and i_blank = '1' then
            y <= std_logic_vector(unsigned(y) + 1);
            x <= (others => '0');
         end if;

      end if;
   end process;
end Behavioral;

