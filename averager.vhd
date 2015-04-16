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
		framebuffer : OUT std_logic_vector(0 to 10*24-1);
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
	signal blocknr : integer range 0 to 10;
	
	type gamma_lut_type is array ( 0 to 255) of std_logic_vector(7 downto 0);
	constant gamma_lut : gamma_lut_type := (
		0 => X"01",
		1 => X"01",
		2 => X"01",
		3 => X"01",
		4 => X"01",
		5 => X"01",
		6 => X"01",
		7 => X"01",
		8 => X"01",
		9 => X"01",
		10 => X"01",
		11 => X"01",
		12 => X"01",
		13 => X"01",
		14 => X"01",
		15 => X"01",
		16 => X"01",
		17 => X"01",
		18 => X"01",
		19 => X"01",
		20 => X"01",
		21 => X"01",
		22 => X"02",
		23 => X"02",
		24 => X"02",
		25 => X"02",
		26 => X"02",
		27 => X"02",
		28 => X"02",
		29 => X"02",
		30 => X"02",
		31 => X"02",
		32 => X"02",
		33 => X"03",
		34 => X"03",
		35 => X"03",
		36 => X"03",
		37 => X"03",
		38 => X"03",
		39 => X"03",
		40 => X"03",
		41 => X"04",
		42 => X"04",
		43 => X"04",
		44 => X"04",
		45 => X"04",
		46 => X"05",
		47 => X"05",
		48 => X"05",
		49 => X"05",
		50 => X"05",
		51 => X"06",
		52 => X"06",
		53 => X"06",
		54 => X"06",
		55 => X"06",
		56 => X"07",
		57 => X"07",
		58 => X"07",
		59 => X"08",
		60 => X"08",
		61 => X"08",
		62 => X"08",
		63 => X"09",
		64 => X"09",
		65 => X"09",
		66 => X"0A",
		67 => X"0A",
		68 => X"0A",
		69 => X"0B",
		70 => X"0B",
		71 => X"0B",
		72 => X"0C",
		73 => X"0C",
		74 => X"0D",
		75 => X"0D",
		76 => X"0D",
		77 => X"0E",
		78 => X"0E",
		79 => X"0F",
		80 => X"0F",
		81 => X"0F",
		82 => X"10",
		83 => X"10",
		84 => X"11",
		85 => X"11",
		86 => X"12",
		87 => X"12",
		88 => X"13",
		89 => X"13",
		90 => X"14",
		91 => X"14",
		92 => X"15",
		93 => X"15",
		94 => X"16",
		95 => X"17",
		96 => X"17",
		97 => X"18",
		98 => X"18",
		99 => X"19",
		100 => X"19",
		101 => X"1A",
		102 => X"1B",
		103 => X"1B",
		104 => X"1C",
		105 => X"1D",
		106 => X"1D",
		107 => X"1E",
		108 => X"1F",
		109 => X"1F",
		110 => X"20",
		111 => X"21",
		112 => X"21",
		113 => X"22",
		114 => X"23",
		115 => X"24",
		116 => X"24",
		117 => X"25",
		118 => X"26",
		119 => X"27",
		120 => X"28",
		121 => X"28",
		122 => X"29",
		123 => X"2A",
		124 => X"2B",
		125 => X"2C",
		126 => X"2D",
		127 => X"2D",
		128 => X"2E",
		129 => X"2F",
		130 => X"30",
		131 => X"31",
		132 => X"32",
		133 => X"33",
		134 => X"34",
		135 => X"35",
		136 => X"36",
		137 => X"37",
		138 => X"38",
		139 => X"39",
		140 => X"3A",
		141 => X"3B",
		142 => X"3C",
		143 => X"3D",
		144 => X"3E",
		145 => X"3F",
		146 => X"40",
		147 => X"41",
		148 => X"42",
		149 => X"43",
		150 => X"44",
		151 => X"46",
		152 => X"47",
		153 => X"48",
		154 => X"49",
		155 => X"4A",
		156 => X"4B",
		157 => X"4D",
		158 => X"4E",
		159 => X"4F",
		160 => X"50",
		161 => X"51",
		162 => X"53",
		163 => X"54",
		164 => X"55",
		165 => X"57",
		166 => X"58",
		167 => X"59",
		168 => X"5A",
		169 => X"5C",
		170 => X"5D",
		171 => X"5F",
		172 => X"60",
		173 => X"61",
		174 => X"63",
		175 => X"64",
		176 => X"66",
		177 => X"67",
		178 => X"68",
		179 => X"6A",
		180 => X"6B",
		181 => X"6D",
		182 => X"6E",
		183 => X"70",
		184 => X"71",
		185 => X"73",
		186 => X"74",
		187 => X"76",
		188 => X"78",
		189 => X"79",
		190 => X"7B",
		191 => X"7C",
		192 => X"7E",
		193 => X"80",
		194 => X"81",
		195 => X"83",
		196 => X"85",
		197 => X"86",
		198 => X"88",
		199 => X"8A",
		200 => X"8B",
		201 => X"8D",
		202 => X"8F",
		203 => X"91",
		204 => X"92",
		205 => X"94",
		206 => X"96",
		207 => X"98",
		208 => X"9A",
		209 => X"9B",
		210 => X"9D",
		211 => X"9F",
		212 => X"A1",
		213 => X"A3",
		214 => X"A5",
		215 => X"A7",
		216 => X"A9",
		217 => X"AB",
		218 => X"AD",
		219 => X"AF",
		220 => X"B1",
		221 => X"B3",
		222 => X"B5",
		223 => X"B7",
		224 => X"B9",
		225 => X"BB",
		226 => X"BD",
		227 => X"BF",
		228 => X"C1",
		229 => X"C3",
		230 => X"C5",
		231 => X"C7",
		232 => X"CA",
		233 => X"CC",
		234 => X"CE",
		235 => X"D0",
		236 => X"D2",
		237 => X"D5",
		238 => X"D7",
		239 => X"D9",
		240 => X"DB",
		241 => X"DE",
		242 => X"E0",
		243 => X"E2",
		244 => X"E4",
		245 => X"E7",
		246 => X"E9",
		247 => X"EC",
		248 => X"EE",
		249 => X"F0",
		250 => X"F3",
		251 => X"F5",
		252 => X"F8",
		253 => X"FA",
		254 => X"FD",
		255 => X"FF");	

begin

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


         -- Working out where we are in the screen..
         if i_vsync /= a_vsync then
            y <= (others => '0');
							
				if i_vsync = '1' then
					for i in 0 to 9 loop
						for c in 0 to 2 loop
							--framebuffer(c * 8 + i * 24 to i * 24 + c * 8 + 7)  <= accumulator(i,c)(21 downto 14);
							
							-- with accumulator(i,c)(21 downto 14) select framebuffer(c * 8 + i * 24 to i * 24 + c * 8 + 7) <=
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

