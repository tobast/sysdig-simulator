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

open Netlist_ast
exception ErrorAffectedTwice of Netlist_ast.ident
exception ErrorROMConsistency

(***
 * Checks that a single ident is not affected twice in the same cycle
 ***)
let checkAffectedTwice program =
	let present = Hashtbl.create (Env.cardinal program.p_vars) in
	let contains x =
		(try Hashtbl.find present x
		 with Not_found -> false)
	in

	List.iter (fun (ident,_) ->
		if contains ident then
			raise (ErrorAffectedTwice ident);
		Hashtbl.add present ident true) program.p_eqs

(***
 * Checks, if multiple ROM instructions are present in the equations list,
 * that they are consistent, ie. they share their word_size, addr_size
 ***)
let checkROMConsistency program =
	let once=ref true and wsize=ref 0 and asize=ref 0 in
	List.iter (fun (ident,eq) -> match eq with
		| Erom(asz,wsz,_) ->
			if !once = true then (
				once:=false;
				wsize:=wsz;
				asize:=asz
			) else if (asz <> !asize) || (wsz <> !wsize) then
				raise ErrorROMConsistency
		| _ -> ()
		) program.p_eqs

let checkAll program =
	checkAffectedTwice program;
	checkROMConsistency program
