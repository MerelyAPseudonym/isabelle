(*  Title:      HOL/Probability/Sigma_Algebra.thy
    Author:     Stefan Richter, Markus Wenzel, TU München
    Author:     Johannes Hölzl, TU München
    Plus material from the Hurd/Coble measure theory development,
    translated by Lawrence Paulson.
*)

section {* Describing measurable sets *}

theory Sigma_Algebra
imports
  Complex_Main
  "~~/src/HOL/Library/Countable_Set"
  "~~/src/HOL/Library/FuncSet"
  "~~/src/HOL/Library/Indicator_Function"
  "~~/src/HOL/Library/Extended_Real"
begin

text {* Sigma algebras are an elementary concept in measure
  theory. To measure --- that is to integrate --- functions, we first have
  to measure sets. Unfortunately, when dealing with a large universe,
  it is often not possible to consistently assign a measure to every
  subset. Therefore it is necessary to define the set of measurable
  subsets of the universe. A sigma algebra is such a set that has
  three very natural and desirable properties. *}

subsection {* Families of sets *}

locale subset_class =
  fixes \<Omega> :: "'a set" and M :: "'a set set"
  assumes space_closed: "M \<subseteq> Pow \<Omega>"

lemma (in subset_class) sets_into_space: "x \<in> M \<Longrightarrow> x \<subseteq> \<Omega>"
  by (metis PowD contra_subsetD space_closed)

subsubsection {* Semiring of sets *}

definition "disjoint A \<longleftrightarrow> (\<forall>a\<in>A. \<forall>b\<in>A. a \<noteq> b \<longrightarrow> a \<inter> b = {})"

lemma disjointI:
  "(\<And>a b. a \<in> A \<Longrightarrow> b \<in> A \<Longrightarrow> a \<noteq> b \<Longrightarrow> a \<inter> b = {}) \<Longrightarrow> disjoint A"
  unfolding disjoint_def by auto

lemma disjointD:
  "disjoint A \<Longrightarrow> a \<in> A \<Longrightarrow> b \<in> A \<Longrightarrow> a \<noteq> b \<Longrightarrow> a \<inter> b = {}"
  unfolding disjoint_def by auto

lemma disjoint_empty[iff]: "disjoint {}"
  by (auto simp: disjoint_def)

lemma disjoint_union: 
  assumes C: "disjoint C" and B: "disjoint B" and disj: "\<Union>C \<inter> \<Union>B = {}"
  shows "disjoint (C \<union> B)"
proof (rule disjointI)
  fix c d assume sets: "c \<in> C \<union> B" "d \<in> C \<union> B" and "c \<noteq> d"
  show "c \<inter> d = {}"
  proof cases
    assume "(c \<in> C \<and> d \<in> C) \<or> (c \<in> B \<and> d \<in> B)"
    then show ?thesis
    proof 
      assume "c \<in> C \<and> d \<in> C" with `c \<noteq> d` C show "c \<inter> d = {}"
        by (auto simp: disjoint_def)
    next
      assume "c \<in> B \<and> d \<in> B" with `c \<noteq> d` B show "c \<inter> d = {}"
        by (auto simp: disjoint_def)
    qed
  next
    assume "\<not> ((c \<in> C \<and> d \<in> C) \<or> (c \<in> B \<and> d \<in> B))"
    with sets have "(c \<subseteq> \<Union>C \<and> d \<subseteq> \<Union>B) \<or> (c \<subseteq> \<Union>B \<and> d \<subseteq> \<Union>C)"
      by auto
    with disj show "c \<inter> d = {}" by auto
  qed
qed

lemma disjoint_singleton [simp]: "disjoint {A}"
by(simp add: disjoint_def)

locale semiring_of_sets = subset_class +
  assumes empty_sets[iff]: "{} \<in> M"
  assumes Int[intro]: "\<And>a b. a \<in> M \<Longrightarrow> b \<in> M \<Longrightarrow> a \<inter> b \<in> M"
  assumes Diff_cover:
    "\<And>a b. a \<in> M \<Longrightarrow> b \<in> M \<Longrightarrow> \<exists>C\<subseteq>M. finite C \<and> disjoint C \<and> a - b = \<Union>C"

lemma (in semiring_of_sets) finite_INT[intro]:
  assumes "finite I" "I \<noteq> {}" "\<And>i. i \<in> I \<Longrightarrow> A i \<in> M"
  shows "(\<Inter>i\<in>I. A i) \<in> M"
  using assms by (induct rule: finite_ne_induct) auto

lemma (in semiring_of_sets) Int_space_eq1 [simp]: "x \<in> M \<Longrightarrow> \<Omega> \<inter> x = x"
  by (metis Int_absorb1 sets_into_space)

lemma (in semiring_of_sets) Int_space_eq2 [simp]: "x \<in> M \<Longrightarrow> x \<inter> \<Omega> = x"
  by (metis Int_absorb2 sets_into_space)

lemma (in semiring_of_sets) sets_Collect_conj:
  assumes "{x\<in>\<Omega>. P x} \<in> M" "{x\<in>\<Omega>. Q x} \<in> M"
  shows "{x\<in>\<Omega>. Q x \<and> P x} \<in> M"
proof -
  have "{x\<in>\<Omega>. Q x \<and> P x} = {x\<in>\<Omega>. Q x} \<inter> {x\<in>\<Omega>. P x}"
    by auto
  with assms show ?thesis by auto
qed

lemma (in semiring_of_sets) sets_Collect_finite_All':
  assumes "\<And>i. i \<in> S \<Longrightarrow> {x\<in>\<Omega>. P i x} \<in> M" "finite S" "S \<noteq> {}"
  shows "{x\<in>\<Omega>. \<forall>i\<in>S. P i x} \<in> M"
proof -
  have "{x\<in>\<Omega>. \<forall>i\<in>S. P i x} = (\<Inter>i\<in>S. {x\<in>\<Omega>. P i x})"
    using `S \<noteq> {}` by auto
  with assms show ?thesis by auto
qed

locale ring_of_sets = semiring_of_sets +
  assumes Un [intro]: "\<And>a b. a \<in> M \<Longrightarrow> b \<in> M \<Longrightarrow> a \<union> b \<in> M"

lemma (in ring_of_sets) finite_Union [intro]:
  "finite X \<Longrightarrow> X \<subseteq> M \<Longrightarrow> Union X \<in> M"
  by (induct set: finite) (auto simp add: Un)

lemma (in ring_of_sets) finite_UN[intro]:
  assumes "finite I" and "\<And>i. i \<in> I \<Longrightarrow> A i \<in> M"
  shows "(\<Union>i\<in>I. A i) \<in> M"
  using assms by induct auto

lemma (in ring_of_sets) Diff [intro]:
  assumes "a \<in> M" "b \<in> M" shows "a - b \<in> M"
  using Diff_cover[OF assms] by auto

lemma ring_of_setsI:
  assumes space_closed: "M \<subseteq> Pow \<Omega>"
  assumes empty_sets[iff]: "{} \<in> M"
  assumes Un[intro]: "\<And>a b. a \<in> M \<Longrightarrow> b \<in> M \<Longrightarrow> a \<union> b \<in> M"
  assumes Diff[intro]: "\<And>a b. a \<in> M \<Longrightarrow> b \<in> M \<Longrightarrow> a - b \<in> M"
  shows "ring_of_sets \<Omega> M"
proof
  fix a b assume ab: "a \<in> M" "b \<in> M"
  from ab show "\<exists>C\<subseteq>M. finite C \<and> disjoint C \<and> a - b = \<Union>C"
    by (intro exI[of _ "{a - b}"]) (auto simp: disjoint_def)
  have "a \<inter> b = a - (a - b)" by auto
  also have "\<dots> \<in> M" using ab by auto
  finally show "a \<inter> b \<in> M" .
qed fact+

lemma ring_of_sets_iff: "ring_of_sets \<Omega> M \<longleftrightarrow> M \<subseteq> Pow \<Omega> \<and> {} \<in> M \<and> (\<forall>a\<in>M. \<forall>b\<in>M. a \<union> b \<in> M) \<and> (\<forall>a\<in>M. \<forall>b\<in>M. a - b \<in> M)"
proof
  assume "ring_of_sets \<Omega> M"
  then interpret ring_of_sets \<Omega> M .
  show "M \<subseteq> Pow \<Omega> \<and> {} \<in> M \<and> (\<forall>a\<in>M. \<forall>b\<in>M. a \<union> b \<in> M) \<and> (\<forall>a\<in>M. \<forall>b\<in>M. a - b \<in> M)"
    using space_closed by auto
qed (auto intro!: ring_of_setsI)

lemma (in ring_of_sets) insert_in_sets:
  assumes "{x} \<in> M" "A \<in> M" shows "insert x A \<in> M"
proof -
  have "{x} \<union> A \<in> M" using assms by (rule Un)
  thus ?thesis by auto
qed

lemma (in ring_of_sets) sets_Collect_disj:
  assumes "{x\<in>\<Omega>. P x} \<in> M" "{x\<in>\<Omega>. Q x} \<in> M"
  shows "{x\<in>\<Omega>. Q x \<or> P x} \<in> M"
proof -
  have "{x\<in>\<Omega>. Q x \<or> P x} = {x\<in>\<Omega>. Q x} \<union> {x\<in>\<Omega>. P x}"
    by auto
  with assms show ?thesis by auto
qed

lemma (in ring_of_sets) sets_Collect_finite_Ex:
  assumes "\<And>i. i \<in> S \<Longrightarrow> {x\<in>\<Omega>. P i x} \<in> M" "finite S"
  shows "{x\<in>\<Omega>. \<exists>i\<in>S. P i x} \<in> M"
proof -
  have "{x\<in>\<Omega>. \<exists>i\<in>S. P i x} = (\<Union>i\<in>S. {x\<in>\<Omega>. P i x})"
    by auto
  with assms show ?thesis by auto
qed

locale algebra = ring_of_sets +
  assumes top [iff]: "\<Omega> \<in> M"

lemma (in algebra) compl_sets [intro]:
  "a \<in> M \<Longrightarrow> \<Omega> - a \<in> M"
  by auto

lemma algebra_iff_Un:
  "algebra \<Omega> M \<longleftrightarrow>
    M \<subseteq> Pow \<Omega> \<and>
    {} \<in> M \<and>
    (\<forall>a \<in> M. \<Omega> - a \<in> M) \<and>
    (\<forall>a \<in> M. \<forall> b \<in> M. a \<union> b \<in> M)" (is "_ \<longleftrightarrow> ?Un")
proof
  assume "algebra \<Omega> M"
  then interpret algebra \<Omega> M .
  show ?Un using sets_into_space by auto
next
  assume ?Un
  then have "\<Omega> \<in> M" by auto
  interpret ring_of_sets \<Omega> M
  proof (rule ring_of_setsI)
    show \<Omega>: "M \<subseteq> Pow \<Omega>" "{} \<in> M"
      using `?Un` by auto
    fix a b assume a: "a \<in> M" and b: "b \<in> M"
    then show "a \<union> b \<in> M" using `?Un` by auto
    have "a - b = \<Omega> - ((\<Omega> - a) \<union> b)"
      using \<Omega> a b by auto
    then show "a - b \<in> M"
      using a b  `?Un` by auto
  qed
  show "algebra \<Omega> M" proof qed fact
qed

lemma algebra_iff_Int:
     "algebra \<Omega> M \<longleftrightarrow>
       M \<subseteq> Pow \<Omega> & {} \<in> M &
       (\<forall>a \<in> M. \<Omega> - a \<in> M) &
       (\<forall>a \<in> M. \<forall> b \<in> M. a \<inter> b \<in> M)" (is "_ \<longleftrightarrow> ?Int")
proof
  assume "algebra \<Omega> M"
  then interpret algebra \<Omega> M .
  show ?Int using sets_into_space by auto
next
  assume ?Int
  show "algebra \<Omega> M"
  proof (unfold algebra_iff_Un, intro conjI ballI)
    show \<Omega>: "M \<subseteq> Pow \<Omega>" "{} \<in> M"
      using `?Int` by auto
    from `?Int` show "\<And>a. a \<in> M \<Longrightarrow> \<Omega> - a \<in> M" by auto
    fix a b assume M: "a \<in> M" "b \<in> M"
    hence "a \<union> b = \<Omega> - ((\<Omega> - a) \<inter> (\<Omega> - b))"
      using \<Omega> by blast
    also have "... \<in> M"
      using M `?Int` by auto
    finally show "a \<union> b \<in> M" .
  qed
qed

lemma (in algebra) sets_Collect_neg:
  assumes "{x\<in>\<Omega>. P x} \<in> M"
  shows "{x\<in>\<Omega>. \<not> P x} \<in> M"
proof -
  have "{x\<in>\<Omega>. \<not> P x} = \<Omega> - {x\<in>\<Omega>. P x}" by auto
  with assms show ?thesis by auto
qed

lemma (in algebra) sets_Collect_imp:
  "{x\<in>\<Omega>. P x} \<in> M \<Longrightarrow> {x\<in>\<Omega>. Q x} \<in> M \<Longrightarrow> {x\<in>\<Omega>. Q x \<longrightarrow> P x} \<in> M"
  unfolding imp_conv_disj by (intro sets_Collect_disj sets_Collect_neg)

lemma (in algebra) sets_Collect_const:
  "{x\<in>\<Omega>. P} \<in> M"
  by (cases P) auto

lemma algebra_single_set:
  "X \<subseteq> S \<Longrightarrow> algebra S { {}, X, S - X, S }"
  by (auto simp: algebra_iff_Int)

subsubsection {* Restricted algebras *}

abbreviation (in algebra)
  "restricted_space A \<equiv> (op \<inter> A) ` M"

lemma (in algebra) restricted_algebra:
  assumes "A \<in> M" shows "algebra A (restricted_space A)"
  using assms by (auto simp: algebra_iff_Int)

subsubsection {* Sigma Algebras *}

locale sigma_algebra = algebra +
  assumes countable_nat_UN [intro]: "\<And>A. range A \<subseteq> M \<Longrightarrow> (\<Union>i::nat. A i) \<in> M"

lemma (in algebra) is_sigma_algebra:
  assumes "finite M"
  shows "sigma_algebra \<Omega> M"
proof
  fix A :: "nat \<Rightarrow> 'a set" assume "range A \<subseteq> M"
  then have "(\<Union>i. A i) = (\<Union>s\<in>M \<inter> range A. s)"
    by auto
  also have "(\<Union>s\<in>M \<inter> range A. s) \<in> M"
    using `finite M` by auto
  finally show "(\<Union>i. A i) \<in> M" .
qed

lemma countable_UN_eq:
  fixes A :: "'i::countable \<Rightarrow> 'a set"
  shows "(range A \<subseteq> M \<longrightarrow> (\<Union>i. A i) \<in> M) \<longleftrightarrow>
    (range (A \<circ> from_nat) \<subseteq> M \<longrightarrow> (\<Union>i. (A \<circ> from_nat) i) \<in> M)"
proof -
  let ?A' = "A \<circ> from_nat"
  have *: "(\<Union>i. ?A' i) = (\<Union>i. A i)" (is "?l = ?r")
  proof safe
    fix x i assume "x \<in> A i" thus "x \<in> ?l"
      by (auto intro!: exI[of _ "to_nat i"])
  next
    fix x i assume "x \<in> ?A' i" thus "x \<in> ?r"
      by (auto intro!: exI[of _ "from_nat i"])
  qed
  have **: "range ?A' = range A"
    using surj_from_nat
    by (auto simp: image_comp [symmetric] intro!: imageI)
  show ?thesis unfolding * ** ..
qed

lemma (in sigma_algebra) countable_Union [intro]:
  assumes "countable X" "X \<subseteq> M" shows "Union X \<in> M"
proof cases
  assume "X \<noteq> {}"
  hence "\<Union>X = (\<Union>n. from_nat_into X n)"
    using assms by (auto intro: from_nat_into) (metis from_nat_into_surj)
  also have "\<dots> \<in> M" using assms
    by (auto intro!: countable_nat_UN) (metis `X \<noteq> {}` from_nat_into set_mp)
  finally show ?thesis .
qed simp

lemma (in sigma_algebra) countable_UN[intro]:
  fixes A :: "'i::countable \<Rightarrow> 'a set"
  assumes "A`X \<subseteq> M"
  shows  "(\<Union>x\<in>X. A x) \<in> M"
proof -
  let ?A = "\<lambda>i. if i \<in> X then A i else {}"
  from assms have "range ?A \<subseteq> M" by auto
  with countable_nat_UN[of "?A \<circ> from_nat"] countable_UN_eq[of ?A M]
  have "(\<Union>x. ?A x) \<in> M" by auto
  moreover have "(\<Union>x. ?A x) = (\<Union>x\<in>X. A x)" by (auto split: split_if_asm)
  ultimately show ?thesis by simp
qed

lemma (in sigma_algebra) countable_UN':
  fixes A :: "'i \<Rightarrow> 'a set"
  assumes X: "countable X"
  assumes A: "A`X \<subseteq> M"
  shows  "(\<Union>x\<in>X. A x) \<in> M"
proof -
  have "(\<Union>x\<in>X. A x) = (\<Union>i\<in>to_nat_on X ` X. A (from_nat_into X i))"
    using X by auto
  also have "\<dots> \<in> M"
    using A X
    by (intro countable_UN) auto
  finally show ?thesis .
qed

lemma (in sigma_algebra) countable_INT [intro]:
  fixes A :: "'i::countable \<Rightarrow> 'a set"
  assumes A: "A`X \<subseteq> M" "X \<noteq> {}"
  shows "(\<Inter>i\<in>X. A i) \<in> M"
proof -
  from A have "\<forall>i\<in>X. A i \<in> M" by fast
  hence "\<Omega> - (\<Union>i\<in>X. \<Omega> - A i) \<in> M" by blast
  moreover
  have "(\<Inter>i\<in>X. A i) = \<Omega> - (\<Union>i\<in>X. \<Omega> - A i)" using space_closed A
    by blast
  ultimately show ?thesis by metis
qed

lemma (in sigma_algebra) countable_INT':
  fixes A :: "'i \<Rightarrow> 'a set"
  assumes X: "countable X" "X \<noteq> {}"
  assumes A: "A`X \<subseteq> M"
  shows  "(\<Inter>x\<in>X. A x) \<in> M"
proof -
  have "(\<Inter>x\<in>X. A x) = (\<Inter>i\<in>to_nat_on X ` X. A (from_nat_into X i))"
    using X by auto
  also have "\<dots> \<in> M"
    using A X
    by (intro countable_INT) auto
  finally show ?thesis .
qed

lemma (in sigma_algebra) countable_INT'':
  "UNIV \<in> M \<Longrightarrow> countable I \<Longrightarrow> (\<And>i. i \<in> I \<Longrightarrow> F i \<in> M) \<Longrightarrow> (\<Inter>i\<in>I. F i) \<in> M"
  by (cases "I = {}") (auto intro: countable_INT')

lemma (in sigma_algebra) countable:
  assumes "\<And>a. a \<in> A \<Longrightarrow> {a} \<in> M" "countable A"
  shows "A \<in> M"
proof -
  have "(\<Union>a\<in>A. {a}) \<in> M"
    using assms by (intro countable_UN') auto
  also have "(\<Union>a\<in>A. {a}) = A" by auto
  finally show ?thesis by auto
qed

lemma ring_of_sets_Pow: "ring_of_sets sp (Pow sp)"
  by (auto simp: ring_of_sets_iff)

lemma algebra_Pow: "algebra sp (Pow sp)"
  by (auto simp: algebra_iff_Un)

lemma sigma_algebra_iff:
  "sigma_algebra \<Omega> M \<longleftrightarrow>
    algebra \<Omega> M \<and> (\<forall>A. range A \<subseteq> M \<longrightarrow> (\<Union>i::nat. A i) \<in> M)"
  by (simp add: sigma_algebra_def sigma_algebra_axioms_def)

lemma sigma_algebra_Pow: "sigma_algebra sp (Pow sp)"
  by (auto simp: sigma_algebra_iff algebra_iff_Int)

lemma (in sigma_algebra) sets_Collect_countable_All:
  assumes "\<And>i. {x\<in>\<Omega>. P i x} \<in> M"
  shows "{x\<in>\<Omega>. \<forall>i::'i::countable. P i x} \<in> M"
proof -
  have "{x\<in>\<Omega>. \<forall>i::'i::countable. P i x} = (\<Inter>i. {x\<in>\<Omega>. P i x})" by auto
  with assms show ?thesis by auto
qed

lemma (in sigma_algebra) sets_Collect_countable_Ex:
  assumes "\<And>i. {x\<in>\<Omega>. P i x} \<in> M"
  shows "{x\<in>\<Omega>. \<exists>i::'i::countable. P i x} \<in> M"
proof -
  have "{x\<in>\<Omega>. \<exists>i::'i::countable. P i x} = (\<Union>i. {x\<in>\<Omega>. P i x})" by auto
  with assms show ?thesis by auto
qed

lemma (in sigma_algebra) sets_Collect_countable_Ex':
  assumes "\<And>i. i \<in> I \<Longrightarrow> {x\<in>\<Omega>. P i x} \<in> M"
  assumes "countable I"
  shows "{x\<in>\<Omega>. \<exists>i\<in>I. P i x} \<in> M"
proof -
  have "{x\<in>\<Omega>. \<exists>i\<in>I. P i x} = (\<Union>i\<in>I. {x\<in>\<Omega>. P i x})" by auto
  with assms show ?thesis 
    by (auto intro!: countable_UN')
qed

lemma (in sigma_algebra) sets_Collect_countable_All':
  assumes "\<And>i. i \<in> I \<Longrightarrow> {x\<in>\<Omega>. P i x} \<in> M"
  assumes "countable I"
  shows "{x\<in>\<Omega>. \<forall>i\<in>I. P i x} \<in> M"
proof -
  have "{x\<in>\<Omega>. \<forall>i\<in>I. P i x} = (\<Inter>i\<in>I. {x\<in>\<Omega>. P i x}) \<inter> \<Omega>" by auto
  with assms show ?thesis 
    by (cases "I = {}") (auto intro!: countable_INT')
qed

lemma (in sigma_algebra) sets_Collect_countable_Ex1':
  assumes "\<And>i. i \<in> I \<Longrightarrow> {x\<in>\<Omega>. P i x} \<in> M"
  assumes "countable I"
  shows "{x\<in>\<Omega>. \<exists>!i\<in>I. P i x} \<in> M"
proof -
  have "{x\<in>\<Omega>. \<exists>!i\<in>I. P i x} = {x\<in>\<Omega>. \<exists>i\<in>I. P i x \<and> (\<forall>j\<in>I. P j x \<longrightarrow> i = j)}"
    by auto
  with assms show ?thesis 
    by (auto intro!: sets_Collect_countable_All' sets_Collect_countable_Ex' sets_Collect_conj sets_Collect_imp sets_Collect_const)
qed

lemmas (in sigma_algebra) sets_Collect =
  sets_Collect_imp sets_Collect_disj sets_Collect_conj sets_Collect_neg sets_Collect_const
  sets_Collect_countable_All sets_Collect_countable_Ex sets_Collect_countable_All

lemma (in sigma_algebra) sets_Collect_countable_Ball:
  assumes "\<And>i. {x\<in>\<Omega>. P i x} \<in> M"
  shows "{x\<in>\<Omega>. \<forall>i::'i::countable\<in>X. P i x} \<in> M"
  unfolding Ball_def by (intro sets_Collect assms)

lemma (in sigma_algebra) sets_Collect_countable_Bex:
  assumes "\<And>i. {x\<in>\<Omega>. P i x} \<in> M"
  shows "{x\<in>\<Omega>. \<exists>i::'i::countable\<in>X. P i x} \<in> M"
  unfolding Bex_def by (intro sets_Collect assms)

lemma sigma_algebra_single_set:
  assumes "X \<subseteq> S"
  shows "sigma_algebra S { {}, X, S - X, S }"
  using algebra.is_sigma_algebra[OF algebra_single_set[OF `X \<subseteq> S`]] by simp

subsubsection {* Binary Unions *}

definition binary :: "'a \<Rightarrow> 'a \<Rightarrow> nat \<Rightarrow> 'a"
  where "binary a b =  (\<lambda>x. b)(0 := a)"

lemma range_binary_eq: "range(binary a b) = {a,b}"
  by (auto simp add: binary_def)

lemma Un_range_binary: "a \<union> b = (\<Union>i::nat. binary a b i)"
  by (simp add: SUP_def range_binary_eq)

lemma Int_range_binary: "a \<inter> b = (\<Inter>i::nat. binary a b i)"
  by (simp add: INF_def range_binary_eq)

lemma sigma_algebra_iff2:
     "sigma_algebra \<Omega> M \<longleftrightarrow>
       M \<subseteq> Pow \<Omega> \<and>
       {} \<in> M \<and> (\<forall>s \<in> M. \<Omega> - s \<in> M) \<and>
       (\<forall>A. range A \<subseteq> M \<longrightarrow> (\<Union>i::nat. A i) \<in> M)"
  by (auto simp add: range_binary_eq sigma_algebra_def sigma_algebra_axioms_def
         algebra_iff_Un Un_range_binary)

subsubsection {* Initial Sigma Algebra *}

text {*Sigma algebras can naturally be created as the closure of any set of
  M with regard to the properties just postulated.  *}

inductive_set sigma_sets :: "'a set \<Rightarrow> 'a set set \<Rightarrow> 'a set set"
  for sp :: "'a set" and A :: "'a set set"
  where
    Basic[intro, simp]: "a \<in> A \<Longrightarrow> a \<in> sigma_sets sp A"
  | Empty: "{} \<in> sigma_sets sp A"
  | Compl: "a \<in> sigma_sets sp A \<Longrightarrow> sp - a \<in> sigma_sets sp A"
  | Union: "(\<And>i::nat. a i \<in> sigma_sets sp A) \<Longrightarrow> (\<Union>i. a i) \<in> sigma_sets sp A"

lemma (in sigma_algebra) sigma_sets_subset:
  assumes a: "a \<subseteq> M"
  shows "sigma_sets \<Omega> a \<subseteq> M"
proof
  fix x
  assume "x \<in> sigma_sets \<Omega> a"
  from this show "x \<in> M"
    by (induct rule: sigma_sets.induct, auto) (metis a subsetD)
qed

lemma sigma_sets_into_sp: "A \<subseteq> Pow sp \<Longrightarrow> x \<in> sigma_sets sp A \<Longrightarrow> x \<subseteq> sp"
  by (erule sigma_sets.induct, auto)

lemma sigma_algebra_sigma_sets:
     "a \<subseteq> Pow \<Omega> \<Longrightarrow> sigma_algebra \<Omega> (sigma_sets \<Omega> a)"
  by (auto simp add: sigma_algebra_iff2 dest: sigma_sets_into_sp
           intro!: sigma_sets.Union sigma_sets.Empty sigma_sets.Compl)

lemma sigma_sets_least_sigma_algebra:
  assumes "A \<subseteq> Pow S"
  shows "sigma_sets S A = \<Inter>{B. A \<subseteq> B \<and> sigma_algebra S B}"
proof safe
  fix B X assume "A \<subseteq> B" and sa: "sigma_algebra S B"
    and X: "X \<in> sigma_sets S A"
  from sigma_algebra.sigma_sets_subset[OF sa, simplified, OF `A \<subseteq> B`] X
  show "X \<in> B" by auto
next
  fix X assume "X \<in> \<Inter>{B. A \<subseteq> B \<and> sigma_algebra S B}"
  then have [intro!]: "\<And>B. A \<subseteq> B \<Longrightarrow> sigma_algebra S B \<Longrightarrow> X \<in> B"
     by simp
  have "A \<subseteq> sigma_sets S A" using assms by auto
  moreover have "sigma_algebra S (sigma_sets S A)"
    using assms by (intro sigma_algebra_sigma_sets[of A]) auto
  ultimately show "X \<in> sigma_sets S A" by auto
qed

lemma sigma_sets_top: "sp \<in> sigma_sets sp A"
  by (metis Diff_empty sigma_sets.Compl sigma_sets.Empty)

lemma sigma_sets_Un:
  "a \<in> sigma_sets sp A \<Longrightarrow> b \<in> sigma_sets sp A \<Longrightarrow> a \<union> b \<in> sigma_sets sp A"
apply (simp add: Un_range_binary range_binary_eq)
apply (rule Union, simp add: binary_def)
done

lemma sigma_sets_Inter:
  assumes Asb: "A \<subseteq> Pow sp"
  shows "(\<And>i::nat. a i \<in> sigma_sets sp A) \<Longrightarrow> (\<Inter>i. a i) \<in> sigma_sets sp A"
proof -
  assume ai: "\<And>i::nat. a i \<in> sigma_sets sp A"
  hence "\<And>i::nat. sp-(a i) \<in> sigma_sets sp A"
    by (rule sigma_sets.Compl)
  hence "(\<Union>i. sp-(a i)) \<in> sigma_sets sp A"
    by (rule sigma_sets.Union)
  hence "sp-(\<Union>i. sp-(a i)) \<in> sigma_sets sp A"
    by (rule sigma_sets.Compl)
  also have "sp-(\<Union>i. sp-(a i)) = sp Int (\<Inter>i. a i)"
    by auto
  also have "... = (\<Inter>i. a i)" using ai
    by (blast dest: sigma_sets_into_sp [OF Asb])
  finally show ?thesis .
qed

lemma sigma_sets_INTER:
  assumes Asb: "A \<subseteq> Pow sp"
      and ai: "\<And>i::nat. i \<in> S \<Longrightarrow> a i \<in> sigma_sets sp A" and non: "S \<noteq> {}"
  shows "(\<Inter>i\<in>S. a i) \<in> sigma_sets sp A"
proof -
  from ai have "\<And>i. (if i\<in>S then a i else sp) \<in> sigma_sets sp A"
    by (simp add: sigma_sets.intros(2-) sigma_sets_top)
  hence "(\<Inter>i. (if i\<in>S then a i else sp)) \<in> sigma_sets sp A"
    by (rule sigma_sets_Inter [OF Asb])
  also have "(\<Inter>i. (if i\<in>S then a i else sp)) = (\<Inter>i\<in>S. a i)"
    by auto (metis ai non sigma_sets_into_sp subset_empty subset_iff Asb)+
  finally show ?thesis .
qed

lemma sigma_sets_UNION: "countable B \<Longrightarrow> (\<And>b. b \<in> B \<Longrightarrow> b \<in> sigma_sets X A) \<Longrightarrow> (\<Union>B) \<in> sigma_sets X A"
  using from_nat_into[of B] range_from_nat_into[of B] sigma_sets.Union[of "from_nat_into B" X A]
  apply (cases "B = {}")
  apply (simp add: sigma_sets.Empty)
  apply (simp del: Union_image_eq add: Union_image_eq[symmetric])
  done

lemma (in sigma_algebra) sigma_sets_eq:
     "sigma_sets \<Omega> M = M"
proof
  show "M \<subseteq> sigma_sets \<Omega> M"
    by (metis Set.subsetI sigma_sets.Basic)
  next
  show "sigma_sets \<Omega> M \<subseteq> M"
    by (metis sigma_sets_subset subset_refl)
qed

lemma sigma_sets_eqI:
  assumes A: "\<And>a. a \<in> A \<Longrightarrow> a \<in> sigma_sets M B"
  assumes B: "\<And>b. b \<in> B \<Longrightarrow> b \<in> sigma_sets M A"
  shows "sigma_sets M A = sigma_sets M B"
proof (intro set_eqI iffI)
  fix a assume "a \<in> sigma_sets M A"
  from this A show "a \<in> sigma_sets M B"
    by induct (auto intro!: sigma_sets.intros(2-) del: sigma_sets.Basic)
next
  fix b assume "b \<in> sigma_sets M B"
  from this B show "b \<in> sigma_sets M A"
    by induct (auto intro!: sigma_sets.intros(2-) del: sigma_sets.Basic)
qed

lemma sigma_sets_subseteq: assumes "A \<subseteq> B" shows "sigma_sets X A \<subseteq> sigma_sets X B"
proof
  fix x assume "x \<in> sigma_sets X A" then show "x \<in> sigma_sets X B"
    by induct (insert `A \<subseteq> B`, auto intro: sigma_sets.intros(2-))
qed

lemma sigma_sets_mono: assumes "A \<subseteq> sigma_sets X B" shows "sigma_sets X A \<subseteq> sigma_sets X B"
proof
  fix x assume "x \<in> sigma_sets X A" then show "x \<in> sigma_sets X B"
    by induct (insert `A \<subseteq> sigma_sets X B`, auto intro: sigma_sets.intros(2-))
qed

lemma sigma_sets_mono': assumes "A \<subseteq> B" shows "sigma_sets X A \<subseteq> sigma_sets X B"
proof
  fix x assume "x \<in> sigma_sets X A" then show "x \<in> sigma_sets X B"
    by induct (insert `A \<subseteq> B`, auto intro: sigma_sets.intros(2-))
qed

lemma sigma_sets_superset_generator: "A \<subseteq> sigma_sets X A"
  by (auto intro: sigma_sets.Basic)

lemma (in sigma_algebra) restriction_in_sets:
  fixes A :: "nat \<Rightarrow> 'a set"
  assumes "S \<in> M"
  and *: "range A \<subseteq> (\<lambda>A. S \<inter> A) ` M" (is "_ \<subseteq> ?r")
  shows "range A \<subseteq> M" "(\<Union>i. A i) \<in> (\<lambda>A. S \<inter> A) ` M"
proof -
  { fix i have "A i \<in> ?r" using * by auto
    hence "\<exists>B. A i = B \<inter> S \<and> B \<in> M" by auto
    hence "A i \<subseteq> S" "A i \<in> M" using `S \<in> M` by auto }
  thus "range A \<subseteq> M" "(\<Union>i. A i) \<in> (\<lambda>A. S \<inter> A) ` M"
    by (auto intro!: image_eqI[of _ _ "(\<Union>i. A i)"])
qed

lemma (in sigma_algebra) restricted_sigma_algebra:
  assumes "S \<in> M"
  shows "sigma_algebra S (restricted_space S)"
  unfolding sigma_algebra_def sigma_algebra_axioms_def
proof safe
  show "algebra S (restricted_space S)" using restricted_algebra[OF assms] .
next
  fix A :: "nat \<Rightarrow> 'a set" assume "range A \<subseteq> restricted_space S"
  from restriction_in_sets[OF assms this[simplified]]
  show "(\<Union>i. A i) \<in> restricted_space S" by simp
qed

lemma sigma_sets_Int:
  assumes "A \<in> sigma_sets sp st" "A \<subseteq> sp"
  shows "op \<inter> A ` sigma_sets sp st = sigma_sets A (op \<inter> A ` st)"
proof (intro equalityI subsetI)
  fix x assume "x \<in> op \<inter> A ` sigma_sets sp st"
  then obtain y where "y \<in> sigma_sets sp st" "x = y \<inter> A" by auto
  then have "x \<in> sigma_sets (A \<inter> sp) (op \<inter> A ` st)"
  proof (induct arbitrary: x)
    case (Compl a)
    then show ?case
      by (force intro!: sigma_sets.Compl simp: Diff_Int_distrib ac_simps)
  next
    case (Union a)
    then show ?case
      by (auto intro!: sigma_sets.Union
               simp add: UN_extend_simps simp del: UN_simps)
  qed (auto intro!: sigma_sets.intros(2-))
  then show "x \<in> sigma_sets A (op \<inter> A ` st)"
    using `A \<subseteq> sp` by (simp add: Int_absorb2)
next
  fix x assume "x \<in> sigma_sets A (op \<inter> A ` st)"
  then show "x \<in> op \<inter> A ` sigma_sets sp st"
  proof induct
    case (Compl a)
    then obtain x where "a = A \<inter> x" "x \<in> sigma_sets sp st" by auto
    then show ?case using `A \<subseteq> sp`
      by (force simp add: image_iff intro!: bexI[of _ "sp - x"] sigma_sets.Compl)
  next
    case (Union a)
    then have "\<forall>i. \<exists>x. x \<in> sigma_sets sp st \<and> a i = A \<inter> x"
      by (auto simp: image_iff Bex_def)
    from choice[OF this] guess f ..
    then show ?case
      by (auto intro!: bexI[of _ "(\<Union>x. f x)"] sigma_sets.Union
               simp add: image_iff)
  qed (auto intro!: sigma_sets.intros(2-))
qed

lemma sigma_sets_empty_eq: "sigma_sets A {} = {{}, A}"
proof (intro set_eqI iffI)
  fix a assume "a \<in> sigma_sets A {}" then show "a \<in> {{}, A}"
    by induct blast+
qed (auto intro: sigma_sets.Empty sigma_sets_top)

lemma sigma_sets_single[simp]: "sigma_sets A {A} = {{}, A}"
proof (intro set_eqI iffI)
  fix x assume "x \<in> sigma_sets A {A}"
  then show "x \<in> {{}, A}"
    by induct blast+
next
  fix x assume "x \<in> {{}, A}"
  then show "x \<in> sigma_sets A {A}"
    by (auto intro: sigma_sets.Empty sigma_sets_top)
qed

lemma sigma_sets_sigma_sets_eq:
  "M \<subseteq> Pow S \<Longrightarrow> sigma_sets S (sigma_sets S M) = sigma_sets S M"
  by (rule sigma_algebra.sigma_sets_eq[OF sigma_algebra_sigma_sets, of M S]) auto

lemma sigma_sets_singleton:
  assumes "X \<subseteq> S"
  shows "sigma_sets S { X } = { {}, X, S - X, S }"
proof -
  interpret sigma_algebra S "{ {}, X, S - X, S }"
    by (rule sigma_algebra_single_set) fact
  have "sigma_sets S { X } \<subseteq> sigma_sets S { {}, X, S - X, S }"
    by (rule sigma_sets_subseteq) simp
  moreover have "\<dots> = { {}, X, S - X, S }"
    using sigma_sets_eq by simp
  moreover
  { fix A assume "A \<in> { {}, X, S - X, S }"
    then have "A \<in> sigma_sets S { X }"
      by (auto intro: sigma_sets.intros(2-) sigma_sets_top) }
  ultimately have "sigma_sets S { X } = sigma_sets S { {}, X, S - X, S }"
    by (intro antisym) auto
  with sigma_sets_eq show ?thesis by simp
qed

lemma restricted_sigma:
  assumes S: "S \<in> sigma_sets \<Omega> M" and M: "M \<subseteq> Pow \<Omega>"
  shows "algebra.restricted_space (sigma_sets \<Omega> M) S =
    sigma_sets S (algebra.restricted_space M S)"
proof -
  from S sigma_sets_into_sp[OF M]
  have "S \<in> sigma_sets \<Omega> M" "S \<subseteq> \<Omega>" by auto
  from sigma_sets_Int[OF this]
  show ?thesis by simp
qed

lemma sigma_sets_vimage_commute:
  assumes X: "X \<in> \<Omega> \<rightarrow> \<Omega>'"
  shows "{X -` A \<inter> \<Omega> |A. A \<in> sigma_sets \<Omega>' M'}
       = sigma_sets \<Omega> {X -` A \<inter> \<Omega> |A. A \<in> M'}" (is "?L = ?R")
proof
  show "?L \<subseteq> ?R"
  proof clarify
    fix A assume "A \<in> sigma_sets \<Omega>' M'"
    then show "X -` A \<inter> \<Omega> \<in> ?R"
    proof induct
      case Empty then show ?case
        by (auto intro!: sigma_sets.Empty)
    next
      case (Compl B)
      have [simp]: "X -` (\<Omega>' - B) \<inter> \<Omega> = \<Omega> - (X -` B \<inter> \<Omega>)"
        by (auto simp add: funcset_mem [OF X])
      with Compl show ?case
        by (auto intro!: sigma_sets.Compl)
    next
      case (Union F)
      then show ?case
        by (auto simp add: vimage_UN UN_extend_simps(4) simp del: UN_simps
                 intro!: sigma_sets.Union)
    qed auto
  qed
  show "?R \<subseteq> ?L"
  proof clarify
    fix A assume "A \<in> ?R"
    then show "\<exists>B. A = X -` B \<inter> \<Omega> \<and> B \<in> sigma_sets \<Omega>' M'"
    proof induct
      case (Basic B) then show ?case by auto
    next
      case Empty then show ?case
        by (auto intro!: sigma_sets.Empty exI[of _ "{}"])
    next
      case (Compl B)
      then obtain A where A: "B = X -` A \<inter> \<Omega>" "A \<in> sigma_sets \<Omega>' M'" by auto
      then have [simp]: "\<Omega> - B = X -` (\<Omega>' - A) \<inter> \<Omega>"
        by (auto simp add: funcset_mem [OF X])
      with A(2) show ?case
        by (auto intro: sigma_sets.Compl)
    next
      case (Union F)
      then have "\<forall>i. \<exists>B. F i = X -` B \<inter> \<Omega> \<and> B \<in> sigma_sets \<Omega>' M'" by auto
      from choice[OF this] guess A .. note A = this
      with A show ?case
        by (auto simp: vimage_UN[symmetric] intro: sigma_sets.Union)
    qed
  qed
qed

subsubsection "Disjoint families"

definition
  disjoint_family_on  where
  "disjoint_family_on A S \<longleftrightarrow> (\<forall>m\<in>S. \<forall>n\<in>S. m \<noteq> n \<longrightarrow> A m \<inter> A n = {})"

abbreviation
  "disjoint_family A \<equiv> disjoint_family_on A UNIV"

lemma range_subsetD: "range f \<subseteq> B \<Longrightarrow> f i \<in> B"
  by blast

lemma disjoint_family_onD: "disjoint_family_on A I \<Longrightarrow> i \<in> I \<Longrightarrow> j \<in> I \<Longrightarrow> i \<noteq> j \<Longrightarrow> A i \<inter> A j = {}"
  by (auto simp: disjoint_family_on_def)

lemma Int_Diff_disjoint: "A \<inter> B \<inter> (A - B) = {}"
  by blast

lemma Int_Diff_Un: "A \<inter> B \<union> (A - B) = A"
  by blast

lemma disjoint_family_subset:
     "disjoint_family A \<Longrightarrow> (!!x. B x \<subseteq> A x) \<Longrightarrow> disjoint_family B"
  by (force simp add: disjoint_family_on_def)

lemma disjoint_family_on_bisimulation:
  assumes "disjoint_family_on f S"
  and "\<And>n m. n \<in> S \<Longrightarrow> m \<in> S \<Longrightarrow> n \<noteq> m \<Longrightarrow> f n \<inter> f m = {} \<Longrightarrow> g n \<inter> g m = {}"
  shows "disjoint_family_on g S"
  using assms unfolding disjoint_family_on_def by auto

lemma disjoint_family_on_mono:
  "A \<subseteq> B \<Longrightarrow> disjoint_family_on f B \<Longrightarrow> disjoint_family_on f A"
  unfolding disjoint_family_on_def by auto

lemma disjoint_family_Suc:
  assumes Suc: "!!n. A n \<subseteq> A (Suc n)"
  shows "disjoint_family (\<lambda>i. A (Suc i) - A i)"
proof -
  {
    fix m
    have "!!n. A n \<subseteq> A (m+n)"
    proof (induct m)
      case 0 show ?case by simp
    next
      case (Suc m) thus ?case
        by (metis Suc_eq_plus1 assms add.commute add.left_commute subset_trans)
    qed
  }
  hence "!!m n. m < n \<Longrightarrow> A m \<subseteq> A n"
    by (metis add.commute le_add_diff_inverse nat_less_le)
  thus ?thesis
    by (auto simp add: disjoint_family_on_def)
      (metis insert_absorb insert_subset le_SucE le_antisym not_leE)
qed

lemma setsum_indicator_disjoint_family:
  fixes f :: "'d \<Rightarrow> 'e::semiring_1"
  assumes d: "disjoint_family_on A P" and "x \<in> A j" and "finite P" and "j \<in> P"
  shows "(\<Sum>i\<in>P. f i * indicator (A i) x) = f j"
proof -
  have "P \<inter> {i. x \<in> A i} = {j}"
    using d `x \<in> A j` `j \<in> P` unfolding disjoint_family_on_def
    by auto
  thus ?thesis
    unfolding indicator_def
    by (simp add: if_distrib setsum.If_cases[OF `finite P`])
qed

definition disjointed :: "(nat \<Rightarrow> 'a set) \<Rightarrow> nat \<Rightarrow> 'a set "
  where "disjointed A n = A n - (\<Union>i\<in>{0..<n}. A i)"

lemma finite_UN_disjointed_eq: "(\<Union>i\<in>{0..<n}. disjointed A i) = (\<Union>i\<in>{0..<n}. A i)"
proof (induct n)
  case 0 show ?case by simp
next
  case (Suc n)
  thus ?case by (simp add: atLeastLessThanSuc disjointed_def)
qed

lemma UN_disjointed_eq: "(\<Union>i. disjointed A i) = (\<Union>i. A i)"
  apply (rule UN_finite2_eq [where k=0])
  apply (simp add: finite_UN_disjointed_eq)
  done

lemma less_disjoint_disjointed: "m<n \<Longrightarrow> disjointed A m \<inter> disjointed A n = {}"
  by (auto simp add: disjointed_def)

lemma disjoint_family_disjointed: "disjoint_family (disjointed A)"
  by (simp add: disjoint_family_on_def)
     (metis neq_iff Int_commute less_disjoint_disjointed)

lemma disjointed_subset: "disjointed A n \<subseteq> A n"
  by (auto simp add: disjointed_def)

lemma (in ring_of_sets) UNION_in_sets:
  fixes A:: "nat \<Rightarrow> 'a set"
  assumes A: "range A \<subseteq> M"
  shows  "(\<Union>i\<in>{0..<n}. A i) \<in> M"
proof (induct n)
  case 0 show ?case by simp
next
  case (Suc n)
  thus ?case
    by (simp add: atLeastLessThanSuc) (metis A Un UNIV_I image_subset_iff)
qed

lemma (in ring_of_sets) range_disjointed_sets:
  assumes A: "range A \<subseteq> M"
  shows  "range (disjointed A) \<subseteq> M"
proof (auto simp add: disjointed_def)
  fix n
  show "A n - (\<Union>i\<in>{0..<n}. A i) \<in> M" using UNION_in_sets
    by (metis A Diff UNIV_I image_subset_iff)
qed

lemma (in algebra) range_disjointed_sets':
  "range A \<subseteq> M \<Longrightarrow> range (disjointed A) \<subseteq> M"
  using range_disjointed_sets .

lemma disjointed_0[simp]: "disjointed A 0 = A 0"
  by (simp add: disjointed_def)

lemma incseq_Un:
  "incseq A \<Longrightarrow> (\<Union>i\<le>n. A i) = A n"
  unfolding incseq_def by auto

lemma disjointed_incseq:
  "incseq A \<Longrightarrow> disjointed A (Suc n) = A (Suc n) - A n"
  using incseq_Un[of A]
  by (simp add: disjointed_def atLeastLessThanSuc_atLeastAtMost atLeast0AtMost)

lemma sigma_algebra_disjoint_iff:
  "sigma_algebra \<Omega> M \<longleftrightarrow> algebra \<Omega> M \<and>
    (\<forall>A. range A \<subseteq> M \<longrightarrow> disjoint_family A \<longrightarrow> (\<Union>i::nat. A i) \<in> M)"
proof (auto simp add: sigma_algebra_iff)
  fix A :: "nat \<Rightarrow> 'a set"
  assume M: "algebra \<Omega> M"
     and A: "range A \<subseteq> M"
     and UnA: "\<forall>A. range A \<subseteq> M \<longrightarrow> disjoint_family A \<longrightarrow> (\<Union>i::nat. A i) \<in> M"
  hence "range (disjointed A) \<subseteq> M \<longrightarrow>
         disjoint_family (disjointed A) \<longrightarrow>
         (\<Union>i. disjointed A i) \<in> M" by blast
  hence "(\<Union>i. disjointed A i) \<in> M"
    by (simp add: algebra.range_disjointed_sets'[of \<Omega>] M A disjoint_family_disjointed)
  thus "(\<Union>i::nat. A i) \<in> M" by (simp add: UN_disjointed_eq)
qed

lemma disjoint_family_on_disjoint_image:
  "disjoint_family_on A I \<Longrightarrow> disjoint (A ` I)"
  unfolding disjoint_family_on_def disjoint_def by force

lemma disjoint_image_disjoint_family_on:
  assumes d: "disjoint (A ` I)" and i: "inj_on A I"
  shows "disjoint_family_on A I"
  unfolding disjoint_family_on_def
proof (intro ballI impI)
  fix n m assume nm: "m \<in> I" "n \<in> I" and "n \<noteq> m"
  with i[THEN inj_onD, of n m] show "A n \<inter> A m = {}"
    by (intro disjointD[OF d]) auto
qed

subsubsection {* Ring generated by a semiring *}

definition (in semiring_of_sets)
  "generated_ring = { \<Union>C | C. C \<subseteq> M \<and> finite C \<and> disjoint C }"

lemma (in semiring_of_sets) generated_ringE[elim?]:
  assumes "a \<in> generated_ring"
  obtains C where "finite C" "disjoint C" "C \<subseteq> M" "a = \<Union>C"
  using assms unfolding generated_ring_def by auto

lemma (in semiring_of_sets) generated_ringI[intro?]:
  assumes "finite C" "disjoint C" "C \<subseteq> M" "a = \<Union>C"
  shows "a \<in> generated_ring"
  using assms unfolding generated_ring_def by auto

lemma (in semiring_of_sets) generated_ringI_Basic:
  "A \<in> M \<Longrightarrow> A \<in> generated_ring"
  by (rule generated_ringI[of "{A}"]) (auto simp: disjoint_def)

lemma (in semiring_of_sets) generated_ring_disjoint_Un[intro]:
  assumes a: "a \<in> generated_ring" and b: "b \<in> generated_ring"
  and "a \<inter> b = {}"
  shows "a \<union> b \<in> generated_ring"
proof -
  from a guess Ca .. note Ca = this
  from b guess Cb .. note Cb = this
  show ?thesis
  proof
    show "disjoint (Ca \<union> Cb)"
      using `a \<inter> b = {}` Ca Cb by (auto intro!: disjoint_union)
  qed (insert Ca Cb, auto)
qed

lemma (in semiring_of_sets) generated_ring_empty: "{} \<in> generated_ring"
  by (auto simp: generated_ring_def disjoint_def)

lemma (in semiring_of_sets) generated_ring_disjoint_Union:
  assumes "finite A" shows "A \<subseteq> generated_ring \<Longrightarrow> disjoint A \<Longrightarrow> \<Union>A \<in> generated_ring"
  using assms by (induct A) (auto simp: disjoint_def intro!: generated_ring_disjoint_Un generated_ring_empty)

lemma (in semiring_of_sets) generated_ring_disjoint_UNION:
  "finite I \<Longrightarrow> disjoint (A ` I) \<Longrightarrow> (\<And>i. i \<in> I \<Longrightarrow> A i \<in> generated_ring) \<Longrightarrow> UNION I A \<in> generated_ring"
  unfolding SUP_def by (intro generated_ring_disjoint_Union) auto

lemma (in semiring_of_sets) generated_ring_Int:
  assumes a: "a \<in> generated_ring" and b: "b \<in> generated_ring"
  shows "a \<inter> b \<in> generated_ring"
proof -
  from a guess Ca .. note Ca = this
  from b guess Cb .. note Cb = this
  def C \<equiv> "(\<lambda>(a,b). a \<inter> b)` (Ca\<times>Cb)"
  show ?thesis
  proof
    show "disjoint C"
    proof (simp add: disjoint_def C_def, intro ballI impI)
      fix a1 b1 a2 b2 assume sets: "a1 \<in> Ca" "b1 \<in> Cb" "a2 \<in> Ca" "b2 \<in> Cb"
      assume "a1 \<inter> b1 \<noteq> a2 \<inter> b2"
      then have "a1 \<noteq> a2 \<or> b1 \<noteq> b2" by auto
      then show "(a1 \<inter> b1) \<inter> (a2 \<inter> b2) = {}"
      proof
        assume "a1 \<noteq> a2"
        with sets Ca have "a1 \<inter> a2 = {}"
          by (auto simp: disjoint_def)
        then show ?thesis by auto
      next
        assume "b1 \<noteq> b2"
        with sets Cb have "b1 \<inter> b2 = {}"
          by (auto simp: disjoint_def)
        then show ?thesis by auto
      qed
    qed
  qed (insert Ca Cb, auto simp: C_def)
qed

lemma (in semiring_of_sets) generated_ring_Inter:
  assumes "finite A" "A \<noteq> {}" shows "A \<subseteq> generated_ring \<Longrightarrow> \<Inter>A \<in> generated_ring"
  using assms by (induct A rule: finite_ne_induct) (auto intro: generated_ring_Int)

lemma (in semiring_of_sets) generated_ring_INTER:
  "finite I \<Longrightarrow> I \<noteq> {} \<Longrightarrow> (\<And>i. i \<in> I \<Longrightarrow> A i \<in> generated_ring) \<Longrightarrow> INTER I A \<in> generated_ring"
  unfolding INF_def by (intro generated_ring_Inter) auto

lemma (in semiring_of_sets) generating_ring:
  "ring_of_sets \<Omega> generated_ring"
proof (rule ring_of_setsI)
  let ?R = generated_ring
  show "?R \<subseteq> Pow \<Omega>"
    using sets_into_space by (auto simp: generated_ring_def generated_ring_empty)
  show "{} \<in> ?R" by (rule generated_ring_empty)

  { fix a assume a: "a \<in> ?R" then guess Ca .. note Ca = this
    fix b assume b: "b \<in> ?R" then guess Cb .. note Cb = this
  
    show "a - b \<in> ?R"
    proof cases
      assume "Cb = {}" with Cb `a \<in> ?R` show ?thesis
        by simp
    next
      assume "Cb \<noteq> {}"
      with Ca Cb have "a - b = (\<Union>a'\<in>Ca. \<Inter>b'\<in>Cb. a' - b')" by auto
      also have "\<dots> \<in> ?R"
      proof (intro generated_ring_INTER generated_ring_disjoint_UNION)
        fix a b assume "a \<in> Ca" "b \<in> Cb"
        with Ca Cb Diff_cover[of a b] show "a - b \<in> ?R"
          by (auto simp add: generated_ring_def)
      next
        show "disjoint ((\<lambda>a'. \<Inter>b'\<in>Cb. a' - b')`Ca)"
          using Ca by (auto simp add: disjoint_def `Cb \<noteq> {}`)
      next
        show "finite Ca" "finite Cb" "Cb \<noteq> {}" by fact+
      qed
      finally show "a - b \<in> ?R" .
    qed }
  note Diff = this

  fix a b assume sets: "a \<in> ?R" "b \<in> ?R"
  have "a \<union> b = (a - b) \<union> (a \<inter> b) \<union> (b - a)" by auto
  also have "\<dots> \<in> ?R"
    by (intro sets generated_ring_disjoint_Un generated_ring_Int Diff) auto
  finally show "a \<union> b \<in> ?R" .
qed

lemma (in semiring_of_sets) sigma_sets_generated_ring_eq: "sigma_sets \<Omega> generated_ring = sigma_sets \<Omega> M"
proof
  interpret M: sigma_algebra \<Omega> "sigma_sets \<Omega> M"
    using space_closed by (rule sigma_algebra_sigma_sets)
  show "sigma_sets \<Omega> generated_ring \<subseteq> sigma_sets \<Omega> M"
    by (blast intro!: sigma_sets_mono elim: generated_ringE)
qed (auto intro!: generated_ringI_Basic sigma_sets_mono)

subsubsection {* A Two-Element Series *}

definition binaryset :: "'a set \<Rightarrow> 'a set \<Rightarrow> nat \<Rightarrow> 'a set "
  where "binaryset A B = (\<lambda>x. {})(0 := A, Suc 0 := B)"

lemma range_binaryset_eq: "range(binaryset A B) = {A,B,{}}"
  apply (simp add: binaryset_def)
  apply (rule set_eqI)
  apply (auto simp add: image_iff)
  done

lemma UN_binaryset_eq: "(\<Union>i. binaryset A B i) = A \<union> B"
  by (simp add: SUP_def range_binaryset_eq)

subsubsection {* Closed CDI *}

definition closed_cdi where
  "closed_cdi \<Omega> M \<longleftrightarrow>
   M \<subseteq> Pow \<Omega> &
   (\<forall>s \<in> M. \<Omega> - s \<in> M) &
   (\<forall>A. (range A \<subseteq> M) & (A 0 = {}) & (\<forall>n. A n \<subseteq> A (Suc n)) \<longrightarrow>
        (\<Union>i. A i) \<in> M) &
   (\<forall>A. (range A \<subseteq> M) & disjoint_family A \<longrightarrow> (\<Union>i::nat. A i) \<in> M)"

inductive_set
  smallest_ccdi_sets :: "'a set \<Rightarrow> 'a set set \<Rightarrow> 'a set set"
  for \<Omega> M
  where
    Basic [intro]:
      "a \<in> M \<Longrightarrow> a \<in> smallest_ccdi_sets \<Omega> M"
  | Compl [intro]:
      "a \<in> smallest_ccdi_sets \<Omega> M \<Longrightarrow> \<Omega> - a \<in> smallest_ccdi_sets \<Omega> M"
  | Inc:
      "range A \<in> Pow(smallest_ccdi_sets \<Omega> M) \<Longrightarrow> A 0 = {} \<Longrightarrow> (\<And>n. A n \<subseteq> A (Suc n))
       \<Longrightarrow> (\<Union>i. A i) \<in> smallest_ccdi_sets \<Omega> M"
  | Disj:
      "range A \<in> Pow(smallest_ccdi_sets \<Omega> M) \<Longrightarrow> disjoint_family A
       \<Longrightarrow> (\<Union>i::nat. A i) \<in> smallest_ccdi_sets \<Omega> M"

lemma (in subset_class) smallest_closed_cdi1: "M \<subseteq> smallest_ccdi_sets \<Omega> M"
  by auto

lemma (in subset_class) smallest_ccdi_sets: "smallest_ccdi_sets \<Omega> M \<subseteq> Pow \<Omega>"
  apply (rule subsetI)
  apply (erule smallest_ccdi_sets.induct)
  apply (auto intro: range_subsetD dest: sets_into_space)
  done

lemma (in subset_class) smallest_closed_cdi2: "closed_cdi \<Omega> (smallest_ccdi_sets \<Omega> M)"
  apply (auto simp add: closed_cdi_def smallest_ccdi_sets)
  apply (blast intro: smallest_ccdi_sets.Inc smallest_ccdi_sets.Disj) +
  done

lemma closed_cdi_subset: "closed_cdi \<Omega> M \<Longrightarrow> M \<subseteq> Pow \<Omega>"
  by (simp add: closed_cdi_def)

lemma closed_cdi_Compl: "closed_cdi \<Omega> M \<Longrightarrow> s \<in> M \<Longrightarrow> \<Omega> - s \<in> M"
  by (simp add: closed_cdi_def)

lemma closed_cdi_Inc:
  "closed_cdi \<Omega> M \<Longrightarrow> range A \<subseteq> M \<Longrightarrow> A 0 = {} \<Longrightarrow> (!!n. A n \<subseteq> A (Suc n)) \<Longrightarrow> (\<Union>i. A i) \<in> M"
  by (simp add: closed_cdi_def)

lemma closed_cdi_Disj:
  "closed_cdi \<Omega> M \<Longrightarrow> range A \<subseteq> M \<Longrightarrow> disjoint_family A \<Longrightarrow> (\<Union>i::nat. A i) \<in> M"
  by (simp add: closed_cdi_def)

lemma closed_cdi_Un:
  assumes cdi: "closed_cdi \<Omega> M" and empty: "{} \<in> M"
      and A: "A \<in> M" and B: "B \<in> M"
      and disj: "A \<inter> B = {}"
    shows "A \<union> B \<in> M"
proof -
  have ra: "range (binaryset A B) \<subseteq> M"
   by (simp add: range_binaryset_eq empty A B)
 have di:  "disjoint_family (binaryset A B)" using disj
   by (simp add: disjoint_family_on_def binaryset_def Int_commute)
 from closed_cdi_Disj [OF cdi ra di]
 show ?thesis
   by (simp add: UN_binaryset_eq)
qed

lemma (in algebra) smallest_ccdi_sets_Un:
  assumes A: "A \<in> smallest_ccdi_sets \<Omega> M" and B: "B \<in> smallest_ccdi_sets \<Omega> M"
      and disj: "A \<inter> B = {}"
    shows "A \<union> B \<in> smallest_ccdi_sets \<Omega> M"
proof -
  have ra: "range (binaryset A B) \<in> Pow (smallest_ccdi_sets \<Omega> M)"
    by (simp add: range_binaryset_eq  A B smallest_ccdi_sets.Basic)
  have di:  "disjoint_family (binaryset A B)" using disj
    by (simp add: disjoint_family_on_def binaryset_def Int_commute)
  from Disj [OF ra di]
  show ?thesis
    by (simp add: UN_binaryset_eq)
qed

lemma (in algebra) smallest_ccdi_sets_Int1:
  assumes a: "a \<in> M"
  shows "b \<in> smallest_ccdi_sets \<Omega> M \<Longrightarrow> a \<inter> b \<in> smallest_ccdi_sets \<Omega> M"
proof (induct rule: smallest_ccdi_sets.induct)
  case (Basic x)
  thus ?case
    by (metis a Int smallest_ccdi_sets.Basic)
next
  case (Compl x)
  have "a \<inter> (\<Omega> - x) = \<Omega> - ((\<Omega> - a) \<union> (a \<inter> x))"
    by blast
  also have "... \<in> smallest_ccdi_sets \<Omega> M"
    by (metis smallest_ccdi_sets.Compl a Compl(2) Diff_Int2 Diff_Int_distrib2
           Diff_disjoint Int_Diff Int_empty_right smallest_ccdi_sets_Un
           smallest_ccdi_sets.Basic smallest_ccdi_sets.Compl)
  finally show ?case .
next
  case (Inc A)
  have 1: "(\<Union>i. (\<lambda>i. a \<inter> A i) i) = a \<inter> (\<Union>i. A i)"
    by blast
  have "range (\<lambda>i. a \<inter> A i) \<in> Pow(smallest_ccdi_sets \<Omega> M)" using Inc
    by blast
  moreover have "(\<lambda>i. a \<inter> A i) 0 = {}"
    by (simp add: Inc)
  moreover have "!!n. (\<lambda>i. a \<inter> A i) n \<subseteq> (\<lambda>i. a \<inter> A i) (Suc n)" using Inc
    by blast
  ultimately have 2: "(\<Union>i. (\<lambda>i. a \<inter> A i) i) \<in> smallest_ccdi_sets \<Omega> M"
    by (rule smallest_ccdi_sets.Inc)
  show ?case
    by (metis 1 2)
next
  case (Disj A)
  have 1: "(\<Union>i. (\<lambda>i. a \<inter> A i) i) = a \<inter> (\<Union>i. A i)"
    by blast
  have "range (\<lambda>i. a \<inter> A i) \<in> Pow(smallest_ccdi_sets \<Omega> M)" using Disj
    by blast
  moreover have "disjoint_family (\<lambda>i. a \<inter> A i)" using Disj
    by (auto simp add: disjoint_family_on_def)
  ultimately have 2: "(\<Union>i. (\<lambda>i. a \<inter> A i) i) \<in> smallest_ccdi_sets \<Omega> M"
    by (rule smallest_ccdi_sets.Disj)
  show ?case
    by (metis 1 2)
qed


lemma (in algebra) smallest_ccdi_sets_Int:
  assumes b: "b \<in> smallest_ccdi_sets \<Omega> M"
  shows "a \<in> smallest_ccdi_sets \<Omega> M \<Longrightarrow> a \<inter> b \<in> smallest_ccdi_sets \<Omega> M"
proof (induct rule: smallest_ccdi_sets.induct)
  case (Basic x)
  thus ?case
    by (metis b smallest_ccdi_sets_Int1)
next
  case (Compl x)
  have "(\<Omega> - x) \<inter> b = \<Omega> - (x \<inter> b \<union> (\<Omega> - b))"
    by blast
  also have "... \<in> smallest_ccdi_sets \<Omega> M"
    by (metis Compl(2) Diff_disjoint Int_Diff Int_commute Int_empty_right b
           smallest_ccdi_sets.Compl smallest_ccdi_sets_Un)
  finally show ?case .
next
  case (Inc A)
  have 1: "(\<Union>i. (\<lambda>i. A i \<inter> b) i) = (\<Union>i. A i) \<inter> b"
    by blast
  have "range (\<lambda>i. A i \<inter> b) \<in> Pow(smallest_ccdi_sets \<Omega> M)" using Inc
    by blast
  moreover have "(\<lambda>i. A i \<inter> b) 0 = {}"
    by (simp add: Inc)
  moreover have "!!n. (\<lambda>i. A i \<inter> b) n \<subseteq> (\<lambda>i. A i \<inter> b) (Suc n)" using Inc
    by blast
  ultimately have 2: "(\<Union>i. (\<lambda>i. A i \<inter> b) i) \<in> smallest_ccdi_sets \<Omega> M"
    by (rule smallest_ccdi_sets.Inc)
  show ?case
    by (metis 1 2)
next
  case (Disj A)
  have 1: "(\<Union>i. (\<lambda>i. A i \<inter> b) i) = (\<Union>i. A i) \<inter> b"
    by blast
  have "range (\<lambda>i. A i \<inter> b) \<in> Pow(smallest_ccdi_sets \<Omega> M)" using Disj
    by blast
  moreover have "disjoint_family (\<lambda>i. A i \<inter> b)" using Disj
    by (auto simp add: disjoint_family_on_def)
  ultimately have 2: "(\<Union>i. (\<lambda>i. A i \<inter> b) i) \<in> smallest_ccdi_sets \<Omega> M"
    by (rule smallest_ccdi_sets.Disj)
  show ?case
    by (metis 1 2)
qed

lemma (in algebra) sigma_property_disjoint_lemma:
  assumes sbC: "M \<subseteq> C"
      and ccdi: "closed_cdi \<Omega> C"
  shows "sigma_sets \<Omega> M \<subseteq> C"
proof -
  have "smallest_ccdi_sets \<Omega> M \<in> {B . M \<subseteq> B \<and> sigma_algebra \<Omega> B}"
    apply (auto simp add: sigma_algebra_disjoint_iff algebra_iff_Int
            smallest_ccdi_sets_Int)
    apply (metis Union_Pow_eq Union_upper subsetD smallest_ccdi_sets)
    apply (blast intro: smallest_ccdi_sets.Disj)
    done
  hence "sigma_sets (\<Omega>) (M) \<subseteq> smallest_ccdi_sets \<Omega> M"
    by clarsimp
       (drule sigma_algebra.sigma_sets_subset [where a="M"], auto)
  also have "...  \<subseteq> C"
    proof
      fix x
      assume x: "x \<in> smallest_ccdi_sets \<Omega> M"
      thus "x \<in> C"
        proof (induct rule: smallest_ccdi_sets.induct)
          case (Basic x)
          thus ?case
            by (metis Basic subsetD sbC)
        next
          case (Compl x)
          thus ?case
            by (blast intro: closed_cdi_Compl [OF ccdi, simplified])
        next
          case (Inc A)
          thus ?case
               by (auto intro: closed_cdi_Inc [OF ccdi, simplified])
        next
          case (Disj A)
          thus ?case
               by (auto intro: closed_cdi_Disj [OF ccdi, simplified])
        qed
    qed
  finally show ?thesis .
qed

lemma (in algebra) sigma_property_disjoint:
  assumes sbC: "M \<subseteq> C"
      and compl: "!!s. s \<in> C \<inter> sigma_sets (\<Omega>) (M) \<Longrightarrow> \<Omega> - s \<in> C"
      and inc: "!!A. range A \<subseteq> C \<inter> sigma_sets (\<Omega>) (M)
                     \<Longrightarrow> A 0 = {} \<Longrightarrow> (!!n. A n \<subseteq> A (Suc n))
                     \<Longrightarrow> (\<Union>i. A i) \<in> C"
      and disj: "!!A. range A \<subseteq> C \<inter> sigma_sets (\<Omega>) (M)
                      \<Longrightarrow> disjoint_family A \<Longrightarrow> (\<Union>i::nat. A i) \<in> C"
  shows "sigma_sets (\<Omega>) (M) \<subseteq> C"
proof -
  have "sigma_sets (\<Omega>) (M) \<subseteq> C \<inter> sigma_sets (\<Omega>) (M)"
    proof (rule sigma_property_disjoint_lemma)
      show "M \<subseteq> C \<inter> sigma_sets (\<Omega>) (M)"
        by (metis Int_greatest Set.subsetI sbC sigma_sets.Basic)
    next
      show "closed_cdi \<Omega> (C \<inter> sigma_sets (\<Omega>) (M))"
        by (simp add: closed_cdi_def compl inc disj)
           (metis PowI Set.subsetI le_infI2 sigma_sets_into_sp space_closed
             IntE sigma_sets.Compl range_subsetD sigma_sets.Union)
    qed
  thus ?thesis
    by blast
qed

subsubsection {* Dynkin systems *}

locale dynkin_system = subset_class +
  assumes space: "\<Omega> \<in> M"
    and   compl[intro!]: "\<And>A. A \<in> M \<Longrightarrow> \<Omega> - A \<in> M"
    and   UN[intro!]: "\<And>A. disjoint_family A \<Longrightarrow> range A \<subseteq> M
                           \<Longrightarrow> (\<Union>i::nat. A i) \<in> M"

lemma (in dynkin_system) empty[intro, simp]: "{} \<in> M"
  using space compl[of "\<Omega>"] by simp

lemma (in dynkin_system) diff:
  assumes sets: "D \<in> M" "E \<in> M" and "D \<subseteq> E"
  shows "E - D \<in> M"
proof -
  let ?f = "\<lambda>x. if x = 0 then D else if x = Suc 0 then \<Omega> - E else {}"
  have "range ?f = {D, \<Omega> - E, {}}"
    by (auto simp: image_iff)
  moreover have "D \<union> (\<Omega> - E) = (\<Union>i. ?f i)"
    by (auto simp: image_iff split: split_if_asm)
  moreover
  have "disjoint_family ?f" unfolding disjoint_family_on_def
    using `D \<in> M`[THEN sets_into_space] `D \<subseteq> E` by auto
  ultimately have "\<Omega> - (D \<union> (\<Omega> - E)) \<in> M"
    using sets by auto
  also have "\<Omega> - (D \<union> (\<Omega> - E)) = E - D"
    using assms sets_into_space by auto
  finally show ?thesis .
qed

lemma dynkin_systemI:
  assumes "\<And> A. A \<in> M \<Longrightarrow> A \<subseteq> \<Omega>" "\<Omega> \<in> M"
  assumes "\<And> A. A \<in> M \<Longrightarrow> \<Omega> - A \<in> M"
  assumes "\<And> A. disjoint_family A \<Longrightarrow> range A \<subseteq> M
          \<Longrightarrow> (\<Union>i::nat. A i) \<in> M"
  shows "dynkin_system \<Omega> M"
  using assms by (auto simp: dynkin_system_def dynkin_system_axioms_def subset_class_def)

lemma dynkin_systemI':
  assumes 1: "\<And> A. A \<in> M \<Longrightarrow> A \<subseteq> \<Omega>"
  assumes empty: "{} \<in> M"
  assumes Diff: "\<And> A. A \<in> M \<Longrightarrow> \<Omega> - A \<in> M"
  assumes 2: "\<And> A. disjoint_family A \<Longrightarrow> range A \<subseteq> M
          \<Longrightarrow> (\<Union>i::nat. A i) \<in> M"
  shows "dynkin_system \<Omega> M"
proof -
  from Diff[OF empty] have "\<Omega> \<in> M" by auto
  from 1 this Diff 2 show ?thesis
    by (intro dynkin_systemI) auto
qed

lemma dynkin_system_trivial:
  shows "dynkin_system A (Pow A)"
  by (rule dynkin_systemI) auto

lemma sigma_algebra_imp_dynkin_system:
  assumes "sigma_algebra \<Omega> M" shows "dynkin_system \<Omega> M"
proof -
  interpret sigma_algebra \<Omega> M by fact
  show ?thesis using sets_into_space by (fastforce intro!: dynkin_systemI)
qed

subsubsection "Intersection sets systems"

definition "Int_stable M \<longleftrightarrow> (\<forall> a \<in> M. \<forall> b \<in> M. a \<inter> b \<in> M)"

lemma (in algebra) Int_stable: "Int_stable M"
  unfolding Int_stable_def by auto

lemma Int_stableI:
  "(\<And>a b. a \<in> A \<Longrightarrow> b \<in> A \<Longrightarrow> a \<inter> b \<in> A) \<Longrightarrow> Int_stable A"
  unfolding Int_stable_def by auto

lemma Int_stableD:
  "Int_stable M \<Longrightarrow> a \<in> M \<Longrightarrow> b \<in> M \<Longrightarrow> a \<inter> b \<in> M"
  unfolding Int_stable_def by auto

lemma (in dynkin_system) sigma_algebra_eq_Int_stable:
  "sigma_algebra \<Omega> M \<longleftrightarrow> Int_stable M"
proof
  assume "sigma_algebra \<Omega> M" then show "Int_stable M"
    unfolding sigma_algebra_def using algebra.Int_stable by auto
next
  assume "Int_stable M"
  show "sigma_algebra \<Omega> M"
    unfolding sigma_algebra_disjoint_iff algebra_iff_Un
  proof (intro conjI ballI allI impI)
    show "M \<subseteq> Pow (\<Omega>)" using sets_into_space by auto
  next
    fix A B assume "A \<in> M" "B \<in> M"
    then have "A \<union> B = \<Omega> - ((\<Omega> - A) \<inter> (\<Omega> - B))"
              "\<Omega> - A \<in> M" "\<Omega> - B \<in> M"
      using sets_into_space by auto
    then show "A \<union> B \<in> M"
      using `Int_stable M` unfolding Int_stable_def by auto
  qed auto
qed

subsubsection "Smallest Dynkin systems"

definition dynkin where
  "dynkin \<Omega> M =  (\<Inter>{D. dynkin_system \<Omega> D \<and> M \<subseteq> D})"

lemma dynkin_system_dynkin:
  assumes "M \<subseteq> Pow (\<Omega>)"
  shows "dynkin_system \<Omega> (dynkin \<Omega> M)"
proof (rule dynkin_systemI)
  fix A assume "A \<in> dynkin \<Omega> M"
  moreover
  { fix D assume "A \<in> D" and d: "dynkin_system \<Omega> D"
    then have "A \<subseteq> \<Omega>" by (auto simp: dynkin_system_def subset_class_def) }
  moreover have "{D. dynkin_system \<Omega> D \<and> M \<subseteq> D} \<noteq> {}"
    using assms dynkin_system_trivial by fastforce
  ultimately show "A \<subseteq> \<Omega>"
    unfolding dynkin_def using assms
    by auto
next
  show "\<Omega> \<in> dynkin \<Omega> M"
    unfolding dynkin_def using dynkin_system.space by fastforce
next
  fix A assume "A \<in> dynkin \<Omega> M"
  then show "\<Omega> - A \<in> dynkin \<Omega> M"
    unfolding dynkin_def using dynkin_system.compl by force
next
  fix A :: "nat \<Rightarrow> 'a set"
  assume A: "disjoint_family A" "range A \<subseteq> dynkin \<Omega> M"
  show "(\<Union>i. A i) \<in> dynkin \<Omega> M" unfolding dynkin_def
  proof (simp, safe)
    fix D assume "dynkin_system \<Omega> D" "M \<subseteq> D"
    with A have "(\<Union>i. A i) \<in> D"
      by (intro dynkin_system.UN) (auto simp: dynkin_def)
    then show "(\<Union>i. A i) \<in> D" by auto
  qed
qed

lemma dynkin_Basic[intro]: "A \<in> M \<Longrightarrow> A \<in> dynkin \<Omega> M"
  unfolding dynkin_def by auto

lemma (in dynkin_system) restricted_dynkin_system:
  assumes "D \<in> M"
  shows "dynkin_system \<Omega> {Q. Q \<subseteq> \<Omega> \<and> Q \<inter> D \<in> M}"
proof (rule dynkin_systemI, simp_all)
  have "\<Omega> \<inter> D = D"
    using `D \<in> M` sets_into_space by auto
  then show "\<Omega> \<inter> D \<in> M"
    using `D \<in> M` by auto
next
  fix A assume "A \<subseteq> \<Omega> \<and> A \<inter> D \<in> M"
  moreover have "(\<Omega> - A) \<inter> D = (\<Omega> - (A \<inter> D)) - (\<Omega> - D)"
    by auto
  ultimately show "\<Omega> - A \<subseteq> \<Omega> \<and> (\<Omega> - A) \<inter> D \<in> M"
    using  `D \<in> M` by (auto intro: diff)
next
  fix A :: "nat \<Rightarrow> 'a set"
  assume "disjoint_family A" "range A \<subseteq> {Q. Q \<subseteq> \<Omega> \<and> Q \<inter> D \<in> M}"
  then have "\<And>i. A i \<subseteq> \<Omega>" "disjoint_family (\<lambda>i. A i \<inter> D)"
    "range (\<lambda>i. A i \<inter> D) \<subseteq> M" "(\<Union>x. A x) \<inter> D = (\<Union>x. A x \<inter> D)"
    by ((fastforce simp: disjoint_family_on_def)+)
  then show "(\<Union>x. A x) \<subseteq> \<Omega> \<and> (\<Union>x. A x) \<inter> D \<in> M"
    by (auto simp del: UN_simps)
qed

lemma (in dynkin_system) dynkin_subset:
  assumes "N \<subseteq> M"
  shows "dynkin \<Omega> N \<subseteq> M"
proof -
  have "dynkin_system \<Omega> M" by default
  then have "dynkin_system \<Omega> M"
    using assms unfolding dynkin_system_def dynkin_system_axioms_def subset_class_def by simp
  with `N \<subseteq> M` show ?thesis by (auto simp add: dynkin_def)
qed

lemma sigma_eq_dynkin:
  assumes sets: "M \<subseteq> Pow \<Omega>"
  assumes "Int_stable M"
  shows "sigma_sets \<Omega> M = dynkin \<Omega> M"
proof -
  have "dynkin \<Omega> M \<subseteq> sigma_sets (\<Omega>) (M)"
    using sigma_algebra_imp_dynkin_system
    unfolding dynkin_def sigma_sets_least_sigma_algebra[OF sets] by auto
  moreover
  interpret dynkin_system \<Omega> "dynkin \<Omega> M"
    using dynkin_system_dynkin[OF sets] .
  have "sigma_algebra \<Omega> (dynkin \<Omega> M)"
    unfolding sigma_algebra_eq_Int_stable Int_stable_def
  proof (intro ballI)
    fix A B assume "A \<in> dynkin \<Omega> M" "B \<in> dynkin \<Omega> M"
    let ?D = "\<lambda>E. {Q. Q \<subseteq> \<Omega> \<and> Q \<inter> E \<in> dynkin \<Omega> M}"
    have "M \<subseteq> ?D B"
    proof
      fix E assume "E \<in> M"
      then have "M \<subseteq> ?D E" "E \<in> dynkin \<Omega> M"
        using sets_into_space `Int_stable M` by (auto simp: Int_stable_def)
      then have "dynkin \<Omega> M \<subseteq> ?D E"
        using restricted_dynkin_system `E \<in> dynkin \<Omega> M`
        by (intro dynkin_system.dynkin_subset) simp_all
      then have "B \<in> ?D E"
        using `B \<in> dynkin \<Omega> M` by auto
      then have "E \<inter> B \<in> dynkin \<Omega> M"
        by (subst Int_commute) simp
      then show "E \<in> ?D B"
        using sets `E \<in> M` by auto
    qed
    then have "dynkin \<Omega> M \<subseteq> ?D B"
      using restricted_dynkin_system `B \<in> dynkin \<Omega> M`
      by (intro dynkin_system.dynkin_subset) simp_all
    then show "A \<inter> B \<in> dynkin \<Omega> M"
      using `A \<in> dynkin \<Omega> M` sets_into_space by auto
  qed
  from sigma_algebra.sigma_sets_subset[OF this, of "M"]
  have "sigma_sets (\<Omega>) (M) \<subseteq> dynkin \<Omega> M" by auto
  ultimately have "sigma_sets (\<Omega>) (M) = dynkin \<Omega> M" by auto
  then show ?thesis
    by (auto simp: dynkin_def)
qed

lemma (in dynkin_system) dynkin_idem:
  "dynkin \<Omega> M = M"
proof -
  have "dynkin \<Omega> M = M"
  proof
    show "M \<subseteq> dynkin \<Omega> M"
      using dynkin_Basic by auto
    show "dynkin \<Omega> M \<subseteq> M"
      by (intro dynkin_subset) auto
  qed
  then show ?thesis
    by (auto simp: dynkin_def)
qed

lemma (in dynkin_system) dynkin_lemma:
  assumes "Int_stable E"
  and E: "E \<subseteq> M" "M \<subseteq> sigma_sets \<Omega> E"
  shows "sigma_sets \<Omega> E = M"
proof -
  have "E \<subseteq> Pow \<Omega>"
    using E sets_into_space by force
  then have *: "sigma_sets \<Omega> E = dynkin \<Omega> E"
    using `Int_stable E` by (rule sigma_eq_dynkin)
  then have "dynkin \<Omega> E = M"
    using assms dynkin_subset[OF E(1)] by simp
  with * show ?thesis
    using assms by (auto simp: dynkin_def)
qed

subsubsection {* Induction rule for intersection-stable generators *}

text {* The reason to introduce Dynkin-systems is the following induction rules for $\sigma$-algebras
generated by a generator closed under intersection. *}

lemma sigma_sets_induct_disjoint[consumes 3, case_names basic empty compl union]:
  assumes "Int_stable G"
    and closed: "G \<subseteq> Pow \<Omega>"
    and A: "A \<in> sigma_sets \<Omega> G"
  assumes basic: "\<And>A. A \<in> G \<Longrightarrow> P A"
    and empty: "P {}"
    and compl: "\<And>A. A \<in> sigma_sets \<Omega> G \<Longrightarrow> P A \<Longrightarrow> P (\<Omega> - A)"
    and union: "\<And>A. disjoint_family A \<Longrightarrow> range A \<subseteq> sigma_sets \<Omega> G \<Longrightarrow> (\<And>i. P (A i)) \<Longrightarrow> P (\<Union>i::nat. A i)"
  shows "P A"
proof -
  let ?D = "{ A \<in> sigma_sets \<Omega> G. P A }"
  interpret sigma_algebra \<Omega> "sigma_sets \<Omega> G"
    using closed by (rule sigma_algebra_sigma_sets)
  from compl[OF _ empty] closed have space: "P \<Omega>" by simp
  interpret dynkin_system \<Omega> ?D
    by default (auto dest: sets_into_space intro!: space compl union)
  have "sigma_sets \<Omega> G = ?D"
    by (rule dynkin_lemma) (auto simp: basic `Int_stable G`)
  with A show ?thesis by auto
qed

subsection {* Measure type *}

definition positive :: "'a set set \<Rightarrow> ('a set \<Rightarrow> ereal) \<Rightarrow> bool" where
  "positive M \<mu> \<longleftrightarrow> \<mu> {} = 0 \<and> (\<forall>A\<in>M. 0 \<le> \<mu> A)"

definition countably_additive :: "'a set set \<Rightarrow> ('a set \<Rightarrow> ereal) \<Rightarrow> bool" where
  "countably_additive M f \<longleftrightarrow> (\<forall>A. range A \<subseteq> M \<longrightarrow> disjoint_family A \<longrightarrow> (\<Union>i. A i) \<in> M \<longrightarrow>
    (\<Sum>i. f (A i)) = f (\<Union>i. A i))"

definition measure_space :: "'a set \<Rightarrow> 'a set set \<Rightarrow> ('a set \<Rightarrow> ereal) \<Rightarrow> bool" where
  "measure_space \<Omega> A \<mu> \<longleftrightarrow> sigma_algebra \<Omega> A \<and> positive A \<mu> \<and> countably_additive A \<mu>"

typedef 'a measure = "{(\<Omega>::'a set, A, \<mu>). (\<forall>a\<in>-A. \<mu> a = 0) \<and> measure_space \<Omega> A \<mu> }"
proof
  have "sigma_algebra UNIV {{}, UNIV}"
    by (auto simp: sigma_algebra_iff2)
  then show "(UNIV, {{}, UNIV}, \<lambda>A. 0) \<in> {(\<Omega>, A, \<mu>). (\<forall>a\<in>-A. \<mu> a = 0) \<and> measure_space \<Omega> A \<mu>} "
    by (auto simp: measure_space_def positive_def countably_additive_def)
qed

definition space :: "'a measure \<Rightarrow> 'a set" where
  "space M = fst (Rep_measure M)"

definition sets :: "'a measure \<Rightarrow> 'a set set" where
  "sets M = fst (snd (Rep_measure M))"

definition emeasure :: "'a measure \<Rightarrow> 'a set \<Rightarrow> ereal" where
  "emeasure M = snd (snd (Rep_measure M))"

definition measure :: "'a measure \<Rightarrow> 'a set \<Rightarrow> real" where
  "measure M A = real (emeasure M A)"

declare [[coercion sets]]

declare [[coercion measure]]

declare [[coercion emeasure]]

lemma measure_space: "measure_space (space M) (sets M) (emeasure M)"
  by (cases M) (auto simp: space_def sets_def emeasure_def Abs_measure_inverse)

interpretation sets!: sigma_algebra "space M" "sets M" for M :: "'a measure"
  using measure_space[of M] by (auto simp: measure_space_def)

definition measure_of :: "'a set \<Rightarrow> 'a set set \<Rightarrow> ('a set \<Rightarrow> ereal) \<Rightarrow> 'a measure" where
  "measure_of \<Omega> A \<mu> = Abs_measure (\<Omega>, if A \<subseteq> Pow \<Omega> then sigma_sets \<Omega> A else {{}, \<Omega>},
    \<lambda>a. if a \<in> sigma_sets \<Omega> A \<and> measure_space \<Omega> (sigma_sets \<Omega> A) \<mu> then \<mu> a else 0)"

abbreviation "sigma \<Omega> A \<equiv> measure_of \<Omega> A (\<lambda>x. 0)"

lemma measure_space_0: "A \<subseteq> Pow \<Omega> \<Longrightarrow> measure_space \<Omega> (sigma_sets \<Omega> A) (\<lambda>x. 0)"
  unfolding measure_space_def
  by (auto intro!: sigma_algebra_sigma_sets simp: positive_def countably_additive_def)

lemma sigma_algebra_trivial: "sigma_algebra \<Omega> {{}, \<Omega>}"
by unfold_locales(fastforce intro: exI[where x="{{}}"] exI[where x="{\<Omega>}"])+

lemma measure_space_0': "measure_space \<Omega> {{}, \<Omega>} (\<lambda>x. 0)"
by(simp add: measure_space_def positive_def countably_additive_def sigma_algebra_trivial)

lemma measure_space_closed:
  assumes "measure_space \<Omega> M \<mu>"
  shows "M \<subseteq> Pow \<Omega>"
proof -
  interpret sigma_algebra \<Omega> M using assms by(simp add: measure_space_def)
  show ?thesis by(rule space_closed)
qed

lemma (in ring_of_sets) positive_cong_eq:
  "(\<And>a. a \<in> M \<Longrightarrow> \<mu>' a = \<mu> a) \<Longrightarrow> positive M \<mu>' = positive M \<mu>"
  by (auto simp add: positive_def)

lemma (in sigma_algebra) countably_additive_eq:
  "(\<And>a. a \<in> M \<Longrightarrow> \<mu>' a = \<mu> a) \<Longrightarrow> countably_additive M \<mu>' = countably_additive M \<mu>"
  unfolding countably_additive_def
  by (intro arg_cong[where f=All] ext) (auto simp add: countably_additive_def subset_eq)

lemma measure_space_eq:
  assumes closed: "A \<subseteq> Pow \<Omega>" and eq: "\<And>a. a \<in> sigma_sets \<Omega> A \<Longrightarrow> \<mu> a = \<mu>' a"
  shows "measure_space \<Omega> (sigma_sets \<Omega> A) \<mu> = measure_space \<Omega> (sigma_sets \<Omega> A) \<mu>'"
proof -
  interpret sigma_algebra \<Omega> "sigma_sets \<Omega> A" using closed by (rule sigma_algebra_sigma_sets)
  from positive_cong_eq[OF eq, of "\<lambda>i. i"] countably_additive_eq[OF eq, of "\<lambda>i. i"] show ?thesis
    by (auto simp: measure_space_def)
qed

lemma measure_of_eq:
  assumes closed: "A \<subseteq> Pow \<Omega>" and eq: "(\<And>a. a \<in> sigma_sets \<Omega> A \<Longrightarrow> \<mu> a = \<mu>' a)"
  shows "measure_of \<Omega> A \<mu> = measure_of \<Omega> A \<mu>'"
proof -
  have "measure_space \<Omega> (sigma_sets \<Omega> A) \<mu> = measure_space \<Omega> (sigma_sets \<Omega> A) \<mu>'"
    using assms by (rule measure_space_eq)
  with eq show ?thesis
    by (auto simp add: measure_of_def intro!: arg_cong[where f=Abs_measure])
qed

lemma
  shows space_measure_of_conv: "space (measure_of \<Omega> A \<mu>) = \<Omega>" (is ?space)
  and sets_measure_of_conv:
  "sets (measure_of \<Omega> A \<mu>) = (if A \<subseteq> Pow \<Omega> then sigma_sets \<Omega> A else {{}, \<Omega>})" (is ?sets)
  and emeasure_measure_of_conv: 
  "emeasure (measure_of \<Omega> A \<mu>) = 
  (\<lambda>B. if B \<in> sigma_sets \<Omega> A \<and> measure_space \<Omega> (sigma_sets \<Omega> A) \<mu> then \<mu> B else 0)" (is ?emeasure)
proof -
  have "?space \<and> ?sets \<and> ?emeasure"
  proof(cases "measure_space \<Omega> (sigma_sets \<Omega> A) \<mu>")
    case True
    from measure_space_closed[OF this] sigma_sets_superset_generator[of A \<Omega>]
    have "A \<subseteq> Pow \<Omega>" by simp
    hence "measure_space \<Omega> (sigma_sets \<Omega> A) \<mu> = measure_space \<Omega> (sigma_sets \<Omega> A)
      (\<lambda>a. if a \<in> sigma_sets \<Omega> A then \<mu> a else 0)"
      by(rule measure_space_eq) auto
    with True `A \<subseteq> Pow \<Omega>` show ?thesis
      by(simp add: measure_of_def space_def sets_def emeasure_def Abs_measure_inverse)
  next
    case False thus ?thesis
      by(cases "A \<subseteq> Pow \<Omega>")(simp_all add: Abs_measure_inverse measure_of_def sets_def space_def emeasure_def measure_space_0 measure_space_0')
  qed
  thus ?space ?sets ?emeasure by simp_all
qed

lemma [simp]:
  assumes A: "A \<subseteq> Pow \<Omega>"
  shows sets_measure_of: "sets (measure_of \<Omega> A \<mu>) = sigma_sets \<Omega> A"
    and space_measure_of: "space (measure_of \<Omega> A \<mu>) = \<Omega>"
using assms
by(simp_all add: sets_measure_of_conv space_measure_of_conv)

lemma (in sigma_algebra) sets_measure_of_eq[simp]: "sets (measure_of \<Omega> M \<mu>) = M"
  using space_closed by (auto intro!: sigma_sets_eq)

lemma (in sigma_algebra) space_measure_of_eq[simp]: "space (measure_of \<Omega> M \<mu>) = \<Omega>"
  by (rule space_measure_of_conv)

lemma measure_of_subset: "M \<subseteq> Pow \<Omega> \<Longrightarrow> M' \<subseteq> M \<Longrightarrow> sets (measure_of \<Omega> M' \<mu>) \<subseteq> sets (measure_of \<Omega> M \<mu>')"
  by (auto intro!: sigma_sets_subseteq)

lemma emeasure_sigma: "emeasure (sigma \<Omega> A) = (\<lambda>x. 0)"
  unfolding measure_of_def emeasure_def
  by (subst Abs_measure_inverse)
     (auto simp: measure_space_def positive_def countably_additive_def
           intro!: sigma_algebra_sigma_sets sigma_algebra_trivial)

lemma sigma_sets_mono'':
  assumes "A \<in> sigma_sets C D"
  assumes "B \<subseteq> D"
  assumes "D \<subseteq> Pow C"
  shows "sigma_sets A B \<subseteq> sigma_sets C D"
proof
  fix x assume "x \<in> sigma_sets A B"
  thus "x \<in> sigma_sets C D"
  proof induct
    case (Basic a) with assms have "a \<in> D" by auto
    thus ?case ..
  next
    case Empty show ?case by (rule sigma_sets.Empty)
  next
    from assms have "A \<in> sets (sigma C D)" by (subst sets_measure_of[OF `D \<subseteq> Pow C`])
    moreover case (Compl a) hence "a \<in> sets (sigma C D)" by (subst sets_measure_of[OF `D \<subseteq> Pow C`])
    ultimately have "A - a \<in> sets (sigma C D)" ..
    thus ?case by (subst (asm) sets_measure_of[OF `D \<subseteq> Pow C`])
  next
    case (Union a)
    thus ?case by (intro sigma_sets.Union)
  qed
qed

lemma in_measure_of[intro, simp]: "M \<subseteq> Pow \<Omega> \<Longrightarrow> A \<in> M \<Longrightarrow> A \<in> sets (measure_of \<Omega> M \<mu>)"
  by auto

lemma space_empty_iff: "space N = {} \<longleftrightarrow> sets N = {{}}"
  by (metis Pow_empty Sup_bot_conv(1) cSup_singleton empty_iff
            sets.sigma_sets_eq sets.space_closed sigma_sets_top subset_singletonD)

subsubsection {* Constructing simple @{typ "'a measure"} *}

lemma emeasure_measure_of:
  assumes M: "M = measure_of \<Omega> A \<mu>"
  assumes ms: "A \<subseteq> Pow \<Omega>" "positive (sets M) \<mu>" "countably_additive (sets M) \<mu>"
  assumes X: "X \<in> sets M"
  shows "emeasure M X = \<mu> X"
proof -
  interpret sigma_algebra \<Omega> "sigma_sets \<Omega> A" by (rule sigma_algebra_sigma_sets) fact
  have "measure_space \<Omega> (sigma_sets \<Omega> A) \<mu>"
    using ms M by (simp add: measure_space_def sigma_algebra_sigma_sets)
  thus ?thesis using X ms
    by(simp add: M emeasure_measure_of_conv sets_measure_of_conv)
qed

lemma emeasure_measure_of_sigma:
  assumes ms: "sigma_algebra \<Omega> M" "positive M \<mu>" "countably_additive M \<mu>"
  assumes A: "A \<in> M"
  shows "emeasure (measure_of \<Omega> M \<mu>) A = \<mu> A"
proof -
  interpret sigma_algebra \<Omega> M by fact
  have "measure_space \<Omega> (sigma_sets \<Omega> M) \<mu>"
    using ms sigma_sets_eq by (simp add: measure_space_def)
  thus ?thesis by(simp add: emeasure_measure_of_conv A)
qed

lemma measure_cases[cases type: measure]:
  obtains (measure) \<Omega> A \<mu> where "x = Abs_measure (\<Omega>, A, \<mu>)" "\<forall>a\<in>-A. \<mu> a = 0" "measure_space \<Omega> A \<mu>"
  by atomize_elim (cases x, auto)

lemma sets_eq_imp_space_eq:
  "sets M = sets M' \<Longrightarrow> space M = space M'"
  using sets.top[of M] sets.top[of M'] sets.space_closed[of M] sets.space_closed[of M']
  by blast

lemma emeasure_notin_sets: "A \<notin> sets M \<Longrightarrow> emeasure M A = 0"
  by (cases M) (auto simp: sets_def emeasure_def Abs_measure_inverse measure_space_def)

lemma emeasure_neq_0_sets: "emeasure M A \<noteq> 0 \<Longrightarrow> A \<in> sets M"
  using emeasure_notin_sets[of A M] by blast

lemma measure_notin_sets: "A \<notin> sets M \<Longrightarrow> measure M A = 0"
  by (simp add: measure_def emeasure_notin_sets)

lemma measure_eqI:
  fixes M N :: "'a measure"
  assumes "sets M = sets N" and eq: "\<And>A. A \<in> sets M \<Longrightarrow> emeasure M A = emeasure N A"
  shows "M = N"
proof (cases M N rule: measure_cases[case_product measure_cases])
  case (measure_measure \<Omega> A \<mu> \<Omega>' A' \<mu>')
  interpret M: sigma_algebra \<Omega> A using measure_measure by (auto simp: measure_space_def)
  interpret N: sigma_algebra \<Omega>' A' using measure_measure by (auto simp: measure_space_def)
  have "A = sets M" "A' = sets N"
    using measure_measure by (simp_all add: sets_def Abs_measure_inverse)
  with `sets M = sets N` have AA': "A = A'" by simp
  moreover from M.top N.top M.space_closed N.space_closed AA' have "\<Omega> = \<Omega>'" by auto
  moreover { fix B have "\<mu> B = \<mu>' B"
    proof cases
      assume "B \<in> A"
      with eq `A = sets M` have "emeasure M B = emeasure N B" by simp
      with measure_measure show "\<mu> B = \<mu>' B"
        by (simp add: emeasure_def Abs_measure_inverse)
    next
      assume "B \<notin> A"
      with `A = sets M` `A' = sets N` `A = A'` have "B \<notin> sets M" "B \<notin> sets N"
        by auto
      then have "emeasure M B = 0" "emeasure N B = 0"
        by (simp_all add: emeasure_notin_sets)
      with measure_measure show "\<mu> B = \<mu>' B"
        by (simp add: emeasure_def Abs_measure_inverse)
    qed }
  then have "\<mu> = \<mu>'" by auto
  ultimately show "M = N"
    by (simp add: measure_measure)
qed

lemma sigma_eqI:
  assumes [simp]: "M \<subseteq> Pow \<Omega>" "N \<subseteq> Pow \<Omega>" "sigma_sets \<Omega> M = sigma_sets \<Omega> N"
  shows "sigma \<Omega> M = sigma \<Omega> N"
  by (rule measure_eqI) (simp_all add: emeasure_sigma)

subsubsection {* Measurable functions *}

definition measurable :: "'a measure \<Rightarrow> 'b measure \<Rightarrow> ('a \<Rightarrow> 'b) set" where
  "measurable A B = {f \<in> space A -> space B. \<forall>y \<in> sets B. f -` y \<inter> space A \<in> sets A}"

lemma measurable_space:
  "f \<in> measurable M A \<Longrightarrow> x \<in> space M \<Longrightarrow> f x \<in> space A"
   unfolding measurable_def by auto

lemma measurable_sets:
  "f \<in> measurable M A \<Longrightarrow> S \<in> sets A \<Longrightarrow> f -` S \<inter> space M \<in> sets M"
   unfolding measurable_def by auto

lemma measurable_sets_Collect:
  assumes f: "f \<in> measurable M N" and P: "{x\<in>space N. P x} \<in> sets N" shows "{x\<in>space M. P (f x)} \<in> sets M"
proof -
  have "f -` {x \<in> space N. P x} \<inter> space M = {x\<in>space M. P (f x)}"
    using measurable_space[OF f] by auto
  with measurable_sets[OF f P] show ?thesis
    by simp
qed

lemma measurable_sigma_sets:
  assumes B: "sets N = sigma_sets \<Omega> A" "A \<subseteq> Pow \<Omega>"
      and f: "f \<in> space M \<rightarrow> \<Omega>"
      and ba: "\<And>y. y \<in> A \<Longrightarrow> (f -` y) \<inter> space M \<in> sets M"
  shows "f \<in> measurable M N"
proof -
  interpret A: sigma_algebra \<Omega> "sigma_sets \<Omega> A" using B(2) by (rule sigma_algebra_sigma_sets)
  from B sets.top[of N] A.top sets.space_closed[of N] A.space_closed have \<Omega>: "\<Omega> = space N" by force
  
  { fix X assume "X \<in> sigma_sets \<Omega> A"
    then have "f -` X \<inter> space M \<in> sets M \<and> X \<subseteq> \<Omega>"
      proof induct
        case (Basic a) then show ?case
          by (auto simp add: ba) (metis B(2) subsetD PowD)
      next
        case (Compl a)
        have [simp]: "f -` \<Omega> \<inter> space M = space M"
          by (auto simp add: funcset_mem [OF f])
        then show ?case
          by (auto simp add: vimage_Diff Diff_Int_distrib2 sets.compl_sets Compl)
      next
        case (Union a)
        then show ?case
          by (simp add: vimage_UN, simp only: UN_extend_simps(4)) blast
      qed auto }
  with f show ?thesis
    by (auto simp add: measurable_def B \<Omega>)
qed

lemma measurable_measure_of:
  assumes B: "N \<subseteq> Pow \<Omega>"
      and f: "f \<in> space M \<rightarrow> \<Omega>"
      and ba: "\<And>y. y \<in> N \<Longrightarrow> (f -` y) \<inter> space M \<in> sets M"
  shows "f \<in> measurable M (measure_of \<Omega> N \<mu>)"
proof -
  have "sets (measure_of \<Omega> N \<mu>) = sigma_sets \<Omega> N"
    using B by (rule sets_measure_of)
  from this assms show ?thesis by (rule measurable_sigma_sets)
qed

lemma measurable_iff_measure_of:
  assumes "N \<subseteq> Pow \<Omega>" "f \<in> space M \<rightarrow> \<Omega>"
  shows "f \<in> measurable M (measure_of \<Omega> N \<mu>) \<longleftrightarrow> (\<forall>A\<in>N. f -` A \<inter> space M \<in> sets M)"
  by (metis assms in_measure_of measurable_measure_of assms measurable_sets)

lemma measurable_cong_sets:
  assumes sets: "sets M = sets M'" "sets N = sets N'"
  shows "measurable M N = measurable M' N'"
  using sets[THEN sets_eq_imp_space_eq] sets by (simp add: measurable_def)

lemma measurable_cong:
  assumes "\<And> w. w \<in> space M \<Longrightarrow> f w = g w"
  shows "f \<in> measurable M M' \<longleftrightarrow> g \<in> measurable M M'"
  unfolding measurable_def using assms
  by (simp cong: vimage_inter_cong Pi_cong)

lemma measurable_cong_strong:
  "M = N \<Longrightarrow> M' = N' \<Longrightarrow> (\<And>w. w \<in> space M \<Longrightarrow> f w = g w) \<Longrightarrow>
    f \<in> measurable M M' \<longleftrightarrow> g \<in> measurable N N'"
  by (metis measurable_cong)

lemma measurable_compose:
  assumes f: "f \<in> measurable M N" and g: "g \<in> measurable N L"
  shows "(\<lambda>x. g (f x)) \<in> measurable M L"
proof -
  have "\<And>A. (\<lambda>x. g (f x)) -` A \<inter> space M = f -` (g -` A \<inter> space N) \<inter> space M"
    using measurable_space[OF f] by auto
  with measurable_space[OF f] measurable_space[OF g] show ?thesis
    by (auto intro: measurable_sets[OF f] measurable_sets[OF g]
             simp del: vimage_Int simp add: measurable_def)
qed

lemma measurable_comp:
  "f \<in> measurable M N \<Longrightarrow> g \<in> measurable N L \<Longrightarrow> g \<circ> f \<in> measurable M L"
  using measurable_compose[of f M N g L] by (simp add: comp_def)

lemma measurable_const:
  "c \<in> space M' \<Longrightarrow> (\<lambda>x. c) \<in> measurable M M'"
  by (auto simp add: measurable_def)

lemma measurable_If:
  assumes measure: "f \<in> measurable M M'" "g \<in> measurable M M'"
  assumes P: "{x\<in>space M. P x} \<in> sets M"
  shows "(\<lambda>x. if P x then f x else g x) \<in> measurable M M'"
  unfolding measurable_def
proof safe
  fix x assume "x \<in> space M"
  thus "(if P x then f x else g x) \<in> space M'"
    using measure unfolding measurable_def by auto
next
  fix A assume "A \<in> sets M'"
  hence *: "(\<lambda>x. if P x then f x else g x) -` A \<inter> space M =
    ((f -` A \<inter> space M) \<inter> {x\<in>space M. P x}) \<union>
    ((g -` A \<inter> space M) \<inter> (space M - {x\<in>space M. P x}))"
    using measure unfolding measurable_def by (auto split: split_if_asm)
  show "(\<lambda>x. if P x then f x else g x) -` A \<inter> space M \<in> sets M"
    using `A \<in> sets M'` measure P unfolding * measurable_def
    by (auto intro!: sets.Un)
qed

lemma measurable_If_set:
  assumes measure: "f \<in> measurable M M'" "g \<in> measurable M M'"
  assumes P: "A \<inter> space M \<in> sets M"
  shows "(\<lambda>x. if x \<in> A then f x else g x) \<in> measurable M M'"
proof (rule measurable_If[OF measure])
  have "{x \<in> space M. x \<in> A} = A \<inter> space M" by auto
  thus "{x \<in> space M. x \<in> A} \<in> sets M" using `A \<inter> space M \<in> sets M` by auto
qed

lemma measurable_ident: "id \<in> measurable M M"
  by (auto simp add: measurable_def)

lemma measurable_id: "(\<lambda>x. x) \<in> measurable M M"
  by (simp add: measurable_def)

lemma measurable_ident_sets:
  assumes eq: "sets M = sets M'" shows "(\<lambda>x. x) \<in> measurable M M'"
  using measurable_ident[of M]
  unfolding id_def measurable_def eq sets_eq_imp_space_eq[OF eq] .

lemma sets_Least:
  assumes meas: "\<And>i::nat. {x\<in>space M. P i x} \<in> M"
  shows "(\<lambda>x. LEAST j. P j x) -` A \<inter> space M \<in> sets M"
proof -
  { fix i have "(\<lambda>x. LEAST j. P j x) -` {i} \<inter> space M \<in> sets M"
    proof cases
      assume i: "(LEAST j. False) = i"
      have "(\<lambda>x. LEAST j. P j x) -` {i} \<inter> space M =
        {x\<in>space M. P i x} \<inter> (space M - (\<Union>j<i. {x\<in>space M. P j x})) \<union> (space M - (\<Union>i. {x\<in>space M. P i x}))"
        by (simp add: set_eq_iff, safe)
           (insert i, auto dest: Least_le intro: LeastI intro!: Least_equality)
      with meas show ?thesis
        by (auto intro!: sets.Int)
    next
      assume i: "(LEAST j. False) \<noteq> i"
      then have "(\<lambda>x. LEAST j. P j x) -` {i} \<inter> space M =
        {x\<in>space M. P i x} \<inter> (space M - (\<Union>j<i. {x\<in>space M. P j x}))"
      proof (simp add: set_eq_iff, safe)
        fix x assume neq: "(LEAST j. False) \<noteq> (LEAST j. P j x)"
        have "\<exists>j. P j x"
          by (rule ccontr) (insert neq, auto)
        then show "P (LEAST j. P j x) x" by (rule LeastI_ex)
      qed (auto dest: Least_le intro!: Least_equality)
      with meas show ?thesis
        by auto
    qed }
  then have "(\<Union>i\<in>A. (\<lambda>x. LEAST j. P j x) -` {i} \<inter> space M) \<in> sets M"
    by (intro sets.countable_UN) auto
  moreover have "(\<Union>i\<in>A. (\<lambda>x. LEAST j. P j x) -` {i} \<inter> space M) =
    (\<lambda>x. LEAST j. P j x) -` A \<inter> space M" by auto
  ultimately show ?thesis by auto
qed

lemma measurable_strong:
  fixes f :: "'a \<Rightarrow> 'b" and g :: "'b \<Rightarrow> 'c"
  assumes f: "f \<in> measurable a b" and g: "g \<in> space b \<rightarrow> space c"
      and t: "f ` (space a) \<subseteq> t"
      and cb: "\<And>s. s \<in> sets c \<Longrightarrow> (g -` s) \<inter> t \<in> sets b"
  shows "(g o f) \<in> measurable a c"
proof -
  have fab: "f \<in> (space a -> space b)"
   and ba: "\<And>y. y \<in> sets b \<Longrightarrow> (f -` y) \<inter> (space a) \<in> sets a" using f
     by (auto simp add: measurable_def)
  have eq: "\<And>y. (g \<circ> f) -` y \<inter> space a = f -` (g -` y \<inter> t) \<inter> space a" using t
    by force
  show ?thesis
    apply (auto simp add: measurable_def vimage_comp)
    apply (metis funcset_mem fab g)
    apply (subst eq)
    apply (metis ba cb)
    done
qed

lemma measurable_discrete_difference:
  assumes f: "f \<in> measurable M N"
  assumes X: "countable X"
  assumes sets: "\<And>x. x \<in> X \<Longrightarrow> {x} \<in> sets M"
  assumes space: "\<And>x. x \<in> X \<Longrightarrow> g x \<in> space N"
  assumes eq: "\<And>x. x \<in> space M \<Longrightarrow> x \<notin> X \<Longrightarrow> f x = g x"
  shows "g \<in> measurable M N"
  unfolding measurable_def
proof safe
  fix x assume "x \<in> space M" then show "g x \<in> space N"
    using measurable_space[OF f, of x] eq[of x] space[of x] by (cases "x \<in> X") auto
next
  fix S assume S: "S \<in> sets N"
  have "g -` S \<inter> space M = (f -` S \<inter> space M) - (\<Union>x\<in>X. {x}) \<union> (\<Union>x\<in>{x\<in>X. g x \<in> S}. {x})"
    using sets.sets_into_space[OF sets] eq by auto
  also have "\<dots> \<in> sets M"
    by (safe intro!: sets.Diff sets.Un measurable_sets[OF f] S sets.countable_UN' X countable_Collect sets)
  finally show "g -` S \<inter> space M \<in> sets M" .
qed

lemma measurable_mono1:
  "M' \<subseteq> Pow \<Omega> \<Longrightarrow> M \<subseteq> M' \<Longrightarrow>
    measurable (measure_of \<Omega> M \<mu>) N \<subseteq> measurable (measure_of \<Omega> M' \<mu>') N"
  using measure_of_subset[of M' \<Omega> M] by (auto simp add: measurable_def)

subsubsection {* Counting space *}

definition count_space :: "'a set \<Rightarrow> 'a measure" where
  "count_space \<Omega> = measure_of \<Omega> (Pow \<Omega>) (\<lambda>A. if finite A then ereal (card A) else \<infinity>)"

lemma 
  shows space_count_space[simp]: "space (count_space \<Omega>) = \<Omega>"
    and sets_count_space[simp]: "sets (count_space \<Omega>) = Pow \<Omega>"
  using sigma_sets_into_sp[of "Pow \<Omega>" \<Omega>]
  by (auto simp: count_space_def)

lemma measurable_count_space_eq1[simp]:
  "f \<in> measurable (count_space A) M \<longleftrightarrow> f \<in> A \<rightarrow> space M"
 unfolding measurable_def by simp

lemma measurable_count_space_eq2:
  assumes "finite A"
  shows "f \<in> measurable M (count_space A) \<longleftrightarrow> (f \<in> space M \<rightarrow> A \<and> (\<forall>a\<in>A. f -` {a} \<inter> space M \<in> sets M))"
proof -
  { fix X assume "X \<subseteq> A" "f \<in> space M \<rightarrow> A"
    with `finite A` have "f -` X \<inter> space M = (\<Union>a\<in>X. f -` {a} \<inter> space M)" "finite X"
      by (auto dest: finite_subset)
    moreover assume "\<forall>a\<in>A. f -` {a} \<inter> space M \<in> sets M"
    ultimately have "f -` X \<inter> space M \<in> sets M"
      using `X \<subseteq> A` by (auto intro!: sets.finite_UN simp del: UN_simps) }
  then show ?thesis
    unfolding measurable_def by auto
qed

lemma measurable_count_space_eq2_countable:
  fixes f :: "'a => 'c::countable"
  shows "f \<in> measurable M (count_space A) \<longleftrightarrow> (f \<in> space M \<rightarrow> A \<and> (\<forall>a\<in>A. f -` {a} \<inter> space M \<in> sets M))"
proof -
  { fix X assume "X \<subseteq> A" "f \<in> space M \<rightarrow> A"
    assume *: "\<And>a. a\<in>A \<Longrightarrow> f -` {a} \<inter> space M \<in> sets M"
    have "f -` X \<inter> space M = (\<Union>a\<in>X. f -` {a} \<inter> space M)"
      by auto
    also have "\<dots> \<in> sets M"
      using * `X \<subseteq> A` by (intro sets.countable_UN) auto
    finally have "f -` X \<inter> space M \<in> sets M" . }
  then show ?thesis
    unfolding measurable_def by auto
qed

lemma measurable_compose_countable':
  assumes f: "\<And>i. i \<in> I \<Longrightarrow> (\<lambda>x. f i x) \<in> measurable M N"
  and g: "g \<in> measurable M (count_space I)" and I: "countable I"
  shows "(\<lambda>x. f (g x) x) \<in> measurable M N"
  unfolding measurable_def
proof safe
  fix x assume "x \<in> space M" then show "f (g x) x \<in> space N"
    using measurable_space[OF f] g[THEN measurable_space] by auto
next
  fix A assume A: "A \<in> sets N"
  have "(\<lambda>x. f (g x) x) -` A \<inter> space M = (\<Union>i\<in>I. (g -` {i} \<inter> space M) \<inter> (f i -` A \<inter> space M))"
    using measurable_space[OF g] by auto
  also have "\<dots> \<in> sets M" using f[THEN measurable_sets, OF _ A] g[THEN measurable_sets]
    apply (auto intro!: sets.countable_UN' measurable_sets I)
    apply (rule sets.Int)
    apply auto
    done
  finally show "(\<lambda>x. f (g x) x) -` A \<inter> space M \<in> sets M" .
qed

lemma measurable_compose_countable:
  assumes f: "\<And>i::'i::countable. (\<lambda>x. f i x) \<in> measurable M N" and g: "g \<in> measurable M (count_space UNIV)"
  shows "(\<lambda>x. f (g x) x) \<in> measurable M N"
  by (rule measurable_compose_countable'[OF assms]) auto
lemma measurable_count_space_const:
  "(\<lambda>x. c) \<in> measurable M (count_space UNIV)"
  by (simp add: measurable_const)

lemma measurable_count_space:
  "f \<in> measurable (count_space A) (count_space UNIV)"
  by simp

lemma measurable_compose_rev:
  assumes f: "f \<in> measurable L N" and g: "g \<in> measurable M L"
  shows "(\<lambda>x. f (g x)) \<in> measurable M N"
  using measurable_compose[OF g f] .

lemma measurable_count_space_eq_countable:
  assumes "countable A"
  shows "f \<in> measurable M (count_space A) \<longleftrightarrow> (f \<in> space M \<rightarrow> A \<and> (\<forall>a\<in>A. f -` {a} \<inter> space M \<in> sets M))"
proof -
  { fix X assume "X \<subseteq> A" "f \<in> space M \<rightarrow> A"
    with `countable A` have "f -` X \<inter> space M = (\<Union>a\<in>X. f -` {a} \<inter> space M)" "countable X"
      by (auto dest: countable_subset)
    moreover assume "\<forall>a\<in>A. f -` {a} \<inter> space M \<in> sets M"
    ultimately have "f -` X \<inter> space M \<in> sets M"
      using `X \<subseteq> A` by (auto intro!: sets.countable_UN' simp del: UN_simps) }
  then show ?thesis
    unfolding measurable_def by auto
qed

lemma measurable_empty_iff: 
  "space N = {} \<Longrightarrow> f \<in> measurable M N \<longleftrightarrow> space M = {}"
  by (auto simp add: measurable_def Pi_iff)

subsubsection {* Extend measure *}

definition "extend_measure \<Omega> I G \<mu> =
  (if (\<exists>\<mu>'. (\<forall>i\<in>I. \<mu>' (G i) = \<mu> i) \<and> measure_space \<Omega> (sigma_sets \<Omega> (G`I)) \<mu>') \<and> \<not> (\<forall>i\<in>I. \<mu> i = 0)
      then measure_of \<Omega> (G`I) (SOME \<mu>'. (\<forall>i\<in>I. \<mu>' (G i) = \<mu> i) \<and> measure_space \<Omega> (sigma_sets \<Omega> (G`I)) \<mu>')
      else measure_of \<Omega> (G`I) (\<lambda>_. 0))"

lemma space_extend_measure: "G ` I \<subseteq> Pow \<Omega> \<Longrightarrow> space (extend_measure \<Omega> I G \<mu>) = \<Omega>"
  unfolding extend_measure_def by simp

lemma sets_extend_measure: "G ` I \<subseteq> Pow \<Omega> \<Longrightarrow> sets (extend_measure \<Omega> I G \<mu>) = sigma_sets \<Omega> (G`I)"
  unfolding extend_measure_def by simp

lemma emeasure_extend_measure:
  assumes M: "M = extend_measure \<Omega> I G \<mu>"
    and eq: "\<And>i. i \<in> I \<Longrightarrow> \<mu>' (G i) = \<mu> i"
    and ms: "G ` I \<subseteq> Pow \<Omega>" "positive (sets M) \<mu>'" "countably_additive (sets M) \<mu>'"
    and "i \<in> I"
  shows "emeasure M (G i) = \<mu> i"
proof cases
  assume *: "(\<forall>i\<in>I. \<mu> i = 0)"
  with M have M_eq: "M = measure_of \<Omega> (G`I) (\<lambda>_. 0)"
   by (simp add: extend_measure_def)
  from measure_space_0[OF ms(1)] ms `i\<in>I`
  have "emeasure M (G i) = 0"
    by (intro emeasure_measure_of[OF M_eq]) (auto simp add: M measure_space_def sets_extend_measure)
  with `i\<in>I` * show ?thesis
    by simp
next
  def P \<equiv> "\<lambda>\<mu>'. (\<forall>i\<in>I. \<mu>' (G i) = \<mu> i) \<and> measure_space \<Omega> (sigma_sets \<Omega> (G`I)) \<mu>'"
  assume "\<not> (\<forall>i\<in>I. \<mu> i = 0)"
  moreover
  have "measure_space (space M) (sets M) \<mu>'"
    using ms unfolding measure_space_def by auto default
  with ms eq have "\<exists>\<mu>'. P \<mu>'"
    unfolding P_def
    by (intro exI[of _ \<mu>']) (auto simp add: M space_extend_measure sets_extend_measure)
  ultimately have M_eq: "M = measure_of \<Omega> (G`I) (Eps P)"
    by (simp add: M extend_measure_def P_def[symmetric])

  from `\<exists>\<mu>'. P \<mu>'` have P: "P (Eps P)" by (rule someI_ex)
  show "emeasure M (G i) = \<mu> i"
  proof (subst emeasure_measure_of[OF M_eq])
    have sets_M: "sets M = sigma_sets \<Omega> (G`I)"
      using M_eq ms by (auto simp: sets_extend_measure)
    then show "G i \<in> sets M" using `i \<in> I` by auto
    show "positive (sets M) (Eps P)" "countably_additive (sets M) (Eps P)" "Eps P (G i) = \<mu> i"
      using P `i\<in>I` by (auto simp add: sets_M measure_space_def P_def)
  qed fact
qed

lemma emeasure_extend_measure_Pair:
  assumes M: "M = extend_measure \<Omega> {(i, j). I i j} (\<lambda>(i, j). G i j) (\<lambda>(i, j). \<mu> i j)"
    and eq: "\<And>i j. I i j \<Longrightarrow> \<mu>' (G i j) = \<mu> i j"
    and ms: "\<And>i j. I i j \<Longrightarrow> G i j \<in> Pow \<Omega>" "positive (sets M) \<mu>'" "countably_additive (sets M) \<mu>'"
    and "I i j"
  shows "emeasure M (G i j) = \<mu> i j"
  using emeasure_extend_measure[OF M _ _ ms(2,3), of "(i,j)"] eq ms(1) `I i j`
  by (auto simp: subset_eq)

subsubsection {* Supremum of a set of $\sigma$-algebras *}

definition "Sup_sigma M = sigma (\<Union>x\<in>M. space x) (\<Union>x\<in>M. sets x)"

syntax
  "_SUP_sigma"   :: "pttrn \<Rightarrow> 'a set \<Rightarrow> 'b \<Rightarrow> 'b"  ("(3\<Squnion>\<^sub>\<sigma> _\<in>_./ _)" [0, 0, 10] 10)

translations
  "\<Squnion>\<^sub>\<sigma> x\<in>A. B"   == "CONST Sup_sigma ((\<lambda>x. B) ` A)"

lemma space_Sup_sigma: "space (Sup_sigma M) = (\<Union>x\<in>M. space x)"
  unfolding Sup_sigma_def by (rule space_measure_of) (auto dest: sets.sets_into_space)

lemma sets_Sup_sigma: "sets (Sup_sigma M) = sigma_sets (\<Union>x\<in>M. space x) (\<Union>x\<in>M. sets x)"
  unfolding Sup_sigma_def by (rule sets_measure_of) (auto dest: sets.sets_into_space)

lemma in_Sup_sigma: "m \<in> M \<Longrightarrow> A \<in> sets m \<Longrightarrow> A \<in> sets (Sup_sigma M)"
  unfolding sets_Sup_sigma by auto

lemma SUP_sigma_cong: 
  assumes *: "\<And>i. i \<in> I \<Longrightarrow> sets (M i) = sets (N i)" shows "sets (\<Squnion>\<^sub>\<sigma> i\<in>I. M i) = sets (\<Squnion>\<^sub>\<sigma> i\<in>I. N i)"
  using * sets_eq_imp_space_eq[OF *] by (simp add: Sup_sigma_def)

lemma sets_Sup_in_sets: 
  assumes "M \<noteq> {}"
  assumes "\<And>m. m \<in> M \<Longrightarrow> space m = space N"
  assumes "\<And>m. m \<in> M \<Longrightarrow> sets m \<subseteq> sets N"
  shows "sets (Sup_sigma M) \<subseteq> sets N"
proof -
  have *: "UNION M space = space N"
    using assms by auto
  show ?thesis
    unfolding sets_Sup_sigma * using assms by (auto intro!: sets.sigma_sets_subset)
qed

lemma measurable_Sup_sigma1:
  assumes m: "m \<in> M" and f: "f \<in> measurable m N"
    and const_space: "\<And>m n. m \<in> M \<Longrightarrow> n \<in> M \<Longrightarrow> space m = space n"
  shows "f \<in> measurable (Sup_sigma M) N"
proof -
  have "space (Sup_sigma M) = space m"
    using m by (auto simp add: space_Sup_sigma dest: const_space)
  then show ?thesis
    using m f unfolding measurable_def by (auto intro: in_Sup_sigma)
qed

lemma measurable_Sup_sigma2:
  assumes M: "M \<noteq> {}"
  assumes f: "\<And>m. m \<in> M \<Longrightarrow> f \<in> measurable N m"
  shows "f \<in> measurable N (Sup_sigma M)"
  unfolding Sup_sigma_def
proof (rule measurable_measure_of)
  show "f \<in> space N \<rightarrow> UNION M space"
    using measurable_space[OF f] M by auto
qed (auto intro: measurable_sets f dest: sets.sets_into_space)

lemma Sup_sigma_sigma:
  assumes [simp]: "M \<noteq> {}" and M: "\<And>m. m \<in> M \<Longrightarrow> m \<subseteq> Pow \<Omega>"
  shows "(\<Squnion>\<^sub>\<sigma> m\<in>M. sigma \<Omega> m) = sigma \<Omega> (\<Union>M)"
proof (rule measure_eqI)
  { fix a m assume "a \<in> sigma_sets \<Omega> m" "m \<in> M"
    then have "a \<in> sigma_sets \<Omega> (\<Union>M)"
     by induction (auto intro: sigma_sets.intros) }
  then show "sets (\<Squnion>\<^sub>\<sigma> m\<in>M. sigma \<Omega> m) = sets (sigma \<Omega> (\<Union>M))"
    apply (simp add: sets_Sup_sigma space_measure_of_conv M Union_least)
    apply (rule sigma_sets_eqI)
    apply auto
    done
qed (simp add: Sup_sigma_def emeasure_sigma)

lemma SUP_sigma_sigma:
  assumes M: "M \<noteq> {}" "\<And>m. m \<in> M \<Longrightarrow> f m \<subseteq> Pow \<Omega>"
  shows "(\<Squnion>\<^sub>\<sigma> m\<in>M. sigma \<Omega> (f m)) = sigma \<Omega> (\<Union>m\<in>M. f m)"
proof -
  have "Sup_sigma (sigma \<Omega> ` f ` M) = sigma \<Omega> (\<Union>(f ` M))"
    using M by (intro Sup_sigma_sigma) auto
  then show ?thesis
    by (simp add: image_image)
qed

subsection {* The smallest $\sigma$-algebra regarding a function *}

definition
  "vimage_algebra X f M = sigma X {f -` A \<inter> X | A. A \<in> sets M}"

lemma space_vimage_algebra[simp]: "space (vimage_algebra X f M) = X"
  unfolding vimage_algebra_def by (rule space_measure_of) auto

lemma sets_vimage_algebra: "sets (vimage_algebra X f M) = sigma_sets X {f -` A \<inter> X | A. A \<in> sets M}"
  unfolding vimage_algebra_def by (rule sets_measure_of) auto

lemma sets_vimage_algebra2:
  "f \<in> X \<rightarrow> space M \<Longrightarrow> sets (vimage_algebra X f M) = {f -` A \<inter> X | A. A \<in> sets M}"
  using sigma_sets_vimage_commute[of f X "space M" "sets M"]
  unfolding sets_vimage_algebra sets.sigma_sets_eq by simp

lemma sets_vimage_algebra_cong: "sets M = sets N \<Longrightarrow> sets (vimage_algebra X f M) = sets (vimage_algebra X f N)"
  by (simp add: sets_vimage_algebra)

lemma vimage_algebra_cong:
  assumes "X = Y"
  assumes "\<And>x. x \<in> Y \<Longrightarrow> f x = g x"
  assumes "sets M = sets N"
  shows "vimage_algebra X f M = vimage_algebra Y g N"
  by (auto simp: vimage_algebra_def assms intro!: arg_cong2[where f=sigma])

lemma in_vimage_algebra: "A \<in> sets M \<Longrightarrow> f -` A \<inter> X \<in> sets (vimage_algebra X f M)"
  by (auto simp: vimage_algebra_def)

lemma sets_image_in_sets:
  assumes N: "space N = X"
  assumes f: "f \<in> measurable N M"
  shows "sets (vimage_algebra X f M) \<subseteq> sets N"
  unfolding sets_vimage_algebra N[symmetric]
  by (rule sets.sigma_sets_subset) (auto intro!: measurable_sets f)

lemma measurable_vimage_algebra1: "f \<in> X \<rightarrow> space M \<Longrightarrow> f \<in> measurable (vimage_algebra X f M) M"
  unfolding measurable_def by (auto intro: in_vimage_algebra)

lemma measurable_vimage_algebra2:
  assumes g: "g \<in> space N \<rightarrow> X" and f: "(\<lambda>x. f (g x)) \<in> measurable N M"
  shows "g \<in> measurable N (vimage_algebra X f M)"
  unfolding vimage_algebra_def
proof (rule measurable_measure_of)
  fix A assume "A \<in> {f -` A \<inter> X | A. A \<in> sets M}"
  then obtain Y where Y: "Y \<in> sets M" and A: "A = f -` Y \<inter> X"
    by auto
  then have "g -` A \<inter> space N = (\<lambda>x. f (g x)) -` Y \<inter> space N"
    using g by auto
  also have "\<dots> \<in> sets N"
    using f Y by (rule measurable_sets)
  finally show "g -` A \<inter> space N \<in> sets N" .
qed (insert g, auto)

lemma vimage_algebra_sigma:
  assumes X: "X \<subseteq> Pow \<Omega>'" and f: "f \<in> \<Omega> \<rightarrow> \<Omega>'"
  shows "vimage_algebra \<Omega> f (sigma \<Omega>' X) = sigma \<Omega> {f -` A \<inter> \<Omega> | A. A \<in> X }" (is "?V = ?S")
proof (rule measure_eqI)
  have \<Omega>: "{f -` A \<inter> \<Omega> |A. A \<in> X} \<subseteq> Pow \<Omega>" by auto
  show "sets ?V = sets ?S"
    using sigma_sets_vimage_commute[OF f, of X]
    by (simp add: space_measure_of_conv f sets_vimage_algebra2 \<Omega> X)
qed (simp add: vimage_algebra_def emeasure_sigma)

lemma vimage_algebra_vimage_algebra_eq:
  assumes *: "f \<in> X \<rightarrow> Y" "g \<in> Y \<rightarrow> space M"
  shows "vimage_algebra X f (vimage_algebra Y g M) = vimage_algebra X (\<lambda>x. g (f x)) M"
    (is "?VV = ?V")
proof (rule measure_eqI)
  have "(\<lambda>x. g (f x)) \<in> X \<rightarrow> space M" "\<And>A. A \<inter> f -` Y \<inter> X = A \<inter> X"
    using * by auto
  with * show "sets ?VV = sets ?V"
    by (simp add: sets_vimage_algebra2 ex_simps[symmetric] vimage_comp comp_def del: ex_simps)
qed (simp add: vimage_algebra_def emeasure_sigma)

lemma sets_vimage_Sup_eq:
  assumes *: "M \<noteq> {}" "\<And>m. m \<in> M \<Longrightarrow> f \<in> X \<rightarrow> space m"
  shows "sets (vimage_algebra X f (Sup_sigma M)) = sets (\<Squnion>\<^sub>\<sigma> m \<in> M. vimage_algebra X f m)"
  (is "?IS = ?SI")
proof
  show "?IS \<subseteq> ?SI"
    by (intro sets_image_in_sets measurable_Sup_sigma2 measurable_Sup_sigma1)
       (auto simp: space_Sup_sigma measurable_vimage_algebra1 *)
  { fix m assume "m \<in> M"
    moreover then have "f \<in> X \<rightarrow> space (Sup_sigma M)" "f \<in> X \<rightarrow> space m"
      using * by (auto simp: space_Sup_sigma)
    ultimately have "f \<in> measurable (vimage_algebra X f (Sup_sigma M)) m"
      by (auto simp add: measurable_def sets_vimage_algebra2 intro: in_Sup_sigma) }
  then show "?SI \<subseteq> ?IS"
    by (auto intro!: sets_image_in_sets sets_Sup_in_sets del: subsetI simp: *)
qed

lemma vimage_algebra_Sup_sigma:
  assumes [simp]: "MM \<noteq> {}" and "\<And>M. M \<in> MM \<Longrightarrow> f \<in> X \<rightarrow> space M"
  shows "vimage_algebra X f (Sup_sigma MM) = Sup_sigma (vimage_algebra X f ` MM)"
proof (rule measure_eqI)
  show "sets (vimage_algebra X f (Sup_sigma MM)) = sets (Sup_sigma (vimage_algebra X f ` MM))"
    using assms by (rule sets_vimage_Sup_eq)
qed (simp add: vimage_algebra_def Sup_sigma_def emeasure_sigma)

subsubsection {* Restricted Space Sigma Algebra *}

definition restrict_space where
  "restrict_space M \<Omega> = measure_of (\<Omega> \<inter> space M) ((op \<inter> \<Omega>) ` sets M) (emeasure M)"

lemma space_restrict_space: "space (restrict_space M \<Omega>) = \<Omega> \<inter> space M"
  using sets.sets_into_space unfolding restrict_space_def by (subst space_measure_of) auto

lemma space_restrict_space2: "\<Omega> \<in> sets M \<Longrightarrow> space (restrict_space M \<Omega>) = \<Omega>"
  by (simp add: space_restrict_space sets.sets_into_space)

lemma sets_restrict_space: "sets (restrict_space M \<Omega>) = (op \<inter> \<Omega>) ` sets M"
  unfolding restrict_space_def
proof (subst sets_measure_of)
  show "op \<inter> \<Omega> ` sets M \<subseteq> Pow (\<Omega> \<inter> space M)"
    by (auto dest: sets.sets_into_space)
  have "sigma_sets (\<Omega> \<inter> space M) {((\<lambda>x. x) -` X) \<inter> (\<Omega> \<inter> space M) | X. X \<in> sets M} =
    (\<lambda>X. X \<inter> (\<Omega> \<inter> space M)) ` sets M"
    by (subst sigma_sets_vimage_commute[symmetric, where \<Omega>' = "space M"])
       (auto simp add: sets.sigma_sets_eq)
  moreover have "{((\<lambda>x. x) -` X) \<inter> (\<Omega> \<inter> space M) | X. X \<in> sets M} = (\<lambda>X. X \<inter> (\<Omega> \<inter> space M)) `  sets M"
    by auto
  moreover have "(\<lambda>X. X \<inter> (\<Omega> \<inter> space M)) `  sets M = (op \<inter> \<Omega>) ` sets M"
    by (intro image_cong) (auto dest: sets.sets_into_space)
  ultimately show "sigma_sets (\<Omega> \<inter> space M) (op \<inter> \<Omega> ` sets M) = op \<inter> \<Omega> ` sets M"
    by simp
qed

lemma sets_restrict_space_iff:
  "\<Omega> \<inter> space M \<in> sets M \<Longrightarrow> A \<in> sets (restrict_space M \<Omega>) \<longleftrightarrow> (A \<subseteq> \<Omega> \<and> A \<in> sets M)"
proof (subst sets_restrict_space, safe)
  fix A assume "\<Omega> \<inter> space M \<in> sets M" and A: "A \<in> sets M"
  then have "(\<Omega> \<inter> space M) \<inter> A \<in> sets M"
    by rule
  also have "(\<Omega> \<inter> space M) \<inter> A = \<Omega> \<inter> A"
    using sets.sets_into_space[OF A] by auto
  finally show "\<Omega> \<inter> A \<in> sets M"
    by auto
qed auto

lemma sets_restrict_space_cong: "sets M = sets N \<Longrightarrow> sets (restrict_space M \<Omega>) = sets (restrict_space N \<Omega>)"
  by (simp add: sets_restrict_space)

lemma restrict_space_eq_vimage_algebra:
  "\<Omega> \<subseteq> space M \<Longrightarrow> sets (restrict_space M \<Omega>) = sets (vimage_algebra \<Omega> (\<lambda>x. x) M)"
  unfolding restrict_space_def
  apply (subst sets_measure_of)
  apply (auto simp add: image_subset_iff dest: sets.sets_into_space) []
  apply (auto simp add: sets_vimage_algebra intro!: arg_cong2[where f=sigma_sets])
  done

lemma sets_Collect_restrict_space_iff: 
  assumes "S \<in> sets M"
  shows "{x\<in>space (restrict_space M S). P x} \<in> sets (restrict_space M S) \<longleftrightarrow> {x\<in>space M. x \<in> S \<and> P x} \<in> sets M"
proof -
  have "{x\<in>S. P x} = {x\<in>space M. x \<in> S \<and> P x}"
    using sets.sets_into_space[OF assms] by auto
  then show ?thesis
    by (subst sets_restrict_space_iff) (auto simp add: space_restrict_space assms)
qed

lemma measurable_restrict_space1:
  assumes \<Omega>: "\<Omega> \<inter> space M \<in> sets M" and f: "f \<in> measurable M N"
  shows "f \<in> measurable (restrict_space M \<Omega>) N"
  unfolding measurable_def
proof (intro CollectI conjI ballI)
  show sp: "f \<in> space (restrict_space M \<Omega>) \<rightarrow> space N"
    using measurable_space[OF f] sets.sets_into_space[OF \<Omega>] by (auto simp: space_restrict_space)

  fix A assume "A \<in> sets N"
  have "f -` A \<inter> space (restrict_space M \<Omega>) = (f -` A \<inter> space M) \<inter> (\<Omega> \<inter> space M)"
    using sets.sets_into_space[OF \<Omega>] by (auto simp: space_restrict_space)
  also have "\<dots> \<in> sets (restrict_space M \<Omega>)"
    unfolding sets_restrict_space_iff[OF \<Omega>]
    using measurable_sets[OF f `A \<in> sets N`] \<Omega> by blast
  finally show "f -` A \<inter> space (restrict_space M \<Omega>) \<in> sets (restrict_space M \<Omega>)" .
qed

lemma measurable_restrict_space2:
  "\<Omega> \<inter> space N \<in> sets N \<Longrightarrow> f \<in> space M \<rightarrow> \<Omega> \<Longrightarrow> f \<in> measurable M N \<Longrightarrow>
    f \<in> measurable M (restrict_space N \<Omega>)"
  by (simp add: measurable_def space_restrict_space sets_restrict_space_iff Pi_Int[symmetric])

lemma measurable_restrict_space_iff:
  assumes \<Omega>[simp, intro]: "\<Omega> \<inter> space M \<in> sets M" "c \<in> space N"
  shows "f \<in> measurable (restrict_space M \<Omega>) N \<longleftrightarrow>
    (\<lambda>x. if x \<in> \<Omega> then f x else c) \<in> measurable M N" (is "f \<in> measurable ?R N \<longleftrightarrow> ?f \<in> measurable M N")
  unfolding measurable_def
proof safe
  fix x assume "f \<in> space ?R \<rightarrow> space N" "x \<in> space M" then show "?f x \<in> space N"
    using `c\<in>space N` by (auto simp: space_restrict_space)
next
  fix x assume "?f \<in> space M \<rightarrow> space N" "x \<in> space ?R" then show "f x \<in> space N"
    using `c\<in>space N` by (auto simp: space_restrict_space Pi_iff)
next
  fix X assume X: "X \<in> sets N"
  assume *[THEN bspec]: "\<forall>y\<in>sets N. f -` y \<inter> space ?R \<in> sets ?R"
  have "?f -` X \<inter> space M = (f -` X \<inter> (\<Omega> \<inter> space M)) \<union> (if c \<in> X then (space M - (\<Omega> \<inter> space M)) else {})"
    by (auto split: split_if_asm)
  also have "\<dots> \<in> sets M"
    using *[OF X] by (auto simp add: space_restrict_space sets_restrict_space_iff)
  finally show "?f -` X \<inter> space M \<in> sets M" .
next
  assume *[THEN bspec]: "\<forall>y\<in>sets N. ?f -` y \<inter> space M \<in> sets M"
  fix X :: "'b set" assume X: "X \<in> sets N"
  have "f -` X \<inter> (\<Omega> \<inter> space M) = (?f -` X \<inter> space M) \<inter> (\<Omega> \<inter> space M)"
    by (auto simp: space_restrict_space)
  also have "\<dots> \<in> sets M"
    using *[OF X] by auto
  finally show "f -` X \<inter> space ?R \<in> sets ?R"
    by (auto simp add: sets_restrict_space_iff space_restrict_space)
qed

end

