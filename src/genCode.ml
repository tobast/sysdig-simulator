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

let strOfArg arg = 
	let strOfBool = function
	| false -> "false"
	| true -> "true"
	in

	let strOfBitarray = Array.fold_left
		(fun cur elem -> cur^(if elem then "1" else "0")) ""
	in
	
	match arg with
	| Avar(id) -> id
	| Aconst(v) -> (match v with
		| VBit(b) -> strOfBool b
		| VBitArray(ba) ->
			"bitset<"^(Array.length ba)^">(string("^(strOfBitarray ba)^"))"
		)

let argType prgm = function
| Avar(id) -> Env.find id (prgm.p_vars)
| Aconst(v) -> (match v with
	| VBit(_) -> TBit
	| VBitArray(a) -> TBitArray(Array.len a))

(***
 * Returns <res> if the types of every var in <vars> matches,
 * raises TypeNotMatchError exception otherwise.
 ***)
let checkTypes vars prgm =
	let checkAhead ty = List.fold_left (fun cur t -> cur && (t=ty)) true in
	let rec check cur = function
	| [] | _::[] -> true
	| hd::tl -> check (cur && (checkAhead hd tl)) tl
	in

	if not check true (List.map (argType prgm) vars) then
		raise TypeNotMatchError

(* Helper function to shorten the calls to checkTypes *)
let argOf ident = Avar(ident)

let bitarrayLen ba = match argType ba with
| TBitArray(a) -> a
| _ -> raise TypeError

let gen_readInputs l =
	(List.fold_left 
		(fun cur id -> cur ^ id ^ " = getBit();\n") "" l) ^ "getchar();\n"

let gen_printOutputs l = 
	(List.fold_left
		(fun cur id -> cur ^ "putchar("^id^"? '1':'0');\n") "") ^
		"putchar('\n');\n"

let codeOfEqn (ident,exp) prgm = match exp with
| Earg(arg) -> 
	checkTypes [ (argOf ident);arg ] prgm;
	(ident ^ " = " ^ (strOfArg arg) ^ ";\n")
| Ereg(arg) ->
	checkTypes [ (argOf ident) ; arg ] prgm;
	(ident ^ " = " ^ (strOfArg Avar(arg)) ^ ";\n")
	(* YES, we tolerate registers on BitArrays. *)
| Enot(arg) ->
	checkTypes [ (argOf ident) ; arg ] prgm;
	(ident ^ " = " ^ (match argType arg with
		| TBit -> "!"
		| TBitArray(_) -> "~") ^ (strOfArg arg) ^ ";\n")
| Ebinop(op,a1,a2) -> 
	checkTypes [ (argOf ident) ; a1 ; a2 ] prgm;
	(ident ^ " = " ^ (if op = Nand then "!" else "") ^ "("
		^ (strOfArg a1) ^ (match op with
		| Or	-> " | "
		| Xor	-> " ^ "
		| And	-> " & "
		| Nand	-> " & ")
		^ (strOfArg a2) ^ ");\n")
(** TODO check that Minijazz generates MUX (ifFalse) (ifTrue) (selector) **)
| Emux(a1,a2,a3) -> (** a3 is the selector, and must be a TBit. **)
	checkTypes [ a3 ; VBit(true) ] prgm ; (* Raises exn if wrong type *)
	checkTypes [ (argOf ident) ; a1 ; a2 ] prgm;
	(ident ^ " = " ^ "("^(strOfArg a3)^") ? " ^
		"("^(strOfArg a2)^") : ("^(strOfArg a1)^");\n")
| Erom(addrSize,wordSize,read_addr) -> (*TODO implement*) ""
| Eram(addrSize,wordSize,readAddr,writeEnable,writeAddr,data) ->
	(*TODO implement*) ""
| Econcat(a1,a2) ->
	(* Type checking is a bit more complex here. Not using checkTypes. *)
	(match (argType a1, argType a2, argType (argOf ident)) with (*CHECK TYPES*)
	| TBitArray(t1),TBitArray(t2),TBitArray(tid) ->
		if (t1 + t2 <> tid) then
			raise TypeNotMatchError
	| _,_,_ -> TypeNotMatchError);
	
	(* Benchmarking proved that using strings was faster than setting each
	bit one after one. *)
	ident ^ " = bitset<" ^ (bitarrayLength (argOf ident)) ^">("^
		(strOfArg a1) ^ ".to_string() + "^
		(strOfArg a2) ^ ".to_string());\n"
| Eslice(sBeg,sEnd,arg) -> (* NOTE we assume the indices to be *inclusive* *)
	(* Type checking *)
	(match (argType (argOf ident), argType arg) with
	| TBitArray(identLen), TBitArray(argLen) ->
		if (identLen <> sEnd-sBeg+1) then
			raise TypeNotMatchError
		else if (sBeg < 0 || sEnd >= argLen || sBeg > sEnd) then
			raise OutOfRangeError
	| _,_ -> raise TypeNotMatchError);
	let len = sEnd - sBeg + 1 in
	ident ^ " = bitset<"^(string_of_int len)^">("^(strOfArg arg)^
		".to_string().substr("^(string_of_int sBeg)^","^
		(string_of_int len)^"));\n"
| Eselect(pos,arg) ->
	(* Type checking *)
	checkTypes [ (argOf ident) ; (VBit(true)) ] prgm ;
	(match (argType arg) with
	| TBitArray(len) ->
		if (pos < 0 || pos >= len) then
			raise OutOfRangeError
	| _ -> raise TypeNotMatchError);
	ident ^ " = " ^ (strOfArg arg) ^ "["^pos^"];\n"
