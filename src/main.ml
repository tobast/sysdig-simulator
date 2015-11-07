open Netlist_ast
open Printf

exception MissingParameter of string

let processArgs args =
	let curPos = ref 1 in
	let nextParam errString convert =
		if !curPos + 1 < (Array.length args) then (
			curPos := !curPos + 1 ;
			(try convert args.(!curPos)
			with _ -> raise (MissingParameter errString))
		) else
			raise (MissingParameter errString)
	in

	while !curPos < ((Array.length args) - 1) do (* Do not process the last *)
		let cArg = args.(!curPos) in
		(if cArg = "--ramSize" then
			Parameters.ramSize :=
				(nextParam "Expected number after --ramSize" int_of_string)
		else if cArg = "-n" then
			Parameters.skipLines := false
		else if cArg = "-O0" then
			Parameters.optimize := 0
		else if cArg = "-O1" then
			Parameters.optimize := 1
		else
			(Printf.eprintf "Warning: invalid argument %s.\n" cArg));

		curPos := !curPos + 1
	done

let main () =
	if (Array.length Sys.argv) < 2 then (
		eprintf ("Missing argument. Usage:\n%s [options] [file.net]\n") (Sys.argv.(0));
		exit 1
	);

	processArgs Sys.argv;
	
	let ast = Netlist.read_file Sys.argv.((Array.length Sys.argv)-1) in

	(try CheckNetlist.checkAll ast with
	| CheckNetlist.ErrorAffectedTwice id ->
		Printf.eprintf ("ERROR: Variable %s is affected at least twice in the same cycle.\n") id;
		exit 1
	| CheckNetlist.ErrorROMConsistency ->
		Printf.eprintf ("ERROR: ROM instructions are inconsistent. All ROM calls must share the same word_size and addr_size.\n");
		exit 1);

	(* If an exception is raised, it is self-explicit: let the user catch it.*)
	let prgm = TransformNetlist.transform ast in
	let graph = DepGraph.from_ast prgm in
	let topList = DepGraph.topological_list graph in
	(* let declMem,memTbl = *)
	let declMem = GenCode.gen_declMemories prgm in

	print_string (Skeleton.assemble
		(declMem ^ (GenCode.gen_declVars prgm.p_vars))
		(GenCode.gen_readInputs prgm prgm.p_inputs)
		(GenCode.gen_mainLoop prgm topList)
		(GenCode.gen_printOutputs prgm prgm.p_outputs))

let () = main ()
