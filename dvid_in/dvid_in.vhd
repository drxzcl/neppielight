----------------------------------------------------------------------------------
-- Engineer:    Mike Field <hamster@snap.net.nz>
-- 
-- Module Name: dvi_in.vhd - Behavioral 
--
-- Description: Design to capture raw DVI-D input
--
-- I've also got do do some work to automatically adjust the phase of the
-- bit clocks, at the moment it needs to be manually tuned to match your source
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity dvid_in is
    Port ( -- DVI-D/HDMI signals
           tmds_in_p : in  STD_LOGIC_VECTOR(3 downto 0);
           tmds_in_n : in  STD_LOGIC_VECTOR(3 downto 0);
           -- debug
           leds     : out std_logic_vector(7 downto 0) := (others => '0');
           -- VGA signals
           clk_pixel : out std_logic;
           red_p     : out std_logic_vector(7 downto 0) := (others => '0');
           green_p   : out std_logic_vector(7 downto 0) := (others => '0');
           blue_p    : out std_logic_vector(7 downto 0) := (others => '0');
           hsync     : out std_logic := '0';
           vsync     : out std_logic := '0';
           blank     : out std_logic := '0'
         );
end dvid_in;

architecture Behavioral of dvid_in is
   signal dvid_clk             : std_logic;
   signal dvid_clk_buffered    : std_logic;
   signal ioclock              : std_logic;
   signal serdes_strobe        : std_logic;

      
   signal clock_x1             : std_logic;
   signal clock_x2             : std_logic;
   signal clock_x10            : std_logic;
   signal clock_x10_unbuffered : std_logic;
   signal clock_x2_unbuffered  : std_logic;
   signal clock_x1_unbuffered  : std_logic;

   signal clk_feedback         : std_logic;
   signal pll_locked           : std_logic;
   signal sync_seen            : std_logic;

   signal c0_d       : std_logic_vector(7 downto 0);
   signal c0_c       : std_logic_vector(1 downto 0);
   signal c0_active  : std_logic;

   signal c1_d       : std_logic_vector(7 downto 0);
   signal c1_c       : std_logic_vector(1 downto 0);
   signal c1_active  : std_logic;

   signal c2_d       : std_logic_vector(7 downto 0);
   signal c2_c       : std_logic_vector(1 downto 0);
   signal c2_active  : std_logic;

   
   signal led_count   : unsigned( 2 downto 0)        := (others => '0');
   signal framing     : std_logic_vector(3 downto 0) := (others => '0');
   signal since_sync  : unsigned(14 downto 0)        := (others => '0');

   signal start_calibrate : std_logic;
   signal reset_delay     : std_logic;
   signal cal_start_count : unsigned(7 downto 0) := (others => '0');          
   
   COMPONENT input_channel
   GENERIC(
         fixed_delay     : in natural
      );
   PORT(
      clk_fabric    : IN  std_logic;
      clk_fabric_x2 : IN  std_logic;
      clk_input     : IN  std_logic;
      strobe        : IN  std_logic;
      tmds_p        : in  STD_LOGIC;
      tmds_n        : in  STD_LOGIC;
      invert        : IN  std_logic;
      framing       : IN  std_logic_vector(3 downto 0);          
      data_out      : OUT std_logic_vector(7 downto 0);
      control       : OUT std_logic_vector(1 downto 0);
      active_data   : OUT std_logic;
      sync_seen     : OUT std_logic;
           
      adjust_delay    : IN  std_logic;
      increase_delay  : IN  std_logic;
      reset_delay     : IN  std_logic;
      start_calibrate : IN  std_logic;          
      calibrate_busy  : OUT std_logic
      );
   END COMPONENT;

   signal x : unsigned(12 downto 0) := (others => '0');
   signal y : unsigned(12 downto 0) := (others => '0');
begin   
   ----------------------------------
   -- Output the decoded VGA signals
   ----------------------------------
   clk_pixel <= clock_x1;
   blue_p  <= c0_d;
   green_p <= c1_d;
   red_p   <= c2_d;
   hsync   <= c0_c(0);  --c2
   vsync   <= c0_c(1);  --c2
   blank   <= not c2_active;

   ----------------------------------
   -- Debug
   ----------------------------------
   leds <= c2_c & (not c2_c) & framing;


------------------------------------------
-- Receive the differential clock
------------------------------------------
clk_diff_input : IBUFDS
   generic map (
      DIFF_TERM    => FALSE,
      IBUF_LOW_PWR => TRUE,
      IOSTANDARD   => "TMDS_33")
   port map (
      O  => dvid_clk,
      I  => tmds_in_p(3),
      IB => tmds_in_n(3)
   );
   
------------------------------------------
-- Buffer it before the PLL
------------------------------------------
BUFG_clk : BUFG port map ( I => dvid_clk, O => dvid_clk_buffered);

------------------------------------------
-- Generate the bit clocks for the serdes
-- 
-- Adjust the phase in a 10:2:1 ratio (e.g. 50:10:5)
------------------------------------------
PLL_BASE_inst : PLL_BASE
   generic map (
      CLKFBOUT_MULT => 10,                  
      -- Almost works with Western Digital Live @ 720p/60 -Noise on blue channel.
      --CLKOUT0_DIVIDE => 1,       CLKOUT0_PHASE => 200.0,   -- Output 10x original frequency
      --CLKOUT1_DIVIDE => 5,       CLKOUT1_PHASE => 40.0,   -- Output 2x original frequency
      --CLKOUT2_DIVIDE => 10,      CLKOUT2_PHASE => 20.0,    -- Output 1x original frequency
      -- Works with Western Digital Live @ 640x480/60Hz
      CLKOUT0_DIVIDE => 1,       CLKOUT0_PHASE => 0.0,   -- Output 10x original frequency
      CLKOUT1_DIVIDE => 5,       CLKOUT1_PHASE => 0.0,   -- Output 2x original frequency
      CLKOUT2_DIVIDE => 10,      CLKOUT2_PHASE => 0.0,    -- Output 1x original frequency
      CLK_FEEDBACK => "CLKFBOUT",                         -- Clock source to drive CLKFBIN ("CLKFBOUT" or "CLKOUT0")
      CLKIN_PERIOD => 10.0,                               -- IMPORTANT! Approx 77 MHz
      DIVCLK_DIVIDE => 1                                  -- Division value for all output clocks (1-52)
   )
      port map (
      CLKFBOUT => clk_feedback, 
      CLKOUT0  => clock_x10_unbuffered,
      CLKOUT1  => clock_x2_unbuffered,
      CLKOUT2  => clock_x1_unbuffered,
      CLKOUT3  => open,
      CLKOUT4  => open,
      CLKOUT5  => open,
      LOCKED   => pll_locked,      
      CLKFBIN  => clk_feedback,    
      CLKIN    => dvid_clk_buffered, 
      RST      => '0'              -- 1-bit input: Reset input
   );

   BUFG_pclockx2  : BUFG port map ( I => clock_x2_unbuffered,  O => clock_x2);
   BUFG_pclock    : BUFG port map ( I => clock_x1_unbuffered,  O => clock_x1);
   BUFG_pclockx10 : BUFG port map ( I => clock_x10_unbuffered, O => clock_x10 );

  
------------------------------------------------
-- Buffer the clocks ready to go the serialisers
------------------------------------------------
BUFPLL_inst : BUFPLL
   generic map (
      DIVIDE => 5,         -- DIVCLK divider (1-8) !!!! IMPORTANT TO CHANGE THIS AS NEEDED !!!!
      ENABLE_SYNC => TRUE  -- Enable synchrnonization between PLL and GCLK (TRUE/FALSE) -- should be true
   )
   port map (
      IOCLK        => ioclock,               -- Clock used to receive bits
      LOCK         => open,                 
      SERDESSTROBE => serdes_strobe,         -- Clock use to load data into SERDES 
      GCLK         => clock_x2,              -- Global clock use as a reference for serdes_strobe
      LOCKED       => pll_locked,            -- When the upstream PLL is locked 
      PLLIN        => clock_x10_unbuffered   -- Clock to use for bit capture - this must be unbuffered
   );

----------------------------------------
-- c0 channel input - Carries the RED channel
----------------------------------------
input_channel_c0: input_channel GENERIC MAP(
      fixed_delay     => 30
    ) PORT MAP(
      clk_fabric      => clock_x1,
      clk_fabric_x2   => clock_x2,
      clk_input       => ioclock,
      strobe          => serdes_strobe,
      tmds_p          => tmds_in_p(0),
      tmds_n          => tmds_in_n(0),
      invert          => '0',
      framing         => framing,
      data_out        => c0_d,
      control         => c0_c,
      active_data     => c0_active,
      sync_seen       => open,
      adjust_delay    => '0',
      increase_delay  => '0',
      reset_delay     => reset_delay,
      start_calibrate => start_calibrate,
      calibrate_busy  => open
   );   

----------------------------------------
-- c1 channel input - Carries the BLUE channel
----------------------------------------
   
input_channel_c1: input_channel GENERIC MAP(
      fixed_delay     => 40
    ) PORT MAP(
      clk_fabric      => clock_x1,
      clk_fabric_x2   => clock_x2,
      clk_input       => ioclock,
      strobe          => serdes_strobe,
      tmds_p          => tmds_in_p(1),
      tmds_n          => tmds_in_n(1),
      invert          => '0',
      framing         => framing,
      data_out        => c1_d,
      control         => c1_c,
      active_data     => c1_active,
      sync_seen       => open,
      adjust_delay    => '0',
      increase_delay  => '0',
      reset_delay     => reset_delay,
      start_calibrate => start_calibrate,
      calibrate_busy  => open
   );   

----------------------------------------
-- c2 channel input - Carries the GREEN channel and syncs
----------------------------------------
input_channel_c2: input_channel GENERIC MAP(
      fixed_delay     => 30
    )  PORT MAP(
      clk_fabric      => clock_x1,
      clk_fabric_x2   => clock_x2,
      clk_input       => ioclock,
      strobe          => serdes_strobe,
      tmds_p          => tmds_in_p(2),
      tmds_n          => tmds_in_n(2),
      invert          => '0',
      framing         => framing,
      data_out        => c2_d,
      control         => c2_c,
      active_data     => c2_active,
      sync_seen       => sync_seen,
      adjust_delay    => '0',
      increase_delay  => '0',
      reset_delay     => reset_delay,
      start_calibrate => start_calibrate,
      calibrate_busy  => open
   );   

calibrate_process: process (clock_x2)
   begin
      if rising_edge(clock_x2) then
         if cal_start_count = "10000000" then
            start_calibrate <= '0';
         else
            start_calibrate <= '0';
         end if;
         if cal_start_count = "11111100" then
            reset_delay <= '0';
         else
            reset_delay <= '0';
         end if;
         
         if cal_start_count /= "11111111" then
            cal_start_count <= cal_start_count + 1;
         end if;
      end if;
   end process;
   
process(clock_x1) 
   begin
      if rising_edge(clock_x1) then
         -- Work out what we need to do to frame the TMDS data correctly
         if sync_seen = '1' then
            ------------------------------------------------------------
            -- We've just seen a sync codeword, so restart the counter
            -- This means that we are in sync
            ------------------------------------------------------------
            since_sync  <= (others => '0');
         elsif since_sync = "111111111111111" then
            ------------------------------------------------------------
            -- We haven't seen a sync in 16383 pixel cycles, so it can't 
            -- be in sync. By incrementing 'framing' we bitslip one bit.
            --            
            -- The 16k number is special, as they two sync codewords
            -- being looked for will not be seen during the VSYNC period
            -- (assuming that you are looking in the channel that 
            -- includes the encoded HSYNC/VSYNC signals 
            ------------------------------------------------------------
            if framing = "1001" then
               framing <= (others =>'0');
            else
               framing <= std_logic_vector(unsigned(framing) + 1);
            end if;
            since_sync  <= since_sync + 1;
         else
            ------------------------------------------------------------
            -- Keep counting and hoping for a sync codeword
            ------------------------------------------------------------
            since_sync  <= since_sync + 1;
         end if;

      end if;
   end process;
end Behavioral;