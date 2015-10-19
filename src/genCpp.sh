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

function escape {
	echo "$1" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g'
}

function genFile {
	barename=`basename "$1" ".cpp" | sed 's/^[0-9]*_//g'`
	echo "let $barename = \""
	contents=`cat "$1"`
	escape "${contents}"

	echo -e "\"\n\n"
}

for file in cpp/* ; do
	[ -f "${file}" ] && genFile "$file"
done

echo "let skeleton = Array.make `ls -1 cpp/skeleton/[0-9]*.cpp | wc -l` \"\""
echo "let () ="

for file in cpp/skeleton/[0-9]*.cpp ; do
	n=`basename "$file" ".cpp"`
	echo "skeleton.($n) <- \""
	escape "`cat $file`"
	echo -e "\";\n\n"
done
echo "()"
