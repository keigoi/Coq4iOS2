type ns_mutable_attributed_string
type parse_match_callback

module L = Ploc
module V = Vernac
module VE = Vernacexpr

let coqstate = ref None
let coqopts : Coqargs.coq_cmdopts option ref = ref None
let state () =
  match !coqstate with
  | Some s -> s
  | None -> raise Not_found
let opts () =
  match !coqopts with
  | Some o -> o
  | None -> raise Not_found


let parsable_of_string str = Pcoq.Gram.parsable (Stream.of_string str)

let parse_sentence (po, verbch) =
  match Pcoq.Gram.entry_parse Pcoq.main_entry po with
    | Some (loc, cmd) -> CAst.make ~loc cmd
    | None -> raise Stm.End_of_input

let next_phrase_range str =
  let po = parsable_of_string str in
  try
    let {CAst.loc} = parse_sentence (po, None) in
    match loc with
    | Some {Loc.bp;ep} -> bp, ep
    | None -> (*FIXME*) -1, -1
  with
    | _ -> (*FIXME return error msg*) -1, -1

let eval ?(raw=false) (str:string) : bool * string =
  let po = parsable_of_string str in
  try
    let last = parse_sentence (po, None) in
    if not raw && Vernacprop.is_navigation_vernac last.CAst.v then
      false, "Please use navigation buttons instead."
    else begin
      coqstate := Some (V.process_expr ~time:(opts ()).Coqargs.time ~state:(state ()) last);
      true, ""
    end
  with
    (* | V.End_of_input -> (false, "end of input") *)
    (* | V.DuringCommandInterp (loc, exn) ->
     *     let msg = Printf.sprintf "error at (%d,%d) %s" (L.first_pos loc) (L.last_pos loc) (Pp.string_of_ppcmds (Errors.print exn)) in
     *     (false, msg) *)
    | e ->
        (false, Printexc.to_string e)

let string_of_compile_exn (file, (_,_,loc), exn) =
  let detail =
  match exn with
  | CErrors.UserError(str,ppcmds) ->
    Printf.sprintf "UserError(\"%s\",\"%s\")" (match str with Some s -> s | None -> "") (Pp.string_of_ppcmds ppcmds)
  (* | CErrors.Error_in_file (file,info,exn) -> string_of_compile_exn (file,info,exn) *)
  | _ -> Printexc.to_string exn
  in
  Printf.sprintf "Compile Error: (%d, %d) in %s : %s\n" (L.first_pos loc) (L.last_pos loc) file detail

(* let compile file =
 *   try
 *     let file = Filename.chop_suffix file ".v" in
 *     States.unfreeze !saved_state;
 *     V.compile !verbose file
 *   with Util.Error_in_file (file,info,exn) ->
 *     print_endline (string_of_compile_exn (file,info,exn));
 *     raise exn *)

(* let rewind i =
 *   try
 *     Backtrack.back i
 *   with
 *     Backtrack.Invalid -> 0 *)

let reset_initial () = eval ~raw:true "Reset Initial.\n"

let start root =
  print_endline "start.";
  let state, opts = Coqtop.init_toplevel ["-coqlib"; root] in
  coqstate := state;
  coqopts := Some opts;
  true

let start root =
  try
    start root
  with
    | CErrors.UserError(str,ppcmds) ->
       print_endline(Printf.sprintf "UserError(\"%s\",\"%s\")" (match str with Some str -> str | None -> ""(*FIXME*)) (Pp.string_of_ppcmds ppcmds));
        false
    (* | Util.Error_in_file (file,info,exn) ->
     *     print_endline (string_of_compile_exn (file,info,exn));
     *     false; *)
    | e ->
        print_endline (Printexc.to_string e);
        false
;;

Callback.register "start" start;
Callback.register "eval" (fun str -> eval str);
Callback.register "next_phranse_range" next_phrase_range;
Callback.register "reset_initial" reset_initial;
(* Callback.register "compile" compile; *)
(* Callback.register "parse" parse; *)
(* Callback.register "rewind" rewind; *)
