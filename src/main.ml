open Netlist_ast

let prgm = TransformNetlist.transform (Netlist.read_file "fulladder.net")

let rec dispIdents = function 
| [] -> ()
| hd::tl -> Printf.printf "\t%s\n" hd; dispIdents tl

let () = Printf.printf "INPUT\n"; dispIdents (prgm.p_inputs);
	Printf.printf "OUTPUT\n"; dispIdents (prgm.p_outputs)

let graph = DepGraph.from_ast prgm
let topList = DepGraph.topological_list graph

let () = 
	print_string "\nINPUT VARS\n";
	print_string (GenCode.gen_readInputs (prgm.p_inputs));
	print_string "\nOUTPUT VARS\n";
	print_string (GenCode.gen_printOutputs (prgm.p_outputs));
	print_string "\nINIT VARS\n";
	print_string (GenCode.gen_declVars prgm.p_vars);
	print_string "\n\n\nCODE\n";
	List.iter (fun eq -> print_string (GenCode.codeOfEqn eq prgm)) topList

