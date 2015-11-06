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

let arrayOfEnv env =
	let len = Env.cardinal env in
	let out = Array.make len (fst (Env.choose env)) in
	let pos = ref 0 in
	Env.iter (fun key _ -> out.(!pos) <- key ; pos := !pos + 1) env;
	out

(***
 * Detects identical equations and identifies the variables implied.
 * This is useful because minijazz tends to copy equations, eg. in
 * x = (a xor b) and c
 * y = (a xor b) or c
 * a xor b is calculated twice, with two different variables...
 ***)
let identifyIdenticalEquations prgm =
	let iterIdentify prgm =
(*		let varEquiv = Hashtbl.create (Env.cardinal prgm.p_vars) in 
		Env.iter (fun id _ -> Hashtbl.add varEquiv id id) prgm.p_vars;
*)
		let nVars = ref prgm.p_vars in
		let varUF = UnionFind.create (arrayOfEnv prgm.p_vars) in
		let changes = ref 0 in

		let cmpArg a b = match a,b with
		| Avar(v1), Avar(v2) -> UnionFind.equal varUF v1 v2
		| _,_ -> false
		in

		let eqExp = function
		| (Earg a, Earg b)
		| (Enot a, Enot b)
			-> cmpArg a b
		| (Ereg a, Ereg b) -> UnionFind.equal varUF a b
		| (Ebinop (op1,a1,b1), Ebinop(op2,a2,b2)) ->
			op1 = op2 && cmpArg a1 a2 && cmpArg b1 b2
		| (Emux (a1,b1,c1), Emux(a2,b2,c2)) ->
			cmpArg a1 a2 && cmpArg b1 b2 && cmpArg c1 c2
		| (Erom (_,_,a1), Erom(_,_,a2)) -> cmpArg a1 a2
		| (Eram (a1,b1,c1,d1,e1,f1), Eram (a2,b2,c2,d2,e2,f2)) ->
			a1 = a2 && b1 = b2 && cmpArg c1 c2 && cmpArg d1 d2 &&
			cmpArg e1 e2 && cmpArg f1 f2
		| (Econcat (a1,b1), Econcat (a2,b2)) -> cmpArg a1 a2 && cmpArg b1 b2
		| (Eslice (a1,b1,c1), Eslice (a2,b2,c2)) ->
			a1 = a2 && b1 = b2 && cmpArg c1 c2
		| (Eselect (a1,b1), Eselect (a2,b2)) ->
			a1 = a2 && cmpArg b1 b2
		| _,_ -> false
		in

		let rec doSimplify cur = function
		| [] -> cur
		| (id,eq)::tl ->
			let nTl = simplifyForward id eq [] tl in
			doSimplify ((id,eq)::cur) nTl
		and simplifyForward id eq cur = function
		| [] -> cur
		| ((oId,oEq) as hd)::tl ->
			if eqExp (oEq,eq) then (
				(*
				Hashtbl.add varEquiv oId id;
				nVars := Env.remove oId !nVars;
				*)
				let discVar = UnionFind.union varUF oId id in
				nVars := Env.remove discVar !nVars; 
				changes := !changes + 1;
				simplifyForward id eq cur tl
			) else
				simplifyForward id eq (hd::cur) tl
		in
		
		let nVar id = (try UnionFind.find varUF id with 
			UnionFind.NotInForest var -> raise (ErrorVarsNotExhaustive var))
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

		let nEqs = List.map (fun (id,exp) -> (nVar id,replaceInExp exp))
			(doSimplify [] prgm.p_eqs) in
		({ p_eqs = nEqs ;
			p_inputs = (List.map nVar prgm.p_inputs) ;
			p_outputs = (List.map nVar prgm.p_outputs) ;
			p_vars = !nVars }, !changes)
	in
	
	let nPrgm = ref prgm in
	let assign (pg, num) = nPrgm := pg; num in
	let optiRounds = ref 1 in
	while assign (iterIdentify !nPrgm) > 0 do optiRounds := !optiRounds + 1 done;
	Printf.eprintf "Optimization rounds : %d\n" !optiRounds ;
	!nPrgm

let ifOpt level funct =
	if (!(Parameters.optimize) >= level)
		then funct
		else (fun k -> k)

let transform prgm =
(*	Netlist_printer.print_program stdout prgm;
	let nPrgm = identifyIdenticalEquations (fixOutputRegisters prgm) in
	Netlist_printer.print_program stdout nPrgm;
	nPrgm
*)
	(ifOpt 1 identifyIdenticalEquations) (fixOutputRegisters prgm)
(*	fixOutputRegisters prgm*)
