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

exception Combinatory_loop

open Netlist_ast

type vertice = { eq : Netlist_ast.equation ;
	edges : int list }
type graph = vertice array

let argsOfExp exp =
	let addArg l = function
	| Netlist_ast.Avar(id) -> l := (id :: !l)
	| _ -> ()
	in

	let rec findArgs curArgs = function
	| Netlist_ast.Ereg(id)
		-> curArgs := (id :: !curArgs)
	| Netlist_ast.Earg(arg)
	| Netlist_ast.Enot(arg)
	| Netlist_ast.Erom(_,_,arg)
	| Netlist_ast.Eslice(_,_,arg)
	| Netlist_ast.Eselect(_,arg)
		-> addArg curArgs arg
	| Netlist_ast.Ebinop(_,a1,a2)
	| Netlist_ast.Econcat(a1,a2)
		-> addArg curArgs a1 ; addArg curArgs a2
	| Netlist_ast.Emux(a1,a2,a3)
		-> addArg curArgs a1 ; addArg curArgs a2 ; addArg curArgs a3
	| Netlist_ast.Eram(_,_,a1,a2,a3,a4)
		-> addArg curArgs a1 ; addArg curArgs a2 ;
			addArg curArgs a3 ; addArg curArgs a4
	in

	let l = ref [] in
	findArgs l exp;
	!l
	

let from_ast (prgm : Netlist_ast.program) =
	let eqsArray = Array.of_list prgm.p_eqs in
	let nbEqs = Array.length eqsArray in
	let edges = Array.make nbEqs [] in

	let seenVerts = Array.make nbEqs false in

	let varsId = Hashtbl.create (2*nbEqs) in
	for k = 0 to nbEqs-1 do
		Hashtbl.add varsId (fst eqsArray.(k)) k
	done;

	let rec fillEdges vert =
		if seenVerts.(vert) = false then begin
			seenVerts.(vert) <- true;

			let args = argsOfExp (snd eqsArray.(vert)) in
			processArgs vert args
		end

	and processArgs vert = function
	| [] -> ()
	| hd::tl ->
		(try
			let id = Hashtbl.find varsId hd in
			(match (snd eqsArray.(id)) with
			| Ereg(_) -> edges.(id) <- vert :: edges.(id)
				(* If it's a register, add a reverse dependency: thus, it will
				still be the previous value when used. *)
			| _ -> edges.(vert) <- id :: edges.(vert)) ;
			(* NOTE might create double edges a -> b, but we don't care *)
			fillEdges id
		with Not_found -> ());
		processArgs vert tl
	in

	for k = 0 to nbEqs - 1 do
		fillEdges k
	done;

	Array.init nbEqs (fun k ->
		{ eq = eqsArray.(k); edges = edges.(k) })

let topological_list graph =
	let sorted = ref [] in
	let nbVert = Array.length graph in
	let seen = Array.make nbVert false in
	let descending = Array.make nbVert false in

	let rec dfs vert =
		if descending.(vert) then
			raise Combinatory_loop
		else if not seen.(vert) then begin
			descending.(vert) <- true;

			recurseChildren graph.(vert).edges;
			sorted := vert :: (!sorted);
			
			descending.(vert) <- false;
			seen.(vert) <- true
		end
	and recurseChildren = function
	| [] -> ()
	| hd::tl -> dfs hd ; recurseChildren tl
	in

	for k=0 to nbVert-1 do
		dfs k
	done;
	
	List.fold_left (fun cur elem -> (graph.(elem).eq)::cur)
		[] (!sorted)

(***************** DEBUG CODE **************************************)

let dispGraph graph =
	let rec printDeps = function
	| [] -> ()
	| hd::tl ->
		Printf.printf "%s " (fst (graph.(hd).eq)) ; printDeps tl
	in
	for k = 0 to (Array.length graph)-1 do
		Printf.printf "%s -> " (fst graph.(k).eq);
		printDeps graph.(k).edges;
		print_newline ()
	done
