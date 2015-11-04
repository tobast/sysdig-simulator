import sys
from random import randint

print(str(sys.argv[1]))
for i in range(int(sys.argv[1])):
	line = ''
	for j in range(int(sys.argv[2])):
		print(randint(0,1), end='')
	print('')

