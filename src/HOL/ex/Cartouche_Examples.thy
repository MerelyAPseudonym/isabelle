(*  Title:      HOL/ex/Cartouche_Examples.thy
    Author:     Makarius
*)

section \<open>Some examples with text cartouches\<close>

theory Cartouche_Examples
imports Main
keywords
  "cartouche" "term_cartouche" :: diag and
  "text_cartouche" :: thy_decl
begin

subsection \<open>Regular outer syntax\<close>

text \<open>Text cartouches may be used in the outer syntax category "text",
  as alternative to the traditional "verbatim" tokens.  An example is
  this text block.\<close>  -- \<open>The same works for small side-comments.\<close>

notepad
begin
  txt \<open>Moreover, cartouches work as additional syntax in the
    "altstring" category, for literal fact references.  For example:\<close>

  fix x y :: 'a
  assume "x = y"
  note \<open>x = y\<close>
  have "x = y" by (rule \<open>x = y\<close>)
  from \<open>x = y\<close> have "x = y" .

  txt \<open>Of course, this can be nested inside formal comments and
    antiquotations, e.g. like this @{thm \<open>x = y\<close>} or this @{thm sym
    [OF \<open>x = y\<close>]}.\<close>

  have "x = y"
    by (tactic \<open>rtac @{thm \<open>x = y\<close>} 1\<close>)  -- \<open>more cartouches involving ML\<close>
end


subsection \<open>Outer syntax: cartouche within command syntax\<close>

ML \<open>
  Outer_Syntax.command @{command_spec "cartouche"} ""
    (Parse.cartouche >> (fn s =>
      Toplevel.imperative (fn () => writeln s)))
\<close>

cartouche \<open>abc\<close>
cartouche \<open>abc \<open>\<alpha>\<beta>\<gamma>\<close> xzy\<close>


subsection \<open>Inner syntax: string literals via cartouche\<close>

ML \<open>
  local
    val mk_nib =
      Syntax.const o Lexicon.mark_const o
        fst o Term.dest_Const o HOLogic.mk_nibble;

    fun mk_char (s, pos) =
      let
        val c =
          if Symbol.is_ascii s then ord s
          else if s = "\<newline>" then 10
          else error ("String literal contains illegal symbol: " ^ quote s ^ Position.here pos);
      in Syntax.const @{const_syntax Char} $ mk_nib (c div 16) $ mk_nib (c mod 16) end;

    fun mk_string [] = Const (@{const_syntax Nil}, @{typ string})
      | mk_string (s :: ss) =
          Syntax.const @{const_syntax Cons} $ mk_char s $ mk_string ss;

  in
    fun string_tr content args =
      let fun err () = raise TERM ("string_tr", args) in
        (case args of
          [(c as Const (@{syntax_const "_constrain"}, _)) $ Free (s, _) $ p] =>
            (case Term_Position.decode_position p of
              SOME (pos, _) => c $ mk_string (content (s, pos)) $ p
            | NONE => err ())
        | _ => err ())
      end;
  end;
\<close>

syntax "_cartouche_string" :: "cartouche_position \<Rightarrow> string"  ("_")

parse_translation \<open>
  [(@{syntax_const "_cartouche_string"},
    K (string_tr (Symbol_Pos.cartouche_content o Symbol_Pos.explode)))]
\<close>

term "\<open>\<close>"
term "\<open>abc\<close>"
term "\<open>abc\<close> @ \<open>xyz\<close>"
term "\<open>\<newline>\<close>"
term "\<open>\001\010\100\<close>"


subsection \<open>Alternate outer and inner syntax: string literals\<close>

subsubsection \<open>Nested quotes\<close>

syntax "_string_string" :: "string_position \<Rightarrow> string"  ("_")

parse_translation \<open>
  [(@{syntax_const "_string_string"}, K (string_tr Lexicon.explode_string))]
\<close>

term "\"\""
term "\"abc\""
term "\"abc\" @ \"xyz\""
term "\"\<newline>\""
term "\"\001\010\100\""


subsubsection \<open>Term cartouche and regular quotes\<close>

ML \<open>
  Outer_Syntax.command @{command_spec "term_cartouche"} ""
    (Parse.inner_syntax Parse.cartouche >> (fn s =>
      Toplevel.keep (fn state =>
        let
          val ctxt = Toplevel.context_of state;
          val t = Syntax.read_term ctxt s;
        in writeln (Syntax.string_of_term ctxt t) end)))
\<close>

term_cartouche \<open>""\<close>
term_cartouche \<open>"abc"\<close>
term_cartouche \<open>"abc" @ "xyz"\<close>
term_cartouche \<open>"\<newline>"\<close>
term_cartouche \<open>"\001\010\100"\<close>


subsubsection \<open>Further nesting: antiquotations\<close>

setup -- "ML antiquotation"
\<open>
  ML_Antiquotation.inline @{binding term_cartouche}
    (Args.context -- Scan.lift (Parse.inner_syntax Parse.cartouche) >>
      (fn (ctxt, s) => ML_Syntax.atomic (ML_Syntax.print_term (Syntax.read_term ctxt s))))
\<close>

setup -- "document antiquotation"
\<open>
  Thy_Output.antiquotation @{binding ML_cartouche}
    (Scan.lift Args.cartouche_source_position) (fn {context, ...} => fn source =>
      let
        val toks = ML_Lex.read "fn _ => (" @ ML_Lex.read_source false source @ ML_Lex.read ");";
        val _ = ML_Context.eval_in (SOME context) ML_Compiler.flags (Input.pos_of source) toks;
      in "" end);
\<close>

ML \<open>
  @{term_cartouche \<open>""\<close>};
  @{term_cartouche \<open>"abc"\<close>};
  @{term_cartouche \<open>"abc" @ "xyz"\<close>};
  @{term_cartouche \<open>"\<newline>"\<close>};
  @{term_cartouche \<open>"\001\010\100"\<close>};
\<close>

text \<open>
  @{ML_cartouche
    \<open>
      (
        @{term_cartouche \<open>""\<close>};
        @{term_cartouche \<open>"abc"\<close>};
        @{term_cartouche \<open>"abc" @ "xyz"\<close>};
        @{term_cartouche \<open>"\<newline>"\<close>};
        @{term_cartouche \<open>"\001\010\100"\<close>}
      )
    \<close>
  }
\<close>


subsubsection \<open>Uniform nesting of sub-languages: document source, ML, term, string literals\<close>

ML \<open>
  Outer_Syntax.command
    @{command_spec "text_cartouche"} ""
    (Parse.opt_target -- Parse.source_position Parse.cartouche >> Thy_Output.document_command)
\<close>

text_cartouche
\<open>
  @{ML_cartouche
    \<open>
      (
        @{term_cartouche \<open>""\<close>};
        @{term_cartouche \<open>"abc"\<close>};
        @{term_cartouche \<open>"abc" @ "xyz"\<close>};
        @{term_cartouche \<open>"\<newline>"\<close>};
        @{term_cartouche \<open>"\001\010\100"\<close>}
      )
    \<close>
  }
\<close>


subsection \<open>Proof method syntax: ML tactic expression\<close>

ML \<open>
structure ML_Tactic:
sig
  val set: (Proof.context -> tactic) -> Proof.context -> Proof.context
  val ml_tactic: Input.source -> Proof.context -> tactic
end =
struct
  structure Data = Proof_Data(type T = Proof.context -> tactic fun init _ = K no_tac);

  val set = Data.put;

  fun ml_tactic source ctxt =
    let
      val ctxt' = ctxt |> Context.proof_map
        (ML_Context.expression (Input.range_of source) "tactic" "Proof.context -> tactic"
          "Context.map_proof (ML_Tactic.set tactic)"
          (ML_Lex.read "fn ctxt: Proof.context =>" @ ML_Lex.read_source false source));
    in Data.get ctxt' ctxt end;
end;
\<close>


subsubsection \<open>Explicit version: method with cartouche argument\<close>

method_setup ml_tactic = \<open>
  Scan.lift Args.cartouche_source_position
    >> (fn arg => fn ctxt => SIMPLE_METHOD (ML_Tactic.ml_tactic arg ctxt))
\<close>

lemma "A \<and> B \<longrightarrow> B \<and> A"
  apply (ml_tactic \<open>rtac @{thm impI} 1\<close>)
  apply (ml_tactic \<open>etac @{thm conjE} 1\<close>)
  apply (ml_tactic \<open>rtac @{thm conjI} 1\<close>)
  apply (ml_tactic \<open>ALLGOALS atac\<close>)
  done

lemma "A \<and> B \<longrightarrow> B \<and> A" by (ml_tactic \<open>blast_tac ctxt 1\<close>)

ML \<open>@{lemma "A \<and> B \<longrightarrow> B \<and> A" by (ml_tactic \<open>blast_tac ctxt 1\<close>)}\<close>

text \<open>@{ML "@{lemma \"A \<and> B \<longrightarrow> B \<and> A\" by (ml_tactic \<open>blast_tac ctxt 1\<close>)}"}\<close>


subsubsection \<open>Implicit version: method with special name "cartouche" (dynamic!)\<close>

method_setup "cartouche" = \<open>
  Scan.lift Args.cartouche_source_position
    >> (fn arg => fn ctxt => SIMPLE_METHOD (ML_Tactic.ml_tactic arg ctxt))
\<close>

lemma "A \<and> B \<longrightarrow> B \<and> A"
  apply \<open>rtac @{thm impI} 1\<close>
  apply \<open>etac @{thm conjE} 1\<close>
  apply \<open>rtac @{thm conjI} 1\<close>
  apply \<open>ALLGOALS atac\<close>
  done

lemma "A \<and> B \<longrightarrow> B \<and> A"
  by (\<open>rtac @{thm impI} 1\<close>, \<open>etac @{thm conjE} 1\<close>, \<open>rtac @{thm conjI} 1\<close>, \<open>atac 1\<close>+)


subsection \<open>ML syntax\<close>

text \<open>Input source with position information:\<close>
ML \<open>
  val s: Input.source = \<open>abc123def456\<close>;
  writeln (Markup.markup Markup.information ("Look here!" ^ Position.here (Input.pos_of s)));

  \<open>abc123def456\<close> |> Input.source_explode |> List.app (fn (s, pos) =>
    if Symbol.is_digit s then Position.report pos Markup.ML_numeral else ());
\<close>

text \<open>Nested ML evaluation:\<close>
ML \<open>
  val ML = ML_Context.eval_source ML_Compiler.flags;

  ML \<open>ML \<open>val a = @{thm refl}\<close>\<close>;
  ML \<open>val b = @{thm sym}\<close>;
  val c = @{thm trans}
  val thms = [a, b, c];
\<close>

end
