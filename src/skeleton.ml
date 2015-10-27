(**************************************************************************
 * SIMCOMP
 **************************************************************************
 * Compiler from net_list to C, for the Sysdig project at the ENS Ulm
 * http://www.di.ens.fr/~bourke/sysdig.html
 **************************************************************************
 * By Théophile BASTIAN
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 **************************************************************************)

let assemble declVars readInput mainLoop printOutput =
	Cpp.includes ^
	Cpp.functions ^
	Cpp.memory_vector ^
	
	Cpp.skeleton.(0) ^
	declVars ^
	Cpp.skeleton.(1) ^
	readInput ^
	Cpp.skeleton.(2) ^
	mainLoop ^
	Cpp.skeleton.(3) ^
	printOutput ^
(*	Cpp.dbg_dumpram ^ *)
	Cpp.skeleton.(4)
