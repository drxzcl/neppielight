----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Module Name:    input_channel - Behavioral 
-- Description:    The end-to-end processing of a TMDS input channel
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VComponents.all;


entity input_channel is
   GENERIC(
         fixed_delay     : in natural
      );
    Port ( clk_fabric      : in  STD_LOGIC;
           clk_fabric_x2   : in  STD_LOGIC;
           clk_input       : in  STD_LOGIC;
           strobe          : in  STD_LOGIC;
           tmds_p          : in  STD_LOGIC;
           tmds_n          : in  STD_LOGIC;
           invert          : in  STD_LOGIC;
           framing         : in  std_logic_vector(3 downto 0);
           data_out        : out STD_LOGIC_VECTOR (7 downto 0);
           control         : out STD_LOGIC_VECTOR (1 downto 0);
           active_data     : out std_logic;
           sync_seen       : out std_logic;
           
           adjust_delay    : IN  std_logic;
           increase_delay  : IN  std_logic;
           reset_delay     : IN  std_logic;
           start_calibrate : IN  std_logic;          
           calibrate_busy  : OUT std_logic
);
end input_channel;

architecture Behavioral of input_channel is

   COMPONENT input_delay
   GENERIC(
         fixed_delay     : in natural
      );
   PORT(
      bit_clock       : IN  std_logic;
      data_in         : IN  std_logic;
      data_out        : OUT std_logic;

      control_clock   : IN  std_logic;
      adjust_delay    : IN  std_logic;
      increase_delay  : IN  std_logic;
      reset_delay     : IN  std_logic;
      start_calibrate : IN  std_logic;          
      calibrate_busy  : OUT std_logic
      );
   END COMPONENT;

   COMPONENT input_serialiser
   PORT(
      clk_fabric_x2 : IN  std_logic;
      clk_input     : IN  std_logic;
      strobe        : IN  std_logic;
      ser_input     : IN  std_logic;          
      ser_data      : OUT std_logic_vector(4 downto 0)
      );
   END COMPONENT;

   COMPONENT gearbox
   PORT(
      clk_fabric_x2 : IN  std_logic;
      framing       : IN  std_logic_vector(3 downto 0);
      invert        : IN  std_logic;
      data_in       : IN  std_logic_vector(4 downto 0);
      data_out      : OUT std_logic_vector(9 downto 0)
      );
   END COMPONENT;

   COMPONENT tmds_decode
   PORT(
      clk         : IN  std_logic;
      data_in     : IN  std_logic_vector(9 downto 0);          
      data_out    : OUT std_logic_vector(7 downto 0);
      c           : OUT std_logic_vector(1 downto 0);
      active_data : OUT std_logic
      );
   END COMPONENT;
   
   signal serial_data         : std_logic;
   signal delayed_serial_data : std_logic;
   signal raw_tmds_word       : std_logic_vector(9 downto 0);          
   signal half_words          : std_logic_vector(4 downto 0);          
begin

diff_input : IBUFDS
   generic map (
      DIFF_TERM    => FALSE,
      IBUF_LOW_PWR => TRUE,
      IOSTANDARD   => "TMDS_33")
   port map (
      O  => serial_data,
      I  => tmds_p,
      IB => tmds_n
   );

--i_input_delay: input_delay GENERIC MAP(
--      fixed_delay     => fixed_delay
--    ) PORT MAP(
--      bit_clock       => clk_input,
--      data_in         => serial_data,
--      data_out        => delayed_serial_data,
--      control_clock   => clk_fabric_x2,
--      adjust_delay    => adjust_delay,
--      increase_delay  => increase_delay,
--      reset_delay     => reset_delay,
--      start_calibrate => start_calibrate,
--      calibrate_busy  => calibrate_busy
--   );

i_input_serialiser: input_serialiser PORT MAP(
      clk_fabric_x2 => clk_fabric_x2,
      clk_input     => clk_input,
      strobe        => strobe,
--      ser_input     => delayed_serial_data,
      ser_input     => serial_data,
      ser_data      => half_words
   );
   
i_gearbox: gearbox PORT MAP(
      clk_fabric_x2 => clk_fabric_x2,
      invert        => invert,
      framing       => framing,
      data_in       => half_words,
      data_out      => raw_tmds_word
   );

i_tmds_decode: tmds_decode PORT MAP(
      clk         => clk_fabric,
      data_in     => raw_tmds_word,
      data_out    => data_out,
      c           => control,
      active_data => active_data 
   );
   
look_for_sync: process (clk_fabric)
   begin
      if rising_edge(clk_fabric) then
         ------------------------------------------------------------
         -- Is the TMDS data one of two special sync codewords?
         ------------------------------------------------------------
         if raw_tmds_word = "1101010100" or raw_tmds_word = "0010101011" then
            sync_seen <= '1';
         else
            sync_seen <= '0';
         end if;
      end if;
   end process;
end Behavioral;

