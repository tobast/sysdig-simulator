#!/usr/bin/python3

import sys
from random import randint

################################### HELP STRING ###############################
HELP_STRING = "Usage: "+sys.argv[0]+" [nb inputs] [nb outputs] [min nb eqs]"
###############################################################################

def randArg(availVars, ty, unusedVars):
	if(ty[0] != 'REG' and randint(0,99) >= 95):
		return str(randint(0,1))
	var = availVars[randint(0,len(availVars)-1)]
	try:
		unusedVars.remove(var)
	except:
		()
	return var

def shuffle(l):
	for i in range(len(l)):
		j = randint(0, len(l)-1)
		(l[i],l[j]) = (l[j],l[i])

def varsLine(vrs):
	line = ''
	for v in vrs[:-1]:
		line += v + ', '
	line += vrs[-1]
	return line

def pick(l):
	pos = randint(0, len(l)-1)
	return l.pop(pos)

def main():
	inputs = [ 'input'+str(x) for x in range(int(sys.argv[1])) ]
	outputs = [ 'output'+str(x) for x in range(int(sys.argv[2])) ]
	availVars  = inputs.copy()

	EQS_POSS = [
		('REG', 1),
		('NOT', 1),
		('OR', 2),
		('XOR', 2),
		('AND', 2),
		('NAND', 2),
		('MUX', 3)
	]
	EQS_2_POSS = EQS_POSS[2:6]
	eqs = []
	
	varNames = [ 'inter'+str(eqId) for eqId in range(int(sys.argv[3])) ]
	unusedVars = set(varNames + inputs)
	shuffle(varNames)
	for nVar in varNames:
		ty = EQS_POSS[randint(0,len(EQS_POSS)-1)]
		eq = nVar+' = '+ty[0]+' '
		for i in range(ty[1]):
			if(ty[0] == 'REG'):
				eq += randArg(availVars, ty, unusedVars)+' '
			else:
				eq += randArg(availVars, ty, unusedVars)+' '
		eqs.append(eq)
		availVars.append(nVar)
	
	unusedList = list(unusedVars)
	cVar = len(varNames)
	once=True
	def nextVar(cVar,once):
		if(len(unusedList) <= 2*len(outputs) and once):
			cVar = 0
			return outputs[cVar],cVar,False
		elif(len(unusedList) > 2*len(outputs)):
			var = 'inter'+str(cVar)
			cVar += 1
			varNames.append(var)
			return var,cVar,once
		else:
			cVar += 1
			return outputs[cVar],cVar,once
	
	while len(unusedList) < 2*len(outputs):
		unusedList.append(availVars[randint(0,len(availVars)-1)])
	while len(unusedList) > 1:
		nVar,cVar,once = nextVar(cVar, once)
		v1,v2 = pick(unusedList), pick(unusedList)
		if(once):
			unusedList.append(nVar)
		eqs.append(nVar + ' = ' + EQS_2_POSS[randint(0, len(EQS_2_POSS)-1)][0]\
			+ ' ' + v1 + ' ' + v2)
	if(len(unusedList) > 1):
		eqs.append(outputs[cVar+1]+'= REG '+unusedList[0])	
	
	print('INPUT '+varsLine(inputs))
	print('OUTPUT '+varsLine(outputs))
	print('VAR\n\t'+varsLine(inputs)+', '+varsLine(varNames)+','+varsLine(outputs)+'\nIN')
	for eq in eqs:
		print(eq)
	
if __name__ == '__main__':
	if(len(sys.argv) < 3):
		print("Missing parameter.\n"+HELP_STRING)
		exit(1)
	main()
