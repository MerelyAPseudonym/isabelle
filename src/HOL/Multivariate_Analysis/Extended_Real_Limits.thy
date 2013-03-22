(*  Title:      HOL/Multivariate_Analysis/Extended_Real_Limits.thy
    Author:     Johannes Hölzl, TU München
    Author:     Robert Himmelmann, TU München
    Author:     Armin Heller, TU München
    Author:     Bogdan Grechuk, University of Edinburgh
*)

header {* Limits on the Extended real number line *}

theory Extended_Real_Limits
  imports Topology_Euclidean_Space "~~/src/HOL/Library/Extended_Real"
begin

lemma convergent_limsup_cl:
  fixes X :: "nat \<Rightarrow> 'a::{complete_linorder, linorder_topology}"
  shows "convergent X \<Longrightarrow> limsup X = lim X"
  by (auto simp: convergent_def limI lim_imp_Limsup)

lemma lim_increasing_cl:
  assumes "\<And>n m. n \<ge> m \<Longrightarrow> f n \<ge> f m"
  obtains l where "f ----> (l::'a::{complete_linorder, linorder_topology})"
proof
  show "f ----> (SUP n. f n)"
    using assms
    by (intro increasing_tendsto)
       (auto simp: SUP_upper eventually_sequentially less_SUP_iff intro: less_le_trans)
qed

lemma lim_decreasing_cl:
  assumes "\<And>n m. n \<ge> m \<Longrightarrow> f n \<le> f m"
  obtains l where "f ----> (l::'a::{complete_linorder, linorder_topology})"
proof
  show "f ----> (INF n. f n)"
    using assms
    by (intro decreasing_tendsto)
       (auto simp: INF_lower eventually_sequentially INF_less_iff intro: le_less_trans)
qed

lemma compact_complete_linorder:
  fixes X :: "nat \<Rightarrow> 'a::{complete_linorder, linorder_topology}"
  shows "\<exists>l r. subseq r \<and> (X \<circ> r) ----> l"
proof -
  obtain r where "subseq r" and mono: "monoseq (X \<circ> r)"
    using seq_monosub[of X] unfolding comp_def by auto
  then have "(\<forall>n m. m \<le> n \<longrightarrow> (X \<circ> r) m \<le> (X \<circ> r) n) \<or> (\<forall>n m. m \<le> n \<longrightarrow> (X \<circ> r) n \<le> (X \<circ> r) m)"
    by (auto simp add: monoseq_def)
  then obtain l where "(X\<circ>r) ----> l"
     using lim_increasing_cl[of "X \<circ> r"] lim_decreasing_cl[of "X \<circ> r"] by auto
  then show ?thesis using `subseq r` by auto
qed

lemma compact_UNIV: "compact (UNIV :: 'a::{complete_linorder, linorder_topology, second_countable_topology} set)"
  using compact_complete_linorder
  by (auto simp: seq_compact_eq_compact[symmetric] seq_compact_def)

lemma compact_eq_closed:
  fixes S :: "'a::{complete_linorder, linorder_topology, second_countable_topology} set"
  shows "compact S \<longleftrightarrow> closed S"
  using closed_inter_compact[of S, OF _ compact_UNIV] compact_imp_closed by auto

lemma closed_contains_Sup_cl:
  fixes S :: "'a::{complete_linorder, linorder_topology, second_countable_topology} set"
  assumes "closed S" "S \<noteq> {}" shows "Sup S \<in> S"
proof -
  from compact_eq_closed[of S] compact_attains_sup[of S] assms
  obtain s where "s \<in> S" "\<forall>t\<in>S. t \<le> s" by auto
  moreover then have "Sup S = s"
    by (auto intro!: Sup_eqI)
  ultimately show ?thesis
    by simp
qed

lemma closed_contains_Inf_cl:
  fixes S :: "'a::{complete_linorder, linorder_topology, second_countable_topology} set"
  assumes "closed S" "S \<noteq> {}" shows "Inf S \<in> S"
proof -
  from compact_eq_closed[of S] compact_attains_inf[of S] assms
  obtain s where "s \<in> S" "\<forall>t\<in>S. s \<le> t" by auto
  moreover then have "Inf S = s"
    by (auto intro!: Inf_eqI)
  ultimately show ?thesis
    by simp
qed

lemma ereal_dense3: 
  fixes x y :: ereal shows "x < y \<Longrightarrow> \<exists>r::rat. x < real_of_rat r \<and> real_of_rat r < y"
proof (cases x y rule: ereal2_cases, simp_all)
  fix r q :: real assume "r < q"
  from Rats_dense_in_real[OF this]
  show "\<exists>x. r < real_of_rat x \<and> real_of_rat x < q"
    by (fastforce simp: Rats_def)
next
  fix r :: real show "\<exists>x. r < real_of_rat x" "\<exists>x. real_of_rat x < r"
    using gt_ex[of r] lt_ex[of r] Rats_dense_in_real
    by (auto simp: Rats_def)
qed

instance ereal :: second_countable_topology
proof (default, intro exI conjI)
  let ?B = "(\<Union>r\<in>\<rat>. {{..< r}, {r <..}} :: ereal set set)"
  show "countable ?B" by (auto intro: countable_rat)
  show "open = generate_topology ?B"
  proof (intro ext iffI)
    fix S :: "ereal set" assume "open S"
    then show "generate_topology ?B S"
      unfolding open_generated_order
    proof induct
      case (Basis b)
      then obtain e where "b = {..< e} \<or> b = {e <..}" by auto
      moreover have "{..<e} = \<Union>{{..<x}|x. x \<in> \<rat> \<and> x < e}" "{e<..} = \<Union>{{x<..}|x. x \<in> \<rat> \<and> e < x}"
        by (auto dest: ereal_dense3
                 simp del: ex_simps
                 simp add: ex_simps[symmetric] conj_commute Rats_def image_iff)
      ultimately show ?case
        by (auto intro: generate_topology.intros)
    qed (auto intro: generate_topology.intros)
  next
    fix S assume "generate_topology ?B S" then show "open S" by induct auto
  qed
qed

lemma continuous_on_ereal[intro, simp]: "continuous_on A ereal"
  unfolding continuous_on_topological open_ereal_def by auto

lemma continuous_at_ereal[intro, simp]: "continuous (at x) ereal"
  using continuous_on_eq_continuous_at[of UNIV] by auto

lemma continuous_within_ereal[intro, simp]: "x \<in> A \<Longrightarrow> continuous (at x within A) ereal"
  using continuous_on_eq_continuous_within[of A] by auto

lemma ereal_open_uminus:
  fixes S :: "ereal set"
  assumes "open S" shows "open (uminus ` S)"
  using `open S`[unfolded open_generated_order]
proof induct
  have "range uminus = (UNIV :: ereal set)"
    by (auto simp: image_iff ereal_uminus_eq_reorder)
  then show "open (range uminus :: ereal set)" by simp
qed (auto simp add: image_Union image_Int)

lemma ereal_uminus_complement:
  fixes S :: "ereal set"
  shows "uminus ` (- S) = - uminus ` S"
  by (auto intro!: bij_image_Compl_eq surjI[of _ uminus] simp: bij_betw_def)

lemma ereal_closed_uminus:
  fixes S :: "ereal set"
  assumes "closed S"
  shows "closed (uminus ` S)"
  using assms unfolding closed_def ereal_uminus_complement[symmetric] by (rule ereal_open_uminus)

lemma ereal_open_closed_aux:
  fixes S :: "ereal set"
  assumes "open S" "closed S"
    and S: "(-\<infinity>) ~: S"
  shows "S = {}"
proof (rule ccontr)
  assume "S ~= {}"
  then have *: "(Inf S):S" by (metis assms(2) closed_contains_Inf_cl)
  { assume "Inf S=(-\<infinity>)"
    then have False using * assms(3) by auto }
  moreover
  { assume "Inf S=\<infinity>"
    then have "S={\<infinity>}" by (metis Inf_eq_PInfty `S ~= {}`)
    then have False by (metis assms(1) not_open_singleton) }
  moreover
  { assume fin: "\<bar>Inf S\<bar> \<noteq> \<infinity>"
    from ereal_open_cont_interval[OF assms(1) * fin] guess e . note e = this
    then obtain b where b_def: "Inf S-e<b & b<Inf S"
      using fin ereal_between[of "Inf S" e] dense[of "Inf S-e"] by auto
    then have "b: {Inf S-e <..< Inf S+e}" using e fin ereal_between[of "Inf S" e]
      by auto
    then have "b:S" using e by auto
    then have False using b_def by (metis complete_lattice_class.Inf_lower leD)
  } ultimately show False by auto
qed

lemma ereal_open_closed:
  fixes S :: "ereal set"
  shows "(open S & closed S) <-> (S = {} | S = UNIV)"
proof -
  { assume lhs: "open S & closed S"
    { assume "(-\<infinity>) ~: S"
      then have "S={}" using lhs ereal_open_closed_aux by auto }
    moreover
    { assume "(-\<infinity>) : S"
      then have "(- S)={}" using lhs ereal_open_closed_aux[of "-S"] by auto }
    ultimately have "S = {} | S = UNIV" by auto
  } then show ?thesis by auto
qed

lemma ereal_open_affinity_pos:
  fixes S :: "ereal set"
  assumes "open S" and m: "m \<noteq> \<infinity>" "0 < m" and t: "\<bar>t\<bar> \<noteq> \<infinity>"
  shows "open ((\<lambda>x. m * x + t) ` S)"
proof -
  obtain r where r[simp]: "m = ereal r" using m by (cases m) auto
  obtain p where p[simp]: "t = ereal p" using t by auto
  have "r \<noteq> 0" "0 < r" and m': "m \<noteq> \<infinity>" "m \<noteq> -\<infinity>" "m \<noteq> 0" using m by auto
  from `open S`[THEN ereal_openE] guess l u . note T = this
  let ?f = "(\<lambda>x. m * x + t)"
  show ?thesis
    unfolding open_ereal_def
  proof (intro conjI impI exI subsetI)
    have "ereal -` ?f ` S = (\<lambda>x. r * x + p) ` (ereal -` S)"
    proof safe
      fix x y
      assume "ereal y = m * x + t" "x \<in> S"
      then show "y \<in> (\<lambda>x. r * x + p) ` ereal -` S"
        using `r \<noteq> 0` by (cases x) (auto intro!: image_eqI[of _ _ "real x"] split: split_if_asm)
    qed force
    then show "open (ereal -` ?f ` S)"
      using open_affinity[OF T(1) `r \<noteq> 0`] by (auto simp: ac_simps)
  next
    assume "\<infinity> \<in> ?f`S"
    with `0 < r` have "\<infinity> \<in> S" by auto
    fix x
    assume "x \<in> {ereal (r * l + p)<..}"
    then have [simp]: "ereal (r * l + p) < x" by auto
    show "x \<in> ?f`S"
    proof (rule image_eqI)
      show "x = m * ((x - t) / m) + t"
        using m t by (cases rule: ereal3_cases[of m x t]) auto
      have "ereal l < (x - t)/m"
        using m t by (simp add: ereal_less_divide_pos ereal_less_minus)
      then show "(x - t)/m \<in> S" using T(2)[OF `\<infinity> \<in> S`] by auto
    qed
  next
    assume "-\<infinity> \<in> ?f`S" with `0 < r` have "-\<infinity> \<in> S" by auto
    fix x assume "x \<in> {..<ereal (r * u + p)}"
    then have [simp]: "x < ereal (r * u + p)" by auto
    show "x \<in> ?f`S"
    proof (rule image_eqI)
      show "x = m * ((x - t) / m) + t"
        using m t by (cases rule: ereal3_cases[of m x t]) auto
      have "(x - t)/m < ereal u"
        using m t by (simp add: ereal_divide_less_pos ereal_minus_less)
      then show "(x - t)/m \<in> S" using T(3)[OF `-\<infinity> \<in> S`] by auto
    qed
  qed
qed

lemma ereal_open_affinity:
  fixes S :: "ereal set"
  assumes "open S"
    and m: "\<bar>m\<bar> \<noteq> \<infinity>" "m \<noteq> 0"
    and t: "\<bar>t\<bar> \<noteq> \<infinity>"
  shows "open ((\<lambda>x. m * x + t) ` S)"
proof cases
  assume "0 < m"
  then show ?thesis
    using ereal_open_affinity_pos[OF `open S` _ _ t, of m] m by auto
next
  assume "\<not> 0 < m" then
  have "0 < -m" using `m \<noteq> 0` by (cases m) auto
  then have m: "-m \<noteq> \<infinity>" "0 < -m" using `\<bar>m\<bar> \<noteq> \<infinity>`
    by (auto simp: ereal_uminus_eq_reorder)
  from ereal_open_affinity_pos[OF ereal_open_uminus[OF `open S`] m t]
  show ?thesis unfolding image_image by simp
qed

lemma ereal_lim_mult:
  fixes X :: "'a \<Rightarrow> ereal"
  assumes lim: "(X ---> L) net"
    and a: "\<bar>a\<bar> \<noteq> \<infinity>"
  shows "((\<lambda>i. a * X i) ---> a * L) net"
proof cases
  assume "a \<noteq> 0"
  show ?thesis
  proof (rule topological_tendstoI)
    fix S
    assume "open S" "a * L \<in> S"
    have "a * L / a = L"
      using `a \<noteq> 0` a by (cases rule: ereal2_cases[of a L]) auto
    then have L: "L \<in> ((\<lambda>x. x / a) ` S)"
      using `a * L \<in> S` by (force simp: image_iff)
    moreover have "open ((\<lambda>x. x / a) ` S)"
      using ereal_open_affinity[OF `open S`, of "inverse a" 0] `a \<noteq> 0` a
      by (auto simp: ereal_divide_eq ereal_inverse_eq_0 divide_ereal_def ac_simps)
    note * = lim[THEN topological_tendstoD, OF this L]
    { fix x
      from a `a \<noteq> 0` have "a * (x / a) = x"
        by (cases rule: ereal2_cases[of a x]) auto }
    note this[simp]
    show "eventually (\<lambda>x. a * X x \<in> S) net"
      by (rule eventually_mono[OF _ *]) auto
  qed
qed auto

lemma ereal_lim_uminus:
  fixes X :: "'a \<Rightarrow> ereal"
  shows "((\<lambda>i. - X i) ---> -L) net \<longleftrightarrow> (X ---> L) net"
  using ereal_lim_mult[of X L net "ereal (-1)"]
    ereal_lim_mult[of "(\<lambda>i. - X i)" "-L" net "ereal (-1)"]
  by (auto simp add: algebra_simps)

lemma ereal_open_atLeast: fixes x :: ereal shows "open {x..} \<longleftrightarrow> x = -\<infinity>"
proof
  assume "x = -\<infinity>" then have "{x..} = UNIV" by auto
  then show "open {x..}" by auto
next
  assume "open {x..}"
  then have "open {x..} \<and> closed {x..}" by auto
  then have "{x..} = UNIV" unfolding ereal_open_closed by auto
  then show "x = -\<infinity>" by (simp add: bot_ereal_def atLeast_eq_UNIV_iff)
qed

lemma open_uminus_iff: "open (uminus ` S) \<longleftrightarrow> open (S::ereal set)"
  using ereal_open_uminus[of S] ereal_open_uminus[of "uminus`S"] by auto

lemma ereal_Liminf_uminus:
  fixes f :: "'a => ereal"
  shows "Liminf net (\<lambda>x. - (f x)) = -(Limsup net f)"
  using ereal_Limsup_uminus[of _ "(\<lambda>x. - (f x))"] by auto

lemma ereal_Lim_uminus:
  fixes f :: "'a \<Rightarrow> ereal"
  shows "(f ---> f0) net \<longleftrightarrow> ((\<lambda>x. - f x) ---> - f0) net"
  using
    ereal_lim_mult[of f f0 net "- 1"]
    ereal_lim_mult[of "\<lambda>x. - (f x)" "-f0" net "- 1"]
  by (auto simp: ereal_uminus_reorder)

lemma Liminf_PInfty:
  fixes f :: "'a \<Rightarrow> ereal"
  assumes "\<not> trivial_limit net"
  shows "(f ---> \<infinity>) net \<longleftrightarrow> Liminf net f = \<infinity>"
  unfolding tendsto_iff_Liminf_eq_Limsup[OF assms] using Liminf_le_Limsup[OF assms, of f] by auto

lemma Limsup_MInfty:
  fixes f :: "'a \<Rightarrow> ereal"
  assumes "\<not> trivial_limit net"
  shows "(f ---> -\<infinity>) net \<longleftrightarrow> Limsup net f = -\<infinity>"
  unfolding tendsto_iff_Liminf_eq_Limsup[OF assms] using Liminf_le_Limsup[OF assms, of f] by auto

lemma convergent_ereal:
  fixes X :: "nat \<Rightarrow> 'a :: {complete_linorder, linorder_topology}"
  shows "convergent X \<longleftrightarrow> limsup X = liminf X"
  using tendsto_iff_Liminf_eq_Limsup[of sequentially]
  by (auto simp: convergent_def)

lemma liminf_PInfty:
  fixes X :: "nat \<Rightarrow> ereal"
  shows "X ----> \<infinity> \<longleftrightarrow> liminf X = \<infinity>"
  by (metis Liminf_PInfty trivial_limit_sequentially)

lemma limsup_MInfty:
  fixes X :: "nat \<Rightarrow> ereal"
  shows "X ----> -\<infinity> \<longleftrightarrow> limsup X = -\<infinity>"
  by (metis Limsup_MInfty trivial_limit_sequentially)

lemma ereal_lim_mono:
  fixes X Y :: "nat => 'a::linorder_topology"
  assumes "\<And>n. N \<le> n \<Longrightarrow> X n <= Y n"
    and "X ----> x" "Y ----> y"
  shows "x <= y"
  using assms(1) by (intro LIMSEQ_le[OF assms(2,3)]) auto

lemma incseq_le_ereal:
  fixes X :: "nat \<Rightarrow> 'a::linorder_topology"
  assumes inc: "incseq X" and lim: "X ----> L"
  shows "X N \<le> L"
  using inc by (intro ereal_lim_mono[of N, OF _ tendsto_const lim]) (simp add: incseq_def)

lemma decseq_ge_ereal:
  assumes dec: "decseq X"
    and lim: "X ----> (L::'a::linorder_topology)"
  shows "X N >= L"
  using dec by (intro ereal_lim_mono[of N, OF _ lim tendsto_const]) (simp add: decseq_def)

lemma bounded_abs:
  assumes "(a::real)<=x" "x<=b"
  shows "abs x <= max (abs a) (abs b)"
  by (metis abs_less_iff assms leI le_max_iff_disj
    less_eq_real_def less_le_not_le less_minus_iff minus_minus)

lemma ereal_Sup_lim:
  assumes "\<And>n. b n \<in> s" "b ----> (a::'a::{complete_linorder, linorder_topology})"
  shows "a \<le> Sup s"
  by (metis Lim_bounded_ereal assms complete_lattice_class.Sup_upper)

lemma ereal_Inf_lim:
  assumes "\<And>n. b n \<in> s" "b ----> (a::'a::{complete_linorder, linorder_topology})"
  shows "Inf s \<le> a"
  by (metis Lim_bounded2_ereal assms complete_lattice_class.Inf_lower)

lemma SUP_Lim_ereal:
  fixes X :: "nat \<Rightarrow> 'a::{complete_linorder, linorder_topology}"
  assumes inc: "incseq X" and l: "X ----> l" shows "(SUP n. X n) = l"
  using LIMSEQ_SUP[OF inc] tendsto_unique[OF trivial_limit_sequentially l] by simp

lemma INF_Lim_ereal:
  fixes X :: "nat \<Rightarrow> 'a::{complete_linorder, linorder_topology}"
  assumes dec: "decseq X" and l: "X ----> l" shows "(INF n. X n) = l"
  using LIMSEQ_INF[OF dec] tendsto_unique[OF trivial_limit_sequentially l] by simp

lemma SUP_eq_LIMSEQ:
  assumes "mono f"
  shows "(SUP n. ereal (f n)) = ereal x \<longleftrightarrow> f ----> x"
proof
  have inc: "incseq (\<lambda>i. ereal (f i))"
    using `mono f` unfolding mono_def incseq_def by auto
  { assume "f ----> x"
    then have "(\<lambda>i. ereal (f i)) ----> ereal x" by auto
    from SUP_Lim_ereal[OF inc this]
    show "(SUP n. ereal (f n)) = ereal x" . }
  { assume "(SUP n. ereal (f n)) = ereal x"
    with LIMSEQ_SUP[OF inc]
    show "f ----> x" by auto }
qed

lemma liminf_ereal_cminus:
  fixes f :: "nat \<Rightarrow> ereal"
  assumes "c \<noteq> -\<infinity>"
  shows "liminf (\<lambda>x. c - f x) = c - limsup f"
proof (cases c)
  case PInf
  then show ?thesis by (simp add: Liminf_const)
next
  case (real r)
  then show ?thesis
    unfolding liminf_SUPR_INFI limsup_INFI_SUPR
    apply (subst INFI_ereal_cminus)
    apply auto
    apply (subst SUPR_ereal_cminus)
    apply auto
    done
qed (insert `c \<noteq> -\<infinity>`, simp)


subsubsection {* Continuity *}

lemma continuous_at_of_ereal:
  fixes x0 :: ereal
  assumes "\<bar>x0\<bar> \<noteq> \<infinity>"
  shows "continuous (at x0) real"
proof -
  { fix T
    assume T_def: "open T & real x0 : T"
    def S == "ereal ` T"
    then have "ereal (real x0) : S" using T_def by auto
    then have "x0 : S" using assms ereal_real by auto
    moreover have "open S" using open_ereal S_def T_def by auto
    moreover have "ALL y:S. real y : T" using S_def T_def by auto
    ultimately have "EX S. x0 : S & open S & (ALL y:S. real y : T)" by auto
  }
  then show ?thesis unfolding continuous_at_open by blast
qed


lemma continuous_at_iff_ereal:
  fixes f :: "'a::t2_space => real"
  shows "continuous (at x0) f <-> continuous (at x0) (ereal o f)"
proof -
  { assume "continuous (at x0) f"
    then have "continuous (at x0) (ereal o f)"
      using continuous_at_ereal continuous_at_compose[of x0 f ereal] by auto
  }
  moreover
  { assume "continuous (at x0) (ereal o f)"
    then have "continuous (at x0) (real o (ereal o f))"
      using continuous_at_of_ereal by (intro continuous_at_compose[of x0 "ereal o f"]) auto
    moreover have "real o (ereal o f) = f" using real_ereal_id by (simp add: o_assoc)
    ultimately have "continuous (at x0) f" by auto
  } ultimately show ?thesis by auto
qed


lemma continuous_on_iff_ereal:
  fixes f :: "'a::t2_space => real"
  fixes A assumes "open A"
  shows "continuous_on A f <-> continuous_on A (ereal o f)"
  using continuous_at_iff_ereal assms by (auto simp add: continuous_on_eq_continuous_at)


lemma continuous_on_real: "continuous_on (UNIV-{\<infinity>,(-\<infinity>::ereal)}) real"
  using continuous_at_of_ereal continuous_on_eq_continuous_at open_image_ereal by auto


lemma continuous_on_iff_real:
  fixes f :: "'a::t2_space => ereal"
  assumes "\<And>x. x \<in> A \<Longrightarrow> \<bar>f x\<bar> \<noteq> \<infinity>"
  shows "continuous_on A f \<longleftrightarrow> continuous_on A (real \<circ> f)"
proof -
  have "f ` A <= UNIV-{\<infinity>,(-\<infinity>)}" using assms by force
  then have *: "continuous_on (f ` A) real"
    using continuous_on_real by (simp add: continuous_on_subset)
  have **: "continuous_on ((real o f) ` A) ereal"
    using continuous_on_ereal continuous_on_subset[of "UNIV" "ereal" "(real o f) ` A"] by blast
  { assume "continuous_on A f"
    then have "continuous_on A (real o f)"
      apply (subst continuous_on_compose)
      using * apply auto
      done
  }
  moreover
  { assume "continuous_on A (real o f)"
    then have "continuous_on A (ereal o (real o f))"
      apply (subst continuous_on_compose)
      using ** apply auto
      done
    then have "continuous_on A f"
      apply (subst continuous_on_eq[of A "ereal o (real o f)" f])
      using assms ereal_real apply auto
      done
  }
  ultimately show ?thesis by auto
qed


lemma continuous_at_const:
  fixes f :: "'a::t2_space => ereal"
  assumes "ALL x. (f x = C)"
  shows "ALL x. continuous (at x) f"
  unfolding continuous_at_open using assms t1_space by auto


lemma mono_closed_real:
  fixes S :: "real set"
  assumes mono: "ALL y z. y:S & y<=z --> z:S"
    and "closed S"
  shows "S = {} | S = UNIV | (EX a. S = {a ..})"
proof -
  { assume "S ~= {}"
    { assume ex: "EX B. ALL x:S. B<=x"
      then have *: "ALL x:S. Inf S <= x" using cInf_lower_EX[of _ S] ex by metis
      then have "Inf S : S" apply (subst closed_contains_Inf) using ex `S ~= {}` `closed S` by auto
      then have "ALL x. (Inf S <= x <-> x:S)" using mono[rule_format, of "Inf S"] * by auto
      then have "S = {Inf S ..}" by auto
      then have "EX a. S = {a ..}" by auto
    }
    moreover
    { assume "~(EX B. ALL x:S. B<=x)"
      then have nex: "ALL B. EX x:S. x<B" by (simp add: not_le)
      { fix y
        obtain x where "x:S & x < y" using nex by auto
        then have "y:S" using mono[rule_format, of x y] by auto
      } then have "S = UNIV" by auto
    }
    ultimately have "S = UNIV | (EX a. S = {a ..})" by blast
  } then show ?thesis by blast
qed


lemma mono_closed_ereal:
  fixes S :: "real set"
  assumes mono: "ALL y z. y:S & y<=z --> z:S"
    and "closed S"
  shows "EX a. S = {x. a <= ereal x}"
proof -
  { assume "S = {}"
    then have ?thesis apply(rule_tac x=PInfty in exI) by auto }
  moreover
  { assume "S = UNIV"
    then have ?thesis apply(rule_tac x="-\<infinity>" in exI) by auto }
  moreover
  { assume "EX a. S = {a ..}"
    then obtain a where "S={a ..}" by auto
    then have ?thesis apply(rule_tac x="ereal a" in exI) by auto
  }
  ultimately show ?thesis using mono_closed_real[of S] assms by auto
qed

subsection {* Sums *}

lemma setsum_ereal[simp]: "(\<Sum>x\<in>A. ereal (f x)) = ereal (\<Sum>x\<in>A. f x)"
proof cases
  assume "finite A"
  then show ?thesis by induct auto
qed simp

lemma setsum_Pinfty:
  fixes f :: "'a \<Rightarrow> ereal"
  shows "(\<Sum>x\<in>P. f x) = \<infinity> \<longleftrightarrow> (finite P \<and> (\<exists>i\<in>P. f i = \<infinity>))"
proof safe
  assume *: "setsum f P = \<infinity>"
  show "finite P"
  proof (rule ccontr) assume "infinite P" with * show False by auto qed
  show "\<exists>i\<in>P. f i = \<infinity>"
  proof (rule ccontr)
    assume "\<not> ?thesis" then have "\<And>i. i \<in> P \<Longrightarrow> f i \<noteq> \<infinity>" by auto
    from `finite P` this have "setsum f P \<noteq> \<infinity>"
      by induct auto
    with * show False by auto
  qed
next
  fix i assume "finite P" "i \<in> P" "f i = \<infinity>"
  then show "setsum f P = \<infinity>"
  proof induct
    case (insert x A)
    show ?case using insert by (cases "x = i") auto
  qed simp
qed

lemma setsum_Inf:
  fixes f :: "'a \<Rightarrow> ereal"
  shows "\<bar>setsum f A\<bar> = \<infinity> \<longleftrightarrow> (finite A \<and> (\<exists>i\<in>A. \<bar>f i\<bar> = \<infinity>))"
proof
  assume *: "\<bar>setsum f A\<bar> = \<infinity>"
  have "finite A" by (rule ccontr) (insert *, auto)
  moreover have "\<exists>i\<in>A. \<bar>f i\<bar> = \<infinity>"
  proof (rule ccontr)
    assume "\<not> ?thesis" then have "\<forall>i\<in>A. \<exists>r. f i = ereal r" by auto
    from bchoice[OF this] guess r ..
    with * show False by auto
  qed
  ultimately show "finite A \<and> (\<exists>i\<in>A. \<bar>f i\<bar> = \<infinity>)" by auto
next
  assume "finite A \<and> (\<exists>i\<in>A. \<bar>f i\<bar> = \<infinity>)"
  then obtain i where "finite A" "i \<in> A" "\<bar>f i\<bar> = \<infinity>" by auto
  then show "\<bar>setsum f A\<bar> = \<infinity>"
  proof induct
    case (insert j A) then show ?case
      by (cases rule: ereal3_cases[of "f i" "f j" "setsum f A"]) auto
  qed simp
qed

lemma setsum_real_of_ereal:
  fixes f :: "'i \<Rightarrow> ereal"
  assumes "\<And>x. x \<in> S \<Longrightarrow> \<bar>f x\<bar> \<noteq> \<infinity>"
  shows "(\<Sum>x\<in>S. real (f x)) = real (setsum f S)"
proof -
  have "\<forall>x\<in>S. \<exists>r. f x = ereal r"
  proof
    fix x assume "x \<in> S"
    from assms[OF this] show "\<exists>r. f x = ereal r" by (cases "f x") auto
  qed
  from bchoice[OF this] guess r ..
  then show ?thesis by simp
qed

lemma setsum_ereal_0:
  fixes f :: "'a \<Rightarrow> ereal" assumes "finite A" "\<And>i. i \<in> A \<Longrightarrow> 0 \<le> f i"
  shows "(\<Sum>x\<in>A. f x) = 0 \<longleftrightarrow> (\<forall>i\<in>A. f i = 0)"
proof
  assume *: "(\<Sum>x\<in>A. f x) = 0"
  then have "(\<Sum>x\<in>A. f x) \<noteq> \<infinity>" by auto
  then have "\<forall>i\<in>A. \<bar>f i\<bar> \<noteq> \<infinity>" using assms by (force simp: setsum_Pinfty)
  then have "\<forall>i\<in>A. \<exists>r. f i = ereal r" by auto
  from bchoice[OF this] * assms show "\<forall>i\<in>A. f i = 0"
    using setsum_nonneg_eq_0_iff[of A "\<lambda>i. real (f i)"] by auto
qed (rule setsum_0')


lemma setsum_ereal_right_distrib:
  fixes f :: "'a \<Rightarrow> ereal"
  assumes "\<And>i. i \<in> A \<Longrightarrow> 0 \<le> f i"
  shows "r * setsum f A = (\<Sum>n\<in>A. r * f n)"
proof cases
  assume "finite A"
  then show ?thesis using assms
    by induct (auto simp: ereal_right_distrib setsum_nonneg)
qed simp

lemma sums_ereal_positive:
  fixes f :: "nat \<Rightarrow> ereal"
  assumes "\<And>i. 0 \<le> f i"
  shows "f sums (SUP n. \<Sum>i<n. f i)"
proof -
  have "incseq (\<lambda>i. \<Sum>j=0..<i. f j)"
    using ereal_add_mono[OF _ assms] by (auto intro!: incseq_SucI)
  from LIMSEQ_SUP[OF this]
  show ?thesis unfolding sums_def by (simp add: atLeast0LessThan)
qed

lemma summable_ereal_pos:
  fixes f :: "nat \<Rightarrow> ereal"
  assumes "\<And>i. 0 \<le> f i"
  shows "summable f"
  using sums_ereal_positive[of f, OF assms] unfolding summable_def by auto

lemma suminf_ereal_eq_SUPR:
  fixes f :: "nat \<Rightarrow> ereal"
  assumes "\<And>i. 0 \<le> f i"
  shows "(\<Sum>x. f x) = (SUP n. \<Sum>i<n. f i)"
  using sums_ereal_positive[of f, OF assms, THEN sums_unique] by simp

lemma sums_ereal: "(\<lambda>x. ereal (f x)) sums ereal x \<longleftrightarrow> f sums x"
  unfolding sums_def by simp

lemma suminf_bound:
  fixes f :: "nat \<Rightarrow> ereal"
  assumes "\<forall>N. (\<Sum>n<N. f n) \<le> x" and pos: "\<And>n. 0 \<le> f n"
  shows "suminf f \<le> x"
proof (rule Lim_bounded_ereal)
  have "summable f" using pos[THEN summable_ereal_pos] .
  then show "(\<lambda>N. \<Sum>n<N. f n) ----> suminf f"
    by (auto dest!: summable_sums simp: sums_def atLeast0LessThan)
  show "\<forall>n\<ge>0. setsum f {..<n} \<le> x"
    using assms by auto
qed

lemma suminf_bound_add:
  fixes f :: "nat \<Rightarrow> ereal"
  assumes "\<forall>N. (\<Sum>n<N. f n) + y \<le> x"
    and pos: "\<And>n. 0 \<le> f n"
    and "y \<noteq> -\<infinity>"
  shows "suminf f + y \<le> x"
proof (cases y)
  case (real r)
  then have "\<forall>N. (\<Sum>n<N. f n) \<le> x - y"
    using assms by (simp add: ereal_le_minus)
  then have "(\<Sum> n. f n) \<le> x - y" using pos by (rule suminf_bound)
  then show "(\<Sum> n. f n) + y \<le> x"
    using assms real by (simp add: ereal_le_minus)
qed (insert assms, auto)

lemma suminf_upper:
  fixes f :: "nat \<Rightarrow> ereal"
  assumes "\<And>n. 0 \<le> f n"
  shows "(\<Sum>n<N. f n) \<le> (\<Sum>n. f n)"
  unfolding suminf_ereal_eq_SUPR[OF assms] SUP_def
  by (auto intro: complete_lattice_class.Sup_upper)

lemma suminf_0_le:
  fixes f :: "nat \<Rightarrow> ereal"
  assumes "\<And>n. 0 \<le> f n"
  shows "0 \<le> (\<Sum>n. f n)"
  using suminf_upper[of f 0, OF assms] by simp

lemma suminf_le_pos:
  fixes f g :: "nat \<Rightarrow> ereal"
  assumes "\<And>N. f N \<le> g N" "\<And>N. 0 \<le> f N"
  shows "suminf f \<le> suminf g"
proof (safe intro!: suminf_bound)
  fix n
  { fix N have "0 \<le> g N" using assms(2,1)[of N] by auto }
  have "setsum f {..<n} \<le> setsum g {..<n}"
    using assms by (auto intro: setsum_mono)
  also have "... \<le> suminf g" using `\<And>N. 0 \<le> g N` by (rule suminf_upper)
  finally show "setsum f {..<n} \<le> suminf g" .
qed (rule assms(2))

lemma suminf_half_series_ereal: "(\<Sum>n. (1/2 :: ereal)^Suc n) = 1"
  using sums_ereal[THEN iffD2, OF power_half_series, THEN sums_unique, symmetric]
  by (simp add: one_ereal_def)

lemma suminf_add_ereal:
  fixes f g :: "nat \<Rightarrow> ereal"
  assumes "\<And>i. 0 \<le> f i" "\<And>i. 0 \<le> g i"
  shows "(\<Sum>i. f i + g i) = suminf f + suminf g"
  apply (subst (1 2 3) suminf_ereal_eq_SUPR)
  unfolding setsum_addf
  apply (intro assms ereal_add_nonneg_nonneg SUPR_ereal_add_pos incseq_setsumI setsum_nonneg ballI)+
  done

lemma suminf_cmult_ereal:
  fixes f g :: "nat \<Rightarrow> ereal"
  assumes "\<And>i. 0 \<le> f i" "0 \<le> a"
  shows "(\<Sum>i. a * f i) = a * suminf f"
  by (auto simp: setsum_ereal_right_distrib[symmetric] assms
                 ereal_zero_le_0_iff setsum_nonneg suminf_ereal_eq_SUPR
           intro!: SUPR_ereal_cmult )

lemma suminf_PInfty:
  fixes f :: "nat \<Rightarrow> ereal"
  assumes "\<And>i. 0 \<le> f i" "suminf f \<noteq> \<infinity>"
  shows "f i \<noteq> \<infinity>"
proof -
  from suminf_upper[of f "Suc i", OF assms(1)] assms(2)
  have "(\<Sum>i<Suc i. f i) \<noteq> \<infinity>" by auto
  then show ?thesis unfolding setsum_Pinfty by simp
qed

lemma suminf_PInfty_fun:
  assumes "\<And>i. 0 \<le> f i" "suminf f \<noteq> \<infinity>"
  shows "\<exists>f'. f = (\<lambda>x. ereal (f' x))"
proof -
  have "\<forall>i. \<exists>r. f i = ereal r"
  proof
    fix i show "\<exists>r. f i = ereal r"
      using suminf_PInfty[OF assms] assms(1)[of i] by (cases "f i") auto
  qed
  from choice[OF this] show ?thesis by auto
qed

lemma summable_ereal:
  assumes "\<And>i. 0 \<le> f i" "(\<Sum>i. ereal (f i)) \<noteq> \<infinity>"
  shows "summable f"
proof -
  have "0 \<le> (\<Sum>i. ereal (f i))"
    using assms by (intro suminf_0_le) auto
  with assms obtain r where r: "(\<Sum>i. ereal (f i)) = ereal r"
    by (cases "\<Sum>i. ereal (f i)") auto
  from summable_ereal_pos[of "\<lambda>x. ereal (f x)"]
  have "summable (\<lambda>x. ereal (f x))" using assms by auto
  from summable_sums[OF this]
  have "(\<lambda>x. ereal (f x)) sums (\<Sum>x. ereal (f x))" by auto
  then show "summable f"
    unfolding r sums_ereal summable_def ..
qed

lemma suminf_ereal:
  assumes "\<And>i. 0 \<le> f i" "(\<Sum>i. ereal (f i)) \<noteq> \<infinity>"
  shows "(\<Sum>i. ereal (f i)) = ereal (suminf f)"
proof (rule sums_unique[symmetric])
  from summable_ereal[OF assms]
  show "(\<lambda>x. ereal (f x)) sums (ereal (suminf f))"
    unfolding sums_ereal using assms by (intro summable_sums summable_ereal)
qed

lemma suminf_ereal_minus:
  fixes f g :: "nat \<Rightarrow> ereal"
  assumes ord: "\<And>i. g i \<le> f i" "\<And>i. 0 \<le> g i" and fin: "suminf f \<noteq> \<infinity>" "suminf g \<noteq> \<infinity>"
  shows "(\<Sum>i. f i - g i) = suminf f - suminf g"
proof -
  { fix i have "0 \<le> f i" using ord[of i] by auto }
  moreover
  from suminf_PInfty_fun[OF `\<And>i. 0 \<le> f i` fin(1)] guess f' .. note this[simp]
  from suminf_PInfty_fun[OF `\<And>i. 0 \<le> g i` fin(2)] guess g' .. note this[simp]
  { fix i have "0 \<le> f i - g i" using ord[of i] by (auto simp: ereal_le_minus_iff) }
  moreover
  have "suminf (\<lambda>i. f i - g i) \<le> suminf f"
    using assms by (auto intro!: suminf_le_pos simp: field_simps)
  then have "suminf (\<lambda>i. f i - g i) \<noteq> \<infinity>" using fin by auto
  ultimately show ?thesis using assms `\<And>i. 0 \<le> f i`
    apply simp
    apply (subst (1 2 3) suminf_ereal)
    apply (auto intro!: suminf_diff[symmetric] summable_ereal)
    done
qed

lemma suminf_ereal_PInf [simp]: "(\<Sum>x. \<infinity>::ereal) = \<infinity>"
proof -
  have "(\<Sum>i<Suc 0. \<infinity>) \<le> (\<Sum>x. \<infinity>::ereal)" by (rule suminf_upper) auto
  then show ?thesis by simp
qed

lemma summable_real_of_ereal:
  fixes f :: "nat \<Rightarrow> ereal"
  assumes f: "\<And>i. 0 \<le> f i"
    and fin: "(\<Sum>i. f i) \<noteq> \<infinity>"
  shows "summable (\<lambda>i. real (f i))"
proof (rule summable_def[THEN iffD2])
  have "0 \<le> (\<Sum>i. f i)" using assms by (auto intro: suminf_0_le)
  with fin obtain r where r: "ereal r = (\<Sum>i. f i)" by (cases "(\<Sum>i. f i)") auto
  { fix i have "f i \<noteq> \<infinity>" using f by (intro suminf_PInfty[OF _ fin]) auto
    then have "\<bar>f i\<bar> \<noteq> \<infinity>" using f[of i] by auto }
  note fin = this
  have "(\<lambda>i. ereal (real (f i))) sums (\<Sum>i. ereal (real (f i)))"
    using f by (auto intro!: summable_ereal_pos summable_sums simp: ereal_le_real_iff zero_ereal_def)
  also have "\<dots> = ereal r" using fin r by (auto simp: ereal_real)
  finally show "\<exists>r. (\<lambda>i. real (f i)) sums r" by (auto simp: sums_ereal)
qed

lemma suminf_SUP_eq:
  fixes f :: "nat \<Rightarrow> nat \<Rightarrow> ereal"
  assumes "\<And>i. incseq (\<lambda>n. f n i)" "\<And>n i. 0 \<le> f n i"
  shows "(\<Sum>i. SUP n. f n i) = (SUP n. \<Sum>i. f n i)"
proof -
  { fix n :: nat
    have "(\<Sum>i<n. SUP k. f k i) = (SUP k. \<Sum>i<n. f k i)"
      using assms by (auto intro!: SUPR_ereal_setsum[symmetric]) }
  note * = this
  show ?thesis using assms
    apply (subst (1 2) suminf_ereal_eq_SUPR)
    unfolding *
    apply (auto intro!: SUP_upper2)
    apply (subst SUP_commute)
    apply rule
    done
qed

lemma suminf_setsum_ereal:
  fixes f :: "_ \<Rightarrow> _ \<Rightarrow> ereal"
  assumes nonneg: "\<And>i a. a \<in> A \<Longrightarrow> 0 \<le> f i a"
  shows "(\<Sum>i. \<Sum>a\<in>A. f i a) = (\<Sum>a\<in>A. \<Sum>i. f i a)"
proof cases
  assume "finite A"
  then show ?thesis using nonneg
    by induct (simp_all add: suminf_add_ereal setsum_nonneg)
qed simp

lemma suminf_ereal_eq_0:
  fixes f :: "nat \<Rightarrow> ereal"
  assumes nneg: "\<And>i. 0 \<le> f i"
  shows "(\<Sum>i. f i) = 0 \<longleftrightarrow> (\<forall>i. f i = 0)"
proof
  assume "(\<Sum>i. f i) = 0"
  { fix i assume "f i \<noteq> 0"
    with nneg have "0 < f i" by (auto simp: less_le)
    also have "f i = (\<Sum>j. if j = i then f i else 0)"
      by (subst suminf_finite[where N="{i}"]) auto
    also have "\<dots> \<le> (\<Sum>i. f i)"
      using nneg by (auto intro!: suminf_le_pos)
    finally have False using `(\<Sum>i. f i) = 0` by auto }
  then show "\<forall>i. f i = 0" by auto
qed simp

lemma Liminf_within:
  fixes f :: "'a::metric_space \<Rightarrow> 'b::complete_lattice"
  shows "Liminf (at x within S) f = (SUP e:{0<..}. INF y:(S \<inter> ball x e - {x}). f y)"
  unfolding Liminf_def eventually_within
proof (rule SUPR_eq, simp_all add: Ball_def Bex_def, safe)
  fix P d assume "0 < d" "\<forall>y. y \<in> S \<longrightarrow> 0 < dist y x \<and> dist y x < d \<longrightarrow> P y"
  then have "S \<inter> ball x d - {x} \<subseteq> {x. P x}"
    by (auto simp: zero_less_dist_iff dist_commute)
  then show "\<exists>r>0. INFI (Collect P) f \<le> INFI (S \<inter> ball x r - {x}) f"
    by (intro exI[of _ d] INF_mono conjI `0 < d`) auto
next
  fix d :: real assume "0 < d"
  then show "\<exists>P. (\<exists>d>0. \<forall>xa. xa \<in> S \<longrightarrow> 0 < dist xa x \<and> dist xa x < d \<longrightarrow> P xa) \<and>
    INFI (S \<inter> ball x d - {x}) f \<le> INFI (Collect P) f"
    by (intro exI[of _ "\<lambda>y. y \<in> S \<inter> ball x d - {x}"])
       (auto intro!: INF_mono exI[of _ d] simp: dist_commute)
qed

lemma Limsup_within:
  fixes f :: "'a::metric_space => 'b::complete_lattice"
  shows "Limsup (at x within S) f = (INF e:{0<..}. SUP y:(S \<inter> ball x e - {x}). f y)"
  unfolding Limsup_def eventually_within
proof (rule INFI_eq, simp_all add: Ball_def Bex_def, safe)
  fix P d assume "0 < d" "\<forall>y. y \<in> S \<longrightarrow> 0 < dist y x \<and> dist y x < d \<longrightarrow> P y"
  then have "S \<inter> ball x d - {x} \<subseteq> {x. P x}"
    by (auto simp: zero_less_dist_iff dist_commute)
  then show "\<exists>r>0. SUPR (S \<inter> ball x r - {x}) f \<le> SUPR (Collect P) f"
    by (intro exI[of _ d] SUP_mono conjI `0 < d`) auto
next
  fix d :: real assume "0 < d"
  then show "\<exists>P. (\<exists>d>0. \<forall>xa. xa \<in> S \<longrightarrow> 0 < dist xa x \<and> dist xa x < d \<longrightarrow> P xa) \<and>
    SUPR (Collect P) f \<le> SUPR (S \<inter> ball x d - {x}) f"
    by (intro exI[of _ "\<lambda>y. y \<in> S \<inter> ball x d - {x}"])
       (auto intro!: SUP_mono exI[of _ d] simp: dist_commute)
qed

lemma Liminf_at:
  fixes f :: "'a::metric_space => _"
  shows "Liminf (at x) f = (SUP e:{0<..}. INF y:(ball x e - {x}). f y)"
  using Liminf_within[of x UNIV f] by simp

lemma Limsup_at:
  fixes f :: "'a::metric_space => _"
  shows "Limsup (at x) f = (INF e:{0<..}. SUP y:(ball x e - {x}). f y)"
  using Limsup_within[of x UNIV f] by simp

lemma min_Liminf_at:
  fixes f :: "'a::metric_space => 'b::complete_linorder"
  shows "min (f x) (Liminf (at x) f) = (SUP e:{0<..}. INF y:ball x e. f y)"
  unfolding inf_min[symmetric] Liminf_at
  apply (subst inf_commute)
  apply (subst SUP_inf)
  apply (intro SUP_cong[OF refl])
  apply (cut_tac A="ball x b - {x}" and B="{x}" and M=f in INF_union)
  apply (simp add: INF_def del: inf_ereal_def)
  done

subsection {* monoset *}

definition (in order) mono_set:
  "mono_set S \<longleftrightarrow> (\<forall>x y. x \<le> y \<longrightarrow> x \<in> S \<longrightarrow> y \<in> S)"

lemma (in order) mono_greaterThan [intro, simp]: "mono_set {B<..}" unfolding mono_set by auto
lemma (in order) mono_atLeast [intro, simp]: "mono_set {B..}" unfolding mono_set by auto
lemma (in order) mono_UNIV [intro, simp]: "mono_set UNIV" unfolding mono_set by auto
lemma (in order) mono_empty [intro, simp]: "mono_set {}" unfolding mono_set by auto

lemma (in complete_linorder) mono_set_iff:
  fixes S :: "'a set"
  defines "a \<equiv> Inf S"
  shows "mono_set S \<longleftrightarrow> (S = {a <..} \<or> S = {a..})" (is "_ = ?c")
proof
  assume "mono_set S"
  then have mono: "\<And>x y. x \<le> y \<Longrightarrow> x \<in> S \<Longrightarrow> y \<in> S" by (auto simp: mono_set)
  show ?c
  proof cases
    assume "a \<in> S"
    show ?c
      using mono[OF _ `a \<in> S`]
      by (auto intro: Inf_lower simp: a_def)
  next
    assume "a \<notin> S"
    have "S = {a <..}"
    proof safe
      fix x assume "x \<in> S"
      then have "a \<le> x" unfolding a_def by (rule Inf_lower)
      then show "a < x" using `x \<in> S` `a \<notin> S` by (cases "a = x") auto
    next
      fix x assume "a < x"
      then obtain y where "y < x" "y \<in> S" unfolding a_def Inf_less_iff ..
      with mono[of y x] show "x \<in> S" by auto
    qed
    then show ?c ..
  qed
qed auto

lemma ereal_open_mono_set:
  fixes S :: "ereal set"
  shows "(open S \<and> mono_set S) \<longleftrightarrow> (S = UNIV \<or> S = {Inf S <..})"
  by (metis Inf_UNIV atLeast_eq_UNIV_iff ereal_open_atLeast
    ereal_open_closed mono_set_iff open_ereal_greaterThan)

lemma ereal_closed_mono_set:
  fixes S :: "ereal set"
  shows "(closed S \<and> mono_set S) \<longleftrightarrow> (S = {} \<or> S = {Inf S ..})"
  by (metis Inf_UNIV atLeast_eq_UNIV_iff closed_ereal_atLeast
    ereal_open_closed mono_empty mono_set_iff open_ereal_greaterThan)

lemma ereal_Liminf_Sup_monoset:
  fixes f :: "'a => ereal"
  shows "Liminf net f =
    Sup {l. \<forall>S. open S \<longrightarrow> mono_set S \<longrightarrow> l \<in> S \<longrightarrow> eventually (\<lambda>x. f x \<in> S) net}"
    (is "_ = Sup ?A")
proof (safe intro!: Liminf_eqI complete_lattice_class.Sup_upper complete_lattice_class.Sup_least)
  fix P assume P: "eventually P net"
  fix S assume S: "mono_set S" "INFI (Collect P) f \<in> S"
  { fix x assume "P x"
    then have "INFI (Collect P) f \<le> f x"
      by (intro complete_lattice_class.INF_lower) simp
    with S have "f x \<in> S"
      by (simp add: mono_set) }
  with P show "eventually (\<lambda>x. f x \<in> S) net"
    by (auto elim: eventually_elim1)
next
  fix y l
  assume S: "\<forall>S. open S \<longrightarrow> mono_set S \<longrightarrow> l \<in> S \<longrightarrow> eventually  (\<lambda>x. f x \<in> S) net"
  assume P: "\<forall>P. eventually P net \<longrightarrow> INFI (Collect P) f \<le> y"
  show "l \<le> y"
  proof (rule dense_le)
    fix B assume "B < l"
    then have "eventually (\<lambda>x. f x \<in> {B <..}) net"
      by (intro S[rule_format]) auto
    then have "INFI {x. B < f x} f \<le> y"
      using P by auto
    moreover have "B \<le> INFI {x. B < f x} f"
      by (intro INF_greatest) auto
    ultimately show "B \<le> y"
      by simp
  qed
qed

lemma ereal_Limsup_Inf_monoset:
  fixes f :: "'a => ereal"
  shows "Limsup net f =
    Inf {l. \<forall>S. open S \<longrightarrow> mono_set (uminus ` S) \<longrightarrow> l \<in> S \<longrightarrow> eventually (\<lambda>x. f x \<in> S) net}"
    (is "_ = Inf ?A")
proof (safe intro!: Limsup_eqI complete_lattice_class.Inf_lower complete_lattice_class.Inf_greatest)
  fix P assume P: "eventually P net"
  fix S assume S: "mono_set (uminus`S)" "SUPR (Collect P) f \<in> S"
  { fix x assume "P x"
    then have "f x \<le> SUPR (Collect P) f"
      by (intro complete_lattice_class.SUP_upper) simp
    with S(1)[unfolded mono_set, rule_format, of "- SUPR (Collect P) f" "- f x"] S(2)
    have "f x \<in> S"
      by (simp add: inj_image_mem_iff) }
  with P show "eventually (\<lambda>x. f x \<in> S) net"
    by (auto elim: eventually_elim1)
next
  fix y l
  assume S: "\<forall>S. open S \<longrightarrow> mono_set (uminus ` S) \<longrightarrow> l \<in> S \<longrightarrow> eventually  (\<lambda>x. f x \<in> S) net"
  assume P: "\<forall>P. eventually P net \<longrightarrow> y \<le> SUPR (Collect P) f"
  show "y \<le> l"
  proof (rule dense_ge)
    fix B assume "l < B"
    then have "eventually (\<lambda>x. f x \<in> {..< B}) net"
      by (intro S[rule_format]) auto
    then have "y \<le> SUPR {x. f x < B} f"
      using P by auto
    moreover have "SUPR {x. f x < B} f \<le> B"
      by (intro SUP_least) auto
    ultimately show "y \<le> B"
      by simp
  qed
qed

lemma liminf_bounded_open:
  fixes x :: "nat \<Rightarrow> ereal"
  shows "x0 \<le> liminf x \<longleftrightarrow> (\<forall>S. open S \<longrightarrow> mono_set S \<longrightarrow> x0 \<in> S \<longrightarrow> (\<exists>N. \<forall>n\<ge>N. x n \<in> S))"
  (is "_ \<longleftrightarrow> ?P x0")
proof
  assume "?P x0"
  then show "x0 \<le> liminf x"
    unfolding ereal_Liminf_Sup_monoset eventually_sequentially
    by (intro complete_lattice_class.Sup_upper) auto
next
  assume "x0 \<le> liminf x"
  { fix S :: "ereal set"
    assume om: "open S & mono_set S & x0:S"
    { assume "S = UNIV" then have "EX N. (ALL n>=N. x n : S)" by auto }
    moreover
    { assume "~(S=UNIV)"
      then obtain B where B_def: "S = {B<..}" using om ereal_open_mono_set by auto
      then have "B<x0" using om by auto
      then have "EX N. ALL n>=N. x n : S"
        unfolding B_def using `x0 \<le> liminf x` liminf_bounded_iff by auto
    }
    ultimately have "EX N. (ALL n>=N. x n : S)" by auto
  }
  then show "?P x0" by auto
qed

end
