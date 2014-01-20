(*  Title:      HOL/BNF/Basic_BNFs.thy
    Author:     Dmitriy Traytel, TU Muenchen
    Author:     Andrei Popescu, TU Muenchen
    Author:     Jasmin Blanchette, TU Muenchen
    Copyright   2012

Registration of basic types as bounded natural functors.
*)

header {* Registration of Basic Types as Bounded Natural Functors *}

theory Basic_BNFs
imports BNF_Def
   (*FIXME: define relators here, reuse in Lifting_* once this theory is in HOL*)
  Lifting_Sum
  Lifting_Product
  Main
begin

bnf ID: 'a
  map: "id :: ('a \<Rightarrow> 'b) \<Rightarrow> 'a \<Rightarrow> 'b"
  sets: "\<lambda>x. {x}"
  bd: natLeq
  rel: "id :: ('a \<Rightarrow> 'b \<Rightarrow> bool) \<Rightarrow> 'a \<Rightarrow> 'b \<Rightarrow> bool"
apply (auto simp: Grp_def fun_eq_iff relcompp.simps natLeq_card_order natLeq_cinfinite)
apply (rule ordLess_imp_ordLeq[OF finite_ordLess_infinite[OF _ natLeq_Well_order]])
apply (auto simp add: Field_card_of Field_natLeq card_of_well_order_on)[3]
done

bnf DEADID: 'a
  map: "id :: 'a \<Rightarrow> 'a"
  bd: "natLeq +c |UNIV :: 'a set|"
  rel: "op = :: 'a \<Rightarrow> 'a \<Rightarrow> bool"
by (auto simp add: Grp_def
  card_order_csum natLeq_card_order card_of_card_order_on
  cinfinite_csum natLeq_cinfinite)

definition setl :: "'a + 'b \<Rightarrow> 'a set" where
"setl x = (case x of Inl z => {z} | _ => {})"

definition setr :: "'a + 'b \<Rightarrow> 'b set" where
"setr x = (case x of Inr z => {z} | _ => {})"

lemmas sum_set_defs = setl_def[abs_def] setr_def[abs_def]

bnf "'a + 'b"
  map: sum_map
  sets: setl setr
  bd: natLeq
  wits: Inl Inr
  rel: sum_rel
proof -
  show "sum_map id id = id" by (rule sum_map.id)
next
  fix f1 :: "'o \<Rightarrow> 's" and f2 :: "'p \<Rightarrow> 't" and g1 :: "'s \<Rightarrow> 'q" and g2 :: "'t \<Rightarrow> 'r"
  show "sum_map (g1 o f1) (g2 o f2) = sum_map g1 g2 o sum_map f1 f2"
    by (rule sum_map.comp[symmetric])
next
  fix x and f1 :: "'o \<Rightarrow> 'q" and f2 :: "'p \<Rightarrow> 'r" and g1 g2
  assume a1: "\<And>z. z \<in> setl x \<Longrightarrow> f1 z = g1 z" and
         a2: "\<And>z. z \<in> setr x \<Longrightarrow> f2 z = g2 z"
  thus "sum_map f1 f2 x = sum_map g1 g2 x"
  proof (cases x)
    case Inl thus ?thesis using a1 by (clarsimp simp: setl_def)
  next
    case Inr thus ?thesis using a2 by (clarsimp simp: setr_def)
  qed
next
  fix f1 :: "'o \<Rightarrow> 'q" and f2 :: "'p \<Rightarrow> 'r"
  show "setl o sum_map f1 f2 = image f1 o setl"
    by (rule ext, unfold o_apply) (simp add: setl_def split: sum.split)
next
  fix f1 :: "'o \<Rightarrow> 'q" and f2 :: "'p \<Rightarrow> 'r"
  show "setr o sum_map f1 f2 = image f2 o setr"
    by (rule ext, unfold o_apply) (simp add: setr_def split: sum.split)
next
  show "card_order natLeq" by (rule natLeq_card_order)
next
  show "cinfinite natLeq" by (rule natLeq_cinfinite)
next
  fix x :: "'o + 'p"
  show "|setl x| \<le>o natLeq"
    apply (rule ordLess_imp_ordLeq)
    apply (rule finite_iff_ordLess_natLeq[THEN iffD1])
    by (simp add: setl_def split: sum.split)
next
  fix x :: "'o + 'p"
  show "|setr x| \<le>o natLeq"
    apply (rule ordLess_imp_ordLeq)
    apply (rule finite_iff_ordLess_natLeq[THEN iffD1])
    by (simp add: setr_def split: sum.split)
next
  fix R1 R2 S1 S2
  show "sum_rel R1 R2 OO sum_rel S1 S2 \<le> sum_rel (R1 OO S1) (R2 OO S2)"
    by (auto simp: sum_rel_def split: sum.splits)
next
  fix R S
  show "sum_rel R S =
        (Grp {x. setl x \<subseteq> Collect (split R) \<and> setr x \<subseteq> Collect (split S)} (sum_map fst fst))\<inverse>\<inverse> OO
        Grp {x. setl x \<subseteq> Collect (split R) \<and> setr x \<subseteq> Collect (split S)} (sum_map snd snd)"
  unfolding setl_def setr_def sum_rel_def Grp_def relcompp.simps conversep.simps fun_eq_iff
  by (fastforce split: sum.splits)
qed (auto simp: sum_set_defs)

definition fsts :: "'a \<times> 'b \<Rightarrow> 'a set" where
"fsts x = {fst x}"

definition snds :: "'a \<times> 'b \<Rightarrow> 'b set" where
"snds x = {snd x}"

lemmas prod_set_defs = fsts_def[abs_def] snds_def[abs_def]

bnf "'a \<times> 'b"
  map: map_pair
  sets: fsts snds
  bd: natLeq
  rel: prod_rel
proof (unfold prod_set_defs)
  show "map_pair id id = id" by (rule map_pair.id)
next
  fix f1 f2 g1 g2
  show "map_pair (g1 o f1) (g2 o f2) = map_pair g1 g2 o map_pair f1 f2"
    by (rule map_pair.comp[symmetric])
next
  fix x f1 f2 g1 g2
  assume "\<And>z. z \<in> {fst x} \<Longrightarrow> f1 z = g1 z" "\<And>z. z \<in> {snd x} \<Longrightarrow> f2 z = g2 z"
  thus "map_pair f1 f2 x = map_pair g1 g2 x" by (cases x) simp
next
  fix f1 f2
  show "(\<lambda>x. {fst x}) o map_pair f1 f2 = image f1 o (\<lambda>x. {fst x})"
    by (rule ext, unfold o_apply) simp
next
  fix f1 f2
  show "(\<lambda>x. {snd x}) o map_pair f1 f2 = image f2 o (\<lambda>x. {snd x})"
    by (rule ext, unfold o_apply) simp
next
  show "card_order natLeq" by (rule natLeq_card_order)
next
  show "cinfinite natLeq" by (rule natLeq_cinfinite)
next
  fix x
  show "|{fst x}| \<le>o natLeq"
    by (metis ordLess_imp_ordLeq finite_iff_ordLess_natLeq finite.emptyI finite_insert)
next
  fix x
  show "|{snd x}| \<le>o natLeq"
    by (metis ordLess_imp_ordLeq finite_iff_ordLess_natLeq finite.emptyI finite_insert)
next
  fix R1 R2 S1 S2
  show "prod_rel R1 R2 OO prod_rel S1 S2 \<le> prod_rel (R1 OO S1) (R2 OO S2)" by auto
next
  fix R S
  show "prod_rel R S =
        (Grp {x. {fst x} \<subseteq> Collect (split R) \<and> {snd x} \<subseteq> Collect (split S)} (map_pair fst fst))\<inverse>\<inverse> OO
        Grp {x. {fst x} \<subseteq> Collect (split R) \<and> {snd x} \<subseteq> Collect (split S)} (map_pair snd snd)"
  unfolding prod_set_defs prod_rel_def Grp_def relcompp.simps conversep.simps fun_eq_iff
  by auto
qed

bnf "'a \<Rightarrow> 'b"
  map: "op \<circ>"
  sets: range
  bd: "natLeq +c |UNIV :: 'a set|"
  rel: "fun_rel op ="
proof
  fix f show "id \<circ> f = id f" by simp
next
  fix f g show "op \<circ> (g \<circ> f) = op \<circ> g \<circ> op \<circ> f"
  unfolding comp_def[abs_def] ..
next
  fix x f g
  assume "\<And>z. z \<in> range x \<Longrightarrow> f z = g z"
  thus "f \<circ> x = g \<circ> x" by auto
next
  fix f show "range \<circ> op \<circ> f = op ` f \<circ> range"
  unfolding image_def comp_def[abs_def] by auto
next
  show "card_order (natLeq +c |UNIV| )" (is "_ (_ +c ?U)")
  apply (rule card_order_csum)
  apply (rule natLeq_card_order)
  by (rule card_of_card_order_on)
(*  *)
  show "cinfinite (natLeq +c ?U)"
    apply (rule cinfinite_csum)
    apply (rule disjI1)
    by (rule natLeq_cinfinite)
next
  fix f :: "'d => 'a"
  have "|range f| \<le>o | (UNIV::'d set) |" (is "_ \<le>o ?U") by (rule card_of_image)
  also have "?U \<le>o natLeq +c ?U" by (rule ordLeq_csum2) (rule card_of_Card_order)
  finally show "|range f| \<le>o natLeq +c ?U" .
next
  fix R S
  show "fun_rel op = R OO fun_rel op = S \<le> fun_rel op = (R OO S)" by (auto simp: fun_rel_def)
next
  fix R
  show "fun_rel op = R =
        (Grp {x. range x \<subseteq> Collect (split R)} (op \<circ> fst))\<inverse>\<inverse> OO
         Grp {x. range x \<subseteq> Collect (split R)} (op \<circ> snd)"
  unfolding fun_rel_def Grp_def fun_eq_iff relcompp.simps conversep.simps  subset_iff image_iff
  by auto (force, metis (no_types) pair_collapse)
qed

end