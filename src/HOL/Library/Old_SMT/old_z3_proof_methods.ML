(*  Title:      HOL/Library/Old_SMT/old_z3_proof_methods.ML
    Author:     Sascha Boehme, TU Muenchen

Proof methods for Z3 proof reconstruction.
*)

signature OLD_Z3_PROOF_METHODS =
sig
  val prove_injectivity: Proof.context -> cterm -> thm
  val prove_ite: Proof.context -> cterm -> thm
end

structure Old_Z3_Proof_Methods: OLD_Z3_PROOF_METHODS =
struct


fun apply tac st =
  (case Seq.pull (tac 1 st) of
    NONE => raise THM ("tactic failed", 1, [st])
  | SOME (st', _) => st')



(* if-then-else *)

val pull_ite = mk_meta_eq
  @{lemma "f (if P then x else y) = (if P then f x else f y)" by simp}

fun pull_ites_conv ct =
  (Conv.rewr_conv pull_ite then_conv
   Conv.binop_conv (Conv.try_conv pull_ites_conv)) ct

fun prove_ite ctxt =
  Old_Z3_Proof_Tools.by_tac ctxt (
    CONVERSION (Conv.arg_conv (Conv.arg1_conv pull_ites_conv))
    THEN' rtac @{thm refl})



(* injectivity *)

local

val B = @{typ bool}
fun mk_univ T = Const (@{const_name top}, HOLogic.mk_setT T)
fun mk_inj_on T U =
  Const (@{const_name inj_on}, (T --> U) --> HOLogic.mk_setT T --> B)
fun mk_inv_into T U =
  Const (@{const_name inv_into}, [HOLogic.mk_setT T, T --> U, U] ---> T)

fun mk_inv_of ctxt ct =
  let
    val (dT, rT) = Term.dest_funT (Old_SMT_Utils.typ_of ct)
    val inv = Old_SMT_Utils.certify ctxt (mk_inv_into dT rT)
    val univ = Old_SMT_Utils.certify ctxt (mk_univ dT)
  in Thm.mk_binop inv univ ct end

fun mk_inj_prop ctxt ct =
  let
    val (dT, rT) = Term.dest_funT (Old_SMT_Utils.typ_of ct)
    val inj = Old_SMT_Utils.certify ctxt (mk_inj_on dT rT)
    val univ = Old_SMT_Utils.certify ctxt (mk_univ dT)
  in Old_SMT_Utils.mk_cprop (Thm.mk_binop inj ct univ) end


val disjE = @{lemma "~P | Q ==> P ==> Q" by fast}

fun prove_inj_prop ctxt def lhs =
  let
    val (ct, ctxt') = Old_SMT_Utils.dest_all_cabs (Thm.rhs_of def) ctxt
    val rule = disjE OF [Object_Logic.rulify ctxt' (Thm.assume lhs)]
  in
    Goal.init (mk_inj_prop ctxt' (Thm.dest_arg ct))
    |> apply (rtac @{thm injI})
    |> apply (Tactic.solve_tac [rule, rule RS @{thm sym}])
    |> Goal.norm_result ctxt' o Goal.finish ctxt'
    |> singleton (Variable.export ctxt' ctxt)
  end

fun prove_rhs ctxt def lhs =
  Old_Z3_Proof_Tools.by_tac ctxt (
    CONVERSION (Conv.top_sweep_conv (K (Conv.rewr_conv def)) ctxt)
    THEN' REPEAT_ALL_NEW (match_tac ctxt @{thms allI})
    THEN' rtac (@{thm inv_f_f} OF [prove_inj_prop ctxt def lhs]))


fun expand thm ct =
  let
    val cpat = Thm.dest_arg (Thm.rhs_of thm)
    val (cl, cr) = Thm.dest_binop (Thm.dest_arg (Thm.dest_arg1 ct))
    val thm1 = Thm.instantiate (Thm.match (cpat, cl)) thm
    val thm2 = Thm.instantiate (Thm.match (cpat, cr)) thm
  in Conv.arg_conv (Conv.binop_conv (Conv.rewrs_conv [thm1, thm2])) ct end

fun prove_lhs ctxt rhs =
  let
    val eq = Thm.symmetric (mk_meta_eq (Object_Logic.rulify ctxt (Thm.assume rhs)))
    val conv = Old_SMT_Utils.binders_conv (K (expand eq)) ctxt
  in
    Old_Z3_Proof_Tools.by_tac ctxt (
      CONVERSION (Old_SMT_Utils.prop_conv conv)
      THEN' Simplifier.simp_tac (put_simpset HOL_ss ctxt))
  end


fun mk_inv_def ctxt rhs =
  let
    val (ct, ctxt') =
      Old_SMT_Utils.dest_all_cbinders (Old_SMT_Utils.dest_cprop rhs) ctxt
    val (cl, cv) = Thm.dest_binop ct
    val (cg, (cargs, cf)) = Drule.strip_comb cl ||> split_last
    val cu = fold_rev Thm.lambda cargs (mk_inv_of ctxt' (Thm.lambda cv cf))
  in Thm.assume (Old_SMT_Utils.mk_cequals cg cu) end

fun prove_inj_eq ctxt ct =
  let
    val (lhs, rhs) =
      apply2 Old_SMT_Utils.mk_cprop (Thm.dest_binop (Old_SMT_Utils.dest_cprop ct))
    val lhs_thm = Thm.implies_intr rhs (prove_lhs ctxt rhs lhs)
    val rhs_thm =
      Thm.implies_intr lhs (prove_rhs ctxt (mk_inv_def ctxt rhs) lhs rhs)
  in lhs_thm COMP (rhs_thm COMP @{thm iffI}) end


val swap_eq_thm = mk_meta_eq @{thm eq_commute}
val swap_disj_thm = mk_meta_eq @{thm disj_commute}

fun swap_conv dest eq =
  Old_SMT_Utils.if_true_conv ((op <) o apply2 Term.size_of_term o dest)
    (Conv.rewr_conv eq)

val swap_eq_conv = swap_conv HOLogic.dest_eq swap_eq_thm
val swap_disj_conv = swap_conv Old_SMT_Utils.dest_disj swap_disj_thm

fun norm_conv ctxt =
  swap_eq_conv then_conv
  Conv.arg1_conv (Old_SMT_Utils.binders_conv (K swap_disj_conv) ctxt) then_conv
  Conv.arg_conv (Old_SMT_Utils.binders_conv (K swap_eq_conv) ctxt)

in

fun prove_injectivity ctxt =
  Old_Z3_Proof_Tools.by_tac ctxt (
    CONVERSION (Old_SMT_Utils.prop_conv (norm_conv ctxt))
    THEN' CSUBGOAL (uncurry (rtac o prove_inj_eq ctxt)))

end

end
