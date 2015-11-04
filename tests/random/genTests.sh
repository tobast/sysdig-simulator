#!/bin/bash

NB_INPUTS=50
NB_OUTPUTS=50
NB_EQS=500
NB_CYCLES=2000

curTests=`find ../* | grep -v random | grep -c ".net$"`
let "nbToGen = 42 - curTests"
rm -f ./*.{net,in,out}

for i in `seq 1 ${nbToGen}`; do
	fname=`printf "%02d" $i`
	echo -n "${fname}..."
	python ./randNetlist.py ${NB_INPUTS} ${NB_OUTPUTS} ${NB_EQS} > "${fname}.net"
	python ./randInputs.py ${NB_CYCLES} ${NB_INPUTS} > "${fname}.in"
	./ncourant.cmp -n ${NB_CYCLES} -iomode 1 "${fname}.net"
	tail -n +2 "${fname}.in" | tr -d '\n' | "./${fname}" | sed -e "s/.\{${NB_INPUTS}\}/&\n/g" > "${fname}.out"
	rm -f "${fname}" "${fname}.c"
	echo ""
done

