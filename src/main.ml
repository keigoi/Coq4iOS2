type ns_mutable_attributed_string
type parse_match_callback

module L = Ploc
module V = Vernac
module VE = Vernacexpr

let orig_stdout = ref stdout

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

let () =
  ignore (Feedback.add_feeder Coqloop.coqloop_feed)

let init_stdout,read_stdout =
  let out_buff = Buffer.create 1024 (*magic number*) in
  let out_ft = Format.formatter_of_buffer out_buff in
  let deep_out_ft = Format.formatter_of_buffer out_buff in
  let inp,outp = Unix.pipe () in
  let inp_chan = Unix.in_channel_of_descr inp in
  let _ = Topfmt.set_gp deep_out_ft Topfmt.deep_gp in
  (fun () ->
     flush_all ();
     orig_stdout := Unix.out_channel_of_descr (Unix.dup Unix.stdout);
     Unix.dup2 outp Unix.stdout;
     (* Unix.dup2 outp Unix.stderr; *)
     Topfmt.std_ft := out_ft;
     Topfmt.err_ft := out_ft;
     Topfmt.deep_ft := deep_out_ft;
     set_binary_mode_out !orig_stdout true;
     set_binary_mode_in stdin true;
  ),
  (fun () ->
    flush_all ();
    Unix.set_nonblock inp;
    begin
      try
        let bufstr = Bytes.create 1024 (*magic number*)
        in
        let rec loop () =
          let count  = input inp_chan bufstr 0 (Bytes.length bufstr) in
          Buffer.add_bytes out_buff (Bytes.sub bufstr 0 count);
          if count = Bytes.length bufstr then
            loop () else
            ()
        in loop ()
      with
          End_of_file -> ()
        | Unix.Unix_error(Unix.EAGAIN,_,_)
        | Unix.Unix_error(Unix.EWOULDBLOCK,_,_)
        | Sys_blocked_io -> ()
    end;
    Unix.clear_nonblock inp;
    Format.pp_print_flush out_ft ();
    let r = Buffer.contents out_buff in
    Buffer.clear out_buff; r)



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

let pr_open_cur_subgoals () =
  try
    let proof = Proof_global.give_me_the_proof () in
    Printer.pr_open_subgoals ~proof
  with Proof_global.NoCurrentProof -> Pp.str ""

let flush_all () =
  Pervasives.flush stderr;
  Pervasives.flush stdout;
  Format.pp_print_flush !Topfmt.std_ft ();
  Format.pp_print_flush !Topfmt.err_ft ()

let eval ?(raw=false) (str:string) : bool * string =
  let po = parsable_of_string str in
  try
    let last = parse_sentence (po, None) in
    if not raw && Vernacprop.is_navigation_vernac last.CAst.v then
      (prerr_endline "not a command\n";
      false, "Please use navigation buttons instead.")
    else begin
      prerr_endline "okay\n";
      coqstate := Some (V.process_expr ~time:(opts ()).Coqargs.time ~state:(state ()) last);
      Feedback.msg_notice (pr_open_cur_subgoals ());
      flush_all();
      true, read_stdout ()
    end
  with
    (* | V.End_of_input -> (false, "end of input") *)
    (* | V.DuringCommandInterp (loc, exn) ->
     *     let msg = Printf.sprintf "error at (%d,%d) %s" (L.first_pos loc) (L.last_pos loc) (Pp.string_of_ppcmds (Errors.print exn)) in
     *     (false, msg) *)
  | e ->
     prerr_endline "exception\n";
     (false, Printexc.to_string e)

let pr_open_cur_subgoals () =
  try
    let proof = Proof_global.give_me_the_proof () in
    Printer.pr_open_subgoals ~proof
  with Proof_global.NoCurrentProof -> Pp.str ""

(* Goal equality heuristic. *)
let pequal cmp1 cmp2 (a1,a2) (b1,b2) = cmp1 a1 b1 && cmp2 a2 b2
let evleq e1 e2 = CList.equal Evar.equal e1 e2
let cproof p1 p2 =
  let (a1,a2,a3,a4,_),(b1,b2,b3,b4,_) = Proof.proof p1, Proof.proof p2 in
  evleq a1 b1 &&
  CList.equal (pequal evleq evleq) a2 b2 &&
  CList.equal Evar.equal a3 b3 &&
  CList.equal Evar.equal a4 b4

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
  init_stdout();
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
Callback.register "read_stdout" read_stdout;
(* Callback.register "compile" compile; *)
(* Callback.register "parse" parse; *)
(* Callback.register "rewind" rewind; *)
