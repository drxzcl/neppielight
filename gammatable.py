import math

for i in range(256):
	g = int(math.pow(float(i) / 255.0, 2.5) * 254.0 + 1.5)
	print 'X"%02X",' % (g),
	
	