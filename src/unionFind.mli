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
 * Implements a hashtable-based union-find
 **************************************************************************)

(***
 * The union-find structure type
 ***)

type t

exception NotInForest of string

(***
 * Creates a forest of orphaned nodes.
 * create : elem array -> forest
 ***)
val create : string array -> t

(***
 * Unites two trees from the forest.
 * union : UFstruct -> elem1 -> elem2 -> discarded elem
 ***)
val union : t -> string -> string -> string

(***
 * Returns true iff the elements are in the same tree. Might be a little faster
 * than find e1 = find e2 because it does not translates the numerical IDs
 * back to strings.
 ***)
val equal : t -> string -> string -> bool

(***
 * Returns the key of the element identifying the searched element.
 * find : UFstruct -> elem -> elemRoot
 ***)
val find : t -> string -> string

