(*  Title:      HOL/SMT_Examples/boogie.ML
    Author:     Sascha Boehme, TU Muenchen

Proving Boogie-generated verification conditions.
*)

signature BOOGIE =
sig
  val boogie_prove: theory -> string list -> unit
end;

structure Boogie: BOOGIE =
struct

(* utility functions *)

val as_int = fst o read_int o raw_explode

val isabelle_name =
  let
    fun purge s = if Symbol.is_letter s orelse Symbol.is_digit s then s else
      (case s of
        "." => "_o_"
      | "_" => "_n_"
      | "$" => "_S_"
      | "@" => "_G_"
      | "#" => "_H_"
      | "^" => "_T_"
      | _   => ("_" ^ string_of_int (ord s) ^ "_"))
  in prefix "b_" o translate_string purge end


(* context *)

type context =
  typ Symtab.table * (term * bool) Symtab.table * term list * term list

val empty_context: context = (Symtab.empty, Symtab.empty, [], [])

fun add_type name (tds, fds, axs, vcs) =
  let
    val T = TFree (isabelle_name name, @{sort type})
    val tds' = Symtab.update (name, T) tds
  in (tds', fds, axs, vcs) end

fun add_func name Ts T unique (tds, fds, axs, vcs) =
  let
    val t = Free (isabelle_name name, Ts ---> T)
    val fds' = Symtab.update (name, (t, unique)) fds
  in (tds, fds', axs, vcs) end

fun add_axiom t (tds, fds, axs, vcs) = (tds, fds, t :: axs, vcs)

fun add_vc t (tds, fds, axs, vcs) = (tds, fds, axs, t :: vcs)

fun lookup_type (tds, _, _, _) name =
  (case Symtab.lookup tds name of
    SOME T => T
  | NONE => error "Undeclared type")

fun lookup_func (_, fds, _, _) name =
  (case Symtab.lookup fds name of
    SOME t_unique => t_unique
  | NONE => error "Undeclared function")


(* constructors *)

fun mk_var name T = Free ("V_" ^ isabelle_name name, T)

fun mk_arrayT (Ts, T) = Type (@{type_name "fun"}, [HOLogic.mk_tupleT Ts, T])

fun mk_binary t (t1, t2) = t $ t1 $ t2

fun mk_nary _ t [] = t
  | mk_nary f _ ts = uncurry (fold_rev f) (split_last ts)

fun mk_distinct [] = @{const HOL.True}
  | mk_distinct [_] = @{const HOL.True}
  | mk_distinct (t :: ts) =
      let
        fun mk_noteq u u' =
          HOLogic.mk_conj (HOLogic.mk_not (HOLogic.mk_eq (t, u)), u')
      in fold_rev mk_noteq ts (mk_distinct ts) end

fun mk_store m k v =
  let
    val mT = Term.fastype_of m and kT = Term.fastype_of k
    val vT = Term.fastype_of v
  in Const (@{const_name fun_upd}, mT --> kT --> vT --> mT) $ m $ k $ v end

fun mk_quant q (Free (x, T)) t = q T $ absfree (x, T) t
  | mk_quant _ t _ = raise TERM ("bad variable", [t])

val patternT = @{typ "SMT.pattern"}

fun mk_pat t =
  Const (@{const_name "SMT.pat"}, Term.fastype_of t --> patternT) $ t

fun mk_pattern [] = raise TERM ("mk_pattern", [])
  | mk_pattern ts = SMT_Util.mk_symb_list patternT (map mk_pat ts)

fun mk_trigger [] t = t
  | mk_trigger pss t =
      @{term "SMT.trigger"} $
        SMT_Util.mk_symb_list @{typ "SMT.pattern SMT.symb_list"} (map mk_pattern pss) $ t


(* parser *)

fun repeat f n ls =
  let fun apply (xs, ls) = f ls |>> (fn x => x :: xs)
  in funpow (as_int n) apply ([], ls) |>> rev end

fun parse_type _ (["bool"] :: ls) = (@{typ bool}, ls)
  | parse_type _ (["int"] :: ls) = (@{typ int}, ls)
  | parse_type cx (["array", arity] :: ls) =
      repeat (parse_type cx) arity ls |>> mk_arrayT o split_last
  | parse_type cx (("type-con" :: name :: _) :: ls) = (lookup_type cx name, ls)
  | parse_type _ _ = error "Bad type"

fun parse_expr _ (["true"] :: ls) = (@{term True}, ls)
  | parse_expr _ (["false"] :: ls) = (@{term False}, ls)
  | parse_expr cx (["not"] :: ls) = parse_expr cx ls |>> HOLogic.mk_not
  | parse_expr cx (["and", n] :: ls) = parse_nary_expr cx n HOLogic.mk_conj @{term True} ls
  | parse_expr cx (["or", n] :: ls) = parse_nary_expr cx n HOLogic.mk_disj @{term False} ls
  | parse_expr cx (["implies"] :: ls) = parse_bin_expr cx (mk_binary @{term HOL.implies}) ls
  | parse_expr cx (["="] :: ls) = parse_bin_expr cx HOLogic.mk_eq ls
  | parse_expr cx (["var", name] :: ls) = parse_type cx ls |>> mk_var name
  | parse_expr cx (["fun", name, n] :: ls) =
      let val (t, _) = lookup_func cx name
      in repeat (parse_expr cx) n ls |>> curry Term.list_comb t end
  | parse_expr cx (("label" :: _) :: ls) = parse_expr cx ls
  | parse_expr _ (["int-num", n] :: ls) = (HOLogic.mk_number @{typ int} (as_int n), ls)
  | parse_expr cx (["<"] :: ls) = parse_bin_expr cx (mk_binary @{term "op < :: int => _"}) ls
  | parse_expr cx (["<="] :: ls) = parse_bin_expr cx (mk_binary @{term "op <= :: int => _"}) ls
  | parse_expr cx ([">"] :: ls) = parse_bin_expr cx (mk_binary @{term "op < :: int => _"}o swap) ls
  | parse_expr cx ([">="] :: ls) =
      parse_bin_expr cx (mk_binary @{term "op <= :: int => _"} o swap) ls
  | parse_expr cx (["+"] :: ls) = parse_bin_expr cx (mk_binary @{term "op + :: int => _"}) ls
  | parse_expr cx (["-"] :: ls) = parse_bin_expr cx (mk_binary @{term "op - :: int => _"}) ls
  | parse_expr cx (["*"] :: ls) = parse_bin_expr cx (mk_binary @{term "op * :: int => _"}) ls
  | parse_expr cx (["/"] :: ls) = parse_bin_expr cx (mk_binary @{term boogie_div}) ls
  | parse_expr cx (["%"] :: ls) = parse_bin_expr cx (mk_binary @{term boogie_mod}) ls
  | parse_expr cx (["select", n] :: ls) =
      repeat (parse_expr cx) n ls
      |>> (fn ts => hd ts $ HOLogic.mk_tuple (tl ts))
  | parse_expr cx (["store", n] :: ls) =
      repeat (parse_expr cx) n ls
      |>> split_last
      |>> (fn (ts, t) => mk_store (hd ts) (HOLogic.mk_tuple (tl ts)) t)
  | parse_expr cx (["forall", vars, pats, atts] :: ls) =
      parse_quant cx HOLogic.all_const vars pats atts ls
  | parse_expr cx (["exists", vars, pats, atts] :: ls) =
      parse_quant cx HOLogic.exists_const vars pats atts ls
  | parse_expr _ _ = error "Bad expression"

and parse_bin_expr cx f ls = ls |> parse_expr cx ||>> parse_expr cx |>> f

and parse_nary_expr cx n f c ls =
  repeat (parse_expr cx) n ls |>> mk_nary (curry f) c

and parse_quant cx q vars pats atts ls =
  let
    val ((((vs, pss), _), t), ls') =
      ls
      |> repeat (parse_var cx) vars
      ||>> repeat (parse_pat cx) pats
      ||>> repeat (parse_attr cx) atts
      ||>> parse_expr cx
  in (fold_rev (mk_quant q) vs (mk_trigger pss t), ls') end

and parse_var cx (["var", name] :: ls) = parse_type cx ls |>> mk_var name
  | parse_var _ _ = error "Bad variable"

and parse_pat cx (["pat", n] :: ls) = repeat (parse_expr cx) n ls
  | parse_pat _ _ = error "Bad pattern"

and parse_attr cx (["attribute", name, n] :: ls) =
      let
        fun attr (["expr-attr"] :: ls) = parse_expr cx ls |>> K ()
          | attr (("string-attr" :: _) :: ls) = ((), ls)
          | attr _ = error "Bad attribute value"
      in repeat attr n ls |>> K name end
  | parse_attr _ _ = error "Bad attribute"

fun parse_func cx arity n ls =
  let
    val ((Ts, atts), ls') =
      ls |> repeat (parse_type cx) arity ||>> repeat (parse_attr cx) n
    val unique = member (op =) atts "unique"
  in ((split_last Ts, unique), ls') end

fun parse_decl (("type-decl" :: name :: _) :: ls) cx = (ls, add_type name cx)
  | parse_decl (["fun-decl", name, arity, n] :: ls) cx =
      let val (((Ts, T), unique), ls') = parse_func cx arity n ls
      in (ls', add_func name Ts T unique cx) end
  | parse_decl (("axiom" :: _) :: ls) cx =
      let val (t, ls') = parse_expr cx ls
      in (ls', add_axiom t cx) end
  | parse_decl (("var-decl" :: _) :: ls) cx =
      parse_type cx ls |> snd |> rpair cx
  | parse_decl (("vc" :: _) :: ls) cx =
      let val (t, ls') = parse_expr cx ls
      in (ls', add_vc t cx) end
  | parse_decl _ _ = error "Bad declaration"

fun parse_lines [] cx = cx
  | parse_lines ls cx = parse_decl ls cx |-> parse_lines


(* splitting of text lines into a lists of tokens *)

fun is_blank c = (c = " " orelse c = "\t" orelse c = "\r" orelse c = "\n")

val token_lines =
  map (String.tokens (is_blank o str))
  #> filter (fn [] => false | _ => true)


(* proving verification conditions *)

fun add_unique_axioms (tds, fds, axs, vcs) =
  Symtab.fold (fn (_, (t, true)) => cons t | _ => I) fds []
  |> map (swap o Term.dest_Free)
  |> AList.group (op =)
  |> map (fn (T, ns) => mk_distinct (map (Free o rpair T) ns))
  |> (fn axs' => (tds, fds, axs' @ axs, vcs))

fun build_proof_context thy (tds, fds, axs, vcs) =
  let
    val vc =
      (case vcs of
        [vc] => vc
      | _ => error "Bad number of verification conditions")
  in
    Proof_Context.init_global thy
    |> Symtab.fold (fn (_, T) => Variable.declare_typ T) tds
    |> Symtab.fold (fn (_, (t, _)) => Variable.declare_term t) fds
    |> fold Variable.declare_term axs
    |> fold Variable.declare_term vcs
    |> pair (map HOLogic.mk_Trueprop axs, HOLogic.mk_Trueprop vc)
  end

val boogie_rules =
  [@{thm fst_conv}, @{thm snd_conv}, @{thm pair_collapse}] @
  [@{thm fun_upd_same}, @{thm fun_upd_apply}]

fun boogie_tac ctxt axioms =
  ALLGOALS (SMT_Solver.smt_tac ctxt (boogie_rules @ axioms))

fun boogie_prove thy lines =
  let
    val ((axioms, vc), ctxt) =
      empty_context
      |> parse_lines (token_lines lines)
      |> add_unique_axioms
      |> build_proof_context thy

    val _ = Goal.prove ctxt [] axioms vc (fn {prems, context} => boogie_tac context prems)
    val _ = writeln "Verification condition proved successfully"

  in () end


(* Isar command *)

val _ =
  Outer_Syntax.command @{command_spec "boogie_file"}
    "prove verification condition from .b2i file"
    (Resources.provide_parse_files "boogie_file" >> (fn files =>
      Toplevel.theory (fn thy =>
        let
          val ([{lines, ...}], thy') = files thy;
          val _ = boogie_prove thy' lines;
        in thy' end)))

end;
