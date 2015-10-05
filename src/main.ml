let prgm = Netlist.read_file "fulladder.net"

let rec dispIdents = function 
| [] -> ()
| hd::tl -> Printf.printf "\t%s\n" hd; dispIdents tl

let () = Printf.printf "INPUT\n"; dispIdents (prgm.p_inputs);
	Printf.printf "OUTPUT\n"; dispIdents (prgm.p_outputs)

let graph = DepGraph.from_ast prgm
let topList = DepGraph.topological_list graph

let dispList l =
	let rec doDispList = function
	| [] -> ()
	| hd::tl -> Printf.printf "%s ; " (fst hd); doDispList tl
	in
	Printf.printf "[ ";
	doDispList l;
	Printf.printf "]\n"

let () = dispList topList
