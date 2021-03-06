(*  Title:      Pure/Isar/outer_syntax.ML
    Author:     Markus Wenzel, TU Muenchen

Isabelle/Isar outer syntax.
*)

signature OUTER_SYNTAX =
sig
  val help: theory -> string list -> unit
  val print_commands: theory -> unit
  type command_spec = string * Position.T
  val command: command_spec -> string ->
    (Toplevel.transition -> Toplevel.transition) parser -> unit
  val local_theory': command_spec -> string ->
    (bool -> local_theory -> local_theory) parser -> unit
  val local_theory: command_spec -> string ->
    (local_theory -> local_theory) parser -> unit
  val local_theory_to_proof': command_spec -> string ->
    (bool -> local_theory -> Proof.state) parser -> unit
  val local_theory_to_proof: command_spec -> string ->
    (local_theory -> Proof.state) parser -> unit
  val parse: theory -> Position.T -> string -> Toplevel.transition list
  val parse_tokens: theory -> Token.T list -> Toplevel.transition list
  val parse_spans: Token.T list -> Command_Span.span list
  val side_comments: Token.T list -> Token.T list
  val command_reports: theory -> Token.T -> Position.report_text list
end;

structure Outer_Syntax: OUTER_SYNTAX =
struct

(** outer syntax **)

(* errors *)

fun err_command msg name ps =
  error (msg ^ quote (Markup.markup Markup.keyword1 name) ^ Position.here_list ps);

fun err_dup_command name ps =
  err_command "Duplicate outer syntax command " name ps;


(* command parsers *)

datatype command = Command of
 {comment: string,
  parse: (Toplevel.transition -> Toplevel.transition) parser,
  pos: Position.T,
  id: serial};

fun eq_command (Command {id = id1, ...}, Command {id = id2, ...}) = id1 = id2;

fun new_command comment parse pos =
  Command {comment = comment, parse = parse, pos = pos, id = serial ()};

fun command_pos (Command {pos, ...}) = pos;

fun command_markup def (name, Command {pos, id, ...}) =
  Markup.properties (Position.entity_properties_of def id pos)
    (Markup.entity Markup.commandN name);

fun pretty_command (cmd as (name, Command {comment, ...})) =
  Pretty.block
    (Pretty.marks_str
      ([Active.make_markup Markup.sendbackN {implicit = true, properties = [Markup.padding_line]},
        command_markup false cmd], name) :: Pretty.str ":" :: Pretty.brk 2 :: Pretty.text comment);


(* theory data *)

structure Data = Theory_Data
(
  type T = command Symtab.table;
  val empty = Symtab.empty;
  val extend = I;
  fun merge data : T =
    data |> Symtab.join (fn name => fn (cmd1, cmd2) =>
      if eq_command (cmd1, cmd2) then raise Symtab.SAME
      else err_dup_command name [command_pos cmd1, command_pos cmd2]);
);

val get_commands = Data.get;
val dest_commands = get_commands #> Symtab.dest #> sort_wrt #1;
val lookup_commands = Symtab.lookup o get_commands;

fun help thy pats =
  dest_commands thy
  |> filter (fn (name, _) => forall (fn pat => match_string pat name) pats)
  |> map pretty_command
  |> Pretty.writeln_chunks;

fun print_commands thy =
  let
    val keywords = Thy_Header.get_keywords thy;
    val minor = Scan.dest_lexicon (Keyword.minor_keywords keywords);
    val commands = dest_commands thy;
  in
    [Pretty.strs ("keywords:" :: map quote minor),
      Pretty.big_list "commands:" (map pretty_command commands)]
    |> Pretty.writeln_chunks
  end;


(* maintain commands *)

fun add_command name cmd thy =
  let
    val _ =
      Keyword.is_command (Thy_Header.get_keywords thy) name orelse
        err_command "Undeclared outer syntax command " name [command_pos cmd];
    val _ =
      (case lookup_commands thy name of
        NONE => ()
      | SOME cmd' => err_dup_command name [command_pos cmd, command_pos cmd']);
    val _ =
      Context_Position.report_generic (ML_Context.the_generic_context ())
        (command_pos cmd) (command_markup true (name, cmd));
  in Data.map (Symtab.update (name, cmd)) thy end;

val _ = Theory.setup (Theory.at_end (fn thy =>
  let
    val command_keywords =
      Scan.dest_lexicon (Keyword.major_keywords (Thy_Header.get_keywords thy));
    val _ =
      (case subtract (op =) (map #1 (dest_commands thy)) command_keywords of
        [] => ()
      | missing => error ("Missing outer syntax command(s) " ^ commas_quote missing))
  in NONE end));


(* implicit theory setup *)

type command_spec = string * Position.T;

fun command (name, pos) comment parse =
  Theory.setup (add_command name (new_command comment parse pos));

fun local_theory_command trans command_spec comment parse =
  command command_spec comment (Parse.opt_target -- parse >> (fn (loc, f) => trans loc f));

val local_theory' = local_theory_command Toplevel.local_theory';
val local_theory = local_theory_command Toplevel.local_theory;
val local_theory_to_proof' = local_theory_command Toplevel.local_theory_to_proof';
val local_theory_to_proof = local_theory_command Toplevel.local_theory_to_proof;



(** toplevel parsing **)

(* parse commands *)

local

fun parse_command thy =
  Parse.position Parse.command_ :|-- (fn (name, pos) =>
    let
      val tr0 = Toplevel.empty |> Toplevel.name name |> Toplevel.position pos;
    in
      (case lookup_commands thy name of
        SOME (Command {parse, ...}) => Parse.!!! (Parse.tags |-- parse) >> (fn f => f tr0)
      | NONE =>
          Scan.succeed
            (tr0 |> Toplevel.imperative (fn () => err_command "Undefined command " name [pos])))
    end);

val parse_cmt = Parse.$$$ "--" -- Parse.!!! Parse.document_source;

in

fun commands_source thy =
  Token.source_proper #>
  Source.source Token.stopper (Scan.bulk (parse_cmt >> K NONE || Parse.not_eof >> SOME)) #>
  Source.map_filter I #>
  Source.source Token.stopper (Scan.bulk (fn xs => Parse.!!! (parse_command thy) xs));

end;

fun parse thy pos str =
  Source.of_string str
  |> Symbol.source
  |> Token.source (Thy_Header.get_keywords thy) pos
  |> commands_source thy
  |> Source.exhaust;

fun parse_tokens thy toks =
  Source.of_list toks
  |> commands_source thy
  |> Source.exhaust;


(* parse spans *)

local

fun ship span =
  let
    val kind =
      if not (null span) andalso Token.is_command (hd span) andalso not (exists Token.is_error span)
      then Command_Span.Command_Span (Token.content_of (hd span), Token.pos_of (hd span))
      else if forall Token.is_improper span then Command_Span.Ignored_Span
      else Command_Span.Malformed_Span;
  in cons (Command_Span.Span (kind, span)) end;

fun flush (result, content, improper) =
  result
  |> not (null content) ? ship (rev content)
  |> not (null improper) ? ship (rev improper);

fun parse tok (result, content, improper) =
  if Token.is_command tok then (flush (result, content, improper), [tok], [])
  else if Token.is_improper tok then (result, content, tok :: improper)
  else (result, tok :: (improper @ content), []);

in

fun parse_spans toks =
  fold parse toks ([], [], []) |> flush |> rev;

end;


(* side-comments *)

fun cmts (t1 :: t2 :: toks) =
      if Token.keyword_with (fn s => s = "--") t1 then t2 :: cmts toks
      else cmts (t2 :: toks)
  | cmts _ = [];

val side_comments = filter Token.is_proper #> cmts;


(* read commands *)

fun command_reports thy tok =
  if Token.is_command tok then
    let val name = Token.content_of tok in
      (case lookup_commands thy name of
        NONE => []
      | SOME cmd => [((Token.pos_of tok, command_markup false (name, cmd)), "")])
    end
  else [];

end;

