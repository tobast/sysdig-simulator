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
 * Performs some checks on a NetList program.
 **************************************************************************)

exception ErrorAffectedTwice of Netlist_ast.ident
exception ErrorROMConsistency

(***
 * Checks some things on a program.
 * - non-ambiguous: at most ONE netlist equation changes a variable
 * - ROM instructions all share the same word size, addr size
 * Raises an exception if incorrect.
 ***
 * checkAll : program -> ()
 ***)
val checkAll : Netlist_ast.program -> unit

