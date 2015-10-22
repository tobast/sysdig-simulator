#!/bin/bash


##########################################################################
# SIMCOMP
##########################################################################
# Compiler from net_list to C, for the Sysdig project at the ENS Ulm
# http://www.di.ens.fr/~bourke/sysdig.html
##########################################################################
# By Théophile BASTIAN
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
##########################################################################
# runTests.sh
# ----------
#
# Runs all tests in the given directories. The directories must contains, to
# run a test named "foo", the files
# 	- foo.net : netlist file
# 	- foo.in : the input of the simulator
# 	- foo.out : the expected output of the simulator
#	- foo.rom : OPTIONNAL if provided, loaded as ROM
# Usage: ./runTests.sh [directories]
# Eg. to run all tests : ./runTests.sh tests/*
#
##########################################################################

if (( $# < 1 )) ; then
	>&2 echo -e "Missing argument. Usage:\n$0 [directories]"
	exit 1
fi
nbErrors=0

while (( $# >= 1 )); do
	dirname=${1%%/}
	echo "####################################"
	echo "## ENTERING DIRECTORY ${dirname}"
	echo "####################################"

	for testFile in $dirname/*.net; do
		baseName=${testFile%%.net}
		echo -n "${baseName}..."

		./compile.sh $testFile "${baseName}.bin"
		rom=""
		if [ -f "${baseName}.rom" ]
			then rom="${baseName}.rom"
		fi

		${baseName}.bin ${rom:+"$rom"} < ${baseName}.in | diff - "${baseName}.out" > /dev/null
		if (( $? > 0 )); then
			echo -e "\t\tFAILED."
			let "nbErrors = nbErrors + 1"
		else
			echo ""
		fi

		rm "${baseName}.bin"
	done
	shift
done

if (( $nbErrors > 0 )); then
	echo -e "\n${nbErrors} ERRORS. Some tests failed!"
else
	echo -e "\nALL TESTS PASSED."
fi
