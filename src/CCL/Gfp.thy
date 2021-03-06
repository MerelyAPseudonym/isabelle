(*  Title:      CCL/Gfp.thy
    Author:     Lawrence C Paulson, Cambridge University Computer Laboratory
    Copyright   1992  University of Cambridge
*)

section {* Greatest fixed points *}

theory Gfp
imports Lfp
begin

definition
  gfp :: "['a set\<Rightarrow>'a set] \<Rightarrow> 'a set" where -- "greatest fixed point"
  "gfp(f) == Union({u. u <= f(u)})"

(* gfp(f) is the least upper bound of {u. u <= f(u)} *)

lemma gfp_upperbound: "A <= f(A) \<Longrightarrow> A <= gfp(f)"
  unfolding gfp_def by blast

lemma gfp_least: "(\<And>u. u <= f(u) \<Longrightarrow> u <= A) \<Longrightarrow> gfp(f) <= A"
  unfolding gfp_def by blast

lemma gfp_lemma2: "mono(f) \<Longrightarrow> gfp(f) <= f(gfp(f))"
  by (rule gfp_least, rule subset_trans, assumption, erule monoD,
    rule gfp_upperbound, assumption)

lemma gfp_lemma3: "mono(f) \<Longrightarrow> f(gfp(f)) <= gfp(f)"
  by (rule gfp_upperbound, frule monoD, rule gfp_lemma2, assumption+)

lemma gfp_Tarski: "mono(f) \<Longrightarrow> gfp(f) = f(gfp(f))"
  by (rule equalityI gfp_lemma2 gfp_lemma3 | assumption)+


(*** Coinduction rules for greatest fixed points ***)

(*weak version*)
lemma coinduct: "\<lbrakk>a: A;  A <= f(A)\<rbrakk> \<Longrightarrow> a : gfp(f)"
  by (blast dest: gfp_upperbound)

lemma coinduct2_lemma: "\<lbrakk>A <= f(A) Un gfp(f); mono(f)\<rbrakk> \<Longrightarrow> A Un gfp(f) <= f(A Un gfp(f))"
  apply (rule subset_trans)
   prefer 2
   apply (erule mono_Un)
  apply (rule subst, erule gfp_Tarski)
  apply (erule Un_least)
  apply (rule Un_upper2)
  done

(*strong version, thanks to Martin Coen*)
lemma coinduct2: "\<lbrakk>a: A; A <= f(A) Un gfp(f); mono(f)\<rbrakk> \<Longrightarrow> a : gfp(f)"
  apply (rule coinduct)
   prefer 2
   apply (erule coinduct2_lemma, assumption)
  apply blast
  done

(***  Even Stronger version of coinduct  [by Martin Coen]
         - instead of the condition  A <= f(A)
                           consider  A <= (f(A) Un f(f(A)) ...) Un gfp(A) ***)

lemma coinduct3_mono_lemma: "mono(f) \<Longrightarrow> mono(\<lambda>x. f(x) Un A Un B)"
  by (rule monoI) (blast dest: monoD)

lemma coinduct3_lemma:
  assumes prem: "A <= f(lfp(\<lambda>x. f(x) Un A Un gfp(f)))"
    and mono: "mono(f)"
  shows "lfp(\<lambda>x. f(x) Un A Un gfp(f)) <= f(lfp(\<lambda>x. f(x) Un A Un gfp(f)))"
  apply (rule subset_trans)
   apply (rule mono [THEN coinduct3_mono_lemma, THEN lfp_lemma3])
  apply (rule Un_least [THEN Un_least])
    apply (rule subset_refl)
   apply (rule prem)
  apply (rule mono [THEN gfp_Tarski, THEN equalityD1, THEN subset_trans])
  apply (rule mono [THEN monoD])
  apply (subst mono [THEN coinduct3_mono_lemma, THEN lfp_Tarski])
  apply (rule Un_upper2)
  done

lemma coinduct3:
  assumes 1: "a:A"
    and 2: "A <= f(lfp(\<lambda>x. f(x) Un A Un gfp(f)))"
    and 3: "mono(f)"
  shows "a : gfp(f)"
  apply (rule coinduct)
   prefer 2
   apply (rule coinduct3_lemma [OF 2 3])
  apply (subst lfp_Tarski [OF coinduct3_mono_lemma, OF 3])
  using 1 apply blast
  done


subsection {* Definition forms of @{text "gfp_Tarski"}, to control unfolding *}

lemma def_gfp_Tarski: "\<lbrakk>h == gfp(f); mono(f)\<rbrakk> \<Longrightarrow> h = f(h)"
  apply unfold
  apply (erule gfp_Tarski)
  done

lemma def_coinduct: "\<lbrakk>h == gfp(f); a:A; A <= f(A)\<rbrakk> \<Longrightarrow> a: h"
  apply unfold
  apply (erule coinduct)
  apply assumption
  done

lemma def_coinduct2: "\<lbrakk>h == gfp(f); a:A; A <= f(A) Un h; mono(f)\<rbrakk> \<Longrightarrow> a: h"
  apply unfold
  apply (erule coinduct2)
   apply assumption
  apply assumption
  done

lemma def_coinduct3: "\<lbrakk>h == gfp(f); a:A; A <= f(lfp(\<lambda>x. f(x) Un A Un h)); mono(f)\<rbrakk> \<Longrightarrow> a: h"
  apply unfold
  apply (erule coinduct3)
   apply assumption
  apply assumption
  done

(*Monotonicity of gfp!*)
lemma gfp_mono: "\<lbrakk>mono(f); \<And>Z. f(Z) <= g(Z)\<rbrakk> \<Longrightarrow> gfp(f) <= gfp(g)"
  apply (rule gfp_upperbound)
  apply (rule subset_trans)
   apply (rule gfp_lemma2)
   apply assumption
  apply (erule meta_spec)
  done

end
