open Printf
open Cil
open Ptranal
(*let files = [ "../tcp_input.i" ;"../tcp.i"]*)
let ()=printf "Please input .i files separated with spaces \n"
let input_file=read_line() 
let files=Str.split(Str.regexp " ") input_file ;;
(* Function print funtion statement kind*)
let print_fun_stmt_kind stmt=
	match stmt.skind with
		|Instr inst_list->
			List.iter(fun instr ->
				match instr with
				|Set (lval,exp,loc)->printf "Set %d\n" loc.line
				|Call (_,exp,_,loc)->printf "Call %d:" loc.line;
					(match exp with
						|Lval (Var vinfo,_)->printf "Lval Var:%s\n" vinfo.vname
						|Lval (Mem expr,_)-> printf "Mem:";
							(match exp with 
							|Lval (Mem expr,_)->printf "Mem:";
								(match exp with
								|Lval(Mem expr,_) ->printf "Mem\n"
								|_->()
								)
							|_->()
							)
						|_->()
					)
				|_ ->()
			)inst_list
		|Return _->printf "Return"
		|_->printf "else\n"
let () =
  (* Load each input file. *)
  let files =
    List.map (
      fun filename ->
	(* Why does parse return a continuation? *)
	let f = Frontc.parse filename in
	f ()
    ) files in

  (* Merge them. *)
  let file = Mergecil.merge files "test" in

  (* Remove unused prototypes and variables. *)
  Rmtmps.removeUnusedTemps file;

  (* Do control-flow-graph analysis. *)
  Cfg.computeFileCFG file;

  (* Go over the internal CIL structure and print some facts. *)
  printf "CIL has loaded the files, merged them and removed unused code.\n\n";

  printf "Merged file has %d globals ...\n\n" (List.length file.globals);
  List.iter (
    function
    | GType _ -> ()			(* typedef *)
    | GCompTag _ -> ()			(* struct/union *)
    | GCompTagDecl _ -> ()		(* forward prototype of struct/union *)
    | GEnumTag _ -> ()			(* enum *)
    | GEnumTagDecl _ -> ()		(* forward prototype of enum *)
    | GVarDecl _ -> ()			(* variable/function prototype *)
    | GVar _ -> ()			(* variable definition *)
    | GFun (fundec, loc) ->		(* function definition *)
		printf "In function: %s\n" fundec.svar.vname;
        List.iter(fun stmt->
			print_fun_stmt_kind stmt
        )fundec.sallstmts
    | GAsm _ -> ()			(* global asm statement *)
    | GPragma _ -> ()			(* toplevel #pragma *)
    | GText _ -> ()			(* verbatim text, comments *)
  ) file.globals;

