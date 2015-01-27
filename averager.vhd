----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:35:50 01/09/2015 
-- Design Name: 
-- Module Name:     - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
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

   -- signal pixel : std_logic_vector(23 downto 0) := (others => '0'); 
   type accumulator_type is array (0 to 9,0 to 3) of std_logic_vector(21 downto 0);
   signal accumulator : accumulator_type; 
   signal address : unsigned(13 downto 0);
	signal blocknr : integer;

begin
   address <= unsigned(not y(6 downto 0))&unsigned(x(6 downto 0));

process(clk_pixel)
   begin
      if rising_edge(clk_pixel) then
         if a_blank = '0' and y(10 downto 7) = "0000" then
			   -- and x(10 downto 7) = "0000"
				blocknr <= to_integer(unsigned(x(10 downto 7)));
				accumulator(blocknr,0) <= std_logic_vector(unsigned(accumulator(blocknr,0)) + unsigned(a_red));
				accumulator(blocknr,1) <= std_logic_vector(unsigned(accumulator(blocknr,1)) + unsigned(a_green));
				accumulator(blocknr,2) <= std_logic_vector(unsigned(accumulator(blocknr,2)) + unsigned(a_blue));
            o_red     <= accumulator(blocknr,0)(21 downto 14);
            o_green   <= accumulator(blocknr,1)(21 downto 14);
            o_blue    <= accumulator(blocknr,2)(21 downto 14);
         else
            o_red     <= a_red;
            o_green   <= a_green;
            o_blue    <= a_blue;
         end if;
         o_blank   <= a_blank;
         o_hsync   <= a_hsync;
         o_vsync   <= a_vsync;

         a_red     <= i_red;
         a_green   <= i_green;
         a_blue    <= i_blue;
         a_blank   <= i_blank;
         a_hsync   <= i_hsync;
         a_vsync   <= i_vsync;

         --pixel <= logo(to_integer(address));

         -- Working out where we are in the screen..
         if i_vsync /= a_vsync then
            y <= (others => '0');
				accumulator(0,0) <= (others => '0');
				accumulator(0,1) <= (others => '0');
				accumulator(0,2) <= (others => '0');
				accumulator(1,0) <= (others => '0');
				accumulator(1,1) <= (others => '0');
				accumulator(1,2) <= (others => '0');
				accumulator(2,0) <= (others => '0');
				accumulator(2,1) <= (others => '0');
				accumulator(2,2) <= (others => '0');
				accumulator(3,0) <= (others => '0');
				accumulator(3,1) <= (others => '0');
				accumulator(3,2) <= (others => '0');
				accumulator(4,0) <= (others => '0');
				accumulator(4,1) <= (others => '0');
				accumulator(4,2) <= (others => '0');
				accumulator(5,0) <= (others => '0');
				accumulator(5,1) <= (others => '0');
				accumulator(5,2) <= (others => '0');
				accumulator(6,0) <= (others => '0');
				accumulator(6,1) <= (others => '0');
				accumulator(6,2) <= (others => '0');
				accumulator(7,0) <= (others => '0');
				accumulator(7,1) <= (others => '0');
				accumulator(7,2) <= (others => '0');
				accumulator(8,0) <= (others => '0');
				accumulator(8,1) <= (others => '0');
				accumulator(8,2) <= (others => '0');
				accumulator(9,0) <= (others => '0');
				accumulator(9,1) <= (others => '0');
				accumulator(9,2) <= (others => '0');
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

