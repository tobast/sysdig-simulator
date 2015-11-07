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

exception ErrorVarsNotExhaustive of string

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

(***
 * Detects identical equations and identifies the variables implied.
 * This is useful because minijazz tends to copy equations, eg. in
 * x = (a xor b) and c
 * y = (a xor b) or c
 * a xor b is calculated twice, with two different variables...
 ***)
let identifyIdenticalEquations prgm =
	Printf.eprintf "Called\n";
	let mkEqClasses eqs =
		let out = Array.make 13 [] in
		let expId = function
		| Earg _ -> 0
		| Ereg _ -> 1
		| Enot _ -> 2
		| Ebinop (bop,_,_) -> (match bop with
			| Or -> 3
			| Xor -> 4
			| And -> 5
			| Nand -> 6 )
		| Emux _ -> 7
		| Erom _ -> 8
		| Eram _ -> 9
		| Econcat _ -> 10
		| Eslice _ -> 11
		| Eselect _ -> 12
		in

		List.iter (fun (id,exp) -> let eId = expId exp in
			out.(eId) <- (id,exp)::(out.(eId)))
			eqs;
		out
	in

	let iterIdentify prgm =
		let varEquiv = Hashtbl.create 17 in
		let eqClasses = mkEqClasses prgm.p_eqs in
		let nVars = ref prgm.p_vars in
		let changes = ref 0 in
		Env.iter (fun id _ -> Hashtbl.add varEquiv id id) prgm.p_vars;

		let rec doSimplify cur = function
		| [] -> cur
		| (id,eq)::tl ->
			let nTl = simplifyForward id eq [] tl in
			doSimplify ((id,eq)::cur) nTl
		and simplifyForward id eq cur = function
		| [] -> cur
		| ((oId,oEq) as hd)::tl ->
			if oEq = eq then (
				Hashtbl.add varEquiv oId id;
				changes := !changes + 1;
				nVars := Env.remove oId !nVars;
				simplifyForward id eq cur tl
			) else
				simplifyForward id eq (hd::cur) tl
		in
		
		let nVar id = (try Hashtbl.find varEquiv id with 
			Not_found -> raise (ErrorVarsNotExhaustive id))
		in
		let nArg = function
		| Avar(id) -> Avar(nVar id)
		| a -> a
		in

		let replaceInExp = function
		| Earg(arg) -> Earg(nArg arg)
		| Ereg(id) -> Ereg(nVar id)
		| Enot(arg) -> Enot(nArg arg)
		| Ebinop(b,a1,a2) -> Ebinop(b,nArg a1,nArg a2)
		| Emux(a,b,c) -> Emux(nArg a, nArg b, nArg c)
		| Erom(i1,i2,a) -> Erom(i1,i2, nArg a)
		| Eram(i1,i2,a,b,c,d) -> Eram(i1,i2, nArg a, nArg b, nArg c, nArg d)
		| Econcat(a,b) -> Econcat(nArg a, nArg b)
		| Eslice(i1,i2,a) -> Eslice(i1,i2, nArg a)
		| Eselect(i,a) -> Eselect(i, nArg a)
		in

(*
		let nEqs = List.map (fun (id,exp) -> (id,replaceInExp exp))
			(doSimplify [] prgm.p_eqs) in
*)
		let nEqs = List.map (fun (id,exp) -> (id, replaceInExp exp))
			(Array.fold_left (fun processed cur -> (
				(doSimplify [] cur)) @ processed) [] eqClasses) in
		({ p_eqs = nEqs ;
			p_inputs = (List.map nVar prgm.p_inputs) ;
			p_outputs = (List.map nVar prgm.p_outputs) ;
			p_vars = !nVars }, !changes)
	in
	
	let nPrgm = ref prgm in
	let assign (pg, num) = nPrgm := pg; num in
	while assign (iterIdentify !nPrgm) > 0 do () done;
	!nPrgm

let optLevel level func =
	if level <= !Parameters.optimize
		then func
		else (fun k -> k)

let transform prgm =
(*	Netlist_printer.print_program stdout prgm;
	let nPrgm = identifyIdenticalEquations (fixOutputRegisters prgm) in
	Netlist_printer.print_program stdout nPrgm;
	nPrgm
*)
	(optLevel 1 identifyIdenticalEquations) (fixOutputRegisters prgm)
(*	fixOutputRegisters prgm*)
