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

(***
 * Transforms a netlist by adding a "wire" between a register whose output
 * is an output of the circuit and the actual output, ie.
 * a -(reg)- output --> a-(reg)-(temp var)-output
 * This enables the trick of retro-dependancy of the registers to work in this
 * case too.
 ***)
let fixOutputRegisters prgm =
	let outputsTbl = Hashtbl.create (Env.cardinal prgm.p_vars) in
	List.iter (fun ident -> Hashtbl.add outputsTbl ident true) prgm.p_outputs;
	let isOutput ident =
		try (Hashtbl.find outputsTbl ident) with Not_found -> false
	in
	let varName varId = "_rshift"^(string_of_int varId) in
	let typeOf ident = Env.find ident prgm.p_vars in (* try..with maybe? *)

	let (_,nEqns,nVars) = List.fold_left
		(fun (nextVar,nEqns,nVars) (ident,expr) -> match expr with
		| Ereg(source) when (isOutput ident) -> 
			let nVarName = varName nextVar in
			let outVars = Env.add nVarName (typeOf ident) nVars in
			(nextVar+1,
				(ident,Earg(Avar(nVarName)))::(nVarName,Ereg(source))::nEqns,
				outVars)
		| a -> (nextVar, (ident,a)::nEqns, nVars))
		(0,[],prgm.p_vars) prgm.p_eqs
	in
	{ p_eqs = nEqns ;
		p_inputs = prgm.p_inputs ; p_outputs = prgm.p_outputs ;
		p_vars = nVars }

let transform prgm =
	fixOutputRegisters prgm
