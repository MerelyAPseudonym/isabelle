(*  Title:      HOL/Topological_Spaces.thy
    Author:     Brian Huffman
    Author:     Johannes Hölzl
*)

section {* Topological Spaces *}

theory Topological_Spaces
imports Main Conditionally_Complete_Lattices
begin

named_theorems continuous_intros "structural introduction rules for continuity"


subsection {* Topological space *}

class "open" =
  fixes "open" :: "'a set \<Rightarrow> bool"

class topological_space = "open" +
  assumes open_UNIV [simp, intro]: "open UNIV"
  assumes open_Int [intro]: "open S \<Longrightarrow> open T \<Longrightarrow> open (S \<inter> T)"
  assumes open_Union [intro]: "\<forall>S\<in>K. open S \<Longrightarrow> open (\<Union> K)"
begin

definition
  closed :: "'a set \<Rightarrow> bool" where
  "closed S \<longleftrightarrow> open (- S)"

lemma open_empty [continuous_intros, intro, simp]: "open {}"
  using open_Union [of "{}"] by simp

lemma open_Un [continuous_intros, intro]: "open S \<Longrightarrow> open T \<Longrightarrow> open (S \<union> T)"
  using open_Union [of "{S, T}"] by simp

lemma open_UN [continuous_intros, intro]: "\<forall>x\<in>A. open (B x) \<Longrightarrow> open (\<Union>x\<in>A. B x)"
  using open_Union [of "B ` A"] by simp

lemma open_Inter [continuous_intros, intro]: "finite S \<Longrightarrow> \<forall>T\<in>S. open T \<Longrightarrow> open (\<Inter>S)"
  by (induct set: finite) auto

lemma open_INT [continuous_intros, intro]: "finite A \<Longrightarrow> \<forall>x\<in>A. open (B x) \<Longrightarrow> open (\<Inter>x\<in>A. B x)"
  using open_Inter [of "B ` A"] by simp

lemma openI:
  assumes "\<And>x. x \<in> S \<Longrightarrow> \<exists>T. open T \<and> x \<in> T \<and> T \<subseteq> S"
  shows "open S"
proof -
  have "open (\<Union>{T. open T \<and> T \<subseteq> S})" by auto
  moreover have "\<Union>{T. open T \<and> T \<subseteq> S} = S" by (auto dest!: assms)
  ultimately show "open S" by simp
qed

lemma closed_empty [continuous_intros, intro, simp]:  "closed {}"
  unfolding closed_def by simp

lemma closed_Un [continuous_intros, intro]: "closed S \<Longrightarrow> closed T \<Longrightarrow> closed (S \<union> T)"
  unfolding closed_def by auto

lemma closed_UNIV [continuous_intros, intro, simp]: "closed UNIV"
  unfolding closed_def by simp

lemma closed_Int [continuous_intros, intro]: "closed S \<Longrightarrow> closed T \<Longrightarrow> closed (S \<inter> T)"
  unfolding closed_def by auto

lemma closed_INT [continuous_intros, intro]: "\<forall>x\<in>A. closed (B x) \<Longrightarrow> closed (\<Inter>x\<in>A. B x)"
  unfolding closed_def by auto

lemma closed_Inter [continuous_intros, intro]: "\<forall>S\<in>K. closed S \<Longrightarrow> closed (\<Inter> K)"
  unfolding closed_def uminus_Inf by auto

lemma closed_Union [continuous_intros, intro]: "finite S \<Longrightarrow> \<forall>T\<in>S. closed T \<Longrightarrow> closed (\<Union>S)"
  by (induct set: finite) auto

lemma closed_UN [continuous_intros, intro]: "finite A \<Longrightarrow> \<forall>x\<in>A. closed (B x) \<Longrightarrow> closed (\<Union>x\<in>A. B x)"
  using closed_Union [of "B ` A"] by simp

lemma open_closed: "open S \<longleftrightarrow> closed (- S)"
  unfolding closed_def by simp

lemma closed_open: "closed S \<longleftrightarrow> open (- S)"
  unfolding closed_def by simp

lemma open_Diff [continuous_intros, intro]: "open S \<Longrightarrow> closed T \<Longrightarrow> open (S - T)"
  unfolding closed_open Diff_eq by (rule open_Int)

lemma closed_Diff [continuous_intros, intro]: "closed S \<Longrightarrow> open T \<Longrightarrow> closed (S - T)"
  unfolding open_closed Diff_eq by (rule closed_Int)

lemma open_Compl [continuous_intros, intro]: "closed S \<Longrightarrow> open (- S)"
  unfolding closed_open .

lemma closed_Compl [continuous_intros, intro]: "open S \<Longrightarrow> closed (- S)"
  unfolding open_closed .

lemma open_Collect_neg: "closed {x. P x} \<Longrightarrow> open {x. \<not> P x}"
  unfolding Collect_neg_eq by (rule open_Compl)

lemma open_Collect_conj: assumes "open {x. P x}" "open {x. Q x}" shows "open {x. P x \<and> Q x}"
  using open_Int[OF assms] by (simp add: Int_def)

lemma open_Collect_disj: assumes "open {x. P x}" "open {x. Q x}" shows "open {x. P x \<or> Q x}"
  using open_Un[OF assms] by (simp add: Un_def)

lemma open_Collect_ex: "(\<And>i. open {x. P i x}) \<Longrightarrow> open {x. \<exists>i. P i x}"
  using open_UN[of UNIV "\<lambda>i. {x. P i x}"] unfolding Collect_ex_eq by simp 

lemma open_Collect_imp: "closed {x. P x} \<Longrightarrow> open {x. Q x} \<Longrightarrow> open {x. P x \<longrightarrow> Q x}"
  unfolding imp_conv_disj by (intro open_Collect_disj open_Collect_neg)

lemma open_Collect_const: "open {x. P}"
  by (cases P) auto

lemma closed_Collect_neg: "open {x. P x} \<Longrightarrow> closed {x. \<not> P x}"
  unfolding Collect_neg_eq by (rule closed_Compl)

lemma closed_Collect_conj: assumes "closed {x. P x}" "closed {x. Q x}" shows "closed {x. P x \<and> Q x}"
  using closed_Int[OF assms] by (simp add: Int_def)

lemma closed_Collect_disj: assumes "closed {x. P x}" "closed {x. Q x}" shows "closed {x. P x \<or> Q x}"
  using closed_Un[OF assms] by (simp add: Un_def)

lemma closed_Collect_all: "(\<And>i. closed {x. P i x}) \<Longrightarrow> closed {x. \<forall>i. P i x}"
  using closed_INT[of UNIV "\<lambda>i. {x. P i x}"] unfolding Collect_all_eq by simp 

lemma closed_Collect_imp: "open {x. P x} \<Longrightarrow> closed {x. Q x} \<Longrightarrow> closed {x. P x \<longrightarrow> Q x}"
  unfolding imp_conv_disj by (intro closed_Collect_disj closed_Collect_neg)

lemma closed_Collect_const: "closed {x. P}"
  by (cases P) auto

end

subsection{* Hausdorff and other separation properties *}

class t0_space = topological_space +
  assumes t0_space: "x \<noteq> y \<Longrightarrow> \<exists>U. open U \<and> \<not> (x \<in> U \<longleftrightarrow> y \<in> U)"

class t1_space = topological_space +
  assumes t1_space: "x \<noteq> y \<Longrightarrow> \<exists>U. open U \<and> x \<in> U \<and> y \<notin> U"

instance t1_space \<subseteq> t0_space
proof qed (fast dest: t1_space)

lemma separation_t1:
  fixes x y :: "'a::t1_space"
  shows "x \<noteq> y \<longleftrightarrow> (\<exists>U. open U \<and> x \<in> U \<and> y \<notin> U)"
  using t1_space[of x y] by blast

lemma closed_singleton:
  fixes a :: "'a::t1_space"
  shows "closed {a}"
proof -
  let ?T = "\<Union>{S. open S \<and> a \<notin> S}"
  have "open ?T" by (simp add: open_Union)
  also have "?T = - {a}"
    by (simp add: set_eq_iff separation_t1, auto)
  finally show "closed {a}" unfolding closed_def .
qed

lemma closed_insert [continuous_intros, simp]:
  fixes a :: "'a::t1_space"
  assumes "closed S" shows "closed (insert a S)"
proof -
  from closed_singleton assms
  have "closed ({a} \<union> S)" by (rule closed_Un)
  thus "closed (insert a S)" by simp
qed

lemma finite_imp_closed:
  fixes S :: "'a::t1_space set"
  shows "finite S \<Longrightarrow> closed S"
by (induct set: finite, simp_all)

text {* T2 spaces are also known as Hausdorff spaces. *}

class t2_space = topological_space +
  assumes hausdorff: "x \<noteq> y \<Longrightarrow> \<exists>U V. open U \<and> open V \<and> x \<in> U \<and> y \<in> V \<and> U \<inter> V = {}"

instance t2_space \<subseteq> t1_space
proof qed (fast dest: hausdorff)

lemma separation_t2:
  fixes x y :: "'a::t2_space"
  shows "x \<noteq> y \<longleftrightarrow> (\<exists>U V. open U \<and> open V \<and> x \<in> U \<and> y \<in> V \<and> U \<inter> V = {})"
  using hausdorff[of x y] by blast

lemma separation_t0:
  fixes x y :: "'a::t0_space"
  shows "x \<noteq> y \<longleftrightarrow> (\<exists>U. open U \<and> ~(x\<in>U \<longleftrightarrow> y\<in>U))"
  using t0_space[of x y] by blast

text {* A perfect space is a topological space with no isolated points. *}

class perfect_space = topological_space +
  assumes not_open_singleton: "\<not> open {x}"


subsection {* Generators for toplogies *}

inductive generate_topology for S where
  UNIV: "generate_topology S UNIV"
| Int: "generate_topology S a \<Longrightarrow> generate_topology S b \<Longrightarrow> generate_topology S (a \<inter> b)"
| UN: "(\<And>k. k \<in> K \<Longrightarrow> generate_topology S k) \<Longrightarrow> generate_topology S (\<Union>K)"
| Basis: "s \<in> S \<Longrightarrow> generate_topology S s"

hide_fact (open) UNIV Int UN Basis 

lemma generate_topology_Union: 
  "(\<And>k. k \<in> I \<Longrightarrow> generate_topology S (K k)) \<Longrightarrow> generate_topology S (\<Union>k\<in>I. K k)"
  using generate_topology.UN [of "K ` I"] by auto

lemma topological_space_generate_topology:
  "class.topological_space (generate_topology S)"
  by default (auto intro: generate_topology.intros)

subsection {* Order topologies *}

class order_topology = order + "open" +
  assumes open_generated_order: "open = generate_topology (range (\<lambda>a. {..< a}) \<union> range (\<lambda>a. {a <..}))"
begin

subclass topological_space
  unfolding open_generated_order
  by (rule topological_space_generate_topology)

lemma open_greaterThan [continuous_intros, simp]: "open {a <..}"
  unfolding open_generated_order by (auto intro: generate_topology.Basis)

lemma open_lessThan [continuous_intros, simp]: "open {..< a}"
  unfolding open_generated_order by (auto intro: generate_topology.Basis)

lemma open_greaterThanLessThan [continuous_intros, simp]: "open {a <..< b}"
   unfolding greaterThanLessThan_eq by (simp add: open_Int)

end

class linorder_topology = linorder + order_topology

lemma closed_atMost [continuous_intros, simp]: "closed {.. a::'a::linorder_topology}"
  by (simp add: closed_open)

lemma closed_atLeast [continuous_intros, simp]: "closed {a::'a::linorder_topology ..}"
  by (simp add: closed_open)

lemma closed_atLeastAtMost [continuous_intros, simp]: "closed {a::'a::linorder_topology .. b}"
proof -
  have "{a .. b} = {a ..} \<inter> {.. b}"
    by auto
  then show ?thesis
    by (simp add: closed_Int)
qed

lemma (in linorder) less_separate:
  assumes "x < y"
  shows "\<exists>a b. x \<in> {..< a} \<and> y \<in> {b <..} \<and> {..< a} \<inter> {b <..} = {}"
proof (cases "\<exists>z. x < z \<and> z < y")
  case True
  then obtain z where "x < z \<and> z < y" ..
  then have "x \<in> {..< z} \<and> y \<in> {z <..} \<and> {z <..} \<inter> {..< z} = {}"
    by auto
  then show ?thesis by blast
next
  case False
  with `x < y` have "x \<in> {..< y} \<and> y \<in> {x <..} \<and> {x <..} \<inter> {..< y} = {}"
    by auto
  then show ?thesis by blast
qed

instance linorder_topology \<subseteq> t2_space
proof
  fix x y :: 'a
  from less_separate[of x y] less_separate[of y x]
  show "x \<noteq> y \<Longrightarrow> \<exists>U V. open U \<and> open V \<and> x \<in> U \<and> y \<in> V \<and> U \<inter> V = {}"
    by (elim neqE) (metis open_lessThan open_greaterThan Int_commute)+
qed

lemma (in linorder_topology) open_right:
  assumes "open S" "x \<in> S" and gt_ex: "x < y" shows "\<exists>b>x. {x ..< b} \<subseteq> S"
  using assms unfolding open_generated_order
proof induction
  case (Int A B)
  then obtain a b where "a > x" "{x ..< a} \<subseteq> A"  "b > x" "{x ..< b} \<subseteq> B" by auto
  then show ?case by (auto intro!: exI[of _ "min a b"])
next
  case (Basis S) then show ?case by (fastforce intro: exI[of _ y] gt_ex)
qed blast+

lemma (in linorder_topology) open_left:
  assumes "open S" "x \<in> S" and lt_ex: "y < x" shows "\<exists>b<x. {b <.. x} \<subseteq> S"
  using assms unfolding open_generated_order
proof induction
  case (Int A B)
  then obtain a b where "a < x" "{a <.. x} \<subseteq> A"  "b < x" "{b <.. x} \<subseteq> B" by auto
  then show ?case by (auto intro!: exI[of _ "max a b"])
next
  case (Basis S) then show ?case by (fastforce intro: exI[of _ y] lt_ex)
qed blast+

subsubsection {* Boolean is an order topology *}

text {* It also is a discrete topology, but don't have a type class for it (yet). *}

instantiation bool :: order_topology
begin

definition open_bool :: "bool set \<Rightarrow> bool" where
  "open_bool = generate_topology (range (\<lambda>a. {..< a}) \<union> range (\<lambda>a. {a <..}))"

instance
  proof qed (rule open_bool_def)

end

lemma open_bool[simp, intro!]: "open (A::bool set)"
proof -
  have *: "{False <..} = {True}" "{..< True} = {False}"
    by auto
  have "A = UNIV \<or> A = {} \<or> A = {False <..} \<or> A = {..< True}"
    using subset_UNIV[of A] unfolding UNIV_bool * by auto
  then show "open A"
    by auto
qed

subsection {* Filters *}

text {*
  This definition also allows non-proper filters.
*}

locale is_filter =
  fixes F :: "('a \<Rightarrow> bool) \<Rightarrow> bool"
  assumes True: "F (\<lambda>x. True)"
  assumes conj: "F (\<lambda>x. P x) \<Longrightarrow> F (\<lambda>x. Q x) \<Longrightarrow> F (\<lambda>x. P x \<and> Q x)"
  assumes mono: "\<forall>x. P x \<longrightarrow> Q x \<Longrightarrow> F (\<lambda>x. P x) \<Longrightarrow> F (\<lambda>x. Q x)"

typedef 'a filter = "{F :: ('a \<Rightarrow> bool) \<Rightarrow> bool. is_filter F}"
proof
  show "(\<lambda>x. True) \<in> ?filter" by (auto intro: is_filter.intro)
qed

lemma is_filter_Rep_filter: "is_filter (Rep_filter F)"
  using Rep_filter [of F] by simp

lemma Abs_filter_inverse':
  assumes "is_filter F" shows "Rep_filter (Abs_filter F) = F"
  using assms by (simp add: Abs_filter_inverse)


subsubsection {* Eventually *}

definition eventually :: "('a \<Rightarrow> bool) \<Rightarrow> 'a filter \<Rightarrow> bool"
  where "eventually P F \<longleftrightarrow> Rep_filter F P"

lemma eventually_Abs_filter:
  assumes "is_filter F" shows "eventually P (Abs_filter F) = F P"
  unfolding eventually_def using assms by (simp add: Abs_filter_inverse)

lemma filter_eq_iff:
  shows "F = F' \<longleftrightarrow> (\<forall>P. eventually P F = eventually P F')"
  unfolding Rep_filter_inject [symmetric] fun_eq_iff eventually_def ..

lemma eventually_True [simp]: "eventually (\<lambda>x. True) F"
  unfolding eventually_def
  by (rule is_filter.True [OF is_filter_Rep_filter])

lemma always_eventually: "\<forall>x. P x \<Longrightarrow> eventually P F"
proof -
  assume "\<forall>x. P x" hence "P = (\<lambda>x. True)" by (simp add: ext)
  thus "eventually P F" by simp
qed

lemma eventually_mono:
  "(\<forall>x. P x \<longrightarrow> Q x) \<Longrightarrow> eventually P F \<Longrightarrow> eventually Q F"
  unfolding eventually_def
  by (rule is_filter.mono [OF is_filter_Rep_filter])

lemma eventually_conj:
  assumes P: "eventually (\<lambda>x. P x) F"
  assumes Q: "eventually (\<lambda>x. Q x) F"
  shows "eventually (\<lambda>x. P x \<and> Q x) F"
  using assms unfolding eventually_def
  by (rule is_filter.conj [OF is_filter_Rep_filter])

lemma eventually_Ball_finite:
  assumes "finite A" and "\<forall>y\<in>A. eventually (\<lambda>x. P x y) net"
  shows "eventually (\<lambda>x. \<forall>y\<in>A. P x y) net"
using assms by (induct set: finite, simp, simp add: eventually_conj)

lemma eventually_all_finite:
  fixes P :: "'a \<Rightarrow> 'b::finite \<Rightarrow> bool"
  assumes "\<And>y. eventually (\<lambda>x. P x y) net"
  shows "eventually (\<lambda>x. \<forall>y. P x y) net"
using eventually_Ball_finite [of UNIV P] assms by simp

lemma eventually_mp:
  assumes "eventually (\<lambda>x. P x \<longrightarrow> Q x) F"
  assumes "eventually (\<lambda>x. P x) F"
  shows "eventually (\<lambda>x. Q x) F"
proof (rule eventually_mono)
  show "\<forall>x. (P x \<longrightarrow> Q x) \<and> P x \<longrightarrow> Q x" by simp
  show "eventually (\<lambda>x. (P x \<longrightarrow> Q x) \<and> P x) F"
    using assms by (rule eventually_conj)
qed

lemma eventually_rev_mp:
  assumes "eventually (\<lambda>x. P x) F"
  assumes "eventually (\<lambda>x. P x \<longrightarrow> Q x) F"
  shows "eventually (\<lambda>x. Q x) F"
using assms(2) assms(1) by (rule eventually_mp)

lemma eventually_conj_iff:
  "eventually (\<lambda>x. P x \<and> Q x) F \<longleftrightarrow> eventually P F \<and> eventually Q F"
  by (auto intro: eventually_conj elim: eventually_rev_mp)

lemma eventually_elim1:
  assumes "eventually (\<lambda>i. P i) F"
  assumes "\<And>i. P i \<Longrightarrow> Q i"
  shows "eventually (\<lambda>i. Q i) F"
  using assms by (auto elim!: eventually_rev_mp)

lemma eventually_elim2:
  assumes "eventually (\<lambda>i. P i) F"
  assumes "eventually (\<lambda>i. Q i) F"
  assumes "\<And>i. P i \<Longrightarrow> Q i \<Longrightarrow> R i"
  shows "eventually (\<lambda>i. R i) F"
  using assms by (auto elim!: eventually_rev_mp)

lemma not_eventually_impI: "eventually P F \<Longrightarrow> \<not> eventually Q F \<Longrightarrow> \<not> eventually (\<lambda>x. P x \<longrightarrow> Q x) F"
  by (auto intro: eventually_mp)

lemma not_eventuallyD: "\<not> eventually P F \<Longrightarrow> \<exists>x. \<not> P x"
  by (metis always_eventually)

lemma eventually_subst:
  assumes "eventually (\<lambda>n. P n = Q n) F"
  shows "eventually P F = eventually Q F" (is "?L = ?R")
proof -
  from assms have "eventually (\<lambda>x. P x \<longrightarrow> Q x) F"
      and "eventually (\<lambda>x. Q x \<longrightarrow> P x) F"
    by (auto elim: eventually_elim1)
  then show ?thesis by (auto elim: eventually_elim2)
qed

ML {*
  fun eventually_elim_tac ctxt thms = SUBGOAL_CASES (fn (_, _, st) =>
    let
      val thy = Proof_Context.theory_of ctxt
      val mp_thms = thms RL [@{thm eventually_rev_mp}]
      val raw_elim_thm =
        (@{thm allI} RS @{thm always_eventually})
        |> fold (fn thm1 => fn thm2 => thm2 RS thm1) mp_thms
        |> fold (fn _ => fn thm => @{thm impI} RS thm) thms
      val cases_prop = prop_of (raw_elim_thm RS st)
      val cases = (Rule_Cases.make_common (thy, cases_prop) [(("elim", []), [])])
    in
      CASES cases (rtac raw_elim_thm 1)
    end) 1
*}

method_setup eventually_elim = {*
  Scan.succeed (fn ctxt => METHOD_CASES (eventually_elim_tac ctxt))
*} "elimination of eventually quantifiers"


subsubsection {* Finer-than relation *}

text {* @{term "F \<le> F'"} means that filter @{term F} is finer than
filter @{term F'}. *}

instantiation filter :: (type) complete_lattice
begin

definition le_filter_def:
  "F \<le> F' \<longleftrightarrow> (\<forall>P. eventually P F' \<longrightarrow> eventually P F)"

definition
  "(F :: 'a filter) < F' \<longleftrightarrow> F \<le> F' \<and> \<not> F' \<le> F"

definition
  "top = Abs_filter (\<lambda>P. \<forall>x. P x)"

definition
  "bot = Abs_filter (\<lambda>P. True)"

definition
  "sup F F' = Abs_filter (\<lambda>P. eventually P F \<and> eventually P F')"

definition
  "inf F F' = Abs_filter
      (\<lambda>P. \<exists>Q R. eventually Q F \<and> eventually R F' \<and> (\<forall>x. Q x \<and> R x \<longrightarrow> P x))"

definition
  "Sup S = Abs_filter (\<lambda>P. \<forall>F\<in>S. eventually P F)"

definition
  "Inf S = Sup {F::'a filter. \<forall>F'\<in>S. F \<le> F'}"

lemma eventually_top [simp]: "eventually P top \<longleftrightarrow> (\<forall>x. P x)"
  unfolding top_filter_def
  by (rule eventually_Abs_filter, rule is_filter.intro, auto)

lemma eventually_bot [simp]: "eventually P bot"
  unfolding bot_filter_def
  by (subst eventually_Abs_filter, rule is_filter.intro, auto)

lemma eventually_sup:
  "eventually P (sup F F') \<longleftrightarrow> eventually P F \<and> eventually P F'"
  unfolding sup_filter_def
  by (rule eventually_Abs_filter, rule is_filter.intro)
     (auto elim!: eventually_rev_mp)

lemma eventually_inf:
  "eventually P (inf F F') \<longleftrightarrow>
   (\<exists>Q R. eventually Q F \<and> eventually R F' \<and> (\<forall>x. Q x \<and> R x \<longrightarrow> P x))"
  unfolding inf_filter_def
  apply (rule eventually_Abs_filter, rule is_filter.intro)
  apply (fast intro: eventually_True)
  apply clarify
  apply (intro exI conjI)
  apply (erule (1) eventually_conj)
  apply (erule (1) eventually_conj)
  apply simp
  apply auto
  done

lemma eventually_Sup:
  "eventually P (Sup S) \<longleftrightarrow> (\<forall>F\<in>S. eventually P F)"
  unfolding Sup_filter_def
  apply (rule eventually_Abs_filter, rule is_filter.intro)
  apply (auto intro: eventually_conj elim!: eventually_rev_mp)
  done

instance proof
  fix F F' F'' :: "'a filter" and S :: "'a filter set"
  { show "F < F' \<longleftrightarrow> F \<le> F' \<and> \<not> F' \<le> F"
    by (rule less_filter_def) }
  { show "F \<le> F"
    unfolding le_filter_def by simp }
  { assume "F \<le> F'" and "F' \<le> F''" thus "F \<le> F''"
    unfolding le_filter_def by simp }
  { assume "F \<le> F'" and "F' \<le> F" thus "F = F'"
    unfolding le_filter_def filter_eq_iff by fast }
  { show "inf F F' \<le> F" and "inf F F' \<le> F'"
    unfolding le_filter_def eventually_inf by (auto intro: eventually_True) }
  { assume "F \<le> F'" and "F \<le> F''" thus "F \<le> inf F' F''"
    unfolding le_filter_def eventually_inf
    by (auto elim!: eventually_mono intro: eventually_conj) }
  { show "F \<le> sup F F'" and "F' \<le> sup F F'"
    unfolding le_filter_def eventually_sup by simp_all }
  { assume "F \<le> F''" and "F' \<le> F''" thus "sup F F' \<le> F''"
    unfolding le_filter_def eventually_sup by simp }
  { assume "F'' \<in> S" thus "Inf S \<le> F''"
    unfolding le_filter_def Inf_filter_def eventually_Sup Ball_def by simp }
  { assume "\<And>F'. F' \<in> S \<Longrightarrow> F \<le> F'" thus "F \<le> Inf S"
    unfolding le_filter_def Inf_filter_def eventually_Sup Ball_def by simp }
  { assume "F \<in> S" thus "F \<le> Sup S"
    unfolding le_filter_def eventually_Sup by simp }
  { assume "\<And>F. F \<in> S \<Longrightarrow> F \<le> F'" thus "Sup S \<le> F'"
    unfolding le_filter_def eventually_Sup by simp }
  { show "Inf {} = (top::'a filter)"
    by (auto simp: top_filter_def Inf_filter_def Sup_filter_def)
      (metis (full_types) top_filter_def always_eventually eventually_top) }
  { show "Sup {} = (bot::'a filter)"
    by (auto simp: bot_filter_def Sup_filter_def) }
qed

end

lemma filter_leD:
  "F \<le> F' \<Longrightarrow> eventually P F' \<Longrightarrow> eventually P F"
  unfolding le_filter_def by simp

lemma filter_leI:
  "(\<And>P. eventually P F' \<Longrightarrow> eventually P F) \<Longrightarrow> F \<le> F'"
  unfolding le_filter_def by simp

lemma eventually_False:
  "eventually (\<lambda>x. False) F \<longleftrightarrow> F = bot"
  unfolding filter_eq_iff by (auto elim: eventually_rev_mp)

abbreviation (input) trivial_limit :: "'a filter \<Rightarrow> bool"
  where "trivial_limit F \<equiv> F = bot"

lemma trivial_limit_def: "trivial_limit F \<longleftrightarrow> eventually (\<lambda>x. False) F"
  by (rule eventually_False [symmetric])

lemma eventually_const: "\<not> trivial_limit net \<Longrightarrow> eventually (\<lambda>x. P) net \<longleftrightarrow> P"
  by (cases P) (simp_all add: eventually_False)

lemma eventually_Inf: "eventually P (Inf B) \<longleftrightarrow> (\<exists>X\<subseteq>B. finite X \<and> eventually P (Inf X))"
proof -
  let ?F = "\<lambda>P. \<exists>X\<subseteq>B. finite X \<and> eventually P (Inf X)"
  
  { fix P have "eventually P (Abs_filter ?F) \<longleftrightarrow> ?F P"
    proof (rule eventually_Abs_filter is_filter.intro)+
      show "?F (\<lambda>x. True)"
        by (rule exI[of _ "{}"]) (simp add: le_fun_def)
    next
      fix P Q
      assume "?F P" then guess X ..
      moreover
      assume "?F Q" then guess Y ..
      ultimately show "?F (\<lambda>x. P x \<and> Q x)"
        by (intro exI[of _ "X \<union> Y"])
           (auto simp: Inf_union_distrib eventually_inf)
    next
      fix P Q
      assume "?F P" then guess X ..
      moreover assume "\<forall>x. P x \<longrightarrow> Q x"
      ultimately show "?F Q"
        by (intro exI[of _ X]) (auto elim: eventually_elim1)
    qed }
  note eventually_F = this

  have "Inf B = Abs_filter ?F"
  proof (intro antisym Inf_greatest)
    show "Inf B \<le> Abs_filter ?F"
      by (auto simp: le_filter_def eventually_F dest: Inf_superset_mono)
  next
    fix F assume "F \<in> B" then show "Abs_filter ?F \<le> F"
      by (auto simp add: le_filter_def eventually_F intro!: exI[of _ "{F}"])
  qed
  then show ?thesis
    by (simp add: eventually_F)
qed

lemma eventually_INF: "eventually P (INF b:B. F b) \<longleftrightarrow> (\<exists>X\<subseteq>B. finite X \<and> eventually P (INF b:X. F b))"
  unfolding INF_def[of B] eventually_Inf[of P "F`B"]
  by (metis Inf_image_eq finite_imageI image_mono finite_subset_image)

lemma Inf_filter_not_bot:
  fixes B :: "'a filter set"
  shows "(\<And>X. X \<subseteq> B \<Longrightarrow> finite X \<Longrightarrow> Inf X \<noteq> bot) \<Longrightarrow> Inf B \<noteq> bot"
  unfolding trivial_limit_def eventually_Inf[of _ B]
    bot_bool_def [symmetric] bot_fun_def [symmetric] bot_unique by simp

lemma INF_filter_not_bot:
  fixes F :: "'i \<Rightarrow> 'a filter"
  shows "(\<And>X. X \<subseteq> B \<Longrightarrow> finite X \<Longrightarrow> (INF b:X. F b) \<noteq> bot) \<Longrightarrow> (INF b:B. F b) \<noteq> bot"
  unfolding trivial_limit_def eventually_INF[of _ B]
    bot_bool_def [symmetric] bot_fun_def [symmetric] bot_unique by simp

lemma eventually_Inf_base:
  assumes "B \<noteq> {}" and base: "\<And>F G. F \<in> B \<Longrightarrow> G \<in> B \<Longrightarrow> \<exists>x\<in>B. x \<le> inf F G"
  shows "eventually P (Inf B) \<longleftrightarrow> (\<exists>b\<in>B. eventually P b)"
proof (subst eventually_Inf, safe)
  fix X assume "finite X" "X \<subseteq> B"
  then have "\<exists>b\<in>B. \<forall>x\<in>X. b \<le> x"
  proof induct
    case empty then show ?case
      using `B \<noteq> {}` by auto
  next
    case (insert x X)
    then obtain b where "b \<in> B" "\<And>x. x \<in> X \<Longrightarrow> b \<le> x"
      by auto
    with `insert x X \<subseteq> B` base[of b x] show ?case
      by (auto intro: order_trans)
  qed
  then obtain b where "b \<in> B" "b \<le> Inf X"
    by (auto simp: le_Inf_iff)
  then show "eventually P (Inf X) \<Longrightarrow> Bex B (eventually P)"
    by (intro bexI[of _ b]) (auto simp: le_filter_def)
qed (auto intro!: exI[of _ "{x}" for x])

lemma eventually_INF_base:
  "B \<noteq> {} \<Longrightarrow> (\<And>a b. a \<in> B \<Longrightarrow> b \<in> B \<Longrightarrow> \<exists>x\<in>B. F x \<le> inf (F a) (F b)) \<Longrightarrow>
    eventually P (INF b:B. F b) \<longleftrightarrow> (\<exists>b\<in>B. eventually P (F b))"
  unfolding INF_def by (subst eventually_Inf_base) auto


subsubsection {* Map function for filters *}

definition filtermap :: "('a \<Rightarrow> 'b) \<Rightarrow> 'a filter \<Rightarrow> 'b filter"
  where "filtermap f F = Abs_filter (\<lambda>P. eventually (\<lambda>x. P (f x)) F)"

lemma eventually_filtermap:
  "eventually P (filtermap f F) = eventually (\<lambda>x. P (f x)) F"
  unfolding filtermap_def
  apply (rule eventually_Abs_filter)
  apply (rule is_filter.intro)
  apply (auto elim!: eventually_rev_mp)
  done

lemma filtermap_ident: "filtermap (\<lambda>x. x) F = F"
  by (simp add: filter_eq_iff eventually_filtermap)

lemma filtermap_filtermap:
  "filtermap f (filtermap g F) = filtermap (\<lambda>x. f (g x)) F"
  by (simp add: filter_eq_iff eventually_filtermap)

lemma filtermap_mono: "F \<le> F' \<Longrightarrow> filtermap f F \<le> filtermap f F'"
  unfolding le_filter_def eventually_filtermap by simp

lemma filtermap_bot [simp]: "filtermap f bot = bot"
  by (simp add: filter_eq_iff eventually_filtermap)

lemma filtermap_sup: "filtermap f (sup F1 F2) = sup (filtermap f F1) (filtermap f F2)"
  by (auto simp: filter_eq_iff eventually_filtermap eventually_sup)

lemma filtermap_inf: "filtermap f (inf F1 F2) \<le> inf (filtermap f F1) (filtermap f F2)"
  by (auto simp: le_filter_def eventually_filtermap eventually_inf)

lemma filtermap_INF: "filtermap f (INF b:B. F b) \<le> (INF b:B. filtermap f (F b))"
proof -
  { fix X :: "'c set" assume "finite X"
    then have "filtermap f (INFIMUM X F) \<le> (INF b:X. filtermap f (F b))"
    proof induct
      case (insert x X)
      have "filtermap f (INF a:insert x X. F a) \<le> inf (filtermap f (F x)) (filtermap f (INF a:X. F a))"
        by (rule order_trans[OF _ filtermap_inf]) simp
      also have "\<dots> \<le> inf (filtermap f (F x)) (INF a:X. filtermap f (F a))"
        by (intro inf_mono insert order_refl)
      finally show ?case
        by simp
    qed simp }
  then show ?thesis
    unfolding le_filter_def eventually_filtermap
    by (subst (1 2) eventually_INF) auto
qed
subsubsection {* Standard filters *}

definition principal :: "'a set \<Rightarrow> 'a filter" where
  "principal S = Abs_filter (\<lambda>P. \<forall>x\<in>S. P x)"

lemma eventually_principal: "eventually P (principal S) \<longleftrightarrow> (\<forall>x\<in>S. P x)"
  unfolding principal_def
  by (rule eventually_Abs_filter, rule is_filter.intro) auto

lemma eventually_inf_principal: "eventually P (inf F (principal s)) \<longleftrightarrow> eventually (\<lambda>x. x \<in> s \<longrightarrow> P x) F"
  unfolding eventually_inf eventually_principal by (auto elim: eventually_elim1)

lemma principal_UNIV[simp]: "principal UNIV = top"
  by (auto simp: filter_eq_iff eventually_principal)

lemma principal_empty[simp]: "principal {} = bot"
  by (auto simp: filter_eq_iff eventually_principal)

lemma principal_eq_bot_iff: "principal X = bot \<longleftrightarrow> X = {}"
  by (auto simp add: filter_eq_iff eventually_principal)

lemma principal_le_iff[iff]: "principal A \<le> principal B \<longleftrightarrow> A \<subseteq> B"
  by (auto simp: le_filter_def eventually_principal)

lemma le_principal: "F \<le> principal A \<longleftrightarrow> eventually (\<lambda>x. x \<in> A) F"
  unfolding le_filter_def eventually_principal
  apply safe
  apply (erule_tac x="\<lambda>x. x \<in> A" in allE)
  apply (auto elim: eventually_elim1)
  done

lemma principal_inject[iff]: "principal A = principal B \<longleftrightarrow> A = B"
  unfolding eq_iff by simp

lemma sup_principal[simp]: "sup (principal A) (principal B) = principal (A \<union> B)"
  unfolding filter_eq_iff eventually_sup eventually_principal by auto

lemma inf_principal[simp]: "inf (principal A) (principal B) = principal (A \<inter> B)"
  unfolding filter_eq_iff eventually_inf eventually_principal
  by (auto intro: exI[of _ "\<lambda>x. x \<in> A"] exI[of _ "\<lambda>x. x \<in> B"])

lemma SUP_principal[simp]: "(SUP i : I. principal (A i)) = principal (\<Union>i\<in>I. A i)"
  unfolding filter_eq_iff eventually_Sup SUP_def by (auto simp: eventually_principal)

lemma INF_principal_finite: "finite X \<Longrightarrow> (INF x:X. principal (f x)) = principal (\<Inter>x\<in>X. f x)"
  by (induct X rule: finite_induct) auto

lemma filtermap_principal[simp]: "filtermap f (principal A) = principal (f ` A)"
  unfolding filter_eq_iff eventually_filtermap eventually_principal by simp

subsubsection {* Order filters *}

definition at_top :: "('a::order) filter"
  where "at_top = (INF k. principal {k ..})"

lemma at_top_sub: "at_top = (INF k:{c::'a::linorder..}. principal {k ..})"
  by (auto intro!: INF_eq max.cobounded1 max.cobounded2 simp: at_top_def)

lemma eventually_at_top_linorder: "eventually P at_top \<longleftrightarrow> (\<exists>N::'a::linorder. \<forall>n\<ge>N. P n)"
  unfolding at_top_def
  by (subst eventually_INF_base) (auto simp: eventually_principal intro: max.cobounded1 max.cobounded2)

lemma eventually_ge_at_top:
  "eventually (\<lambda>x. (c::_::linorder) \<le> x) at_top"
  unfolding eventually_at_top_linorder by auto

lemma eventually_at_top_dense: "eventually P at_top \<longleftrightarrow> (\<exists>N::'a::{no_top, linorder}. \<forall>n>N. P n)"
proof -
  have "eventually P (INF k. principal {k <..}) \<longleftrightarrow> (\<exists>N::'a. \<forall>n>N. P n)"
    by (subst eventually_INF_base) (auto simp: eventually_principal intro: max.cobounded1 max.cobounded2)
  also have "(INF k. principal {k::'a <..}) = at_top"
    unfolding at_top_def 
    by (intro INF_eq) (auto intro: less_imp_le simp: Ici_subset_Ioi_iff gt_ex)
  finally show ?thesis .
qed

lemma eventually_gt_at_top:
  "eventually (\<lambda>x. (c::_::unbounded_dense_linorder) < x) at_top"
  unfolding eventually_at_top_dense by auto

definition at_bot :: "('a::order) filter"
  where "at_bot = (INF k. principal {.. k})"

lemma at_bot_sub: "at_bot = (INF k:{.. c::'a::linorder}. principal {.. k})"
  by (auto intro!: INF_eq min.cobounded1 min.cobounded2 simp: at_bot_def)

lemma eventually_at_bot_linorder:
  fixes P :: "'a::linorder \<Rightarrow> bool" shows "eventually P at_bot \<longleftrightarrow> (\<exists>N. \<forall>n\<le>N. P n)"
  unfolding at_bot_def
  by (subst eventually_INF_base) (auto simp: eventually_principal intro: min.cobounded1 min.cobounded2)

lemma eventually_le_at_bot:
  "eventually (\<lambda>x. x \<le> (c::_::linorder)) at_bot"
  unfolding eventually_at_bot_linorder by auto

lemma eventually_at_bot_dense: "eventually P at_bot \<longleftrightarrow> (\<exists>N::'a::{no_bot, linorder}. \<forall>n<N. P n)"
proof -
  have "eventually P (INF k. principal {..< k}) \<longleftrightarrow> (\<exists>N::'a. \<forall>n<N. P n)"
    by (subst eventually_INF_base) (auto simp: eventually_principal intro: min.cobounded1 min.cobounded2)
  also have "(INF k. principal {..< k::'a}) = at_bot"
    unfolding at_bot_def 
    by (intro INF_eq) (auto intro: less_imp_le simp: Iic_subset_Iio_iff lt_ex)
  finally show ?thesis .
qed

lemma eventually_gt_at_bot:
  "eventually (\<lambda>x. x < (c::_::unbounded_dense_linorder)) at_bot"
  unfolding eventually_at_bot_dense by auto

lemma trivial_limit_at_bot_linorder: "\<not> trivial_limit (at_bot ::('a::linorder) filter)"
  unfolding trivial_limit_def
  by (metis eventually_at_bot_linorder order_refl)

lemma trivial_limit_at_top_linorder: "\<not> trivial_limit (at_top ::('a::linorder) filter)"
  unfolding trivial_limit_def
  by (metis eventually_at_top_linorder order_refl)

subsection {* Sequentially *}

abbreviation sequentially :: "nat filter"
  where "sequentially \<equiv> at_top"

lemma eventually_sequentially:
  "eventually P sequentially \<longleftrightarrow> (\<exists>N. \<forall>n\<ge>N. P n)"
  by (rule eventually_at_top_linorder)

lemma sequentially_bot [simp, intro]: "sequentially \<noteq> bot"
  unfolding filter_eq_iff eventually_sequentially by auto

lemmas trivial_limit_sequentially = sequentially_bot

lemma eventually_False_sequentially [simp]:
  "\<not> eventually (\<lambda>n. False) sequentially"
  by (simp add: eventually_False)

lemma le_sequentially:
  "F \<le> sequentially \<longleftrightarrow> (\<forall>N. eventually (\<lambda>n. N \<le> n) F)"
  by (simp add: at_top_def le_INF_iff le_principal)

lemma eventually_sequentiallyI:
  assumes "\<And>x. c \<le> x \<Longrightarrow> P x"
  shows "eventually P sequentially"
using assms by (auto simp: eventually_sequentially)

lemma eventually_sequentially_seg:
  "eventually (\<lambda>n. P (n + k)) sequentially \<longleftrightarrow> eventually P sequentially"
  unfolding eventually_sequentially
  apply safe
   apply (rule_tac x="N + k" in exI)
   apply rule
   apply (erule_tac x="n - k" in allE)
   apply auto []
  apply (rule_tac x=N in exI)
  apply auto []
  done

subsubsection {* Topological filters *}

definition (in topological_space) nhds :: "'a \<Rightarrow> 'a filter"
  where "nhds a = (INF S:{S. open S \<and> a \<in> S}. principal S)"

definition (in topological_space) at_within :: "'a \<Rightarrow> 'a set \<Rightarrow> 'a filter" ("at (_) within (_)" [1000, 60] 60)
  where "at a within s = inf (nhds a) (principal (s - {a}))"

abbreviation (in topological_space) at :: "'a \<Rightarrow> 'a filter" ("at") where
  "at x \<equiv> at x within (CONST UNIV)"

abbreviation (in order_topology) at_right :: "'a \<Rightarrow> 'a filter" where
  "at_right x \<equiv> at x within {x <..}"

abbreviation (in order_topology) at_left :: "'a \<Rightarrow> 'a filter" where
  "at_left x \<equiv> at x within {..< x}"

lemma (in topological_space) nhds_generated_topology:
  "open = generate_topology T \<Longrightarrow> nhds x = (INF S:{S\<in>T. x \<in> S}. principal S)"
  unfolding nhds_def
proof (safe intro!: antisym INF_greatest)
  fix S assume "generate_topology T S" "x \<in> S"
  then show "(INF S:{S \<in> T. x \<in> S}. principal S) \<le> principal S"
    by induction 
       (auto intro: INF_lower order_trans simp add: inf_principal[symmetric] simp del: inf_principal)
qed (auto intro!: INF_lower intro: generate_topology.intros)

lemma (in topological_space) eventually_nhds:
  "eventually P (nhds a) \<longleftrightarrow> (\<exists>S. open S \<and> a \<in> S \<and> (\<forall>x\<in>S. P x))"
  unfolding nhds_def by (subst eventually_INF_base) (auto simp: eventually_principal)

lemma nhds_neq_bot [simp]: "nhds a \<noteq> bot"
  unfolding trivial_limit_def eventually_nhds by simp

lemma at_within_eq: "at x within s = (INF S:{S. open S \<and> x \<in> S}. principal (S \<inter> s - {x}))"
  unfolding nhds_def at_within_def by (subst INF_inf_const2[symmetric]) (auto simp add: Diff_Int_distrib)

lemma eventually_at_filter:
  "eventually P (at a within s) \<longleftrightarrow> eventually (\<lambda>x. x \<noteq> a \<longrightarrow> x \<in> s \<longrightarrow> P x) (nhds a)"
  unfolding at_within_def eventually_inf_principal by (simp add: imp_conjL[symmetric] conj_commute)

lemma at_le: "s \<subseteq> t \<Longrightarrow> at x within s \<le> at x within t"
  unfolding at_within_def by (intro inf_mono) auto

lemma eventually_at_topological:
  "eventually P (at a within s) \<longleftrightarrow> (\<exists>S. open S \<and> a \<in> S \<and> (\<forall>x\<in>S. x \<noteq> a \<longrightarrow> x \<in> s \<longrightarrow> P x))"
  unfolding eventually_nhds eventually_at_filter by simp

lemma at_within_open: "a \<in> S \<Longrightarrow> open S \<Longrightarrow> at a within S = at a"
  unfolding filter_eq_iff eventually_at_topological by (metis open_Int Int_iff UNIV_I)

lemma at_within_empty [simp]: "at a within {} = bot"
  unfolding at_within_def by simp

lemma at_within_union: "at x within (S \<union> T) = sup (at x within S) (at x within T)"
  unfolding filter_eq_iff eventually_sup eventually_at_filter
  by (auto elim!: eventually_rev_mp)

lemma at_eq_bot_iff: "at a = bot \<longleftrightarrow> open {a}"
  unfolding trivial_limit_def eventually_at_topological
  by (safe, case_tac "S = {a}", simp, fast, fast)

lemma at_neq_bot [simp]: "at (a::'a::perfect_space) \<noteq> bot"
  by (simp add: at_eq_bot_iff not_open_singleton)

lemma (in order_topology) nhds_order: "nhds x =
  inf (INF a:{x <..}. principal {..< a}) (INF a:{..< x}. principal {a <..})"
proof -
  have 1: "{S \<in> range lessThan \<union> range greaterThan. x \<in> S} = 
      (\<lambda>a. {..< a}) ` {x <..} \<union> (\<lambda>a. {a <..}) ` {..< x}"
    by auto
  show ?thesis
    unfolding nhds_generated_topology[OF open_generated_order] INF_union 1 INF_image comp_def ..
qed

lemma (in linorder_topology) at_within_order: "UNIV \<noteq> {x} \<Longrightarrow> 
  at x within s = inf (INF a:{x <..}. principal ({..< a} \<inter> s - {x}))
                      (INF a:{..< x}. principal ({a <..} \<inter> s - {x}))"
proof (cases "{x <..} = {}" "{..< x} = {}" rule: case_split[case_product case_split])
  assume "UNIV \<noteq> {x}" "{x<..} = {}" "{..< x} = {}"
  moreover have "UNIV = {..< x} \<union> {x} \<union> {x <..}"
    by auto
  ultimately show ?thesis
    by auto
qed (auto simp: at_within_def nhds_order Int_Diff inf_principal[symmetric] INF_inf_const2
                inf_sup_aci[where 'a="'a filter"]
          simp del: inf_principal)

lemma (in linorder_topology) at_left_eq:
  "y < x \<Longrightarrow> at_left x = (INF a:{..< x}. principal {a <..< x})"
  by (subst at_within_order)
     (auto simp: greaterThan_Int_greaterThan greaterThanLessThan_eq[symmetric] min.absorb2 INF_constant
           intro!: INF_lower2 inf_absorb2)

lemma (in linorder_topology) eventually_at_left:
  "y < x \<Longrightarrow> eventually P (at_left x) \<longleftrightarrow> (\<exists>b<x. \<forall>y>b. y < x \<longrightarrow> P y)"
  unfolding at_left_eq by (subst eventually_INF_base) (auto simp: eventually_principal Ball_def)

lemma (in linorder_topology) at_right_eq:
  "x < y \<Longrightarrow> at_right x = (INF a:{x <..}. principal {x <..< a})"
  by (subst at_within_order)
     (auto simp: lessThan_Int_lessThan greaterThanLessThan_eq[symmetric] max.absorb2 INF_constant Int_commute
           intro!: INF_lower2 inf_absorb1)

lemma (in linorder_topology) eventually_at_right:
  "x < y \<Longrightarrow> eventually P (at_right x) \<longleftrightarrow> (\<exists>b>x. \<forall>y>x. y < b \<longrightarrow> P y)"
  unfolding at_right_eq by (subst eventually_INF_base) (auto simp: eventually_principal Ball_def)

lemma trivial_limit_at_right_top: "at_right (top::_::{order_top, linorder_topology}) = bot"
  unfolding filter_eq_iff eventually_at_topological by auto

lemma trivial_limit_at_left_bot: "at_left (bot::_::{order_bot, linorder_topology}) = bot"
  unfolding filter_eq_iff eventually_at_topological by auto

lemma trivial_limit_at_left_real [simp]:
  "\<not> trivial_limit (at_left (x::'a::{no_bot, dense_order, linorder_topology}))"
  using lt_ex[of x]
  by safe (auto simp add: trivial_limit_def eventually_at_left dest: dense)

lemma trivial_limit_at_right_real [simp]:
  "\<not> trivial_limit (at_right (x::'a::{no_top, dense_order, linorder_topology}))"
  using gt_ex[of x]
  by safe (auto simp add: trivial_limit_def eventually_at_right dest: dense)

lemma at_eq_sup_left_right: "at (x::'a::linorder_topology) = sup (at_left x) (at_right x)"
  by (auto simp: eventually_at_filter filter_eq_iff eventually_sup 
           elim: eventually_elim2 eventually_elim1)

lemma eventually_at_split:
  "eventually P (at (x::'a::linorder_topology)) \<longleftrightarrow> eventually P (at_left x) \<and> eventually P (at_right x)"
  by (subst at_eq_sup_left_right) (simp add: eventually_sup)

subsection {* Limits *}

definition filterlim :: "('a \<Rightarrow> 'b) \<Rightarrow> 'b filter \<Rightarrow> 'a filter \<Rightarrow> bool" where
  "filterlim f F2 F1 \<longleftrightarrow> filtermap f F1 \<le> F2"

syntax
  "_LIM" :: "pttrns \<Rightarrow> 'a \<Rightarrow> 'b \<Rightarrow> 'a \<Rightarrow> bool" ("(3LIM (_)/ (_)./ (_) :> (_))" [1000, 10, 0, 10] 10)

translations
  "LIM x F1. f :> F2"   == "CONST filterlim (%x. f) F2 F1"

lemma filterlim_iff:
  "(LIM x F1. f x :> F2) \<longleftrightarrow> (\<forall>P. eventually P F2 \<longrightarrow> eventually (\<lambda>x. P (f x)) F1)"
  unfolding filterlim_def le_filter_def eventually_filtermap ..

lemma filterlim_compose:
  "filterlim g F3 F2 \<Longrightarrow> filterlim f F2 F1 \<Longrightarrow> filterlim (\<lambda>x. g (f x)) F3 F1"
  unfolding filterlim_def filtermap_filtermap[symmetric] by (metis filtermap_mono order_trans)

lemma filterlim_mono:
  "filterlim f F2 F1 \<Longrightarrow> F2 \<le> F2' \<Longrightarrow> F1' \<le> F1 \<Longrightarrow> filterlim f F2' F1'"
  unfolding filterlim_def by (metis filtermap_mono order_trans)

lemma filterlim_ident: "LIM x F. x :> F"
  by (simp add: filterlim_def filtermap_ident)

lemma filterlim_cong:
  "F1 = F1' \<Longrightarrow> F2 = F2' \<Longrightarrow> eventually (\<lambda>x. f x = g x) F2 \<Longrightarrow> filterlim f F1 F2 = filterlim g F1' F2'"
  by (auto simp: filterlim_def le_filter_def eventually_filtermap elim: eventually_elim2)

lemma filterlim_mono_eventually:
  assumes "filterlim f F G" and ord: "F \<le> F'" "G' \<le> G"
  assumes eq: "eventually (\<lambda>x. f x = f' x) G'"
  shows "filterlim f' F' G'"
  apply (rule filterlim_cong[OF refl refl eq, THEN iffD1])
  apply (rule filterlim_mono[OF _ ord])
  apply fact
  done

lemma filtermap_mono_strong: "inj f \<Longrightarrow> filtermap f F \<le> filtermap f G \<longleftrightarrow> F \<le> G"
  apply (auto intro!: filtermap_mono) []
  apply (auto simp: le_filter_def eventually_filtermap)
  apply (erule_tac x="\<lambda>x. P (inv f x)" in allE)
  apply auto
  done

lemma filtermap_eq_strong: "inj f \<Longrightarrow> filtermap f F = filtermap f G \<longleftrightarrow> F = G"
  by (simp add: filtermap_mono_strong eq_iff)

lemma filterlim_principal:
  "(LIM x F. f x :> principal S) \<longleftrightarrow> (eventually (\<lambda>x. f x \<in> S) F)"
  unfolding filterlim_def eventually_filtermap le_principal ..

lemma filterlim_inf:
  "(LIM x F1. f x :> inf F2 F3) \<longleftrightarrow> ((LIM x F1. f x :> F2) \<and> (LIM x F1. f x :> F3))"
  unfolding filterlim_def by simp

lemma filterlim_INF:
  "(LIM x F. f x :> (INF b:B. G b)) \<longleftrightarrow> (\<forall>b\<in>B. LIM x F. f x :> G b)"
  unfolding filterlim_def le_INF_iff ..

lemma filterlim_INF_INF:
  "(\<And>m. m \<in> J \<Longrightarrow> \<exists>i\<in>I. filtermap f (F i) \<le> G m) \<Longrightarrow> LIM x (INF i:I. F i). f x :> (INF j:J. G j)"
  unfolding filterlim_def by (rule order_trans[OF filtermap_INF INF_mono])

lemma filterlim_base:
  "(\<And>m x. m \<in> J \<Longrightarrow> i m \<in> I) \<Longrightarrow> (\<And>m x. m \<in> J \<Longrightarrow> x \<in> F (i m) \<Longrightarrow> f x \<in> G m) \<Longrightarrow> 
    LIM x (INF i:I. principal (F i)). f x :> (INF j:J. principal (G j))"
  by (force intro!: filterlim_INF_INF simp: image_subset_iff)

lemma filterlim_base_iff: 
  assumes "I \<noteq> {}" and chain: "\<And>i j. i \<in> I \<Longrightarrow> j \<in> I \<Longrightarrow> F i \<subseteq> F j \<or> F j \<subseteq> F i"
  shows "(LIM x (INF i:I. principal (F i)). f x :> INF j:J. principal (G j)) \<longleftrightarrow>
    (\<forall>j\<in>J. \<exists>i\<in>I. \<forall>x\<in>F i. f x \<in> G j)"
  unfolding filterlim_INF filterlim_principal
proof (subst eventually_INF_base)
  fix i j assume "i \<in> I" "j \<in> I"
  with chain[OF this] show "\<exists>x\<in>I. principal (F x) \<le> inf (principal (F i)) (principal (F j))"
    by auto
qed (auto simp: eventually_principal `I \<noteq> {}`)

lemma filterlim_filtermap: "filterlim f F1 (filtermap g F2) = filterlim (\<lambda>x. f (g x)) F1 F2"
  unfolding filterlim_def filtermap_filtermap ..

lemma filterlim_sup:
  "filterlim f F F1 \<Longrightarrow> filterlim f F F2 \<Longrightarrow> filterlim f F (sup F1 F2)"
  unfolding filterlim_def filtermap_sup by auto

lemma eventually_sequentially_Suc: "eventually (\<lambda>i. P (Suc i)) sequentially \<longleftrightarrow> eventually P sequentially"
  unfolding eventually_sequentially by (metis Suc_le_D Suc_le_mono le_Suc_eq)

lemma filterlim_sequentially_Suc:
  "(LIM x sequentially. f (Suc x) :> F) \<longleftrightarrow> (LIM x sequentially. f x :> F)"
  unfolding filterlim_iff by (subst eventually_sequentially_Suc) simp

lemma filterlim_Suc: "filterlim Suc sequentially sequentially"
  by (simp add: filterlim_iff eventually_sequentially) (metis le_Suc_eq)

subsubsection {* Tendsto *}

abbreviation (in topological_space)
  tendsto :: "('b \<Rightarrow> 'a) \<Rightarrow> 'a \<Rightarrow> 'b filter \<Rightarrow> bool" (infixr "--->" 55) where
  "(f ---> l) F \<equiv> filterlim f (nhds l) F"

definition (in t2_space) Lim :: "'f filter \<Rightarrow> ('f \<Rightarrow> 'a) \<Rightarrow> 'a" where
  "Lim A f = (THE l. (f ---> l) A)"

lemma tendsto_eq_rhs: "(f ---> x) F \<Longrightarrow> x = y \<Longrightarrow> (f ---> y) F"
  by simp

named_theorems tendsto_intros "introduction rules for tendsto"
setup {*
  Global_Theory.add_thms_dynamic (@{binding tendsto_eq_intros},
    fn context =>
      Named_Theorems.get (Context.proof_of context) @{named_theorems tendsto_intros}
      |> map_filter (try (fn thm => @{thm tendsto_eq_rhs} OF [thm])))
*}

lemma (in topological_space) tendsto_def:
   "(f ---> l) F \<longleftrightarrow> (\<forall>S. open S \<longrightarrow> l \<in> S \<longrightarrow> eventually (\<lambda>x. f x \<in> S) F)"
   unfolding nhds_def filterlim_INF filterlim_principal by auto

lemma tendsto_mono: "F \<le> F' \<Longrightarrow> (f ---> l) F' \<Longrightarrow> (f ---> l) F"
  unfolding tendsto_def le_filter_def by fast

lemma tendsto_within_subset: "(f ---> l) (at x within S) \<Longrightarrow> T \<subseteq> S \<Longrightarrow> (f ---> l) (at x within T)"
  by (blast intro: tendsto_mono at_le)

lemma filterlim_at:
  "(LIM x F. f x :> at b within s) \<longleftrightarrow> (eventually (\<lambda>x. f x \<in> s \<and> f x \<noteq> b) F \<and> (f ---> b) F)"
  by (simp add: at_within_def filterlim_inf filterlim_principal conj_commute)

lemma (in topological_space) topological_tendstoI:
  "(\<And>S. open S \<Longrightarrow> l \<in> S \<Longrightarrow> eventually (\<lambda>x. f x \<in> S) F) \<Longrightarrow> (f ---> l) F"
  unfolding tendsto_def by auto

lemma (in topological_space) topological_tendstoD:
  "(f ---> l) F \<Longrightarrow> open S \<Longrightarrow> l \<in> S \<Longrightarrow> eventually (\<lambda>x. f x \<in> S) F"
  unfolding tendsto_def by auto

lemma (in order_topology) order_tendsto_iff:
  "(f ---> x) F \<longleftrightarrow> (\<forall>l<x. eventually (\<lambda>x. l < f x) F) \<and> (\<forall>u>x. eventually (\<lambda>x. f x < u) F)"
  unfolding nhds_order filterlim_inf filterlim_INF filterlim_principal by auto

lemma (in order_topology) order_tendstoI:
  "(\<And>a. a < y \<Longrightarrow> eventually (\<lambda>x. a < f x) F) \<Longrightarrow> (\<And>a. y < a \<Longrightarrow> eventually (\<lambda>x. f x < a) F) \<Longrightarrow>
    (f ---> y) F"
  unfolding order_tendsto_iff by auto

lemma (in order_topology) order_tendstoD:
  assumes "(f ---> y) F"
  shows "a < y \<Longrightarrow> eventually (\<lambda>x. a < f x) F"
    and "y < a \<Longrightarrow> eventually (\<lambda>x. f x < a) F"
  using assms unfolding order_tendsto_iff by auto

lemma tendsto_bot [simp]: "(f ---> a) bot"
  unfolding tendsto_def by simp

lemma (in linorder_topology) tendsto_max:
  assumes X: "(X ---> x) net"
  assumes Y: "(Y ---> y) net"
  shows "((\<lambda>x. max (X x) (Y x)) ---> max x y) net"
proof (rule order_tendstoI)
  fix a assume "a < max x y"
  then show "eventually (\<lambda>x. a < max (X x) (Y x)) net"
    using order_tendstoD(1)[OF X, of a] order_tendstoD(1)[OF Y, of a]
    by (auto simp: less_max_iff_disj elim: eventually_elim1)
next
  fix a assume "max x y < a"
  then show "eventually (\<lambda>x. max (X x) (Y x) < a) net"
    using order_tendstoD(2)[OF X, of a] order_tendstoD(2)[OF Y, of a]
    by (auto simp: eventually_conj_iff)
qed

lemma (in linorder_topology) tendsto_min:
  assumes X: "(X ---> x) net"
  assumes Y: "(Y ---> y) net"
  shows "((\<lambda>x. min (X x) (Y x)) ---> min x y) net"
proof (rule order_tendstoI)
  fix a assume "a < min x y"
  then show "eventually (\<lambda>x. a < min (X x) (Y x)) net"
    using order_tendstoD(1)[OF X, of a] order_tendstoD(1)[OF Y, of a]
    by (auto simp: eventually_conj_iff)
next
  fix a assume "min x y < a"
  then show "eventually (\<lambda>x. min (X x) (Y x) < a) net"
    using order_tendstoD(2)[OF X, of a] order_tendstoD(2)[OF Y, of a]
    by (auto simp: min_less_iff_disj elim: eventually_elim1)
qed

lemma tendsto_ident_at [tendsto_intros, simp, intro]: "((\<lambda>x. x) ---> a) (at a within s)"
  unfolding tendsto_def eventually_at_topological by auto

lemma (in topological_space) tendsto_const [tendsto_intros, simp, intro]: "((\<lambda>x. k) ---> k) F"
  by (simp add: tendsto_def)

lemma (in t2_space) tendsto_unique:
  assumes "F \<noteq> bot" and "(f ---> a) F" and "(f ---> b) F"
  shows "a = b"
proof (rule ccontr)
  assume "a \<noteq> b"
  obtain U V where "open U" "open V" "a \<in> U" "b \<in> V" "U \<inter> V = {}"
    using hausdorff [OF `a \<noteq> b`] by fast
  have "eventually (\<lambda>x. f x \<in> U) F"
    using `(f ---> a) F` `open U` `a \<in> U` by (rule topological_tendstoD)
  moreover
  have "eventually (\<lambda>x. f x \<in> V) F"
    using `(f ---> b) F` `open V` `b \<in> V` by (rule topological_tendstoD)
  ultimately
  have "eventually (\<lambda>x. False) F"
  proof eventually_elim
    case (elim x)
    hence "f x \<in> U \<inter> V" by simp
    with `U \<inter> V = {}` show ?case by simp
  qed
  with `\<not> trivial_limit F` show "False"
    by (simp add: trivial_limit_def)
qed

lemma (in t2_space) tendsto_const_iff:
  assumes "\<not> trivial_limit F" shows "((\<lambda>x. a :: 'a) ---> b) F \<longleftrightarrow> a = b"
  by (auto intro!: tendsto_unique [OF assms tendsto_const])

lemma increasing_tendsto:
  fixes f :: "_ \<Rightarrow> 'a::order_topology"
  assumes bdd: "eventually (\<lambda>n. f n \<le> l) F"
      and en: "\<And>x. x < l \<Longrightarrow> eventually (\<lambda>n. x < f n) F"
  shows "(f ---> l) F"
  using assms by (intro order_tendstoI) (auto elim!: eventually_elim1)

lemma decreasing_tendsto:
  fixes f :: "_ \<Rightarrow> 'a::order_topology"
  assumes bdd: "eventually (\<lambda>n. l \<le> f n) F"
      and en: "\<And>x. l < x \<Longrightarrow> eventually (\<lambda>n. f n < x) F"
  shows "(f ---> l) F"
  using assms by (intro order_tendstoI) (auto elim!: eventually_elim1)

lemma tendsto_sandwich:
  fixes f g h :: "'a \<Rightarrow> 'b::order_topology"
  assumes ev: "eventually (\<lambda>n. f n \<le> g n) net" "eventually (\<lambda>n. g n \<le> h n) net"
  assumes lim: "(f ---> c) net" "(h ---> c) net"
  shows "(g ---> c) net"
proof (rule order_tendstoI)
  fix a show "a < c \<Longrightarrow> eventually (\<lambda>x. a < g x) net"
    using order_tendstoD[OF lim(1), of a] ev by (auto elim: eventually_elim2)
next
  fix a show "c < a \<Longrightarrow> eventually (\<lambda>x. g x < a) net"
    using order_tendstoD[OF lim(2), of a] ev by (auto elim: eventually_elim2)
qed

lemma tendsto_le:
  fixes f g :: "'a \<Rightarrow> 'b::linorder_topology"
  assumes F: "\<not> trivial_limit F"
  assumes x: "(f ---> x) F" and y: "(g ---> y) F"
  assumes ev: "eventually (\<lambda>x. g x \<le> f x) F"
  shows "y \<le> x"
proof (rule ccontr)
  assume "\<not> y \<le> x"
  with less_separate[of x y] obtain a b where xy: "x < a" "b < y" "{..<a} \<inter> {b<..} = {}"
    by (auto simp: not_le)
  then have "eventually (\<lambda>x. f x < a) F" "eventually (\<lambda>x. b < g x) F"
    using x y by (auto intro: order_tendstoD)
  with ev have "eventually (\<lambda>x. False) F"
    by eventually_elim (insert xy, fastforce)
  with F show False
    by (simp add: eventually_False)
qed

lemma tendsto_le_const:
  fixes f :: "'a \<Rightarrow> 'b::linorder_topology"
  assumes F: "\<not> trivial_limit F"
  assumes x: "(f ---> x) F" and a: "eventually (\<lambda>i. a \<le> f i) F"
  shows "a \<le> x"
  using F x tendsto_const a by (rule tendsto_le)

lemma tendsto_ge_const:
  fixes f :: "'a \<Rightarrow> 'b::linorder_topology"
  assumes F: "\<not> trivial_limit F"
  assumes x: "(f ---> x) F" and a: "eventually (\<lambda>i. a \<ge> f i) F"
  shows "a \<ge> x"
  by (rule tendsto_le [OF F tendsto_const x a])

subsubsection {* Rules about @{const Lim} *}

lemma tendsto_Lim:
  "\<not>(trivial_limit net) \<Longrightarrow> (f ---> l) net \<Longrightarrow> Lim net f = l"
  unfolding Lim_def using tendsto_unique[of net f] by auto

lemma Lim_ident_at: "\<not> trivial_limit (at x within s) \<Longrightarrow> Lim (at x within s) (\<lambda>x. x) = x"
  by (rule tendsto_Lim[OF _ tendsto_ident_at]) auto

subsection {* Limits to @{const at_top} and @{const at_bot} *}

lemma filterlim_at_top:
  fixes f :: "'a \<Rightarrow> ('b::linorder)"
  shows "(LIM x F. f x :> at_top) \<longleftrightarrow> (\<forall>Z. eventually (\<lambda>x. Z \<le> f x) F)"
  by (auto simp: filterlim_iff eventually_at_top_linorder elim!: eventually_elim1)

lemma filterlim_at_top_mono:
  "LIM x F. f x :> at_top \<Longrightarrow> eventually (\<lambda>x. f x \<le> (g x::'a::linorder)) F \<Longrightarrow>
    LIM x F. g x :> at_top"
  by (auto simp: filterlim_at_top elim: eventually_elim2 intro: order_trans)

lemma filterlim_at_top_dense:
  fixes f :: "'a \<Rightarrow> ('b::unbounded_dense_linorder)"
  shows "(LIM x F. f x :> at_top) \<longleftrightarrow> (\<forall>Z. eventually (\<lambda>x. Z < f x) F)"
  by (metis eventually_elim1[of _ F] eventually_gt_at_top order_less_imp_le
            filterlim_at_top[of f F] filterlim_iff[of f at_top F])

lemma filterlim_at_top_ge:
  fixes f :: "'a \<Rightarrow> ('b::linorder)" and c :: "'b"
  shows "(LIM x F. f x :> at_top) \<longleftrightarrow> (\<forall>Z\<ge>c. eventually (\<lambda>x. Z \<le> f x) F)"
  unfolding at_top_sub[of c] filterlim_INF by (auto simp add: filterlim_principal)

lemma filterlim_at_top_at_top:
  fixes f :: "'a::linorder \<Rightarrow> 'b::linorder"
  assumes mono: "\<And>x y. Q x \<Longrightarrow> Q y \<Longrightarrow> x \<le> y \<Longrightarrow> f x \<le> f y"
  assumes bij: "\<And>x. P x \<Longrightarrow> f (g x) = x" "\<And>x. P x \<Longrightarrow> Q (g x)"
  assumes Q: "eventually Q at_top"
  assumes P: "eventually P at_top"
  shows "filterlim f at_top at_top"
proof -
  from P obtain x where x: "\<And>y. x \<le> y \<Longrightarrow> P y"
    unfolding eventually_at_top_linorder by auto
  show ?thesis
  proof (intro filterlim_at_top_ge[THEN iffD2] allI impI)
    fix z assume "x \<le> z"
    with x have "P z" by auto
    have "eventually (\<lambda>x. g z \<le> x) at_top"
      by (rule eventually_ge_at_top)
    with Q show "eventually (\<lambda>x. z \<le> f x) at_top"
      by eventually_elim (metis mono bij `P z`)
  qed
qed

lemma filterlim_at_top_gt:
  fixes f :: "'a \<Rightarrow> ('b::unbounded_dense_linorder)" and c :: "'b"
  shows "(LIM x F. f x :> at_top) \<longleftrightarrow> (\<forall>Z>c. eventually (\<lambda>x. Z \<le> f x) F)"
  by (metis filterlim_at_top order_less_le_trans gt_ex filterlim_at_top_ge)

lemma filterlim_at_bot: 
  fixes f :: "'a \<Rightarrow> ('b::linorder)"
  shows "(LIM x F. f x :> at_bot) \<longleftrightarrow> (\<forall>Z. eventually (\<lambda>x. f x \<le> Z) F)"
  by (auto simp: filterlim_iff eventually_at_bot_linorder elim!: eventually_elim1)

lemma filterlim_at_bot_dense:
  fixes f :: "'a \<Rightarrow> ('b::{dense_linorder, no_bot})"
  shows "(LIM x F. f x :> at_bot) \<longleftrightarrow> (\<forall>Z. eventually (\<lambda>x. f x < Z) F)"
proof (auto simp add: filterlim_at_bot[of f F])
  fix Z :: 'b
  from lt_ex [of Z] obtain Z' where 1: "Z' < Z" ..
  assume "\<forall>Z. eventually (\<lambda>x. f x \<le> Z) F"
  hence "eventually (\<lambda>x. f x \<le> Z') F" by auto
  thus "eventually (\<lambda>x. f x < Z) F"
    apply (rule eventually_mono[rotated])
    using 1 by auto
  next 
    fix Z :: 'b 
    show "\<forall>Z. eventually (\<lambda>x. f x < Z) F \<Longrightarrow> eventually (\<lambda>x. f x \<le> Z) F"
      by (drule spec [of _ Z], erule eventually_mono[rotated], auto simp add: less_imp_le)
qed

lemma filterlim_at_bot_le:
  fixes f :: "'a \<Rightarrow> ('b::linorder)" and c :: "'b"
  shows "(LIM x F. f x :> at_bot) \<longleftrightarrow> (\<forall>Z\<le>c. eventually (\<lambda>x. Z \<ge> f x) F)"
  unfolding filterlim_at_bot
proof safe
  fix Z assume *: "\<forall>Z\<le>c. eventually (\<lambda>x. Z \<ge> f x) F"
  with *[THEN spec, of "min Z c"] show "eventually (\<lambda>x. Z \<ge> f x) F"
    by (auto elim!: eventually_elim1)
qed simp

lemma filterlim_at_bot_lt:
  fixes f :: "'a \<Rightarrow> ('b::unbounded_dense_linorder)" and c :: "'b"
  shows "(LIM x F. f x :> at_bot) \<longleftrightarrow> (\<forall>Z<c. eventually (\<lambda>x. Z \<ge> f x) F)"
  by (metis filterlim_at_bot filterlim_at_bot_le lt_ex order_le_less_trans)

lemma filterlim_at_bot_at_right:
  fixes f :: "'a::linorder_topology \<Rightarrow> 'b::linorder"
  assumes mono: "\<And>x y. Q x \<Longrightarrow> Q y \<Longrightarrow> x \<le> y \<Longrightarrow> f x \<le> f y"
  assumes bij: "\<And>x. P x \<Longrightarrow> f (g x) = x" "\<And>x. P x \<Longrightarrow> Q (g x)"
  assumes Q: "eventually Q (at_right a)" and bound: "\<And>b. Q b \<Longrightarrow> a < b"
  assumes P: "eventually P at_bot"
  shows "filterlim f at_bot (at_right a)"
proof -
  from P obtain x where x: "\<And>y. y \<le> x \<Longrightarrow> P y"
    unfolding eventually_at_bot_linorder by auto
  show ?thesis
  proof (intro filterlim_at_bot_le[THEN iffD2] allI impI)
    fix z assume "z \<le> x"
    with x have "P z" by auto
    have "eventually (\<lambda>x. x \<le> g z) (at_right a)"
      using bound[OF bij(2)[OF `P z`]]
      unfolding eventually_at_right[OF bound[OF bij(2)[OF `P z`]]] by (auto intro!: exI[of _ "g z"])
    with Q show "eventually (\<lambda>x. f x \<le> z) (at_right a)"
      by eventually_elim (metis bij `P z` mono)
  qed
qed

lemma filterlim_at_top_at_left:
  fixes f :: "'a::linorder_topology \<Rightarrow> 'b::linorder"
  assumes mono: "\<And>x y. Q x \<Longrightarrow> Q y \<Longrightarrow> x \<le> y \<Longrightarrow> f x \<le> f y"
  assumes bij: "\<And>x. P x \<Longrightarrow> f (g x) = x" "\<And>x. P x \<Longrightarrow> Q (g x)"
  assumes Q: "eventually Q (at_left a)" and bound: "\<And>b. Q b \<Longrightarrow> b < a"
  assumes P: "eventually P at_top"
  shows "filterlim f at_top (at_left a)"
proof -
  from P obtain x where x: "\<And>y. x \<le> y \<Longrightarrow> P y"
    unfolding eventually_at_top_linorder by auto
  show ?thesis
  proof (intro filterlim_at_top_ge[THEN iffD2] allI impI)
    fix z assume "x \<le> z"
    with x have "P z" by auto
    have "eventually (\<lambda>x. g z \<le> x) (at_left a)"
      using bound[OF bij(2)[OF `P z`]]
      unfolding eventually_at_left[OF bound[OF bij(2)[OF `P z`]]] by (auto intro!: exI[of _ "g z"])
    with Q show "eventually (\<lambda>x. z \<le> f x) (at_left a)"
      by eventually_elim (metis bij `P z` mono)
  qed
qed

lemma filterlim_split_at:
  "filterlim f F (at_left x) \<Longrightarrow> filterlim f F (at_right x) \<Longrightarrow> filterlim f F (at (x::'a::linorder_topology))"
  by (subst at_eq_sup_left_right) (rule filterlim_sup)

lemma filterlim_at_split:
  "filterlim f F (at (x::'a::linorder_topology)) \<longleftrightarrow> filterlim f F (at_left x) \<and> filterlim f F (at_right x)"
  by (subst at_eq_sup_left_right) (simp add: filterlim_def filtermap_sup)

lemma eventually_nhds_top:
  fixes P :: "'a :: {order_top, linorder_topology} \<Rightarrow> bool"
  assumes "(b::'a) < top"
  shows "eventually P (nhds top) \<longleftrightarrow> (\<exists>b<top. (\<forall>z. b < z \<longrightarrow> P z))"
  unfolding eventually_nhds
proof safe
  fix S :: "'a set" assume "open S" "top \<in> S"
  note open_left[OF this `b < top`]
  moreover assume "\<forall>s\<in>S. P s"
  ultimately show "\<exists>b<top. \<forall>z>b. P z"
    by (auto simp: subset_eq Ball_def)
next
  fix b assume "b < top" "\<forall>z>b. P z"
  then show "\<exists>S. open S \<and> top \<in> S \<and> (\<forall>xa\<in>S. P xa)"
    by (intro exI[of _ "{b <..}"]) auto
qed

lemma tendsto_at_within_iff_tendsto_nhds:
  "(g ---> g l) (at l within S) \<longleftrightarrow> (g ---> g l) (inf (nhds l) (principal S))"
  unfolding tendsto_def eventually_at_filter eventually_inf_principal
  by (intro ext all_cong imp_cong) (auto elim!: eventually_elim1)

subsection {* Limits on sequences *}

abbreviation (in topological_space)
  LIMSEQ :: "[nat \<Rightarrow> 'a, 'a] \<Rightarrow> bool"
    ("((_)/ ----> (_))" [60, 60] 60) where
  "X ----> L \<equiv> (X ---> L) sequentially"

abbreviation (in t2_space) lim :: "(nat \<Rightarrow> 'a) \<Rightarrow> 'a" where
  "lim X \<equiv> Lim sequentially X"

definition (in topological_space) convergent :: "(nat \<Rightarrow> 'a) \<Rightarrow> bool" where
  "convergent X = (\<exists>L. X ----> L)"

lemma lim_def: "lim X = (THE L. X ----> L)"
  unfolding Lim_def ..

subsubsection {* Monotone sequences and subsequences *}

definition
  monoseq :: "(nat \<Rightarrow> 'a::order) \<Rightarrow> bool" where
    --{*Definition of monotonicity.
        The use of disjunction here complicates proofs considerably.
        One alternative is to add a Boolean argument to indicate the direction.
        Another is to develop the notions of increasing and decreasing first.*}
  "monoseq X = ((\<forall>m. \<forall>n\<ge>m. X m \<le> X n) \<or> (\<forall>m. \<forall>n\<ge>m. X n \<le> X m))"

abbreviation incseq :: "(nat \<Rightarrow> 'a::order) \<Rightarrow> bool" where
  "incseq X \<equiv> mono X"

lemma incseq_def: "incseq X \<longleftrightarrow> (\<forall>m. \<forall>n\<ge>m. X n \<ge> X m)"
  unfolding mono_def ..

abbreviation decseq :: "(nat \<Rightarrow> 'a::order) \<Rightarrow> bool" where
  "decseq X \<equiv> antimono X"

lemma decseq_def: "decseq X \<longleftrightarrow> (\<forall>m. \<forall>n\<ge>m. X n \<le> X m)"
  unfolding antimono_def ..

definition
  subseq :: "(nat \<Rightarrow> nat) \<Rightarrow> bool" where
    --{*Definition of subsequence*}
  "subseq f \<longleftrightarrow> (\<forall>m. \<forall>n>m. f m < f n)"

lemma incseq_SucI:
  "(\<And>n. X n \<le> X (Suc n)) \<Longrightarrow> incseq X"
  using lift_Suc_mono_le[of X]
  by (auto simp: incseq_def)

lemma incseqD: "\<And>i j. incseq f \<Longrightarrow> i \<le> j \<Longrightarrow> f i \<le> f j"
  by (auto simp: incseq_def)

lemma incseq_SucD: "incseq A \<Longrightarrow> A i \<le> A (Suc i)"
  using incseqD[of A i "Suc i"] by auto

lemma incseq_Suc_iff: "incseq f \<longleftrightarrow> (\<forall>n. f n \<le> f (Suc n))"
  by (auto intro: incseq_SucI dest: incseq_SucD)

lemma incseq_const[simp, intro]: "incseq (\<lambda>x. k)"
  unfolding incseq_def by auto

lemma decseq_SucI:
  "(\<And>n. X (Suc n) \<le> X n) \<Longrightarrow> decseq X"
  using order.lift_Suc_mono_le[OF dual_order, of X]
  by (auto simp: decseq_def)

lemma decseqD: "\<And>i j. decseq f \<Longrightarrow> i \<le> j \<Longrightarrow> f j \<le> f i"
  by (auto simp: decseq_def)

lemma decseq_SucD: "decseq A \<Longrightarrow> A (Suc i) \<le> A i"
  using decseqD[of A i "Suc i"] by auto

lemma decseq_Suc_iff: "decseq f \<longleftrightarrow> (\<forall>n. f (Suc n) \<le> f n)"
  by (auto intro: decseq_SucI dest: decseq_SucD)

lemma decseq_const[simp, intro]: "decseq (\<lambda>x. k)"
  unfolding decseq_def by auto

lemma monoseq_iff: "monoseq X \<longleftrightarrow> incseq X \<or> decseq X"
  unfolding monoseq_def incseq_def decseq_def ..

lemma monoseq_Suc:
  "monoseq X \<longleftrightarrow> (\<forall>n. X n \<le> X (Suc n)) \<or> (\<forall>n. X (Suc n) \<le> X n)"
  unfolding monoseq_iff incseq_Suc_iff decseq_Suc_iff ..

lemma monoI1: "\<forall>m. \<forall> n \<ge> m. X m \<le> X n ==> monoseq X"
by (simp add: monoseq_def)

lemma monoI2: "\<forall>m. \<forall> n \<ge> m. X n \<le> X m ==> monoseq X"
by (simp add: monoseq_def)

lemma mono_SucI1: "\<forall>n. X n \<le> X (Suc n) ==> monoseq X"
by (simp add: monoseq_Suc)

lemma mono_SucI2: "\<forall>n. X (Suc n) \<le> X n ==> monoseq X"
by (simp add: monoseq_Suc)

lemma monoseq_minus:
  fixes a :: "nat \<Rightarrow> 'a::ordered_ab_group_add"
  assumes "monoseq a"
  shows "monoseq (\<lambda> n. - a n)"
proof (cases "\<forall> m. \<forall> n \<ge> m. a m \<le> a n")
  case True
  hence "\<forall> m. \<forall> n \<ge> m. - a n \<le> - a m" by auto
  thus ?thesis by (rule monoI2)
next
  case False
  hence "\<forall> m. \<forall> n \<ge> m. - a m \<le> - a n" using `monoseq a`[unfolded monoseq_def] by auto
  thus ?thesis by (rule monoI1)
qed

text{*Subsequence (alternative definition, (e.g. Hoskins)*}

lemma subseq_Suc_iff: "subseq f = (\<forall>n. (f n) < (f (Suc n)))"
apply (simp add: subseq_def)
apply (auto dest!: less_imp_Suc_add)
apply (induct_tac k)
apply (auto intro: less_trans)
done

text{* for any sequence, there is a monotonic subsequence *}
lemma seq_monosub:
  fixes s :: "nat => 'a::linorder"
  shows "\<exists>f. subseq f \<and> monoseq (\<lambda>n. (s (f n)))"
proof cases
  assume "\<forall>n. \<exists>p>n. \<forall>m\<ge>p. s m \<le> s p"
  then have "\<exists>f. \<forall>n. (\<forall>m\<ge>f n. s m \<le> s (f n)) \<and> f n < f (Suc n)"
    by (intro dependent_nat_choice) (auto simp: conj_commute)
  then obtain f where "subseq f" and mono: "\<And>n m. f n \<le> m \<Longrightarrow> s m \<le> s (f n)"
    by (auto simp: subseq_Suc_iff)
  moreover 
  then have "incseq f"
    unfolding subseq_Suc_iff incseq_Suc_iff by (auto intro: less_imp_le)
  then have "monoseq (\<lambda>n. s (f n))"
    by (auto simp add: incseq_def intro!: mono monoI2)
  ultimately show ?thesis
    by auto
next
  assume "\<not> (\<forall>n. \<exists>p>n. (\<forall>m\<ge>p. s m \<le> s p))"
  then obtain N where N: "\<And>p. p > N \<Longrightarrow> \<exists>m>p. s p < s m" by (force simp: not_le le_less)
  have "\<exists>f. \<forall>n. N < f n \<and> f n < f (Suc n) \<and> s (f n) \<le> s (f (Suc n))"
  proof (intro dependent_nat_choice)
    fix x assume "N < x" with N[of x] show "\<exists>y>N. x < y \<and> s x \<le> s y"
      by (auto intro: less_trans)
  qed auto
  then show ?thesis
    by (auto simp: monoseq_iff incseq_Suc_iff subseq_Suc_iff)
qed

lemma seq_suble: assumes sf: "subseq f" shows "n \<le> f n"
proof(induct n)
  case 0 thus ?case by simp
next
  case (Suc n)
  from sf[unfolded subseq_Suc_iff, rule_format, of n] Suc.hyps
  have "n < f (Suc n)" by arith
  thus ?case by arith
qed

lemma eventually_subseq:
  "subseq r \<Longrightarrow> eventually P sequentially \<Longrightarrow> eventually (\<lambda>n. P (r n)) sequentially"
  unfolding eventually_sequentially by (metis seq_suble le_trans)

lemma not_eventually_sequentiallyD:
  assumes P: "\<not> eventually P sequentially"
  shows "\<exists>r. subseq r \<and> (\<forall>n. \<not> P (r n))"
proof -
  from P have "\<forall>n. \<exists>m\<ge>n. \<not> P m"
    unfolding eventually_sequentially by (simp add: not_less)
  then obtain r where "\<And>n. r n \<ge> n" "\<And>n. \<not> P (r n)"
    by (auto simp: choice_iff)
  then show ?thesis
    by (auto intro!: exI[of _ "\<lambda>n. r (((Suc \<circ> r) ^^ Suc n) 0)"]
             simp: less_eq_Suc_le subseq_Suc_iff)
qed

lemma filterlim_subseq: "subseq f \<Longrightarrow> filterlim f sequentially sequentially"
  unfolding filterlim_iff by (metis eventually_subseq)

lemma subseq_o: "subseq r \<Longrightarrow> subseq s \<Longrightarrow> subseq (r \<circ> s)"
  unfolding subseq_def by simp

lemma subseq_mono: assumes "subseq r" "m < n" shows "r m < r n"
  using assms by (auto simp: subseq_def)

lemma incseq_imp_monoseq:  "incseq X \<Longrightarrow> monoseq X"
  by (simp add: incseq_def monoseq_def)

lemma decseq_imp_monoseq:  "decseq X \<Longrightarrow> monoseq X"
  by (simp add: decseq_def monoseq_def)

lemma decseq_eq_incseq:
  fixes X :: "nat \<Rightarrow> 'a::ordered_ab_group_add" shows "decseq X = incseq (\<lambda>n. - X n)" 
  by (simp add: decseq_def incseq_def)

lemma INT_decseq_offset:
  assumes "decseq F"
  shows "(\<Inter>i. F i) = (\<Inter>i\<in>{n..}. F i)"
proof safe
  fix x i assume x: "x \<in> (\<Inter>i\<in>{n..}. F i)"
  show "x \<in> F i"
  proof cases
    from x have "x \<in> F n" by auto
    also assume "i \<le> n" with `decseq F` have "F n \<subseteq> F i"
      unfolding decseq_def by simp
    finally show ?thesis .
  qed (insert x, simp)
qed auto

lemma LIMSEQ_const_iff:
  fixes k l :: "'a::t2_space"
  shows "(\<lambda>n. k) ----> l \<longleftrightarrow> k = l"
  using trivial_limit_sequentially by (rule tendsto_const_iff)

lemma LIMSEQ_SUP:
  "incseq X \<Longrightarrow> X ----> (SUP i. X i :: 'a :: {complete_linorder, linorder_topology})"
  by (intro increasing_tendsto)
     (auto simp: SUP_upper less_SUP_iff incseq_def eventually_sequentially intro: less_le_trans)

lemma LIMSEQ_INF:
  "decseq X \<Longrightarrow> X ----> (INF i. X i :: 'a :: {complete_linorder, linorder_topology})"
  by (intro decreasing_tendsto)
     (auto simp: INF_lower INF_less_iff decseq_def eventually_sequentially intro: le_less_trans)

lemma LIMSEQ_ignore_initial_segment:
  "f ----> a \<Longrightarrow> (\<lambda>n. f (n + k)) ----> a"
  unfolding tendsto_def
  by (subst eventually_sequentially_seg[where k=k])

lemma LIMSEQ_offset:
  "(\<lambda>n. f (n + k)) ----> a \<Longrightarrow> f ----> a"
  unfolding tendsto_def
  by (subst (asm) eventually_sequentially_seg[where k=k])

lemma LIMSEQ_Suc: "f ----> l \<Longrightarrow> (\<lambda>n. f (Suc n)) ----> l"
by (drule_tac k="Suc 0" in LIMSEQ_ignore_initial_segment, simp)

lemma LIMSEQ_imp_Suc: "(\<lambda>n. f (Suc n)) ----> l \<Longrightarrow> f ----> l"
by (rule_tac k="Suc 0" in LIMSEQ_offset, simp)

lemma LIMSEQ_Suc_iff: "(\<lambda>n. f (Suc n)) ----> l = f ----> l"
by (blast intro: LIMSEQ_imp_Suc LIMSEQ_Suc)

lemma LIMSEQ_unique:
  fixes a b :: "'a::t2_space"
  shows "\<lbrakk>X ----> a; X ----> b\<rbrakk> \<Longrightarrow> a = b"
  using trivial_limit_sequentially by (rule tendsto_unique)

lemma LIMSEQ_le_const:
  "\<lbrakk>X ----> (x::'a::linorder_topology); \<exists>N. \<forall>n\<ge>N. a \<le> X n\<rbrakk> \<Longrightarrow> a \<le> x"
  using tendsto_le_const[of sequentially X x a] by (simp add: eventually_sequentially)

lemma LIMSEQ_le:
  "\<lbrakk>X ----> x; Y ----> y; \<exists>N. \<forall>n\<ge>N. X n \<le> Y n\<rbrakk> \<Longrightarrow> x \<le> (y::'a::linorder_topology)"
  using tendsto_le[of sequentially Y y X x] by (simp add: eventually_sequentially)

lemma LIMSEQ_le_const2:
  "\<lbrakk>X ----> (x::'a::linorder_topology); \<exists>N. \<forall>n\<ge>N. X n \<le> a\<rbrakk> \<Longrightarrow> x \<le> a"
  by (rule LIMSEQ_le[of X x "\<lambda>n. a"]) auto

lemma convergentD: "convergent X ==> \<exists>L. (X ----> L)"
by (simp add: convergent_def)

lemma convergentI: "(X ----> L) ==> convergent X"
by (auto simp add: convergent_def)

lemma convergent_LIMSEQ_iff: "convergent X = (X ----> lim X)"
by (auto intro: theI LIMSEQ_unique simp add: convergent_def lim_def)

lemma convergent_const: "convergent (\<lambda>n. c)"
  by (rule convergentI, rule tendsto_const)

lemma monoseq_le:
  "monoseq a \<Longrightarrow> a ----> (x::'a::linorder_topology) \<Longrightarrow>
    ((\<forall> n. a n \<le> x) \<and> (\<forall>m. \<forall>n\<ge>m. a m \<le> a n)) \<or> ((\<forall> n. x \<le> a n) \<and> (\<forall>m. \<forall>n\<ge>m. a n \<le> a m))"
  by (metis LIMSEQ_le_const LIMSEQ_le_const2 decseq_def incseq_def monoseq_iff)

lemma LIMSEQ_subseq_LIMSEQ:
  "\<lbrakk> X ----> L; subseq f \<rbrakk> \<Longrightarrow> (X o f) ----> L"
  unfolding comp_def by (rule filterlim_compose[of X, OF _ filterlim_subseq])

lemma convergent_subseq_convergent:
  "\<lbrakk>convergent X; subseq f\<rbrakk> \<Longrightarrow> convergent (X o f)"
  unfolding convergent_def by (auto intro: LIMSEQ_subseq_LIMSEQ)

lemma limI: "X ----> L ==> lim X = L"
  by (rule tendsto_Lim) (rule trivial_limit_sequentially)

lemma lim_le: "convergent f \<Longrightarrow> (\<And>n. f n \<le> (x::'a::linorder_topology)) \<Longrightarrow> lim f \<le> x"
  using LIMSEQ_le_const2[of f "lim f" x] by (simp add: convergent_LIMSEQ_iff)

subsubsection{*Increasing and Decreasing Series*}

lemma incseq_le: "incseq X \<Longrightarrow> X ----> L \<Longrightarrow> X n \<le> (L::'a::linorder_topology)"
  by (metis incseq_def LIMSEQ_le_const)

lemma decseq_le: "decseq X \<Longrightarrow> X ----> L \<Longrightarrow> (L::'a::linorder_topology) \<le> X n"
  by (metis decseq_def LIMSEQ_le_const2)

subsection {* First countable topologies *}

class first_countable_topology = topological_space +
  assumes first_countable_basis:
    "\<exists>A::nat \<Rightarrow> 'a set. (\<forall>i. x \<in> A i \<and> open (A i)) \<and> (\<forall>S. open S \<and> x \<in> S \<longrightarrow> (\<exists>i. A i \<subseteq> S))"

lemma (in first_countable_topology) countable_basis_at_decseq:
  obtains A :: "nat \<Rightarrow> 'a set" where
    "\<And>i. open (A i)" "\<And>i. x \<in> (A i)"
    "\<And>S. open S \<Longrightarrow> x \<in> S \<Longrightarrow> eventually (\<lambda>i. A i \<subseteq> S) sequentially"
proof atomize_elim
  from first_countable_basis[of x] obtain A :: "nat \<Rightarrow> 'a set" where
    nhds: "\<And>i. open (A i)" "\<And>i. x \<in> A i"
    and incl: "\<And>S. open S \<Longrightarrow> x \<in> S \<Longrightarrow> \<exists>i. A i \<subseteq> S"  by auto
  def F \<equiv> "\<lambda>n. \<Inter>i\<le>n. A i"
  show "\<exists>A. (\<forall>i. open (A i)) \<and> (\<forall>i. x \<in> A i) \<and>
      (\<forall>S. open S \<longrightarrow> x \<in> S \<longrightarrow> eventually (\<lambda>i. A i \<subseteq> S) sequentially)"
  proof (safe intro!: exI[of _ F])
    fix i
    show "open (F i)" using nhds(1) by (auto simp: F_def)
    show "x \<in> F i" using nhds(2) by (auto simp: F_def)
  next
    fix S assume "open S" "x \<in> S"
    from incl[OF this] obtain i where "F i \<subseteq> S" unfolding F_def by auto
    moreover have "\<And>j. i \<le> j \<Longrightarrow> F j \<subseteq> F i"
      by (auto simp: F_def)
    ultimately show "eventually (\<lambda>i. F i \<subseteq> S) sequentially"
      by (auto simp: eventually_sequentially)
  qed
qed

lemma (in first_countable_topology) nhds_countable:
  obtains X :: "nat \<Rightarrow> 'a set"
  where "decseq X" "\<And>n. open (X n)" "\<And>n. x \<in> X n" "nhds x = (INF n. principal (X n))"
proof -
  from first_countable_basis obtain A :: "nat \<Rightarrow> 'a set"
    where A: "\<And>n. x \<in> A n" "\<And>n. open (A n)" "\<And>S. open S \<Longrightarrow> x \<in> S \<Longrightarrow> \<exists>i. A i \<subseteq> S"
    by metis
  show thesis
  proof
    show "decseq (\<lambda>n. \<Inter>i\<le>n. A i)"
      by (auto simp: decseq_def)
    show "\<And>n. x \<in> (\<Inter>i\<le>n. A i)" "\<And>n. open (\<Inter>i\<le>n. A i)"
      using A by auto
    show "nhds x = (INF n. principal (\<Inter> i\<le>n. A i))"
      using A unfolding nhds_def
      apply (intro INF_eq)
      apply simp_all
      apply force
      apply (intro exI[of _ "\<Inter> i\<le>n. A i" for n] conjI open_INT)
      apply auto
      done
  qed
qed

lemma (in first_countable_topology) countable_basis:
  obtains A :: "nat \<Rightarrow> 'a set" where
    "\<And>i. open (A i)" "\<And>i. x \<in> A i"
    "\<And>F. (\<forall>n. F n \<in> A n) \<Longrightarrow> F ----> x"
proof atomize_elim
  obtain A :: "nat \<Rightarrow> 'a set" where A:
    "\<And>i. open (A i)"
    "\<And>i. x \<in> A i"
    "\<And>S. open S \<Longrightarrow> x \<in> S \<Longrightarrow> eventually (\<lambda>i. A i \<subseteq> S) sequentially"
    by (rule countable_basis_at_decseq) blast
  {
    fix F S assume "\<forall>n. F n \<in> A n" "open S" "x \<in> S"
    with A(3)[of S] have "eventually (\<lambda>n. F n \<in> S) sequentially"
      by (auto elim: eventually_elim1 simp: subset_eq)
  }
  with A show "\<exists>A. (\<forall>i. open (A i)) \<and> (\<forall>i. x \<in> A i) \<and> (\<forall>F. (\<forall>n. F n \<in> A n) \<longrightarrow> F ----> x)"
    by (intro exI[of _ A]) (auto simp: tendsto_def)
qed

lemma (in first_countable_topology) sequentially_imp_eventually_nhds_within:
  assumes "\<forall>f. (\<forall>n. f n \<in> s) \<and> f ----> a \<longrightarrow> eventually (\<lambda>n. P (f n)) sequentially"
  shows "eventually P (inf (nhds a) (principal s))"
proof (rule ccontr)
  obtain A :: "nat \<Rightarrow> 'a set" where A:
    "\<And>i. open (A i)"
    "\<And>i. a \<in> A i"
    "\<And>F. \<forall>n. F n \<in> A n \<Longrightarrow> F ----> a"
    by (rule countable_basis) blast
  assume "\<not> ?thesis"
  with A have P: "\<exists>F. \<forall>n. F n \<in> s \<and> F n \<in> A n \<and> \<not> P (F n)"
    unfolding eventually_inf_principal eventually_nhds by (intro choice) fastforce
  then obtain F where F0: "\<forall>n. F n \<in> s" and F2: "\<forall>n. F n \<in> A n" and F3: "\<forall>n. \<not> P (F n)"
    by blast
  with A have "F ----> a" by auto
  hence "eventually (\<lambda>n. P (F n)) sequentially"
    using assms F0 by simp
  thus "False" by (simp add: F3)
qed

lemma (in first_countable_topology) eventually_nhds_within_iff_sequentially:
  "eventually P (inf (nhds a) (principal s)) \<longleftrightarrow> 
    (\<forall>f. (\<forall>n. f n \<in> s) \<and> f ----> a \<longrightarrow> eventually (\<lambda>n. P (f n)) sequentially)"
proof (safe intro!: sequentially_imp_eventually_nhds_within)
  assume "eventually P (inf (nhds a) (principal s))" 
  then obtain S where "open S" "a \<in> S" "\<forall>x\<in>S. x \<in> s \<longrightarrow> P x"
    by (auto simp: eventually_inf_principal eventually_nhds)
  moreover fix f assume "\<forall>n. f n \<in> s" "f ----> a"
  ultimately show "eventually (\<lambda>n. P (f n)) sequentially"
    by (auto dest!: topological_tendstoD elim: eventually_elim1)
qed

lemma (in first_countable_topology) eventually_nhds_iff_sequentially:
  "eventually P (nhds a) \<longleftrightarrow> (\<forall>f. f ----> a \<longrightarrow> eventually (\<lambda>n. P (f n)) sequentially)"
  using eventually_nhds_within_iff_sequentially[of P a UNIV] by simp

lemma tendsto_at_iff_sequentially:
  fixes f :: "'a :: first_countable_topology \<Rightarrow> _"
  shows "(f ---> a) (at x within s) \<longleftrightarrow> (\<forall>X. (\<forall>i. X i \<in> s - {x}) \<longrightarrow> X ----> x \<longrightarrow> ((f \<circ> X) ----> a))"
  unfolding filterlim_def[of _ "nhds a"] le_filter_def eventually_filtermap at_within_def eventually_nhds_within_iff_sequentially comp_def
  by metis

subsection {* Function limit at a point *}

abbreviation
  LIM :: "('a::topological_space \<Rightarrow> 'b::topological_space) \<Rightarrow> 'a \<Rightarrow> 'b \<Rightarrow> bool"
        ("((_)/ -- (_)/ --> (_))" [60, 0, 60] 60) where
  "f -- a --> L \<equiv> (f ---> L) (at a)"

lemma tendsto_within_open: "a \<in> S \<Longrightarrow> open S \<Longrightarrow> (f ---> l) (at a within S) \<longleftrightarrow> (f -- a --> l)"
  unfolding tendsto_def by (simp add: at_within_open[where S=S])

lemma LIM_const_not_eq[tendsto_intros]:
  fixes a :: "'a::perfect_space"
  fixes k L :: "'b::t2_space"
  shows "k \<noteq> L \<Longrightarrow> \<not> (\<lambda>x. k) -- a --> L"
  by (simp add: tendsto_const_iff)

lemmas LIM_not_zero = LIM_const_not_eq [where L = 0]

lemma LIM_const_eq:
  fixes a :: "'a::perfect_space"
  fixes k L :: "'b::t2_space"
  shows "(\<lambda>x. k) -- a --> L \<Longrightarrow> k = L"
  by (simp add: tendsto_const_iff)

lemma LIM_unique:
  fixes a :: "'a::perfect_space" and L M :: "'b::t2_space"
  shows "f -- a --> L \<Longrightarrow> f -- a --> M \<Longrightarrow> L = M"
  using at_neq_bot by (rule tendsto_unique)

text {* Limits are equal for functions equal except at limit point *}

lemma LIM_equal: "\<forall>x. x \<noteq> a --> (f x = g x) \<Longrightarrow> (f -- a --> l) \<longleftrightarrow> (g -- a --> l)"
  unfolding tendsto_def eventually_at_topological by simp

lemma LIM_cong: "a = b \<Longrightarrow> (\<And>x. x \<noteq> b \<Longrightarrow> f x = g x) \<Longrightarrow> l = m \<Longrightarrow> (f -- a --> l) \<longleftrightarrow> (g -- b --> m)"
  by (simp add: LIM_equal)

lemma LIM_cong_limit: "f -- x --> L \<Longrightarrow> K = L \<Longrightarrow> f -- x --> K"
  by simp

lemma tendsto_at_iff_tendsto_nhds:
  "g -- l --> g l \<longleftrightarrow> (g ---> g l) (nhds l)"
  unfolding tendsto_def eventually_at_filter
  by (intro ext all_cong imp_cong) (auto elim!: eventually_elim1)

lemma tendsto_compose:
  "g -- l --> g l \<Longrightarrow> (f ---> l) F \<Longrightarrow> ((\<lambda>x. g (f x)) ---> g l) F"
  unfolding tendsto_at_iff_tendsto_nhds by (rule filterlim_compose[of g])

lemma LIM_o: "\<lbrakk>g -- l --> g l; f -- a --> l\<rbrakk> \<Longrightarrow> (g \<circ> f) -- a --> g l"
  unfolding o_def by (rule tendsto_compose)

lemma tendsto_compose_eventually:
  "g -- l --> m \<Longrightarrow> (f ---> l) F \<Longrightarrow> eventually (\<lambda>x. f x \<noteq> l) F \<Longrightarrow> ((\<lambda>x. g (f x)) ---> m) F"
  by (rule filterlim_compose[of g _ "at l"]) (auto simp add: filterlim_at)

lemma LIM_compose_eventually:
  assumes f: "f -- a --> b"
  assumes g: "g -- b --> c"
  assumes inj: "eventually (\<lambda>x. f x \<noteq> b) (at a)"
  shows "(\<lambda>x. g (f x)) -- a --> c"
  using g f inj by (rule tendsto_compose_eventually)

lemma tendsto_compose_filtermap: "((g \<circ> f) ---> T) F \<longleftrightarrow> (g ---> T) (filtermap f F)"
  by (simp add: filterlim_def filtermap_filtermap comp_def)

subsubsection {* Relation of LIM and LIMSEQ *}

lemma (in first_countable_topology) sequentially_imp_eventually_within:
  "(\<forall>f. (\<forall>n. f n \<in> s \<and> f n \<noteq> a) \<and> f ----> a \<longrightarrow> eventually (\<lambda>n. P (f n)) sequentially) \<Longrightarrow>
    eventually P (at a within s)"
  unfolding at_within_def
  by (intro sequentially_imp_eventually_nhds_within) auto

lemma (in first_countable_topology) sequentially_imp_eventually_at:
  "(\<forall>f. (\<forall>n. f n \<noteq> a) \<and> f ----> a \<longrightarrow> eventually (\<lambda>n. P (f n)) sequentially) \<Longrightarrow> eventually P (at a)"
  using assms sequentially_imp_eventually_within [where s=UNIV] by simp

lemma LIMSEQ_SEQ_conv1:
  fixes f :: "'a::topological_space \<Rightarrow> 'b::topological_space"
  assumes f: "f -- a --> l"
  shows "\<forall>S. (\<forall>n. S n \<noteq> a) \<and> S ----> a \<longrightarrow> (\<lambda>n. f (S n)) ----> l"
  using tendsto_compose_eventually [OF f, where F=sequentially] by simp

lemma LIMSEQ_SEQ_conv2:
  fixes f :: "'a::first_countable_topology \<Rightarrow> 'b::topological_space"
  assumes "\<forall>S. (\<forall>n. S n \<noteq> a) \<and> S ----> a \<longrightarrow> (\<lambda>n. f (S n)) ----> l"
  shows "f -- a --> l"
  using assms unfolding tendsto_def [where l=l] by (simp add: sequentially_imp_eventually_at)

lemma LIMSEQ_SEQ_conv:
  "(\<forall>S. (\<forall>n. S n \<noteq> a) \<and> S ----> (a::'a::first_countable_topology) \<longrightarrow> (\<lambda>n. X (S n)) ----> L) =
   (X -- a --> (L::'b::topological_space))"
  using LIMSEQ_SEQ_conv2 LIMSEQ_SEQ_conv1 ..

lemma sequentially_imp_eventually_at_left:
  fixes a :: "'a :: {dense_linorder, linorder_topology, first_countable_topology}"
  assumes b[simp]: "b < a"
  assumes *: "\<And>f. (\<And>n. b < f n) \<Longrightarrow> (\<And>n. f n < a) \<Longrightarrow> incseq f \<Longrightarrow> f ----> a \<Longrightarrow> eventually (\<lambda>n. P (f n)) sequentially"
  shows "eventually P (at_left a)"
proof (safe intro!: sequentially_imp_eventually_within)
  fix X assume X: "\<forall>n. X n \<in> {..< a} \<and> X n \<noteq> a" "X ----> a"
  show "eventually (\<lambda>n. P (X n)) sequentially"
  proof (rule ccontr)
    assume neg: "\<not> eventually (\<lambda>n. P (X n)) sequentially"
    have "\<exists>s. \<forall>n. (\<not> P (X (s n)) \<and> b < X (s n)) \<and> (X (s n) \<le> X (s (Suc n)) \<and> Suc (s n) \<le> s (Suc n))"
    proof (rule dependent_nat_choice)
      have "\<not> eventually (\<lambda>n. b < X n \<longrightarrow> P (X n)) sequentially"
        by (intro not_eventually_impI neg order_tendstoD(1) [OF X(2) b])
      then show "\<exists>x. \<not> P (X x) \<and> b < X x"
        by (auto dest!: not_eventuallyD)
    next
      fix x n
      have "\<not> eventually (\<lambda>n. Suc x \<le> n \<longrightarrow> b < X n \<longrightarrow> X x < X n \<longrightarrow> P (X n)) sequentially"
        using X by (intro not_eventually_impI order_tendstoD(1)[OF X(2)] eventually_ge_at_top neg) auto
      then show "\<exists>n. (\<not> P (X n) \<and> b < X n) \<and> (X x \<le> X n \<and> Suc x \<le> n)"
        by (auto dest!: not_eventuallyD)
    qed
    then guess s ..
    then have "\<And>n. b < X (s n)" "\<And>n. X (s n) < a" "incseq (\<lambda>n. X (s n))" "(\<lambda>n. X (s n)) ----> a" "\<And>n. \<not> P (X (s n))"
      using X by (auto simp: subseq_Suc_iff Suc_le_eq incseq_Suc_iff intro!: LIMSEQ_subseq_LIMSEQ[OF `X ----> a`, unfolded comp_def])
    from *[OF this(1,2,3,4)] this(5) show False by auto
  qed
qed

lemma tendsto_at_left_sequentially:
  fixes a :: "_ :: {dense_linorder, linorder_topology, first_countable_topology}"
  assumes "b < a"
  assumes *: "\<And>S. (\<And>n. S n < a) \<Longrightarrow> (\<And>n. b < S n) \<Longrightarrow> incseq S \<Longrightarrow> S ----> a \<Longrightarrow> (\<lambda>n. X (S n)) ----> L"
  shows "(X ---> L) (at_left a)"
  using assms unfolding tendsto_def [where l=L]
  by (simp add: sequentially_imp_eventually_at_left)

lemma sequentially_imp_eventually_at_right:
  fixes a :: "'a :: {dense_linorder, linorder_topology, first_countable_topology}"
  assumes b[simp]: "a < b"
  assumes *: "\<And>f. (\<And>n. a < f n) \<Longrightarrow> (\<And>n. f n < b) \<Longrightarrow> decseq f \<Longrightarrow> f ----> a \<Longrightarrow> eventually (\<lambda>n. P (f n)) sequentially"
  shows "eventually P (at_right a)"
proof (safe intro!: sequentially_imp_eventually_within)
  fix X assume X: "\<forall>n. X n \<in> {a <..} \<and> X n \<noteq> a" "X ----> a"
  show "eventually (\<lambda>n. P (X n)) sequentially"
  proof (rule ccontr)
    assume neg: "\<not> eventually (\<lambda>n. P (X n)) sequentially"
    have "\<exists>s. \<forall>n. (\<not> P (X (s n)) \<and> X (s n) < b) \<and> (X (s (Suc n)) \<le> X (s n) \<and> Suc (s n) \<le> s (Suc n))"
    proof (rule dependent_nat_choice)
      have "\<not> eventually (\<lambda>n. X n < b \<longrightarrow> P (X n)) sequentially"
        by (intro not_eventually_impI neg order_tendstoD(2) [OF X(2) b])
      then show "\<exists>x. \<not> P (X x) \<and> X x < b"
        by (auto dest!: not_eventuallyD)
    next
      fix x n
      have "\<not> eventually (\<lambda>n. Suc x \<le> n \<longrightarrow> X n < b \<longrightarrow> X n < X x \<longrightarrow> P (X n)) sequentially"
        using X by (intro not_eventually_impI order_tendstoD(2)[OF X(2)] eventually_ge_at_top neg) auto
      then show "\<exists>n. (\<not> P (X n) \<and> X n < b) \<and> (X n \<le> X x \<and> Suc x \<le> n)"
        by (auto dest!: not_eventuallyD)
    qed
    then guess s ..
    then have "\<And>n. a < X (s n)" "\<And>n. X (s n) < b" "decseq (\<lambda>n. X (s n))" "(\<lambda>n. X (s n)) ----> a" "\<And>n. \<not> P (X (s n))"
      using X by (auto simp: subseq_Suc_iff Suc_le_eq decseq_Suc_iff intro!: LIMSEQ_subseq_LIMSEQ[OF `X ----> a`, unfolded comp_def])
    from *[OF this(1,2,3,4)] this(5) show False by auto
  qed
qed

lemma tendsto_at_right_sequentially:
  fixes a :: "_ :: {dense_linorder, linorder_topology, first_countable_topology}"
  assumes "a < b"
  assumes *: "\<And>S. (\<And>n. a < S n) \<Longrightarrow> (\<And>n. S n < b) \<Longrightarrow> decseq S \<Longrightarrow> S ----> a \<Longrightarrow> (\<lambda>n. X (S n)) ----> L"
  shows "(X ---> L) (at_right a)"
  using assms unfolding tendsto_def [where l=L]
  by (simp add: sequentially_imp_eventually_at_right)

subsection {* Continuity *}

subsubsection {* Continuity on a set *}

definition continuous_on :: "'a set \<Rightarrow> ('a :: topological_space \<Rightarrow> 'b :: topological_space) \<Rightarrow> bool" where
  "continuous_on s f \<longleftrightarrow> (\<forall>x\<in>s. (f ---> f x) (at x within s))"

lemma continuous_on_cong [cong]:
  "s = t \<Longrightarrow> (\<And>x. x \<in> t \<Longrightarrow> f x = g x) \<Longrightarrow> continuous_on s f \<longleftrightarrow> continuous_on t g"
  unfolding continuous_on_def by (intro ball_cong filterlim_cong) (auto simp: eventually_at_filter)

lemma continuous_on_topological:
  "continuous_on s f \<longleftrightarrow>
    (\<forall>x\<in>s. \<forall>B. open B \<longrightarrow> f x \<in> B \<longrightarrow> (\<exists>A. open A \<and> x \<in> A \<and> (\<forall>y\<in>s. y \<in> A \<longrightarrow> f y \<in> B)))"
  unfolding continuous_on_def tendsto_def eventually_at_topological by metis

lemma continuous_on_open_invariant:
  "continuous_on s f \<longleftrightarrow> (\<forall>B. open B \<longrightarrow> (\<exists>A. open A \<and> A \<inter> s = f -` B \<inter> s))"
proof safe
  fix B :: "'b set" assume "continuous_on s f" "open B"
  then have "\<forall>x\<in>f -` B \<inter> s. (\<exists>A. open A \<and> x \<in> A \<and> s \<inter> A \<subseteq> f -` B)"
    by (auto simp: continuous_on_topological subset_eq Ball_def imp_conjL)
  then obtain A where "\<forall>x\<in>f -` B \<inter> s. open (A x) \<and> x \<in> A x \<and> s \<inter> A x \<subseteq> f -` B"
    unfolding bchoice_iff ..
  then show "\<exists>A. open A \<and> A \<inter> s = f -` B \<inter> s"
    by (intro exI[of _ "\<Union>x\<in>f -` B \<inter> s. A x"]) auto
next
  assume B: "\<forall>B. open B \<longrightarrow> (\<exists>A. open A \<and> A \<inter> s = f -` B \<inter> s)"
  show "continuous_on s f"
    unfolding continuous_on_topological
  proof safe
    fix x B assume "x \<in> s" "open B" "f x \<in> B"
    with B obtain A where A: "open A" "A \<inter> s = f -` B \<inter> s" by auto
    with `x \<in> s` `f x \<in> B` show "\<exists>A. open A \<and> x \<in> A \<and> (\<forall>y\<in>s. y \<in> A \<longrightarrow> f y \<in> B)"
      by (intro exI[of _ A]) auto
  qed
qed

lemma continuous_on_open_vimage:
  "open s \<Longrightarrow> continuous_on s f \<longleftrightarrow> (\<forall>B. open B \<longrightarrow> open (f -` B \<inter> s))"
  unfolding continuous_on_open_invariant
  by (metis open_Int Int_absorb Int_commute[of s] Int_assoc[of _ _ s])

corollary continuous_imp_open_vimage:
  assumes "continuous_on s f" "open s" "open B" "f -` B \<subseteq> s"
    shows "open (f -` B)"
by (metis assms continuous_on_open_vimage le_iff_inf)

corollary open_vimage[continuous_intros]:
  assumes "open s" and "continuous_on UNIV f"
  shows "open (f -` s)"
  using assms unfolding continuous_on_open_vimage [OF open_UNIV]
  by simp

lemma continuous_on_closed_invariant:
  "continuous_on s f \<longleftrightarrow> (\<forall>B. closed B \<longrightarrow> (\<exists>A. closed A \<and> A \<inter> s = f -` B \<inter> s))"
proof -
  have *: "\<And>P Q::'b set\<Rightarrow>bool. (\<And>A. P A \<longleftrightarrow> Q (- A)) \<Longrightarrow> (\<forall>A. P A) \<longleftrightarrow> (\<forall>A. Q A)"
    by (metis double_compl)
  show ?thesis
    unfolding continuous_on_open_invariant by (intro *) (auto simp: open_closed[symmetric])
qed

lemma continuous_on_closed_vimage:
  "closed s \<Longrightarrow> continuous_on s f \<longleftrightarrow> (\<forall>B. closed B \<longrightarrow> closed (f -` B \<inter> s))"
  unfolding continuous_on_closed_invariant
  by (metis closed_Int Int_absorb Int_commute[of s] Int_assoc[of _ _ s])

corollary closed_vimage[continuous_intros]:
  assumes "closed s" and "continuous_on UNIV f"
  shows "closed (f -` s)"
  using assms unfolding continuous_on_closed_vimage [OF closed_UNIV]
  by simp

lemma continuous_on_open_Union:
  "(\<And>s. s \<in> S \<Longrightarrow> open s) \<Longrightarrow> (\<And>s. s \<in> S \<Longrightarrow> continuous_on s f) \<Longrightarrow> continuous_on (\<Union>S) f"
  unfolding continuous_on_def by safe (metis open_Union at_within_open UnionI)

lemma continuous_on_open_UN:
  "(\<And>s. s \<in> S \<Longrightarrow> open (A s)) \<Longrightarrow> (\<And>s. s \<in> S \<Longrightarrow> continuous_on (A s) f) \<Longrightarrow> continuous_on (\<Union>s\<in>S. A s) f"
  unfolding Union_image_eq[symmetric] by (rule continuous_on_open_Union) auto

lemma continuous_on_closed_Un:
  "closed s \<Longrightarrow> closed t \<Longrightarrow> continuous_on s f \<Longrightarrow> continuous_on t f \<Longrightarrow> continuous_on (s \<union> t) f"
  by (auto simp add: continuous_on_closed_vimage closed_Un Int_Un_distrib)

lemma continuous_on_If:
  assumes closed: "closed s" "closed t" and cont: "continuous_on s f" "continuous_on t g"
    and P: "\<And>x. x \<in> s \<Longrightarrow> \<not> P x \<Longrightarrow> f x = g x" "\<And>x. x \<in> t \<Longrightarrow> P x \<Longrightarrow> f x = g x"
  shows "continuous_on (s \<union> t) (\<lambda>x. if P x then f x else g x)" (is "continuous_on _ ?h")
proof-
  from P have "\<forall>x\<in>s. f x = ?h x" "\<forall>x\<in>t. g x = ?h x"
    by auto
  with cont have "continuous_on s ?h" "continuous_on t ?h"
    by simp_all
  with closed show ?thesis
    by (rule continuous_on_closed_Un)
qed

lemma continuous_on_id[continuous_intros]: "continuous_on s (\<lambda>x. x)"
  unfolding continuous_on_def by fast

lemma continuous_on_const[continuous_intros]: "continuous_on s (\<lambda>x. c)"
  unfolding continuous_on_def by auto

lemma continuous_on_compose[continuous_intros]:
  "continuous_on s f \<Longrightarrow> continuous_on (f ` s) g \<Longrightarrow> continuous_on s (g o f)"
  unfolding continuous_on_topological by simp metis

lemma continuous_on_compose2:
  "continuous_on t g \<Longrightarrow> continuous_on s f \<Longrightarrow> t = f ` s \<Longrightarrow> continuous_on s (\<lambda>x. g (f x))"
  using continuous_on_compose[of s f g] by (simp add: comp_def)

subsubsection {* Continuity at a point *}

definition continuous :: "'a::t2_space filter \<Rightarrow> ('a \<Rightarrow> 'b::topological_space) \<Rightarrow> bool" where
  "continuous F f \<longleftrightarrow> (f ---> f (Lim F (\<lambda>x. x))) F"

lemma continuous_bot[continuous_intros, simp]: "continuous bot f"
  unfolding continuous_def by auto

lemma continuous_trivial_limit: "trivial_limit net \<Longrightarrow> continuous net f"
  by simp

lemma continuous_within: "continuous (at x within s) f \<longleftrightarrow> (f ---> f x) (at x within s)"
  by (cases "trivial_limit (at x within s)") (auto simp add: Lim_ident_at continuous_def)

lemma continuous_within_topological:
  "continuous (at x within s) f \<longleftrightarrow>
    (\<forall>B. open B \<longrightarrow> f x \<in> B \<longrightarrow> (\<exists>A. open A \<and> x \<in> A \<and> (\<forall>y\<in>s. y \<in> A \<longrightarrow> f y \<in> B)))"
  unfolding continuous_within tendsto_def eventually_at_topological by metis

lemma continuous_within_compose[continuous_intros]:
  "continuous (at x within s) f \<Longrightarrow> continuous (at (f x) within f ` s) g \<Longrightarrow>
  continuous (at x within s) (g o f)"
  by (simp add: continuous_within_topological) metis

lemma continuous_within_compose2:
  "continuous (at x within s) f \<Longrightarrow> continuous (at (f x) within f ` s) g \<Longrightarrow>
  continuous (at x within s) (\<lambda>x. g (f x))"
  using continuous_within_compose[of x s f g] by (simp add: comp_def)

lemma continuous_at: "continuous (at x) f \<longleftrightarrow> f -- x --> f x"
  using continuous_within[of x UNIV f] by simp

lemma continuous_ident[continuous_intros, simp]: "continuous (at x within S) (\<lambda>x. x)"
  unfolding continuous_within by (rule tendsto_ident_at)

lemma continuous_const[continuous_intros, simp]: "continuous F (\<lambda>x. c)"
  unfolding continuous_def by (rule tendsto_const)

lemma continuous_on_eq_continuous_within:
  "continuous_on s f \<longleftrightarrow> (\<forall>x\<in>s. continuous (at x within s) f)"
  unfolding continuous_on_def continuous_within ..

abbreviation isCont :: "('a::t2_space \<Rightarrow> 'b::topological_space) \<Rightarrow> 'a \<Rightarrow> bool" where
  "isCont f a \<equiv> continuous (at a) f"

lemma isCont_def: "isCont f a \<longleftrightarrow> f -- a --> f a"
  by (rule continuous_at)

lemma continuous_at_within: "isCont f x \<Longrightarrow> continuous (at x within s) f"
  by (auto intro: tendsto_mono at_le simp: continuous_at continuous_within)

lemma continuous_on_eq_continuous_at: "open s \<Longrightarrow> continuous_on s f \<longleftrightarrow> (\<forall>x\<in>s. isCont f x)"
  by (simp add: continuous_on_def continuous_at at_within_open[of _ s])

lemma continuous_on_subset: "continuous_on s f \<Longrightarrow> t \<subseteq> s \<Longrightarrow> continuous_on t f"
  unfolding continuous_on_def by (metis subset_eq tendsto_within_subset)

lemma continuous_at_imp_continuous_on: "\<forall>x\<in>s. isCont f x \<Longrightarrow> continuous_on s f"
  by (auto intro: continuous_at_within simp: continuous_on_eq_continuous_within)

lemma isContI_continuous: "continuous (at x within UNIV) f \<Longrightarrow> isCont f x"
  by simp

lemma isCont_ident[continuous_intros, simp]: "isCont (\<lambda>x. x) a"
  using continuous_ident by (rule isContI_continuous)

lemmas isCont_const = continuous_const

lemma isCont_o2: "isCont f a \<Longrightarrow> isCont g (f a) \<Longrightarrow> isCont (\<lambda>x. g (f x)) a"
  unfolding isCont_def by (rule tendsto_compose)

lemma isCont_o[continuous_intros]: "isCont f a \<Longrightarrow> isCont g (f a) \<Longrightarrow> isCont (g \<circ> f) a"
  unfolding o_def by (rule isCont_o2)

lemma isCont_tendsto_compose: "isCont g l \<Longrightarrow> (f ---> l) F \<Longrightarrow> ((\<lambda>x. g (f x)) ---> g l) F"
  unfolding isCont_def by (rule tendsto_compose)

lemma continuous_within_compose3:
  "isCont g (f x) \<Longrightarrow> continuous (at x within s) f \<Longrightarrow> continuous (at x within s) (\<lambda>x. g (f x))"
  using continuous_within_compose2[of x s f g] by (simp add: continuous_at_within)

lemma filtermap_nhds_open_map:
  assumes cont: "isCont f a" and open_map: "\<And>S. open S \<Longrightarrow> open (f`S)"
  shows "filtermap f (nhds a) = nhds (f a)"
  unfolding filter_eq_iff
proof safe
  fix P assume "eventually P (filtermap f (nhds a))"
  then guess S unfolding eventually_filtermap eventually_nhds ..
  then show "eventually P (nhds (f a))"
    unfolding eventually_nhds by (intro exI[of _ "f`S"]) (auto intro!: open_map)
qed (metis filterlim_iff tendsto_at_iff_tendsto_nhds isCont_def eventually_filtermap cont)

lemma continuous_at_split: 
  "continuous (at (x::'a::linorder_topology)) f = (continuous (at_left x) f \<and> continuous (at_right x) f)"
  by (simp add: continuous_within filterlim_at_split)

subsubsection{* Open-cover compactness *}

context topological_space
begin

definition compact :: "'a set \<Rightarrow> bool" where
  compact_eq_heine_borel: -- "This name is used for backwards compatibility"
    "compact S \<longleftrightarrow> (\<forall>C. (\<forall>c\<in>C. open c) \<and> S \<subseteq> \<Union>C \<longrightarrow> (\<exists>D\<subseteq>C. finite D \<and> S \<subseteq> \<Union>D))"

lemma compactI:
  assumes "\<And>C. \<forall>t\<in>C. open t \<Longrightarrow> s \<subseteq> \<Union> C \<Longrightarrow> \<exists>C'. C' \<subseteq> C \<and> finite C' \<and> s \<subseteq> \<Union> C'"
  shows "compact s"
  unfolding compact_eq_heine_borel using assms by metis

lemma compact_empty[simp]: "compact {}"
  by (auto intro!: compactI)

lemma compactE:
  assumes "compact s" and "\<forall>t\<in>C. open t" and "s \<subseteq> \<Union>C"
  obtains C' where "C' \<subseteq> C" and "finite C'" and "s \<subseteq> \<Union>C'"
  using assms unfolding compact_eq_heine_borel by metis

lemma compactE_image:
  assumes "compact s" and "\<forall>t\<in>C. open (f t)" and "s \<subseteq> (\<Union>c\<in>C. f c)"
  obtains C' where "C' \<subseteq> C" and "finite C'" and "s \<subseteq> (\<Union>c\<in>C'. f c)"
  using assms unfolding ball_simps[symmetric] SUP_def
  by (metis (lifting) finite_subset_image compact_eq_heine_borel[of s])

lemma compact_inter_closed [intro]:
  assumes "compact s" and "closed t"
  shows "compact (s \<inter> t)"
proof (rule compactI)
  fix C assume C: "\<forall>c\<in>C. open c" and cover: "s \<inter> t \<subseteq> \<Union>C"
  from C `closed t` have "\<forall>c\<in>C \<union> {-t}. open c" by auto
  moreover from cover have "s \<subseteq> \<Union>(C \<union> {-t})" by auto
  ultimately have "\<exists>D\<subseteq>C \<union> {-t}. finite D \<and> s \<subseteq> \<Union>D"
    using `compact s` unfolding compact_eq_heine_borel by auto
  then obtain D where "D \<subseteq> C \<union> {- t} \<and> finite D \<and> s \<subseteq> \<Union>D" ..
  then show "\<exists>D\<subseteq>C. finite D \<and> s \<inter> t \<subseteq> \<Union>D"
    by (intro exI[of _ "D - {-t}"]) auto
qed

lemma inj_setminus: "inj_on uminus (A::'a set set)"
  by (auto simp: inj_on_def)

lemma compact_fip:
  "compact U \<longleftrightarrow>
    (\<forall>A. (\<forall>a\<in>A. closed a) \<longrightarrow> (\<forall>B \<subseteq> A. finite B \<longrightarrow> U \<inter> \<Inter>B \<noteq> {}) \<longrightarrow> U \<inter> \<Inter>A \<noteq> {})"
  (is "_ \<longleftrightarrow> ?R")
proof (safe intro!: compact_eq_heine_borel[THEN iffD2])
  fix A
  assume "compact U"
    and A: "\<forall>a\<in>A. closed a" "U \<inter> \<Inter>A = {}"
    and fi: "\<forall>B \<subseteq> A. finite B \<longrightarrow> U \<inter> \<Inter>B \<noteq> {}"
  from A have "(\<forall>a\<in>uminus`A. open a) \<and> U \<subseteq> \<Union>(uminus`A)"
    by auto
  with `compact U` obtain B where "B \<subseteq> A" "finite (uminus`B)" "U \<subseteq> \<Union>(uminus`B)"
    unfolding compact_eq_heine_borel by (metis subset_image_iff)
  with fi[THEN spec, of B] show False
    by (auto dest: finite_imageD intro: inj_setminus)
next
  fix A
  assume ?R
  assume "\<forall>a\<in>A. open a" "U \<subseteq> \<Union>A"
  then have "U \<inter> \<Inter>(uminus`A) = {}" "\<forall>a\<in>uminus`A. closed a"
    by auto
  with `?R` obtain B where "B \<subseteq> A" "finite (uminus`B)" "U \<inter> \<Inter>(uminus`B) = {}"
    by (metis subset_image_iff)
  then show "\<exists>T\<subseteq>A. finite T \<and> U \<subseteq> \<Union>T"
    by  (auto intro!: exI[of _ B] inj_setminus dest: finite_imageD)
qed

lemma compact_imp_fip:
  "compact s \<Longrightarrow> \<forall>t \<in> f. closed t \<Longrightarrow> \<forall>f'. finite f' \<and> f' \<subseteq> f \<longrightarrow> (s \<inter> (\<Inter> f') \<noteq> {}) \<Longrightarrow>
    s \<inter> (\<Inter> f) \<noteq> {}"
  unfolding compact_fip by auto

lemma compact_imp_fip_image:
  assumes "compact s"
    and P: "\<And>i. i \<in> I \<Longrightarrow> closed (f i)"
    and Q: "\<And>I'. finite I' \<Longrightarrow> I' \<subseteq> I \<Longrightarrow> (s \<inter> (\<Inter>i\<in>I'. f i) \<noteq> {})"
  shows "s \<inter> (\<Inter>i\<in>I. f i) \<noteq> {}"
proof -
  note `compact s`
  moreover from P have "\<forall>i \<in> f ` I. closed i" by blast
  moreover have "\<forall>A. finite A \<and> A \<subseteq> f ` I \<longrightarrow> (s \<inter> (\<Inter>A) \<noteq> {})"
  proof (rule, rule, erule conjE)
    fix A :: "'a set set"
    assume "finite A"
    moreover assume "A \<subseteq> f ` I"
    ultimately obtain B where "B \<subseteq> I" and "finite B" and "A = f ` B"
      using finite_subset_image [of A f I] by blast
    with Q [of B] show "s \<inter> \<Inter>A \<noteq> {}" by simp
  qed
  ultimately have "s \<inter> (\<Inter>(f ` I)) \<noteq> {}" by (rule compact_imp_fip)
  then show ?thesis by simp
qed

end

lemma (in t2_space) compact_imp_closed:
  assumes "compact s" shows "closed s"
unfolding closed_def
proof (rule openI)
  fix y assume "y \<in> - s"
  let ?C = "\<Union>x\<in>s. {u. open u \<and> x \<in> u \<and> eventually (\<lambda>y. y \<notin> u) (nhds y)}"
  note `compact s`
  moreover have "\<forall>u\<in>?C. open u" by simp
  moreover have "s \<subseteq> \<Union>?C"
  proof
    fix x assume "x \<in> s"
    with `y \<in> - s` have "x \<noteq> y" by clarsimp
    hence "\<exists>u v. open u \<and> open v \<and> x \<in> u \<and> y \<in> v \<and> u \<inter> v = {}"
      by (rule hausdorff)
    with `x \<in> s` show "x \<in> \<Union>?C"
      unfolding eventually_nhds by auto
  qed
  ultimately obtain D where "D \<subseteq> ?C" and "finite D" and "s \<subseteq> \<Union>D"
    by (rule compactE)
  from `D \<subseteq> ?C` have "\<forall>x\<in>D. eventually (\<lambda>y. y \<notin> x) (nhds y)" by auto
  with `finite D` have "eventually (\<lambda>y. y \<notin> \<Union>D) (nhds y)"
    by (simp add: eventually_Ball_finite)
  with `s \<subseteq> \<Union>D` have "eventually (\<lambda>y. y \<notin> s) (nhds y)"
    by (auto elim!: eventually_mono [rotated])
  thus "\<exists>t. open t \<and> y \<in> t \<and> t \<subseteq> - s"
    by (simp add: eventually_nhds subset_eq)
qed

lemma compact_continuous_image:
  assumes f: "continuous_on s f" and s: "compact s"
  shows "compact (f ` s)"
proof (rule compactI)
  fix C assume "\<forall>c\<in>C. open c" and cover: "f`s \<subseteq> \<Union>C"
  with f have "\<forall>c\<in>C. \<exists>A. open A \<and> A \<inter> s = f -` c \<inter> s"
    unfolding continuous_on_open_invariant by blast
  then obtain A where A: "\<forall>c\<in>C. open (A c) \<and> A c \<inter> s = f -` c \<inter> s"
    unfolding bchoice_iff ..
  with cover have "\<forall>c\<in>C. open (A c)" "s \<subseteq> (\<Union>c\<in>C. A c)"
    by (fastforce simp add: subset_eq set_eq_iff)+
  from compactE_image[OF s this] obtain D where "D \<subseteq> C" "finite D" "s \<subseteq> (\<Union>c\<in>D. A c)" .
  with A show "\<exists>D \<subseteq> C. finite D \<and> f`s \<subseteq> \<Union>D"
    by (intro exI[of _ D]) (fastforce simp add: subset_eq set_eq_iff)+
qed

lemma continuous_on_inv:
  fixes f :: "'a::topological_space \<Rightarrow> 'b::t2_space"
  assumes "continuous_on s f"  "compact s"  "\<forall>x\<in>s. g (f x) = x"
  shows "continuous_on (f ` s) g"
unfolding continuous_on_topological
proof (clarsimp simp add: assms(3))
  fix x :: 'a and B :: "'a set"
  assume "x \<in> s" and "open B" and "x \<in> B"
  have 1: "\<forall>x\<in>s. f x \<in> f ` (s - B) \<longleftrightarrow> x \<in> s - B"
    using assms(3) by (auto, metis)
  have "continuous_on (s - B) f"
    using `continuous_on s f` Diff_subset
    by (rule continuous_on_subset)
  moreover have "compact (s - B)"
    using `open B` and `compact s`
    unfolding Diff_eq by (intro compact_inter_closed closed_Compl)
  ultimately have "compact (f ` (s - B))"
    by (rule compact_continuous_image)
  hence "closed (f ` (s - B))"
    by (rule compact_imp_closed)
  hence "open (- f ` (s - B))"
    by (rule open_Compl)
  moreover have "f x \<in> - f ` (s - B)"
    using `x \<in> s` and `x \<in> B` by (simp add: 1)
  moreover have "\<forall>y\<in>s. f y \<in> - f ` (s - B) \<longrightarrow> y \<in> B"
    by (simp add: 1)
  ultimately show "\<exists>A. open A \<and> f x \<in> A \<and> (\<forall>y\<in>s. f y \<in> A \<longrightarrow> y \<in> B)"
    by fast
qed

lemma continuous_on_inv_into:
  fixes f :: "'a::topological_space \<Rightarrow> 'b::t2_space"
  assumes s: "continuous_on s f" "compact s" and f: "inj_on f s"
  shows "continuous_on (f ` s) (the_inv_into s f)"
  by (rule continuous_on_inv[OF s]) (auto simp: the_inv_into_f_f[OF f])

lemma (in linorder_topology) compact_attains_sup:
  assumes "compact S" "S \<noteq> {}"
  shows "\<exists>s\<in>S. \<forall>t\<in>S. t \<le> s"
proof (rule classical)
  assume "\<not> (\<exists>s\<in>S. \<forall>t\<in>S. t \<le> s)"
  then obtain t where t: "\<forall>s\<in>S. t s \<in> S" and "\<forall>s\<in>S. s < t s"
    by (metis not_le)
  then have "\<forall>s\<in>S. open {..< t s}" "S \<subseteq> (\<Union>s\<in>S. {..< t s})"
    by auto
  with `compact S` obtain C where "C \<subseteq> S" "finite C" and C: "S \<subseteq> (\<Union>s\<in>C. {..< t s})"
    by (erule compactE_image)
  with `S \<noteq> {}` have Max: "Max (t`C) \<in> t`C" and "\<forall>s\<in>t`C. s \<le> Max (t`C)"
    by (auto intro!: Max_in)
  with C have "S \<subseteq> {..< Max (t`C)}"
    by (auto intro: less_le_trans simp: subset_eq)
  with t Max `C \<subseteq> S` show ?thesis
    by fastforce
qed

lemma (in linorder_topology) compact_attains_inf:
  assumes "compact S" "S \<noteq> {}"
  shows "\<exists>s\<in>S. \<forall>t\<in>S. s \<le> t"
proof (rule classical)
  assume "\<not> (\<exists>s\<in>S. \<forall>t\<in>S. s \<le> t)"
  then obtain t where t: "\<forall>s\<in>S. t s \<in> S" and "\<forall>s\<in>S. t s < s"
    by (metis not_le)
  then have "\<forall>s\<in>S. open {t s <..}" "S \<subseteq> (\<Union>s\<in>S. {t s <..})"
    by auto
  with `compact S` obtain C where "C \<subseteq> S" "finite C" and C: "S \<subseteq> (\<Union>s\<in>C. {t s <..})"
    by (erule compactE_image)
  with `S \<noteq> {}` have Min: "Min (t`C) \<in> t`C" and "\<forall>s\<in>t`C. Min (t`C) \<le> s"
    by (auto intro!: Min_in)
  with C have "S \<subseteq> {Min (t`C) <..}"
    by (auto intro: le_less_trans simp: subset_eq)
  with t Min `C \<subseteq> S` show ?thesis
    by fastforce
qed

lemma continuous_attains_sup:
  fixes f :: "'a::topological_space \<Rightarrow> 'b::linorder_topology"
  shows "compact s \<Longrightarrow> s \<noteq> {} \<Longrightarrow> continuous_on s f \<Longrightarrow> (\<exists>x\<in>s. \<forall>y\<in>s.  f y \<le> f x)"
  using compact_attains_sup[of "f ` s"] compact_continuous_image[of s f] by auto

lemma continuous_attains_inf:
  fixes f :: "'a::topological_space \<Rightarrow> 'b::linorder_topology"
  shows "compact s \<Longrightarrow> s \<noteq> {} \<Longrightarrow> continuous_on s f \<Longrightarrow> (\<exists>x\<in>s. \<forall>y\<in>s. f x \<le> f y)"
  using compact_attains_inf[of "f ` s"] compact_continuous_image[of s f] by auto

subsection {* Connectedness *}

context topological_space
begin

definition "connected S \<longleftrightarrow>
  \<not> (\<exists>A B. open A \<and> open B \<and> S \<subseteq> A \<union> B \<and> A \<inter> B \<inter> S = {} \<and> A \<inter> S \<noteq> {} \<and> B \<inter> S \<noteq> {})"

lemma connectedI:
  "(\<And>A B. open A \<Longrightarrow> open B \<Longrightarrow> A \<inter> U \<noteq> {} \<Longrightarrow> B \<inter> U \<noteq> {} \<Longrightarrow> A \<inter> B \<inter> U = {} \<Longrightarrow> U \<subseteq> A \<union> B \<Longrightarrow> False)
  \<Longrightarrow> connected U"
  by (auto simp: connected_def)

lemma connected_empty[simp]: "connected {}"
  by (auto intro!: connectedI)

lemma connectedD:
  "connected A \<Longrightarrow> open U \<Longrightarrow> open V \<Longrightarrow> U \<inter> V \<inter> A = {} \<Longrightarrow> A \<subseteq> U \<union> V \<Longrightarrow> U \<inter> A = {} \<or> V \<inter> A = {}" 
  by (auto simp: connected_def)

end

lemma connected_iff_const:
  fixes S :: "'a::topological_space set"
  shows "connected S \<longleftrightarrow> (\<forall>P::'a \<Rightarrow> bool. continuous_on S P \<longrightarrow> (\<exists>c. \<forall>s\<in>S. P s = c))"
proof safe
  fix P :: "'a \<Rightarrow> bool" assume "connected S" "continuous_on S P"
  then have "\<And>b. \<exists>A. open A \<and> A \<inter> S = P -` {b} \<inter> S"
    unfolding continuous_on_open_invariant by simp
  from this[of True] this[of False]
  obtain t f where "open t" "open f" and *: "f \<inter> S = P -` {False} \<inter> S" "t \<inter> S = P -` {True} \<inter> S"
    by auto
  then have "t \<inter> S = {} \<or> f \<inter> S = {}"
    by (intro connectedD[OF `connected S`])  auto
  then show "\<exists>c. \<forall>s\<in>S. P s = c"
  proof (rule disjE)
    assume "t \<inter> S = {}" then show ?thesis
      unfolding * by (intro exI[of _ False]) auto
  next
    assume "f \<inter> S = {}" then show ?thesis
      unfolding * by (intro exI[of _ True]) auto
  qed
next
  assume P: "\<forall>P::'a \<Rightarrow> bool. continuous_on S P \<longrightarrow> (\<exists>c. \<forall>s\<in>S. P s = c)"
  show "connected S"
  proof (rule connectedI)
    fix A B assume *: "open A" "open B" "A \<inter> S \<noteq> {}" "B \<inter> S \<noteq> {}" "A \<inter> B \<inter> S = {}" "S \<subseteq> A \<union> B"
    have "continuous_on S (\<lambda>x. x \<in> A)"
      unfolding continuous_on_open_invariant
    proof safe
      fix C :: "bool set"
      have "C = UNIV \<or> C = {True} \<or> C = {False} \<or> C = {}"
        using subset_UNIV[of C] unfolding UNIV_bool by auto
      with * show "\<exists>T. open T \<and> T \<inter> S = (\<lambda>x. x \<in> A) -` C \<inter> S"
        by (intro exI[of _ "(if True \<in> C then A else {}) \<union> (if False \<in> C then B else {})"]) auto
    qed
    from P[rule_format, OF this] obtain c where "\<And>s. s \<in> S \<Longrightarrow> (s \<in> A) = c" by blast
    with * show False
      by (cases c) auto
  qed
qed

lemma connectedD_const:
  fixes P :: "'a::topological_space \<Rightarrow> bool"
  shows "connected S \<Longrightarrow> continuous_on S P \<Longrightarrow> \<exists>c. \<forall>s\<in>S. P s = c"
  unfolding connected_iff_const by auto

lemma connectedI_const:
  "(\<And>P::'a::topological_space \<Rightarrow> bool. continuous_on S P \<Longrightarrow> \<exists>c. \<forall>s\<in>S. P s = c) \<Longrightarrow> connected S"
  unfolding connected_iff_const by auto

lemma connected_local_const:
  assumes "connected A" "a \<in> A" "b \<in> A"
  assumes *: "\<forall>a\<in>A. eventually (\<lambda>b. f a = f b) (at a within A)"
  shows "f a = f b"
proof -
  obtain S where S: "\<And>a. a \<in> A \<Longrightarrow> a \<in> S a" "\<And>a. a \<in> A \<Longrightarrow> open (S a)"
    "\<And>a x. a \<in> A \<Longrightarrow> x \<in> S a \<Longrightarrow> x \<in> A \<Longrightarrow> f a = f x"
    using * unfolding eventually_at_topological by metis

  let ?P = "\<Union>b\<in>{b\<in>A. f a = f b}. S b" and ?N = "\<Union>b\<in>{b\<in>A. f a \<noteq> f b}. S b"
  have "?P \<inter> A = {} \<or> ?N \<inter> A = {}"
    using `connected A` S `a\<in>A`
    by (intro connectedD) (auto, metis)
  then show "f a = f b"
  proof
    assume "?N \<inter> A = {}"
    then have "\<forall>x\<in>A. f a = f x"
      using S(1) by auto
    with `b\<in>A` show ?thesis by auto
  next
    assume "?P \<inter> A = {}" then show ?thesis
      using `a \<in> A` S(1)[of a] by auto
  qed
qed

lemma (in linorder_topology) connectedD_interval:
  assumes "connected U" and xy: "x \<in> U" "y \<in> U" and "x \<le> z" "z \<le> y"
  shows "z \<in> U"
proof -
  have eq: "{..<z} \<union> {z<..} = - {z}"
    by auto
  { assume "z \<notin> U" "x < z" "z < y"
    with xy have "\<not> connected U"
      unfolding connected_def simp_thms
      apply (rule_tac exI[of _ "{..< z}"])
      apply (rule_tac exI[of _ "{z <..}"])
      apply (auto simp add: eq)
      done }
  with assms show "z \<in> U"
    by (metis less_le)
qed

lemma connected_continuous_image:
  assumes *: "continuous_on s f"
  assumes "connected s"
  shows "connected (f ` s)"
proof (rule connectedI_const)
  fix P :: "'b \<Rightarrow> bool" assume "continuous_on (f ` s) P"
  then have "continuous_on s (P \<circ> f)"
    by (rule continuous_on_compose[OF *])
  from connectedD_const[OF `connected s` this] show "\<exists>c. \<forall>s\<in>f ` s. P s = c"
    by auto
qed

section {* Connectedness *}

class linear_continuum_topology = linorder_topology + linear_continuum
begin

lemma Inf_notin_open:
  assumes A: "open A" and bnd: "\<forall>a\<in>A. x < a"
  shows "Inf A \<notin> A"
proof
  assume "Inf A \<in> A"
  then obtain b where "b < Inf A" "{b <.. Inf A} \<subseteq> A"
    using open_left[of A "Inf A" x] assms by auto
  with dense[of b "Inf A"] obtain c where "c < Inf A" "c \<in> A"
    by (auto simp: subset_eq)
  then show False
    using cInf_lower[OF `c \<in> A`] bnd by (metis not_le less_imp_le bdd_belowI)
qed

lemma Sup_notin_open:
  assumes A: "open A" and bnd: "\<forall>a\<in>A. a < x"
  shows "Sup A \<notin> A"
proof
  assume "Sup A \<in> A"
  then obtain b where "Sup A < b" "{Sup A ..< b} \<subseteq> A"
    using open_right[of A "Sup A" x] assms by auto
  with dense[of "Sup A" b] obtain c where "Sup A < c" "c \<in> A"
    by (auto simp: subset_eq)
  then show False
    using cSup_upper[OF `c \<in> A`] bnd by (metis less_imp_le not_le bdd_aboveI)
qed

end

instance linear_continuum_topology \<subseteq> perfect_space
proof
  fix x :: 'a
  obtain y where "x < y \<or> y < x"
    using ex_gt_or_lt [of x] ..
  with Inf_notin_open[of "{x}" y] Sup_notin_open[of "{x}" y]
  show "\<not> open {x}"
    by auto
qed

lemma connectedI_interval:
  fixes U :: "'a :: linear_continuum_topology set"
  assumes *: "\<And>x y z. x \<in> U \<Longrightarrow> y \<in> U \<Longrightarrow> x \<le> z \<Longrightarrow> z \<le> y \<Longrightarrow> z \<in> U"
  shows "connected U"
proof (rule connectedI)
  { fix A B assume "open A" "open B" "A \<inter> B \<inter> U = {}" "U \<subseteq> A \<union> B"
    fix x y assume "x < y" "x \<in> A" "y \<in> B" "x \<in> U" "y \<in> U"

    let ?z = "Inf (B \<inter> {x <..})"

    have "x \<le> ?z" "?z \<le> y"
      using `y \<in> B` `x < y` by (auto intro: cInf_lower cInf_greatest)
    with `x \<in> U` `y \<in> U` have "?z \<in> U"
      by (rule *)
    moreover have "?z \<notin> B \<inter> {x <..}"
      using `open B` by (intro Inf_notin_open) auto
    ultimately have "?z \<in> A"
      using `x \<le> ?z` `A \<inter> B \<inter> U = {}` `x \<in> A` `U \<subseteq> A \<union> B` by auto

    { assume "?z < y"
      obtain a where "?z < a" "{?z ..< a} \<subseteq> A"
        using open_right[OF `open A` `?z \<in> A` `?z < y`] by auto
      moreover obtain b where "b \<in> B" "x < b" "b < min a y"
        using cInf_less_iff[of "B \<inter> {x <..}" "min a y"] `?z < a` `?z < y` `x < y` `y \<in> B`
        by (auto intro: less_imp_le)
      moreover have "?z \<le> b"
        using `b \<in> B` `x < b`
        by (intro cInf_lower) auto
      moreover have "b \<in> U"
        using `x \<le> ?z` `?z \<le> b` `b < min a y`
        by (intro *[OF `x \<in> U` `y \<in> U`]) (auto simp: less_imp_le)
      ultimately have "\<exists>b\<in>B. b \<in> A \<and> b \<in> U"
        by (intro bexI[of _ b]) auto }
    then have False
      using `?z \<le> y` `?z \<in> A` `y \<in> B` `y \<in> U` `A \<inter> B \<inter> U = {}` unfolding le_less by blast }
  note not_disjoint = this

  fix A B assume AB: "open A" "open B" "U \<subseteq> A \<union> B" "A \<inter> B \<inter> U = {}"
  moreover assume "A \<inter> U \<noteq> {}" then obtain x where x: "x \<in> U" "x \<in> A" by auto
  moreover assume "B \<inter> U \<noteq> {}" then obtain y where y: "y \<in> U" "y \<in> B" by auto
  moreover note not_disjoint[of B A y x] not_disjoint[of A B x y]
  ultimately show False by (cases x y rule: linorder_cases) auto
qed

lemma connected_iff_interval:
  fixes U :: "'a :: linear_continuum_topology set"
  shows "connected U \<longleftrightarrow> (\<forall>x\<in>U. \<forall>y\<in>U. \<forall>z. x \<le> z \<longrightarrow> z \<le> y \<longrightarrow> z \<in> U)"
  by (auto intro: connectedI_interval dest: connectedD_interval)

lemma connected_UNIV[simp]: "connected (UNIV::'a::linear_continuum_topology set)"
  unfolding connected_iff_interval by auto

lemma connected_Ioi[simp]: "connected {a::'a::linear_continuum_topology <..}"
  unfolding connected_iff_interval by auto

lemma connected_Ici[simp]: "connected {a::'a::linear_continuum_topology ..}"
  unfolding connected_iff_interval by auto

lemma connected_Iio[simp]: "connected {..< a::'a::linear_continuum_topology}"
  unfolding connected_iff_interval by auto

lemma connected_Iic[simp]: "connected {.. a::'a::linear_continuum_topology}"
  unfolding connected_iff_interval by auto

lemma connected_Ioo[simp]: "connected {a <..< b::'a::linear_continuum_topology}"
  unfolding connected_iff_interval by auto

lemma connected_Ioc[simp]: "connected {a <.. b::'a::linear_continuum_topology}"
  unfolding connected_iff_interval by auto

lemma connected_Ico[simp]: "connected {a ..< b::'a::linear_continuum_topology}"
  unfolding connected_iff_interval by auto

lemma connected_Icc[simp]: "connected {a .. b::'a::linear_continuum_topology}"
  unfolding connected_iff_interval by auto

lemma connected_contains_Ioo: 
  fixes A :: "'a :: linorder_topology set"
  assumes A: "connected A" "a \<in> A" "b \<in> A" shows "{a <..< b} \<subseteq> A"
  using connectedD_interval[OF A] by (simp add: subset_eq Ball_def less_imp_le)

subsection {* Intermediate Value Theorem *}

lemma IVT':
  fixes f :: "'a :: linear_continuum_topology \<Rightarrow> 'b :: linorder_topology"
  assumes y: "f a \<le> y" "y \<le> f b" "a \<le> b"
  assumes *: "continuous_on {a .. b} f"
  shows "\<exists>x. a \<le> x \<and> x \<le> b \<and> f x = y"
proof -
  have "connected {a..b}"
    unfolding connected_iff_interval by auto
  from connected_continuous_image[OF * this, THEN connectedD_interval, of "f a" "f b" y] y
  show ?thesis
    by (auto simp add: atLeastAtMost_def atLeast_def atMost_def)
qed

lemma IVT2':
  fixes f :: "'a :: linear_continuum_topology \<Rightarrow> 'b :: linorder_topology"
  assumes y: "f b \<le> y" "y \<le> f a" "a \<le> b"
  assumes *: "continuous_on {a .. b} f"
  shows "\<exists>x. a \<le> x \<and> x \<le> b \<and> f x = y"
proof -
  have "connected {a..b}"
    unfolding connected_iff_interval by auto
  from connected_continuous_image[OF * this, THEN connectedD_interval, of "f b" "f a" y] y
  show ?thesis
    by (auto simp add: atLeastAtMost_def atLeast_def atMost_def)
qed

lemma IVT:
  fixes f :: "'a :: linear_continuum_topology \<Rightarrow> 'b :: linorder_topology"
  shows "f a \<le> y \<Longrightarrow> y \<le> f b \<Longrightarrow> a \<le> b \<Longrightarrow> (\<forall>x. a \<le> x \<and> x \<le> b \<longrightarrow> isCont f x) \<Longrightarrow> \<exists>x. a \<le> x \<and> x \<le> b \<and> f x = y"
  by (rule IVT') (auto intro: continuous_at_imp_continuous_on)

lemma IVT2:
  fixes f :: "'a :: linear_continuum_topology \<Rightarrow> 'b :: linorder_topology"
  shows "f b \<le> y \<Longrightarrow> y \<le> f a \<Longrightarrow> a \<le> b \<Longrightarrow> (\<forall>x. a \<le> x \<and> x \<le> b \<longrightarrow> isCont f x) \<Longrightarrow> \<exists>x. a \<le> x \<and> x \<le> b \<and> f x = y"
  by (rule IVT2') (auto intro: continuous_at_imp_continuous_on)

lemma continuous_inj_imp_mono:
  fixes f :: "'a::linear_continuum_topology \<Rightarrow> 'b :: linorder_topology"
  assumes x: "a < x" "x < b"
  assumes cont: "continuous_on {a..b} f"
  assumes inj: "inj_on f {a..b}"
  shows "(f a < f x \<and> f x < f b) \<or> (f b < f x \<and> f x < f a)"
proof -
  note I = inj_on_iff[OF inj]
  { assume "f x < f a" "f x < f b"
    then obtain s t where "x \<le> s" "s \<le> b" "a \<le> t" "t \<le> x" "f s = f t" "f x < f s"
      using IVT'[of f x "min (f a) (f b)" b] IVT2'[of f x "min (f a) (f b)" a] x
      by (auto simp: continuous_on_subset[OF cont] less_imp_le)
    with x I have False by auto }
  moreover
  { assume "f a < f x" "f b < f x"
    then obtain s t where "x \<le> s" "s \<le> b" "a \<le> t" "t \<le> x" "f s = f t" "f s < f x"
      using IVT'[of f a "max (f a) (f b)" x] IVT2'[of f b "max (f a) (f b)" x] x
      by (auto simp: continuous_on_subset[OF cont] less_imp_le)
    with x I have False by auto }
  ultimately show ?thesis
    using I[of a x] I[of x b] x less_trans[OF x] by (auto simp add: le_less less_imp_neq neq_iff)
qed

subsection {* Setup @{typ "'a filter"} for lifting and transfer *}

context begin interpretation lifting_syntax .

definition rel_filter :: "('a \<Rightarrow> 'b \<Rightarrow> bool) \<Rightarrow> 'a filter \<Rightarrow> 'b filter \<Rightarrow> bool"
where "rel_filter R F G = ((R ===> op =) ===> op =) (Rep_filter F) (Rep_filter G)"

lemma rel_filter_eventually:
  "rel_filter R F G \<longleftrightarrow> 
  ((R ===> op =) ===> op =) (\<lambda>P. eventually P F) (\<lambda>P. eventually P G)"
by(simp add: rel_filter_def eventually_def)

lemma filtermap_id [simp, id_simps]: "filtermap id = id"
by(simp add: fun_eq_iff id_def filtermap_ident)

lemma filtermap_id' [simp]: "filtermap (\<lambda>x. x) = (\<lambda>F. F)"
using filtermap_id unfolding id_def .

lemma Quotient_filter [quot_map]:
  assumes Q: "Quotient R Abs Rep T"
  shows "Quotient (rel_filter R) (filtermap Abs) (filtermap Rep) (rel_filter T)"
unfolding Quotient_alt_def
proof(intro conjI strip)
  from Q have *: "\<And>x y. T x y \<Longrightarrow> Abs x = y"
    unfolding Quotient_alt_def by blast

  fix F G
  assume "rel_filter T F G"
  thus "filtermap Abs F = G" unfolding filter_eq_iff
    by(auto simp add: eventually_filtermap rel_filter_eventually * rel_funI del: iffI elim!: rel_funD)
next
  from Q have *: "\<And>x. T (Rep x) x" unfolding Quotient_alt_def by blast

  fix F
  show "rel_filter T (filtermap Rep F) F" 
    by(auto elim: rel_funD intro: * intro!: ext arg_cong[where f="\<lambda>P. eventually P F"] rel_funI
            del: iffI simp add: eventually_filtermap rel_filter_eventually)
qed(auto simp add: map_fun_def o_def eventually_filtermap filter_eq_iff fun_eq_iff rel_filter_eventually
         fun_quotient[OF fun_quotient[OF Q identity_quotient] identity_quotient, unfolded Quotient_alt_def])

lemma eventually_parametric [transfer_rule]:
  "((A ===> op =) ===> rel_filter A ===> op =) eventually eventually"
by(simp add: rel_fun_def rel_filter_eventually)

lemma rel_filter_eq [relator_eq]: "rel_filter op = = op ="
by(auto simp add: rel_filter_eventually rel_fun_eq fun_eq_iff filter_eq_iff)

lemma rel_filter_mono [relator_mono]:
  "A \<le> B \<Longrightarrow> rel_filter A \<le> rel_filter B"
unfolding rel_filter_eventually[abs_def]
by(rule le_funI)+(intro fun_mono fun_mono[THEN le_funD, THEN le_funD] order.refl)

lemma rel_filter_conversep [simp]: "rel_filter A\<inverse>\<inverse> = (rel_filter A)\<inverse>\<inverse>"
by(auto simp add: rel_filter_eventually fun_eq_iff rel_fun_def)

lemma is_filter_parametric_aux:
  assumes "is_filter F"
  assumes [transfer_rule]: "bi_total A" "bi_unique A"
  and [transfer_rule]: "((A ===> op =) ===> op =) F G"
  shows "is_filter G"
proof -
  interpret is_filter F by fact
  show ?thesis
  proof
    have "F (\<lambda>_. True) = G (\<lambda>x. True)" by transfer_prover
    thus "G (\<lambda>x. True)" by(simp add: True)
  next
    fix P' Q'
    assume "G P'" "G Q'"
    moreover
    from bi_total_fun[OF `bi_unique A` bi_total_eq, unfolded bi_total_def]
    obtain P Q where [transfer_rule]: "(A ===> op =) P P'" "(A ===> op =) Q Q'" by blast
    have "F P = G P'" "F Q = G Q'" by transfer_prover+
    ultimately have "F (\<lambda>x. P x \<and> Q x)" by(simp add: conj)
    moreover have "F (\<lambda>x. P x \<and> Q x) = G (\<lambda>x. P' x \<and> Q' x)" by transfer_prover
    ultimately show "G (\<lambda>x. P' x \<and> Q' x)" by simp
  next
    fix P' Q'
    assume "\<forall>x. P' x \<longrightarrow> Q' x" "G P'"
    moreover
    from bi_total_fun[OF `bi_unique A` bi_total_eq, unfolded bi_total_def]
    obtain P Q where [transfer_rule]: "(A ===> op =) P P'" "(A ===> op =) Q Q'" by blast
    have "F P = G P'" by transfer_prover
    moreover have "(\<forall>x. P x \<longrightarrow> Q x) \<longleftrightarrow> (\<forall>x. P' x \<longrightarrow> Q' x)" by transfer_prover
    ultimately have "F Q" by(simp add: mono)
    moreover have "F Q = G Q'" by transfer_prover
    ultimately show "G Q'" by simp
  qed
qed

lemma is_filter_parametric [transfer_rule]:
  "\<lbrakk> bi_total A; bi_unique A \<rbrakk>
  \<Longrightarrow> (((A ===> op =) ===> op =) ===> op =) is_filter is_filter"
apply(rule rel_funI)
apply(rule iffI)
 apply(erule (3) is_filter_parametric_aux)
apply(erule is_filter_parametric_aux[where A="conversep A"])
apply(auto simp add: rel_fun_def)
done

lemma left_total_rel_filter [transfer_rule]:
  assumes [transfer_rule]: "bi_total A" "bi_unique A"
  shows "left_total (rel_filter A)"
proof(rule left_totalI)
  fix F :: "'a filter"
  from bi_total_fun[OF bi_unique_fun[OF `bi_total A` bi_unique_eq] bi_total_eq]
  obtain G where [transfer_rule]: "((A ===> op =) ===> op =) (\<lambda>P. eventually P F) G" 
    unfolding  bi_total_def by blast
  moreover have "is_filter (\<lambda>P. eventually P F) \<longleftrightarrow> is_filter G" by transfer_prover
  hence "is_filter G" by(simp add: eventually_def is_filter_Rep_filter)
  ultimately have "rel_filter A F (Abs_filter G)"
    by(simp add: rel_filter_eventually eventually_Abs_filter)
  thus "\<exists>G. rel_filter A F G" ..
qed

lemma right_total_rel_filter [transfer_rule]:
  "\<lbrakk> bi_total A; bi_unique A \<rbrakk> \<Longrightarrow> right_total (rel_filter A)"
using left_total_rel_filter[of "A\<inverse>\<inverse>"] by simp

lemma bi_total_rel_filter [transfer_rule]:
  assumes "bi_total A" "bi_unique A"
  shows "bi_total (rel_filter A)"
unfolding bi_total_alt_def using assms
by(simp add: left_total_rel_filter right_total_rel_filter)

lemma left_unique_rel_filter [transfer_rule]:
  assumes "left_unique A"
  shows "left_unique (rel_filter A)"
proof(rule left_uniqueI)
  fix F F' G
  assume [transfer_rule]: "rel_filter A F G" "rel_filter A F' G"
  show "F = F'"
    unfolding filter_eq_iff
  proof
    fix P :: "'a \<Rightarrow> bool"
    obtain P' where [transfer_rule]: "(A ===> op =) P P'"
      using left_total_fun[OF assms left_total_eq] unfolding left_total_def by blast
    have "eventually P F = eventually P' G" 
      and "eventually P F' = eventually P' G" by transfer_prover+
    thus "eventually P F = eventually P F'" by simp
  qed
qed

lemma right_unique_rel_filter [transfer_rule]:
  "right_unique A \<Longrightarrow> right_unique (rel_filter A)"
using left_unique_rel_filter[of "A\<inverse>\<inverse>"] by simp

lemma bi_unique_rel_filter [transfer_rule]:
  "bi_unique A \<Longrightarrow> bi_unique (rel_filter A)"
by(simp add: bi_unique_alt_def left_unique_rel_filter right_unique_rel_filter)

lemma top_filter_parametric [transfer_rule]:
  "bi_total A \<Longrightarrow> (rel_filter A) top top"
by(simp add: rel_filter_eventually All_transfer)

lemma bot_filter_parametric [transfer_rule]: "(rel_filter A) bot bot"
by(simp add: rel_filter_eventually rel_fun_def)

lemma sup_filter_parametric [transfer_rule]:
  "(rel_filter A ===> rel_filter A ===> rel_filter A) sup sup"
by(fastforce simp add: rel_filter_eventually[abs_def] eventually_sup dest: rel_funD)

lemma Sup_filter_parametric [transfer_rule]:
  "(rel_set (rel_filter A) ===> rel_filter A) Sup Sup"
proof(rule rel_funI)
  fix S T
  assume [transfer_rule]: "rel_set (rel_filter A) S T"
  show "rel_filter A (Sup S) (Sup T)"
    by(simp add: rel_filter_eventually eventually_Sup) transfer_prover
qed

lemma principal_parametric [transfer_rule]:
  "(rel_set A ===> rel_filter A) principal principal"
proof(rule rel_funI)
  fix S S'
  assume [transfer_rule]: "rel_set A S S'"
  show "rel_filter A (principal S) (principal S')"
    by(simp add: rel_filter_eventually eventually_principal) transfer_prover
qed

context
  fixes A :: "'a \<Rightarrow> 'b \<Rightarrow> bool"
  assumes [transfer_rule]: "bi_unique A" 
begin

lemma le_filter_parametric [transfer_rule]:
  "(rel_filter A ===> rel_filter A ===> op =) op \<le> op \<le>"
unfolding le_filter_def[abs_def] by transfer_prover

lemma less_filter_parametric [transfer_rule]:
  "(rel_filter A ===> rel_filter A ===> op =) op < op <"
unfolding less_filter_def[abs_def] by transfer_prover

context
  assumes [transfer_rule]: "bi_total A"
begin

lemma Inf_filter_parametric [transfer_rule]:
  "(rel_set (rel_filter A) ===> rel_filter A) Inf Inf"
unfolding Inf_filter_def[abs_def] by transfer_prover

lemma inf_filter_parametric [transfer_rule]:
  "(rel_filter A ===> rel_filter A ===> rel_filter A) inf inf"
proof(intro rel_funI)+
  fix F F' G G'
  assume [transfer_rule]: "rel_filter A F F'" "rel_filter A G G'"
  have "rel_filter A (Inf {F, G}) (Inf {F', G'})" by transfer_prover
  thus "rel_filter A (inf F G) (inf F' G')" by simp
qed

end

end

end

end
