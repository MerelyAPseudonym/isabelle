(*  Title:      HOL/Library/Old_Recdef.thy
    Author:     Konrad Slind and Markus Wenzel, TU Muenchen
*)

section {* TFL: recursive function definitions *}

theory Old_Recdef
imports Main
keywords
  "recdef" "defer_recdef" :: thy_decl and
  "recdef_tc" :: thy_goal and
  "permissive" "congs" "hints"
begin

subsection {* Lemmas for TFL *}

lemma tfl_wf_induct: "ALL R. wf R -->  
       (ALL P. (ALL x. (ALL y. (y,x):R --> P y) --> P x) --> (ALL x. P x))"
apply clarify
apply (rule_tac r = R and P = P and a = x in wf_induct, assumption, blast)
done

lemma tfl_cut_def: "cut f r x \<equiv> (\<lambda>y. if (y,x) \<in> r then f y else undefined)"
  unfolding cut_def .

lemma tfl_cut_apply: "ALL f R. (x,a):R --> (cut f R a)(x) = f(x)"
apply clarify
apply (rule cut_apply, assumption)
done

lemma tfl_wfrec:
     "ALL M R f. (f=wfrec R M) --> wf R --> (ALL x. f x = M (cut f R x) x)"
apply clarify
apply (erule wfrec)
done

lemma tfl_eq_True: "(x = True) --> x"
  by blast

lemma tfl_rev_eq_mp: "(x = y) --> y --> x"
  by blast

lemma tfl_simp_thm: "(x --> y) --> (x = x') --> (x' --> y)"
  by blast

lemma tfl_P_imp_P_iff_True: "P ==> P = True"
  by blast

lemma tfl_imp_trans: "(A --> B) ==> (B --> C) ==> (A --> C)"
  by blast

lemma tfl_disj_assoc: "(a \<or> b) \<or> c == a \<or> (b \<or> c)"
  by simp

lemma tfl_disjE: "P \<or> Q ==> P --> R ==> Q --> R ==> R"
  by blast

lemma tfl_exE: "\<exists>x. P x ==> \<forall>x. P x --> Q ==> Q"
  by blast

ML_file "~~/src/HOL/Tools/TFL/casesplit.ML"
ML_file "~~/src/HOL/Tools/TFL/utils.ML"
ML_file "~~/src/HOL/Tools/TFL/usyntax.ML"
ML_file "~~/src/HOL/Tools/TFL/dcterm.ML"
ML_file "~~/src/HOL/Tools/TFL/thms.ML"
ML_file "~~/src/HOL/Tools/TFL/rules.ML"
ML_file "~~/src/HOL/Tools/TFL/thry.ML"
ML_file "~~/src/HOL/Tools/TFL/tfl.ML"
ML_file "~~/src/HOL/Tools/TFL/post.ML"
ML_file "~~/src/HOL/Tools/recdef.ML"


subsection {* Rule setup *}

lemmas [recdef_simp] =
  inv_image_def
  measure_def
  lex_prod_def
  same_fst_def
  less_Suc_eq [THEN iffD2]

lemmas [recdef_cong] =
  if_cong let_cong image_cong INF_cong SUP_cong bex_cong ball_cong imp_cong
  map_cong filter_cong takeWhile_cong dropWhile_cong foldl_cong foldr_cong 

lemmas [recdef_wf] =
  wf_trancl
  wf_less_than
  wf_lex_prod
  wf_inv_image
  wf_measure
  wf_measures
  wf_pred_nat
  wf_same_fst
  wf_empty

end
