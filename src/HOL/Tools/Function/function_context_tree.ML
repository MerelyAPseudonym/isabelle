(*  Title:      HOL/Tools/Function/function_context_tree.ML
    Author:     Alexander Krauss, TU Muenchen

Construction and traversal of trees of nested contexts along a term.
*)

signature FUNCTION_CONTEXT_TREE =
sig
  (* poor man's contexts: fixes + assumes *)
  type ctxt = (string * typ) list * thm list
  type ctx_tree

  (* FIXME: This interface is a mess and needs to be cleaned up! *)
  val get_function_congs : Proof.context -> thm list
  val add_function_cong : thm -> Context.generic -> Context.generic
  val map_function_congs : (thm list -> thm list) -> Context.generic -> Context.generic

  val cong_add: attribute
  val cong_del: attribute

  val mk_tree: (string * typ) -> term -> Proof.context -> term -> ctx_tree

  val inst_tree: theory -> term -> term -> ctx_tree -> ctx_tree

  val export_term : ctxt -> term -> term
  val export_thm : theory -> ctxt -> thm -> thm
  val import_thm : theory -> ctxt -> thm -> thm

  val traverse_tree :
   (ctxt -> term ->
   (ctxt * thm) list ->
   (ctxt * thm) list * 'b ->
   (ctxt * thm) list * 'b)
   -> ctx_tree -> 'b -> 'b

  val rewrite_by_tree : Proof.context -> term -> thm -> (thm * thm) list ->
    ctx_tree -> thm * (thm * thm) list
end

structure Function_Context_Tree : FUNCTION_CONTEXT_TREE =
struct

type ctxt = (string * typ) list * thm list

open Function_Common
open Function_Lib

structure FunctionCongs = Generic_Data
(
  type T = thm list
  val empty = []
  val extend = I
  val merge = Thm.merge_thms
);

val get_function_congs = FunctionCongs.get o Context.Proof
val map_function_congs = FunctionCongs.map
val add_function_cong = FunctionCongs.map o Thm.add_thm

(* congruence rules *)

val cong_add = Thm.declaration_attribute (map_function_congs o Thm.add_thm o safe_mk_meta_eq);
val cong_del = Thm.declaration_attribute (map_function_congs o Thm.del_thm o safe_mk_meta_eq);


type depgraph = int Int_Graph.T

datatype ctx_tree =
  Leaf of term
  | Cong of (thm * depgraph * (ctxt * ctx_tree) list)
  | RCall of (term * ctx_tree)


(* Maps "Trueprop A = B" to "A" *)
val rhs_of = snd o HOLogic.dest_eq o HOLogic.dest_Trueprop


(*** Dependency analysis for congruence rules ***)

fun branch_vars t =
  let
    val t' = snd (dest_all_all t)
    val (assumes, concl) = Logic.strip_horn t'
  in
    (fold Term.add_vars assumes [], Term.add_vars concl [])
  end

fun cong_deps crule =
  let
    val num_branches = map_index (apsnd branch_vars) (prems_of crule)
  in
    Int_Graph.empty
    |> fold (fn (i,_)=> Int_Graph.new_node (i,i)) num_branches
    |> fold_product (fn (i, (c1, _)) => fn (j, (_, t2)) =>
         if i = j orelse null (inter (op =) c1 t2)
         then I else Int_Graph.add_edge_acyclic (i,j))
       num_branches num_branches
    end

val default_congs =
  map (fn c => c RS eq_reflection) [@{thm "cong"}, @{thm "ext"}]

(* Called on the INSTANTIATED branches of the congruence rule *)
fun mk_branch ctxt t =
  let
    val ((params, impl), ctxt') = Variable.focus t ctxt
    val (assms, concl) = Logic.strip_horn impl
  in
    (ctxt', map #2 params, assms, rhs_of concl)
  end

fun find_cong_rule ctxt fvar h ((r,dep)::rs) t =
     (let
        val thy = Proof_Context.theory_of ctxt

        val tt' = Logic.mk_equals (Pattern.rewrite_term thy [(Free fvar, h)] [] t, t)
        val (c, subs) = (concl_of r, prems_of r)

        val subst =
          Pattern.match (Proof_Context.theory_of ctxt) (c, tt') (Vartab.empty, Vartab.empty)
        val branches = map (mk_branch ctxt o Envir.beta_norm o Envir.subst_term subst) subs
        val inst = map (fn v =>
            (cterm_of thy (Var v), cterm_of thy (Envir.subst_term subst (Var v))))
          (Term.add_vars c [])
      in
         (cterm_instantiate inst r, dep, branches)
      end
      handle Pattern.MATCH => find_cong_rule ctxt fvar h rs t)
  | find_cong_rule _ _ _ [] _ = raise General.Fail "No cong rule found!"


fun mk_tree fvar h ctxt t =
  let
    val congs = get_function_congs ctxt

    (* FIXME: Save in theory: *)
    val congs_deps = map (fn c => (c, cong_deps c)) (congs @ default_congs)

    fun matchcall (a $ b) = if a = Free fvar then SOME b else NONE
      | matchcall _ = NONE

    fun mk_tree' ctxt t =
      case matchcall t of
        SOME arg => RCall (t, mk_tree' ctxt arg)
      | NONE =>
        if not (exists_subterm (fn Free v => v = fvar | _ => false) t) then Leaf t
        else
          let
            val (r, dep, branches) = find_cong_rule ctxt fvar h congs_deps t
            fun subtree (ctxt', fixes, assumes, st) =
              ((fixes,
                map (Thm.assume o cterm_of (Proof_Context.theory_of ctxt)) assumes),
               mk_tree' ctxt' st)
          in
            Cong (r, dep, map subtree branches)
          end
  in
    mk_tree' ctxt t
  end

fun inst_tree thy fvar f tr =
  let
    val cfvar = cterm_of thy fvar
    val cf = cterm_of thy f

    fun inst_term t =
      subst_bound(f, abstract_over (fvar, t))

    val inst_thm = Thm.forall_elim cf o Thm.forall_intr cfvar

    fun inst_tree_aux (Leaf t) = Leaf t
      | inst_tree_aux (Cong (crule, deps, branches)) =
        Cong (inst_thm crule, deps, map inst_branch branches)
      | inst_tree_aux (RCall (t, str)) =
        RCall (inst_term t, inst_tree_aux str)
    and inst_branch ((fxs, assms), str) =
      ((fxs, map (Thm.assume o cterm_of thy o inst_term o prop_of) assms),
       inst_tree_aux str)
  in
    inst_tree_aux tr
  end


(* Poor man's contexts: Only fixes and assumes *)
fun compose (fs1, as1) (fs2, as2) = (fs1 @ fs2, as1 @ as2)

fun export_term (fixes, assumes) =
 fold_rev (curry Logic.mk_implies o prop_of) assumes
 #> fold_rev (Logic.all o Free) fixes

fun export_thm thy (fixes, assumes) =
 fold_rev (Thm.implies_intr o cprop_of) assumes
 #> fold_rev (Thm.forall_intr o cterm_of thy o Free) fixes

fun import_thm thy (fixes, athms) =
 fold (Thm.forall_elim o cterm_of thy o Free) fixes
 #> fold Thm.elim_implies athms


(* folds in the order of the dependencies of a graph. *)
fun fold_deps G f x =
  let
    fun fill_table i (T, x) =
      case Inttab.lookup T i of
        SOME _ => (T, x)
      | NONE =>
        let
          val (T', x') = Int_Graph.Keys.fold fill_table (Int_Graph.imm_succs G i) (T, x)
          val (v, x'') = f (the o Inttab.lookup T') i x'
        in
          (Inttab.update (i, v) T', x'')
        end

    val (T, x) = fold fill_table (Int_Graph.keys G) (Inttab.empty, x)
  in
    (Inttab.fold (cons o snd) T [], x)
  end

fun traverse_tree rcOp tr =
  let
    fun traverse_help ctxt (Leaf _) _ x = ([], x)
      | traverse_help ctxt (RCall (t, st)) u x =
          rcOp ctxt t u (traverse_help ctxt st u x)
      | traverse_help ctxt (Cong (_, deps, branches)) u x =
          let
            fun sub_step lu i x =
              let
                val (ctxt', subtree) = nth branches i
                val used = Int_Graph.Keys.fold_rev (append o lu) (Int_Graph.imm_succs deps i) u
                val (subs, x') = traverse_help (compose ctxt ctxt') subtree used x
                val exported_subs = map (apfst (compose ctxt')) subs (* FIXME: Right order of composition? *)
              in
                (exported_subs, x')
              end
          in
            fold_deps deps sub_step x
            |> apfst flat
          end
  in
    snd o traverse_help ([], []) tr []
  end

fun rewrite_by_tree ctxt h ih x tr =
  let
    val thy = Proof_Context.theory_of ctxt
    fun rewrite_help _ _ x (Leaf t) = (Thm.reflexive (cterm_of thy t), x)
      | rewrite_help fix h_as x (RCall (_ $ arg, st)) =
        let
          val (inner, (lRi,ha)::x') = rewrite_help fix h_as x st (* "a' = a" *)

          val iha = import_thm thy (fix, h_as) ha (* (a', h a') : G *)
            |> Conv.fconv_rule (Conv.arg_conv (Conv.comb_conv (Conv.arg_conv (K inner))))
                                                    (* (a, h a) : G   *)
          val inst_ih = instantiate' [] [SOME (cterm_of thy arg)] ih
          val eq = Thm.implies_elim (Thm.implies_elim inst_ih lRi) iha (* h a = f a *)

          val h_a'_eq_h_a = Thm.combination (Thm.reflexive (cterm_of thy h)) inner
          val h_a_eq_f_a = eq RS eq_reflection
          val result = Thm.transitive h_a'_eq_h_a h_a_eq_f_a
        in
          (result, x')
        end
      | rewrite_help fix h_as x (Cong (crule, deps, branches)) =
        let
          fun sub_step lu i x =
            let
              val ((fixes, assumes), st) = nth branches i
              val used = map lu (Int_Graph.immediate_succs deps i)
                |> map (fn u_eq => (u_eq RS sym) RS eq_reflection)
                |> filter_out Thm.is_reflexive

              val assumes' = map (simplify (put_simpset HOL_basic_ss  ctxt addsimps used)) assumes

              val (subeq, x') =
                rewrite_help (fix @ fixes) (h_as @ assumes') x st
              val subeq_exp =
                export_thm thy (fixes, assumes) (subeq RS meta_eq_to_obj_eq)
            in
              (subeq_exp, x')
            end
          val (subthms, x') = fold_deps deps sub_step x
        in
          (fold_rev (curry op COMP) subthms crule, x')
        end
  in
    rewrite_help [] [] x tr
  end

end
