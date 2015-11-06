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

type t = { forwardMatch : (string,int) Hashtbl.t ;
		backwardMatch : string array ;
		parentOf : int array ;
		sizeOf : int array }
exception NotInForest of string

let create elems =
	let len = Array.length elems in
	let outHash = Hashtbl.create len in
	let backwardMatch = Array.init len (fun k -> elems.(k)) in
	Array.iteri (fun pos elem -> Hashtbl.add outHash elem pos ) elems;

	{ forwardMatch = outHash ;
	  backwardMatch = backwardMatch ;
	  parentOf = Array.init len (fun k -> k) ;
	  sizeOf = Array.make len 1 }

(***
 * Finds an elem and returns its ID, or raises NotInForest if not found
 ***)
let findID uf elem =
	try Hashtbl.find uf.forwardMatch elem
	with Not_found -> raise (NotInForest elem)

let rec union uf el1 el2 =
	let id1 = findID uf el1 and id2 = findID uf el2 in
	if ( uf.sizeOf.(id1) < uf.sizeOf.(id2) ) then
		union uf el2 el1
	else begin
		uf.parentOf.(id2) <- id1; 
		uf.sizeOf.(id1) <- uf.sizeOf.(id2) + uf.sizeOf.(id1);
		el2
	end

(***
 * Finds the ID of the root of an element identified by its ID
 ***)

let rec findParId uf id =
	if uf.parentOf.(id) = id then
		id
	else begin
		let pId = findParId uf (uf.parentOf.(id)) in
		uf.parentOf.(id) <- pId;
		pId
	end
	
let equal uf e1 e2 =
	(findParId uf (findID uf e1)) = (findParId uf (findID uf e2))

let find uf elt =
	let id = findID uf elt in
	uf.backwardMatch.(findParId uf id)
