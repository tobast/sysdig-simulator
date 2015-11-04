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
exception UndefinedBehavior of string

(***
 * Generates a piece of C code which declares all the memories of the program
 * (ie. RAMs and a ROM)
 * gen_declVars : variables map -> code
 ***)
val gen_declMemories : Netlist_ast.program -> string

(***
 * Generates a piece of C code which declares all the variables of the program
 * gen_declVars : variables map -> code
 ***)
val gen_declVars : Netlist_ast.ty Netlist_ast.Env.t -> string
(***
 * Generates a piece of C code which reads stdin and updates the input pins
 * gen_readInputs : program -> inputs list -> code
 ***)
val gen_readInputs : Netlist_ast.program -> Netlist_ast.ident list -> string
(***
 * Generates a piece of C code which writes the state of the outputs to stdout
 * gen_printOutputs : program -> outputs list -> code
 ***)
val gen_printOutputs : Netlist_ast.program -> Netlist_ast.ident list -> string

(***
 * Generates a piece of C code executing the given Netlist.equation
 * codeOfEqn : equation -> program -> code
 ***)
(***
 * WARNING! Must NOT be used directly.
 ***)
(*
val codeOfEqn : Netlist_ast.equation -> Netlist_ast.program -> string
*)

(***
 * Generates the C code executing the equations given, in that order.
 * gen_mainLoop : program -> equations list -> main loop code
 ***)
val gen_mainLoop : Netlist_ast.program -> Netlist_ast.equation list -> string

