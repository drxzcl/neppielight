"""
	Print a conversion table for a gamma value of 2.5 that 
	can be included in VHDL code.
	
	Due to the large gap in brightness between level 1 and level 0 (off),
	we only use 1-255 instead of 0-255. This greatly reduces the
	dynamic range of the LEDs, but it saves us from some nasty glitches
	at low intensity levels.
"""

import math

for i in range(256):
	g = int(math.pow(float(i) / 255.0, 2.5) * 254.0 + 1.5)
	print 'X"%02X",' % (g),
	