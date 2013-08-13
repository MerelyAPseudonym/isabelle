(*  Title:      HOL/Library/Quotient_Option.thy
    Author:     Cezary Kaliszyk and Christian Urban
*)

header {* Quotient infrastructure for the option type *}

theory Quotient_Option
imports Main Quotient_Syntax
begin

subsection {* Rules for the Quotient package *}

lemma option_rel_map1:
  "option_rel R (Option.map f x) y \<longleftrightarrow> option_rel (\<lambda>x. R (f x)) x y"
  by (simp add: option_rel_def split: option.split)

lemma option_rel_map2:
  "option_rel R x (Option.map f y) \<longleftrightarrow> option_rel (\<lambda>x y. R x (f y)) x y"
  by (simp add: option_rel_def split: option.split)

lemma option_map_id [id_simps]:
  "Option.map id = id"
  by (simp add: id_def Option.map.identity fun_eq_iff)

lemma option_rel_eq [id_simps]:
  "option_rel (op =) = (op =)"
  by (simp add: option_rel_def fun_eq_iff split: option.split)

lemma option_symp:
  "symp R \<Longrightarrow> symp (option_rel R)"
  unfolding symp_def split_option_all option_rel_simps by fast

lemma option_transp:
  "transp R \<Longrightarrow> transp (option_rel R)"
  unfolding transp_def split_option_all option_rel_simps by fast

lemma option_equivp [quot_equiv]:
  "equivp R \<Longrightarrow> equivp (option_rel R)"
  by (blast intro: equivpI reflp_option_rel option_symp option_transp elim: equivpE)

lemma option_quotient [quot_thm]:
  assumes "Quotient3 R Abs Rep"
  shows "Quotient3 (option_rel R) (Option.map Abs) (Option.map Rep)"
  apply (rule Quotient3I)
  apply (simp_all add: Option.map.compositionality comp_def Option.map.identity option_rel_eq option_rel_map1 option_rel_map2 Quotient3_abs_rep [OF assms] Quotient3_rel_rep [OF assms])
  using Quotient3_rel [OF assms]
  apply (simp add: option_rel_def split: option.split)
  done

declare [[mapQ3 option = (option_rel, option_quotient)]]

lemma option_None_rsp [quot_respect]:
  assumes q: "Quotient3 R Abs Rep"
  shows "option_rel R None None"
  by (rule None_transfer)

lemma option_Some_rsp [quot_respect]:
  assumes q: "Quotient3 R Abs Rep"
  shows "(R ===> option_rel R) Some Some"
  by (rule Some_transfer)

lemma option_None_prs [quot_preserve]:
  assumes q: "Quotient3 R Abs Rep"
  shows "Option.map Abs None = None"
  by simp

lemma option_Some_prs [quot_preserve]:
  assumes q: "Quotient3 R Abs Rep"
  shows "(Rep ---> Option.map Abs) Some = Some"
  apply(simp add: fun_eq_iff)
  apply(simp add: Quotient3_abs_rep[OF q])
  done

end
