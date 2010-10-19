(*  Title:      HOLCF/Representable.thy
    Author:     Brian Huffman
*)

header {* Representable Types *}

theory Representable
imports Algebraic Bifinite Universal Ssum One Fixrec Domain_Aux
uses
  ("Tools/repdef.ML")
  ("Tools/Domain/domain_isomorphism.ML")
begin

default_sort bifinite

subsection {* Representations of types *}

lemma emb_prj: "emb\<cdot>((prj\<cdot>x)::'a) = cast\<cdot>DEFL('a)\<cdot>x"
by (simp add: cast_DEFL)

lemma emb_prj_emb:
  fixes x :: "'a"
  assumes "DEFL('a) \<sqsubseteq> DEFL('b)"
  shows "emb\<cdot>(prj\<cdot>(emb\<cdot>x) :: 'b) = emb\<cdot>x"
unfolding emb_prj
apply (rule cast.belowD)
apply (rule monofun_cfun_arg [OF assms])
apply (simp add: cast_DEFL)
done

lemma prj_emb_prj:
  assumes "DEFL('a) \<sqsubseteq> DEFL('b)"
  shows "prj\<cdot>(emb\<cdot>(prj\<cdot>x :: 'b)) = (prj\<cdot>x :: 'a)"
 apply (rule emb_eq_iff [THEN iffD1])
 apply (simp only: emb_prj)
 apply (rule deflation_below_comp1)
   apply (rule deflation_cast)
  apply (rule deflation_cast)
 apply (rule monofun_cfun_arg [OF assms])
done

text {* Isomorphism lemmas used internally by the domain package: *}

lemma domain_abs_iso:
  fixes abs and rep
  assumes DEFL: "DEFL('b) = DEFL('a)"
  assumes abs_def: "(abs :: 'a \<rightarrow> 'b) \<equiv> prj oo emb"
  assumes rep_def: "(rep :: 'b \<rightarrow> 'a) \<equiv> prj oo emb"
  shows "rep\<cdot>(abs\<cdot>x) = x"
unfolding abs_def rep_def
by (simp add: emb_prj_emb DEFL)

lemma domain_rep_iso:
  fixes abs and rep
  assumes DEFL: "DEFL('b) = DEFL('a)"
  assumes abs_def: "(abs :: 'a \<rightarrow> 'b) \<equiv> prj oo emb"
  assumes rep_def: "(rep :: 'b \<rightarrow> 'a) \<equiv> prj oo emb"
  shows "abs\<cdot>(rep\<cdot>x) = x"
unfolding abs_def rep_def
by (simp add: emb_prj_emb DEFL)

subsection {* Proving a subtype is representable *}

text {*
  Temporarily relax type constraints for @{term emb} and @{term prj}.
*}

setup {*
  fold Sign.add_const_constraint
  [ (@{const_name defl}, SOME @{typ "'a::pcpo itself \<Rightarrow> defl"})
  , (@{const_name emb}, SOME @{typ "'a::pcpo \<rightarrow> udom"})
  , (@{const_name prj}, SOME @{typ "udom \<rightarrow> 'a::pcpo"}) ]
*}

lemma typedef_rep_class:
  fixes Rep :: "'a::pcpo \<Rightarrow> udom"
  fixes Abs :: "udom \<Rightarrow> 'a::pcpo"
  fixes t :: defl
  assumes type: "type_definition Rep Abs {x. x ::: t}"
  assumes below: "op \<sqsubseteq> \<equiv> \<lambda>x y. Rep x \<sqsubseteq> Rep y"
  assumes emb: "emb \<equiv> (\<Lambda> x. Rep x)"
  assumes prj: "prj \<equiv> (\<Lambda> x. Abs (cast\<cdot>t\<cdot>x))"
  assumes defl: "defl \<equiv> (\<lambda> a::'a itself. t)"
  shows "OFCLASS('a, bifinite_class)"
proof
  have adm: "adm (\<lambda>x. x \<in> {x. x ::: t})"
    by (simp add: adm_in_defl)
  have emb_beta: "\<And>x. emb\<cdot>x = Rep x"
    unfolding emb
    apply (rule beta_cfun)
    apply (rule typedef_cont_Rep [OF type below adm])
    done
  have prj_beta: "\<And>y. prj\<cdot>y = Abs (cast\<cdot>t\<cdot>y)"
    unfolding prj
    apply (rule beta_cfun)
    apply (rule typedef_cont_Abs [OF type below adm])
    apply simp_all
    done
  have emb_in_defl: "\<And>x::'a. emb\<cdot>x ::: t"
    using type_definition.Rep [OF type]
    by (simp add: emb_beta)
  have prj_emb: "\<And>x::'a. prj\<cdot>(emb\<cdot>x) = x"
    unfolding prj_beta
    apply (simp add: cast_fixed [OF emb_in_defl])
    apply (simp add: emb_beta type_definition.Rep_inverse [OF type])
    done
  have emb_prj: "\<And>y. emb\<cdot>(prj\<cdot>y :: 'a) = cast\<cdot>t\<cdot>y"
    unfolding prj_beta emb_beta
    by (simp add: type_definition.Abs_inverse [OF type])
  show "ep_pair (emb :: 'a \<rightarrow> udom) prj"
    apply default
    apply (simp add: prj_emb)
    apply (simp add: emb_prj cast.below)
    done
  show "cast\<cdot>DEFL('a) = emb oo (prj :: udom \<rightarrow> 'a)"
    by (rule cfun_eqI, simp add: defl emb_prj)
qed

lemma typedef_DEFL:
  assumes "defl \<equiv> (\<lambda>a::'a::pcpo itself. t)"
  shows "DEFL('a::pcpo) = t"
unfolding assms ..

text {* Restore original typing constraints. *}

setup {*
  fold Sign.add_const_constraint
  [ (@{const_name defl}, SOME @{typ "'a::bifinite itself \<Rightarrow> defl"})
  , (@{const_name emb}, SOME @{typ "'a::bifinite \<rightarrow> udom"})
  , (@{const_name prj}, SOME @{typ "udom \<rightarrow> 'a::bifinite"}) ]
*}

lemma adm_mem_Collect_in_defl: "adm (\<lambda>x. x \<in> {x. x ::: A})"
unfolding mem_Collect_eq by (rule adm_in_defl)

use "Tools/repdef.ML"

subsection {* Isomorphic deflations *}

definition
  isodefl :: "('a \<rightarrow> 'a) \<Rightarrow> defl \<Rightarrow> bool"
where
  "isodefl d t \<longleftrightarrow> cast\<cdot>t = emb oo d oo prj"

lemma isodeflI: "(\<And>x. cast\<cdot>t\<cdot>x = emb\<cdot>(d\<cdot>(prj\<cdot>x))) \<Longrightarrow> isodefl d t"
unfolding isodefl_def by (simp add: cfun_eqI)

lemma cast_isodefl: "isodefl d t \<Longrightarrow> cast\<cdot>t = (\<Lambda> x. emb\<cdot>(d\<cdot>(prj\<cdot>x)))"
unfolding isodefl_def by (simp add: cfun_eqI)

lemma isodefl_strict: "isodefl d t \<Longrightarrow> d\<cdot>\<bottom> = \<bottom>"
unfolding isodefl_def
by (drule cfun_fun_cong [where x="\<bottom>"], simp)

lemma isodefl_imp_deflation:
  fixes d :: "'a \<rightarrow> 'a"
  assumes "isodefl d t" shows "deflation d"
proof
  note assms [unfolded isodefl_def, simp]
  fix x :: 'a
  show "d\<cdot>(d\<cdot>x) = d\<cdot>x"
    using cast.idem [of t "emb\<cdot>x"] by simp
  show "d\<cdot>x \<sqsubseteq> x"
    using cast.below [of t "emb\<cdot>x"] by simp
qed

lemma isodefl_ID_DEFL: "isodefl (ID :: 'a \<rightarrow> 'a) DEFL('a)"
unfolding isodefl_def by (simp add: cast_DEFL)

lemma isodefl_DEFL_imp_ID: "isodefl (d :: 'a \<rightarrow> 'a) DEFL('a) \<Longrightarrow> d = ID"
unfolding isodefl_def
apply (simp add: cast_DEFL)
apply (simp add: cfun_eq_iff)
apply (rule allI)
apply (drule_tac x="emb\<cdot>x" in spec)
apply simp
done

lemma isodefl_bottom: "isodefl \<bottom> \<bottom>"
unfolding isodefl_def by (simp add: cfun_eq_iff)

lemma adm_isodefl:
  "cont f \<Longrightarrow> cont g \<Longrightarrow> adm (\<lambda>x. isodefl (f x) (g x))"
unfolding isodefl_def by simp

lemma isodefl_lub:
  assumes "chain d" and "chain t"
  assumes "\<And>i. isodefl (d i) (t i)"
  shows "isodefl (\<Squnion>i. d i) (\<Squnion>i. t i)"
using prems unfolding isodefl_def
by (simp add: contlub_cfun_arg contlub_cfun_fun)

lemma isodefl_fix:
  assumes "\<And>d t. isodefl d t \<Longrightarrow> isodefl (f\<cdot>d) (g\<cdot>t)"
  shows "isodefl (fix\<cdot>f) (fix\<cdot>g)"
unfolding fix_def2
apply (rule isodefl_lub, simp, simp)
apply (induct_tac i)
apply (simp add: isodefl_bottom)
apply (simp add: assms)
done

lemma isodefl_abs_rep:
  fixes abs and rep and d
  assumes DEFL: "DEFL('b) = DEFL('a)"
  assumes abs_def: "(abs :: 'a \<rightarrow> 'b) \<equiv> prj oo emb"
  assumes rep_def: "(rep :: 'b \<rightarrow> 'a) \<equiv> prj oo emb"
  shows "isodefl d t \<Longrightarrow> isodefl (abs oo d oo rep) t"
unfolding isodefl_def
by (simp add: cfun_eq_iff assms prj_emb_prj emb_prj_emb)

lemma isodefl_cfun:
  "isodefl d1 t1 \<Longrightarrow> isodefl d2 t2 \<Longrightarrow>
    isodefl (cfun_map\<cdot>d1\<cdot>d2) (cfun_defl\<cdot>t1\<cdot>t2)"
apply (rule isodeflI)
apply (simp add: cast_cfun_defl cast_isodefl)
apply (simp add: emb_cfun_def prj_cfun_def)
apply (simp add: cfun_map_map cfcomp1)
done

lemma isodefl_ssum:
  "isodefl d1 t1 \<Longrightarrow> isodefl d2 t2 \<Longrightarrow>
    isodefl (ssum_map\<cdot>d1\<cdot>d2) (ssum_defl\<cdot>t1\<cdot>t2)"
apply (rule isodeflI)
apply (simp add: cast_ssum_defl cast_isodefl)
apply (simp add: emb_ssum_def prj_ssum_def)
apply (simp add: ssum_map_map isodefl_strict)
done

lemma isodefl_sprod:
  "isodefl d1 t1 \<Longrightarrow> isodefl d2 t2 \<Longrightarrow>
    isodefl (sprod_map\<cdot>d1\<cdot>d2) (sprod_defl\<cdot>t1\<cdot>t2)"
apply (rule isodeflI)
apply (simp add: cast_sprod_defl cast_isodefl)
apply (simp add: emb_sprod_def prj_sprod_def)
apply (simp add: sprod_map_map isodefl_strict)
done

lemma isodefl_cprod:
  "isodefl d1 t1 \<Longrightarrow> isodefl d2 t2 \<Longrightarrow>
    isodefl (cprod_map\<cdot>d1\<cdot>d2) (prod_defl\<cdot>t1\<cdot>t2)"
apply (rule isodeflI)
apply (simp add: cast_prod_defl cast_isodefl)
apply (simp add: emb_prod_def prj_prod_def)
apply (simp add: cprod_map_map cfcomp1)
done

lemma isodefl_u:
  "isodefl d t \<Longrightarrow> isodefl (u_map\<cdot>d) (u_defl\<cdot>t)"
apply (rule isodeflI)
apply (simp add: cast_u_defl cast_isodefl)
apply (simp add: emb_u_def prj_u_def)
apply (simp add: u_map_map)
done

subsection {* Constructing Domain Isomorphisms *}

use "Tools/Domain/domain_isomorphism.ML"

setup {*
  fold Domain_Isomorphism.add_type_constructor
    [(@{type_name cfun}, @{term cfun_defl}, @{const_name cfun_map}, @{thm DEFL_cfun},
        @{thm isodefl_cfun}, @{thm cfun_map_ID}, @{thm deflation_cfun_map}),

     (@{type_name ssum}, @{term ssum_defl}, @{const_name ssum_map}, @{thm DEFL_ssum},
        @{thm isodefl_ssum}, @{thm ssum_map_ID}, @{thm deflation_ssum_map}),

     (@{type_name sprod}, @{term sprod_defl}, @{const_name sprod_map}, @{thm DEFL_sprod},
        @{thm isodefl_sprod}, @{thm sprod_map_ID}, @{thm deflation_sprod_map}),

     (@{type_name prod}, @{term cprod_defl}, @{const_name cprod_map}, @{thm DEFL_prod},
        @{thm isodefl_cprod}, @{thm cprod_map_ID}, @{thm deflation_cprod_map}),

     (@{type_name "u"}, @{term u_defl}, @{const_name u_map}, @{thm DEFL_u},
        @{thm isodefl_u}, @{thm u_map_ID}, @{thm deflation_u_map})]
*}

end
