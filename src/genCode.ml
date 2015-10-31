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

exception TypeNotMatchError
exception TypeError
exception OutOfRangeError
exception UndefinedBehavior of string

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
			"bitset<"^(string_of_int (Array.length ba))^">(revStr(string(\""^
				(strOfBitarray ba)^"\")))"
		)

let argType prgm = function
| Avar(id) -> (try Env.find id (prgm.p_vars)
	with Not_found -> print_string ("Unknown var "^id^"\n"); raise Not_found)
| Aconst(v) -> (match v with
	| VBit(_) -> TBit
	| VBitArray(a) -> TBitArray(Array.length a))

(***
 * Returns <res> if the types of every var in <vars> matches,
 * raises TypeNotMatchError exception otherwise.
 ***)
let checkTypes vars prgm =
	let checkNext ty tl = (List.hd tl) = ty in
	let rec check cur = function
	| [] | _::[] -> true
	| hd::tl -> check (cur && (checkNext hd tl)) tl
	in

	if not (check true (List.map (argType prgm) vars)) then
		raise TypeNotMatchError

(* Helper function to shorten the calls to checkTypes *)
let argOf ident = Avar(ident)

let bitarrayLen prgm ba = match argType prgm ba with
| TBitArray(a) -> a
| _ -> raise TypeError

let gen_declMemories prgm =
	let outTbl = Hashtbl.create 17 in
	let hasRom = ref false in
	let curId = ref 0 in
	let inTable v =
		(try let _ = Hashtbl.find outTbl v in true
		with Not_found -> false)
	in

	List.iter
		(fun eq -> match eq with
		| (ident, Eram(_)) ->
			if inTable ident then
				(* This shall never be raised, if CheckNetlist does its job. *)
				raise (UndefinedBehavior("Multiple RAM access with "^ident)) ;
			Hashtbl.add outTbl ident (!curId) ;
			curId := !curId + 1
		| (_, Erom(_,_,_)) -> hasRom := true
		| _ -> ())
		prgm.p_eqs;
		
	(
	(if (!hasRom)
		then Cpp.declareRom
		else "")^
	if (!curId > 0) then
		"vector<bool> ___ram["^(string_of_int !curId)^"];"^
		"for(int i=0; i < "^(string_of_int !curId)^"; i++)\n"^
		"\t___ram[i].resize("^(string_of_int !(Parameters.ramSize))^
		", false);\n"
	else
		"")
	, outTbl

			
	

let gen_declVars varsMap =
	let genOne key vType cur = cur ^ (match vType with
	| TBit -> "bool "^key^"=false;\n"
	| TBitArray(len) -> "bitset<"^(string_of_int len)^"> "^key^";\n")
	in

	(Env.fold genOne varsMap "")

let gen_readInputs prgm = function
| [] -> "" (* NOTE if there is no inputs, we do not expect \n's *)
| l ->
	(List.fold_left 
		(fun cur id -> cur ^ (match argType prgm (argOf id) with
		| TBit -> id ^ " = getBit();\n"
		| TBitArray(n) ->
			let rec iter k curstr =
				if k = n then curstr
				else iter (k+1)
					(curstr^id^"["^(string_of_int k)^"] = getBit();\n")
			in
			iter 0 ""
		)) "" l) ^ "getchar();\n"

let gen_printOutputs prgm l =
	(List.fold_left
		(fun cur id -> cur ^ (match argType prgm (argOf id) with
		| TBit -> "putchar("^id^"+'0');\n"
		| TBitArray(n) ->
			let rec iter k curstr =
				if k = n then curstr
				else iter (k+1)
					(curstr^"putchar("^id^"["^(string_of_int k)^
					"] + '0');\n")
			in
			iter 0 ""
		)) "" l) ^
		(if !Parameters.skipLines then "putchar('\\n');\n" else "")

let codeOfEqn memTable (ident,exp) prgm = match exp with
| Earg(arg) -> 
	checkTypes [ (argOf ident);arg ] prgm;
	(ident ^ " = " ^ (strOfArg arg) ^ ";\n")
| Ereg(arg) ->
	checkTypes [ (argOf ident) ; (argOf arg) ] prgm;
	(ident ^ " = " ^ (strOfArg (Avar(arg))) ^ ";\n")
	(* YES, we tolerate registers on BitArrays. *)
| Enot(arg) ->
	checkTypes [ (argOf ident) ; arg ] prgm;
	(ident ^ " = " ^ (match argType prgm arg with
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
	checkTypes [ a3 ; Aconst(VBit(true)) ] prgm ; (* Raises exn if wrong type *)
	checkTypes [ (argOf ident) ; a1 ; a2 ] prgm;
	(ident ^ " = " ^ "("^(strOfArg a3)^") ? " ^
		"("^(strOfArg a2)^") : ("^(strOfArg a1)^");\n")
| Erom(addrSize,wordSize,read_addr) ->
	(match argType prgm read_addr with
	| TBitArray(l) when l = addrSize -> ()
	| _ -> raise TypeNotMatchError) ;
	(match argType prgm (argOf ident) with
	| TBitArray(l) when l = wordSize -> ()
	| _ -> raise TypeNotMatchError) ;
	("readMemory<"^(string_of_int wordSize)^","^(string_of_int addrSize)^">("^
		ident^", "^(strOfArg read_addr)^", ___rom);\n")
| Eram(addrSize,wordSize,readAddr,writeEnable,writeAddr,data) ->
	(match (argType prgm readAddr, argType prgm writeAddr) with
	| TBitArray(l),TBitArray(l2) when l = addrSize && l2 = addrSize -> ()
	| _ -> raise TypeNotMatchError) ;
	(match (argType prgm (argOf ident), argType prgm data) with
	| TBitArray(l), TBitArray(l2) when l = wordSize && l2 = wordSize -> ()
	| _ -> raise TypeNotMatchError) ;
	checkTypes [ writeEnable ; Aconst(VBit(true)) ] prgm ;

	("readMemory<"^(string_of_int wordSize)^","^(string_of_int addrSize)^">("^
		ident^", "^(strOfArg readAddr)^", ___ram["^
		(string_of_int (Hashtbl.find memTable ident))^"]);\n"^
	"if("^(strOfArg writeEnable)^")\n\twriteMemory<"^
		(string_of_int wordSize)^","^(string_of_int addrSize)^">("^
		(strOfArg data)^", "^(strOfArg writeAddr)^", ___ram["^
		(string_of_int (Hashtbl.find memTable ident))^"]);\n")

| Econcat(a1,a2) ->
	(* Type checking is a bit more complex here. Not using checkTypes. *)
	(*CHECK TYPES*)
	(match (argType prgm a1, argType prgm a2, argType prgm (argOf ident)) with
	| TBitArray(t1),TBitArray(t2),TBitArray(tid) ->
		if (t1 + t2 <> tid) then
			raise TypeNotMatchError
	| TBit,TBitArray(t),TBitArray(tid) | TBitArray(t),TBit,TBitArray(tid) ->
		if (t + 1 <> tid) then
			raise TypeNotMatchError
	| TBit,TBit,TBitArray(2) -> ()
	| _,_,_ -> raise TypeNotMatchError);
	
	let bitstrOfArg arg = match (argType prgm arg) with
	| TBit -> "string("^(strOfArg arg)^" ? \"1\" : \"0\")"
	| TBitArray(_) -> (strOfArg arg) ^ ".to_string()"
	in

	(* Benchmarking proved that using strings was faster than setting each
	bit one after one. *)
	(* WARNING! Due to the "endianness" of the bitset.to_string(), we should
	concat with "rev(rev(b1)+rev(b2))", ie. b2+b1 ! *)
	ident ^ " = bitset<" ^ (string_of_int (bitarrayLen prgm (argOf ident))) ^
		">("^(bitstrOfArg a2)^" + "^(bitstrOfArg a1)^");\n"
		(*(strOfArg a1) ^ ".to_string() + "^
		(strOfArg a2) ^ ".to_string());\n"*)
| Eslice(sBeg,sEnd,arg) -> (* NOTE we assume the indices to be *inclusive* *)
	(* Type checking *)
	(match (argType prgm (argOf ident), argType prgm arg) with
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
	checkTypes [ (argOf ident) ; Aconst(VBit(true)) ] prgm ;
	(match (argType prgm arg) with
	| TBitArray(len) ->
		if (pos < 0 || pos >= len) then
			raise OutOfRangeError
	| _ -> raise TypeNotMatchError);
	ident ^ " = " ^ (strOfArg arg) ^ "["^(string_of_int pos)^"];\n"


let gen_mainLoop memTable program = List.fold_left
	(fun cur nEqn -> cur ^ (codeOfEqn memTable nEqn program)) ""
