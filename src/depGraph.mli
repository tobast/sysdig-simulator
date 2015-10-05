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

(* DepGraph -- provides a way to handle and order topologically a list of
	net_list equations, as a DAG *)

type graph
exception Combinatory_loop


(***
 * Imports a graph from a Netlist_ast.program
 * from_ast : program -> programGraph
 ***)
val from_ast : Netlist_ast.program -> graph

(***
 * Creates a topologically ordered list from a graph, ie. you can process
 * the elements of the list in that order to compute the outputs
 * topological_list -> programGraph -> equation list
 ***)
val topological_list : graph -> Netlist_ast.equation list

(***
 * Debug function, displays the graph on stdout
 ***)
val dispGraph : graph -> unit
