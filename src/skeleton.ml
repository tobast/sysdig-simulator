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

let codeSkeletonParts = Array.make 5 ""

let assemble declVars readInput mainLoop printOutput =
	codeSkeletonParts.(0) ^
	declVars ^
	codeSkeletonParts.(1) ^
	readInput ^
	codeSkeletonParts.(2) ^
	mainLoop ^
	codeSkeletonParts.(3) ^
	printOutput ^
	codeSkeletonParts.(4)

let () =
	codeSkeletonParts.(0) <- "#include <cstdio>
#include <bitset>
#include <string>
#include <stdexcept>
using namespace std;

int nbCycles;

inline bool getBit() {
	switch(getchar()) {
	case '0':
		return false;
	case '1':
		return true;
	default:
		throw invalid_argument(\"Invalid character received, expected '0' or '1'.\");
	}
}

int main(void) {
	scanf(\"%d\\n\", &nbCycles);
";

	codeSkeletonParts.(1) <-"
	for(int cyc=0; cyc < nbCycles; ++cyc) {
";
	
	codeSkeletonParts.(2) <- "\n\n";
	codeSkeletonParts.(3) <- "\n\n";
	codeSkeletonParts.(4) <- "
	}

	return 0;
}"
