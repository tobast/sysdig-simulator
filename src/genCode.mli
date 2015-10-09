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

exception TypeNotMatchError
exception TypeError
exception OutOfRangeError

(***
 * Generates a piece of C code which reads stdin and updates the input pins
 * gen_readInputs : inputs list -> code
 ***)
val gen_readInputs = Netlist_ast.ident list -> string
(***
 * Generates a piece of C code which writes the state of the outputs to stdout
 * gen_printOutputs : outputs list -> code
 ***)
val gen_printOutputs = Netlist_ast.ident list -> string

(***
 * Generates a piece of C code executing the given Netlist.equation
 * codeOfEqn : equation -> code
 ***)
val codeOfEqn = Netlist_ast.equation -> string
