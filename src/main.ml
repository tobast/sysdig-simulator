open Netlist_ast
open Printf

let main () =
	if (Array.length Sys.argv) < 2 then (
		eprintf ("Missing argument. Usage:\n%s [file.net]\n") (Sys.argv.(0));
		exit 1
	);
	
	let ast = Netlist.read_file Sys.argv.(1) in
	(* If an exception is raised, it is self-explicit: let the user catch it.*)
	let prgm = TransformNetlist.transform ast in
	let graph = DepGraph.from_ast prgm in
	let topList = DepGraph.topological_list graph in

	print_string (Skeleton.assemble
		(GenCode.gen_declVars prgm.p_vars)
		(GenCode.gen_readInputs prgm.p_inputs)
		(GenCode.gen_mainLoop prgm topList)
		(GenCode.gen_printOutputs prgm.p_outputs))

let () = main ()
