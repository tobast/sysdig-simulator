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
# compile.sh
# ----------
#
# Compiles the given argument into an executable simulator
# Usage: ./compile.sh [filename.net] [outbinary]
#
##########################################################################

COMPNL="./simcomp"
COMPCPP="g++ -O2"

if (( $# < 2 )); then
	>&2 echo -e "ERROR: Missing argument. Usage:\n$0 [filename.net] [outbinary]"
	exit 1
fi

[ -f "$1" ] && ($COMPNL "$1" | $COMPCPP -o "$2" -xc++ -)
