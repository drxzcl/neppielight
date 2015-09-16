----------------------------------------------------------------------------------
-- Engineer:   Mike Field <hamster@snap.net.nz>
-- 
-- Module Name: input_serialiser 
--
-- Description: A 5-bits per cycle SDR input serialiser
--
--              Maybe in the future the 'bitslip' funciton can be implemented.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity input_serialiser is
    Port ( clk_fabric_x2 : in  STD_LOGIC;
           clk_input     : in  STD_LOGIC;
           strobe        : in  STD_LOGIC;
           ser_data      : out  STD_LOGIC_VECTOR (4 downto 0);
           ser_input     : in STD_LOGIC);
end input_serialiser;

architecture Behavioral of input_serialiser is
   signal clk0,     clk1,     clkdiv : std_logic;
   signal cascade : std_logic;
   constant bitslip : std_logic := '0';
begin
   clkdiv <= clk_fabric_x2;
   clk0   <= clk_input;
   clk1   <= '0';

ISERDES2_master : ISERDES2
   generic map (
      BITSLIP_ENABLE => TRUE,         -- Enable Bitslip Functionality (TRUE/FALSE)
      DATA_RATE      => "SDR",        -- Data-rate ("SDR" or "DDR")
      DATA_WIDTH     => 5,            -- Parallel data width selection (2-8)
      INTERFACE_TYPE => "RETIMED",    -- "NETWORKING", "NETWORKING_PIPELINED" or "RETIMED" 
      SERDES_MODE    => "MASTER"      -- "NONE", "MASTER" or "SLAVE" 
   )
   port map (
      CFB0      => open,      -- 1-bit output: Clock feed-through route output
      CFB1      => open,      -- 1-bit output: Clock feed-through route output
      DFB       => open,       -- 1-bit output: Feed-through clock output
      FABRICOUT => open,      -- 1-bit output: Unsynchrnonized data output
      INCDEC    => open,      -- 1-bit output: Phase detector output
      -- Q1 - Q4: 1-bit (each) output: Registered outputs to FPGA logic
      Q1        => ser_data(1),
      Q2        => ser_data(2),
      Q3        => ser_data(3),
      Q4        => ser_data(4),
      SHIFTOUT  => cascade,   -- 1-bit output: Cascade output signal for master/slave I/O
      VALID     => open,      -- 1-bit output: Output status of the phase detector
      BITSLIP   => bitslip ,   -- 1-bit input: Bitslip enable input
      CE0       => '1',        -- 1-bit input: Clock enable input
      CLK0      => clk0,       -- 1-bit input: I/O clock network input
      CLK1      => clk1,       -- 1-bit input: Secondary I/O clock network input
      CLKDIV    => clkdiv,     -- 1-bit input: FPGA logic domain clock input
      D         => ser_input,  -- 1-bit input: Input data
      IOCE      => strobe,     -- 1-bit input: Data strobe input
      RST       => '0',        -- 1-bit input: Asynchronous reset input
      SHIFTIN   => '0'         -- 1-bit input: Cascade input signal for master/slave I/O
   );

ISERDES2_slave : ISERDES2
   generic map (
      BITSLIP_ENABLE => TRUE,         -- Enable Bitslip Functionality (TRUE/FALSE)
      DATA_RATE      => "SDR",        -- Data-rate ("SDR" or "DDR")
      DATA_WIDTH     => 5,            -- Parallel data width selection (2-8)
      INTERFACE_TYPE => "RETIMED",    -- "NETWORKING", "NETWORKING_PIPELINED" or "RETIMED" 
      SERDES_MODE    => "SLAVE"       -- "NONE", "MASTER" or "SLAVE" 
   )
   port map (
      CFB0      => open,      -- 1-bit output: Clock feed-through route output
      CFB1      => open,      -- 1-bit output: Clock feed-through route output
      DFB       => open,      -- 1-bit output: Feed-through clock output
      FABRICOUT => open,    -- 1-bit output: Unsynchrnonized data output
      INCDEC    => open,    -- 1-bit output: Phase detector output
      -- Q1 - Q4: 1-bit (each) output: Registered outputs to FPGA logic
      Q1        => open,
      Q2        => open,
      Q3        => open,
      Q4        => ser_data(0),
      SHIFTOUT  => open,      -- 1-bit output: Cascade output signal for master/slave I/O
      VALID     => open,      -- 1-bit output: Output status of the phase detector
      BITSLIP   => bitslip,   -- 1-bit input: Bitslip enable input
      CE0       => '1',       -- 1-bit input: Clock enable input
      CLK0      => clk0,      -- 1-bit input: I/O clock network input
      CLK1      => clk1,      -- 1-bit input: Secondary I/O clock network input
      CLKDIV    => clkdiv,    -- 1-bit input: FPGA logic domain clock input
      D         => '0',       -- 1-bit input: Input data
      IOCE      => '1',       -- 1-bit input: Data strobe input
      RST       => '0',       -- 1-bit input: Asynchronous reset input
      SHIFTIN   => cascade    -- 1-bit input: Cascade input signal for master/slave I/O
   );
   
end Behavioral;

