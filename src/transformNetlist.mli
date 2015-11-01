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
 **************************************************************************
 * Transforms a net_list Ast by applying various algorithms, either to fix
 * problems or to optimize it
 *
 * Current effects:
 * ----------------
 * - Fixes registers whose outputs are circuit outputs by adding a wire
 * - Merges vars with the same equation
 * - Transforms NOToREGoNOT into Enotreg
 **************************************************************************)

(***
 * Fired when the VARS field does not contains all variables.
 ***)
exception ErrorVarsNotExhaustive of string

(***
 * Applies all transformations
 ***)
val transform : Netlist_ast.program -> Netlist_ast.program
