(*  Title:      HOL/Probability/Information.thy
    Author:     Johannes Hölzl, TU München
    Author:     Armin Heller, TU München
*)

section {*Information theory*}

theory Information
imports
  Independent_Family
  "~~/src/HOL/Library/Convex"
begin

lemma log_le: "1 < a \<Longrightarrow> 0 < x \<Longrightarrow> x \<le> y \<Longrightarrow> log a x \<le> log a y"
  by (subst log_le_cancel_iff) auto

lemma log_less: "1 < a \<Longrightarrow> 0 < x \<Longrightarrow> x < y \<Longrightarrow> log a x < log a y"
  by (subst log_less_cancel_iff) auto

lemma setsum_cartesian_product':
  "(\<Sum>x\<in>A \<times> B. f x) = (\<Sum>x\<in>A. setsum (\<lambda>y. f (x, y)) B)"
  unfolding setsum.cartesian_product by simp

lemma split_pairs:
  "((A, B) = X) \<longleftrightarrow> (fst X = A \<and> snd X = B)" and
  "(X = (A, B)) \<longleftrightarrow> (fst X = A \<and> snd X = B)" by auto

subsection "Information theory"

locale information_space = prob_space +
  fixes b :: real assumes b_gt_1: "1 < b"

context information_space
begin

text {* Introduce some simplification rules for logarithm of base @{term b}. *}

lemma log_neg_const:
  assumes "x \<le> 0"
  shows "log b x = log b 0"
proof -
  { fix u :: real
    have "x \<le> 0" by fact
    also have "0 < exp u"
      using exp_gt_zero .
    finally have "exp u \<noteq> x"
      by auto }
  then show "log b x = log b 0"
    by (simp add: log_def ln_def)
qed

lemma log_mult_eq:
  "log b (A * B) = (if 0 < A * B then log b \<bar>A\<bar> + log b \<bar>B\<bar> else log b 0)"
  using log_mult[of b "\<bar>A\<bar>" "\<bar>B\<bar>"] b_gt_1 log_neg_const[of "A * B"]
  by (auto simp: zero_less_mult_iff mult_le_0_iff)

lemma log_inverse_eq:
  "log b (inverse B) = (if 0 < B then - log b B else log b 0)"
  using log_inverse[of b B] log_neg_const[of "inverse B"] b_gt_1 by simp

lemma log_divide_eq:
  "log b (A / B) = (if 0 < A * B then log b \<bar>A\<bar> - log b \<bar>B\<bar> else log b 0)"
  unfolding divide_inverse log_mult_eq log_inverse_eq abs_inverse
  by (auto simp: zero_less_mult_iff mult_le_0_iff)

lemmas log_simps = log_mult_eq log_inverse_eq log_divide_eq

end

subsection "Kullback$-$Leibler divergence"

text {* The Kullback$-$Leibler divergence is also known as relative entropy or
Kullback$-$Leibler distance. *}

definition
  "entropy_density b M N = log b \<circ> real \<circ> RN_deriv M N"

definition
  "KL_divergence b M N = integral\<^sup>L N (entropy_density b M N)"

lemma measurable_entropy_density[measurable]: "entropy_density b M N \<in> borel_measurable M"
  unfolding entropy_density_def by auto

lemma (in sigma_finite_measure) KL_density:
  fixes f :: "'a \<Rightarrow> real"
  assumes "1 < b"
  assumes f[measurable]: "f \<in> borel_measurable M" and nn: "AE x in M. 0 \<le> f x"
  shows "KL_divergence b M (density M f) = (\<integral>x. f x * log b (f x) \<partial>M)"
  unfolding KL_divergence_def
proof (subst integral_real_density)
  show [measurable]: "entropy_density b M (density M (\<lambda>x. ereal (f x))) \<in> borel_measurable M"
    using f
    by (auto simp: comp_def entropy_density_def)
  have "density M (RN_deriv M (density M f)) = density M f"
    using f nn by (intro density_RN_deriv_density) auto
  then have eq: "AE x in M. RN_deriv M (density M f) x = f x"
    using f nn by (intro density_unique) (auto simp: RN_deriv_nonneg)
  show "(\<integral>x. f x * entropy_density b M (density M (\<lambda>x. ereal (f x))) x \<partial>M) = (\<integral>x. f x * log b (f x) \<partial>M)"
    apply (intro integral_cong_AE)
    apply measurable
    using eq
    apply eventually_elim
    apply (auto simp: entropy_density_def)
    done
qed fact+

lemma (in sigma_finite_measure) KL_density_density:
  fixes f g :: "'a \<Rightarrow> real"
  assumes "1 < b"
  assumes f: "f \<in> borel_measurable M" "AE x in M. 0 \<le> f x"
  assumes g: "g \<in> borel_measurable M" "AE x in M. 0 \<le> g x"
  assumes ac: "AE x in M. f x = 0 \<longrightarrow> g x = 0"
  shows "KL_divergence b (density M f) (density M g) = (\<integral>x. g x * log b (g x / f x) \<partial>M)"
proof -
  interpret Mf: sigma_finite_measure "density M f"
    using f by (subst sigma_finite_iff_density_finite) auto
  have "KL_divergence b (density M f) (density M g) =
    KL_divergence b (density M f) (density (density M f) (\<lambda>x. g x / f x))"
    using f g ac by (subst density_density_divide) simp_all
  also have "\<dots> = (\<integral>x. (g x / f x) * log b (g x / f x) \<partial>density M f)"
    using f g `1 < b` by (intro Mf.KL_density) (auto simp: AE_density)
  also have "\<dots> = (\<integral>x. g x * log b (g x / f x) \<partial>M)"
    using ac f g `1 < b` by (subst integral_density) (auto intro!: integral_cong_AE)
  finally show ?thesis .
qed

lemma (in information_space) KL_gt_0:
  fixes D :: "'a \<Rightarrow> real"
  assumes "prob_space (density M D)"
  assumes D: "D \<in> borel_measurable M" "AE x in M. 0 \<le> D x"
  assumes int: "integrable M (\<lambda>x. D x * log b (D x))"
  assumes A: "density M D \<noteq> M"
  shows "0 < KL_divergence b M (density M D)"
proof -
  interpret N: prob_space "density M D" by fact

  obtain A where "A \<in> sets M" "emeasure (density M D) A \<noteq> emeasure M A"
    using measure_eqI[of "density M D" M] `density M D \<noteq> M` by auto

  let ?D_set = "{x\<in>space M. D x \<noteq> 0}"
  have [simp, intro]: "?D_set \<in> sets M"
    using D by auto

  have D_neg: "(\<integral>\<^sup>+ x. ereal (- D x) \<partial>M) = 0"
    using D by (subst nn_integral_0_iff_AE) auto

  have "(\<integral>\<^sup>+ x. ereal (D x) \<partial>M) = emeasure (density M D) (space M)"
    using D by (simp add: emeasure_density cong: nn_integral_cong)
  then have D_pos: "(\<integral>\<^sup>+ x. ereal (D x) \<partial>M) = 1"
    using N.emeasure_space_1 by simp

  have "integrable M D"
    using D D_pos D_neg unfolding real_integrable_def real_lebesgue_integral_def by simp_all
  then have "integral\<^sup>L M D = 1"
    using D D_pos D_neg by (simp add: real_lebesgue_integral_def)

  have "0 \<le> 1 - measure M ?D_set"
    using prob_le_1 by (auto simp: field_simps)
  also have "\<dots> = (\<integral> x. D x - indicator ?D_set x \<partial>M)"
    using `integrable M D` `integral\<^sup>L M D = 1`
    by (simp add: emeasure_eq_measure)
  also have "\<dots> < (\<integral> x. D x * (ln b * log b (D x)) \<partial>M)"
  proof (rule integral_less_AE)
    show "integrable M (\<lambda>x. D x - indicator ?D_set x)"
      using `integrable M D` by auto
  next
    from integrable_mult_left(1)[OF int, of "ln b"]
    show "integrable M (\<lambda>x. D x * (ln b * log b (D x)))" 
      by (simp add: ac_simps)
  next
    show "emeasure M {x\<in>space M. D x \<noteq> 1 \<and> D x \<noteq> 0} \<noteq> 0"
    proof
      assume eq_0: "emeasure M {x\<in>space M. D x \<noteq> 1 \<and> D x \<noteq> 0} = 0"
      then have disj: "AE x in M. D x = 1 \<or> D x = 0"
        using D(1) by (auto intro!: AE_I[OF subset_refl] sets.sets_Collect)

      have "emeasure M {x\<in>space M. D x = 1} = (\<integral>\<^sup>+ x. indicator {x\<in>space M. D x = 1} x \<partial>M)"
        using D(1) by auto
      also have "\<dots> = (\<integral>\<^sup>+ x. ereal (D x) \<partial>M)"
        using disj by (auto intro!: nn_integral_cong_AE simp: indicator_def one_ereal_def)
      finally have "AE x in M. D x = 1"
        using D D_pos by (intro AE_I_eq_1) auto
      then have "(\<integral>\<^sup>+x. indicator A x\<partial>M) = (\<integral>\<^sup>+x. ereal (D x) * indicator A x\<partial>M)"
        by (intro nn_integral_cong_AE) (auto simp: one_ereal_def[symmetric])
      also have "\<dots> = density M D A"
        using `A \<in> sets M` D by (simp add: emeasure_density)
      finally show False using `A \<in> sets M` `emeasure (density M D) A \<noteq> emeasure M A` by simp
    qed
    show "{x\<in>space M. D x \<noteq> 1 \<and> D x \<noteq> 0} \<in> sets M"
      using D(1) by (auto intro: sets.sets_Collect_conj)

    show "AE t in M. t \<in> {x\<in>space M. D x \<noteq> 1 \<and> D x \<noteq> 0} \<longrightarrow>
      D t - indicator ?D_set t \<noteq> D t * (ln b * log b (D t))"
      using D(2)
    proof (eventually_elim, safe)
      fix t assume Dt: "t \<in> space M" "D t \<noteq> 1" "D t \<noteq> 0" "0 \<le> D t"
        and eq: "D t - indicator ?D_set t = D t * (ln b * log b (D t))"

      have "D t - 1 = D t - indicator ?D_set t"
        using Dt by simp
      also note eq
      also have "D t * (ln b * log b (D t)) = - D t * ln (1 / D t)"
        using b_gt_1 `D t \<noteq> 0` `0 \<le> D t`
        by (simp add: log_def ln_div less_le)
      finally have "ln (1 / D t) = 1 / D t - 1"
        using `D t \<noteq> 0` by (auto simp: field_simps)
      from ln_eq_minus_one[OF _ this] `D t \<noteq> 0` `0 \<le> D t` `D t \<noteq> 1`
      show False by auto
    qed

    show "AE t in M. D t - indicator ?D_set t \<le> D t * (ln b * log b (D t))"
      using D(2) AE_space
    proof eventually_elim
      fix t assume "t \<in> space M" "0 \<le> D t"
      show "D t - indicator ?D_set t \<le> D t * (ln b * log b (D t))"
      proof cases
        assume asm: "D t \<noteq> 0"
        then have "0 < D t" using `0 \<le> D t` by auto
        then have "0 < 1 / D t" by auto
        have "D t - indicator ?D_set t \<le> - D t * (1 / D t - 1)"
          using asm `t \<in> space M` by (simp add: field_simps)
        also have "- D t * (1 / D t - 1) \<le> - D t * ln (1 / D t)"
          using ln_le_minus_one `0 < 1 / D t` by (intro mult_left_mono_neg) auto
        also have "\<dots> = D t * (ln b * log b (D t))"
          using `0 < D t` b_gt_1
          by (simp_all add: log_def ln_div)
        finally show ?thesis by simp
      qed simp
    qed
  qed
  also have "\<dots> = (\<integral> x. ln b * (D x * log b (D x)) \<partial>M)"
    by (simp add: ac_simps)
  also have "\<dots> = ln b * (\<integral> x. D x * log b (D x) \<partial>M)"
    using int by simp
  finally show ?thesis
    using b_gt_1 D by (subst KL_density) (auto simp: zero_less_mult_iff)
qed

lemma (in sigma_finite_measure) KL_same_eq_0: "KL_divergence b M M = 0"
proof -
  have "AE x in M. 1 = RN_deriv M M x"
  proof (rule RN_deriv_unique)
    show "(\<lambda>x. 1) \<in> borel_measurable M" "AE x in M. 0 \<le> (1 :: ereal)" by auto
    show "density M (\<lambda>x. 1) = M"
      apply (auto intro!: measure_eqI emeasure_density)
      apply (subst emeasure_density)
      apply auto
      done
  qed
  then have "AE x in M. log b (real (RN_deriv M M x)) = 0"
    by (elim AE_mp) simp
  from integral_cong_AE[OF _ _ this]
  have "integral\<^sup>L M (entropy_density b M M) = 0"
    by (simp add: entropy_density_def comp_def)
  then show "KL_divergence b M M = 0"
    unfolding KL_divergence_def
    by auto
qed

lemma (in information_space) KL_eq_0_iff_eq:
  fixes D :: "'a \<Rightarrow> real"
  assumes "prob_space (density M D)"
  assumes D: "D \<in> borel_measurable M" "AE x in M. 0 \<le> D x"
  assumes int: "integrable M (\<lambda>x. D x * log b (D x))"
  shows "KL_divergence b M (density M D) = 0 \<longleftrightarrow> density M D = M"
  using KL_same_eq_0[of b] KL_gt_0[OF assms]
  by (auto simp: less_le)

lemma (in information_space) KL_eq_0_iff_eq_ac:
  fixes D :: "'a \<Rightarrow> real"
  assumes "prob_space N"
  assumes ac: "absolutely_continuous M N" "sets N = sets M"
  assumes int: "integrable N (entropy_density b M N)"
  shows "KL_divergence b M N = 0 \<longleftrightarrow> N = M"
proof -
  interpret N: prob_space N by fact
  have "finite_measure N" by unfold_locales
  from real_RN_deriv[OF this ac] guess D . note D = this
  
  have "N = density M (RN_deriv M N)"
    using ac by (rule density_RN_deriv[symmetric])
  also have "\<dots> = density M D"
    using D by (auto intro!: density_cong)
  finally have N: "N = density M D" .

  from absolutely_continuous_AE[OF ac(2,1) D(2)] D b_gt_1 ac measurable_entropy_density
  have "integrable N (\<lambda>x. log b (D x))"
    by (intro integrable_cong_AE[THEN iffD2, OF _ _ _ int])
       (auto simp: N entropy_density_def)
  with D b_gt_1 have "integrable M (\<lambda>x. D x * log b (D x))"
    by (subst integrable_real_density[symmetric]) (auto simp: N[symmetric] comp_def)
  with `prob_space N` D show ?thesis
    unfolding N
    by (intro KL_eq_0_iff_eq) auto
qed

lemma (in information_space) KL_nonneg:
  assumes "prob_space (density M D)"
  assumes D: "D \<in> borel_measurable M" "AE x in M. 0 \<le> D x"
  assumes int: "integrable M (\<lambda>x. D x * log b (D x))"
  shows "0 \<le> KL_divergence b M (density M D)"
  using KL_gt_0[OF assms] by (cases "density M D = M") (auto simp: KL_same_eq_0)

lemma (in sigma_finite_measure) KL_density_density_nonneg:
  fixes f g :: "'a \<Rightarrow> real"
  assumes "1 < b"
  assumes f: "f \<in> borel_measurable M" "AE x in M. 0 \<le> f x" "prob_space (density M f)"
  assumes g: "g \<in> borel_measurable M" "AE x in M. 0 \<le> g x" "prob_space (density M g)"
  assumes ac: "AE x in M. f x = 0 \<longrightarrow> g x = 0"
  assumes int: "integrable M (\<lambda>x. g x * log b (g x / f x))"
  shows "0 \<le> KL_divergence b (density M f) (density M g)"
proof -
  interpret Mf: prob_space "density M f" by fact
  interpret Mf: information_space "density M f" b by default fact
  have eq: "density (density M f) (\<lambda>x. g x / f x) = density M g" (is "?DD = _")
    using f g ac by (subst density_density_divide) simp_all

  have "0 \<le> KL_divergence b (density M f) (density (density M f) (\<lambda>x. g x / f x))"
  proof (rule Mf.KL_nonneg)
    show "prob_space ?DD" unfolding eq by fact
    from f g show "(\<lambda>x. g x / f x) \<in> borel_measurable (density M f)"
      by auto
    show "AE x in density M f. 0 \<le> g x / f x"
      using f g by (auto simp: AE_density)
    show "integrable (density M f) (\<lambda>x. g x / f x * log b (g x / f x))"
      using `1 < b` f g ac
      by (subst integrable_density)
         (auto intro!: integrable_cong_AE[THEN iffD2, OF _ _ _ int] measurable_If)
  qed
  also have "\<dots> = KL_divergence b (density M f) (density M g)"
    using f g ac by (subst density_density_divide) simp_all
  finally show ?thesis .
qed

subsection {* Finite Entropy *}

definition (in information_space) 
  "finite_entropy S X f \<longleftrightarrow> distributed M S X f \<and> integrable S (\<lambda>x. f x * log b (f x))"

lemma (in information_space) finite_entropy_simple_function:
  assumes X: "simple_function M X"
  shows "finite_entropy (count_space (X`space M)) X (\<lambda>a. measure M {x \<in> space M. X x = a})"
  unfolding finite_entropy_def
proof
  have [simp]: "finite (X ` space M)"
    using X by (auto simp: simple_function_def)
  then show "integrable (count_space (X ` space M))
     (\<lambda>x. prob {xa \<in> space M. X xa = x} * log b (prob {xa \<in> space M. X xa = x}))"
    by (rule integrable_count_space)
  have d: "distributed M (count_space (X ` space M)) X (\<lambda>x. ereal (if x \<in> X`space M then prob {xa \<in> space M. X xa = x} else 0))"
    by (rule distributed_simple_function_superset[OF X]) (auto intro!: arg_cong[where f=prob])
  show "distributed M (count_space (X ` space M)) X (\<lambda>x. ereal (prob {xa \<in> space M. X xa = x}))"
    by (rule distributed_cong_density[THEN iffD1, OF _ _ _ d]) auto
qed

lemma distributed_transform_AE:
  assumes T: "T \<in> measurable P Q" "absolutely_continuous Q (distr P Q T)"
  assumes g: "distributed M Q Y g"
  shows "AE x in P. 0 \<le> g (T x)"
  using g
  apply (subst AE_distr_iff[symmetric, OF T(1)])
  apply simp
  apply (rule absolutely_continuous_AE[OF _ T(2)])
  apply simp
  apply (simp add: distributed_AE)
  done

lemma ac_fst:
  assumes "sigma_finite_measure T"
  shows "absolutely_continuous S (distr (S \<Otimes>\<^sub>M T) S fst)"
proof -
  interpret sigma_finite_measure T by fact
  { fix A assume A: "A \<in> sets S" "emeasure S A = 0"
    then have "fst -` A \<inter> space (S \<Otimes>\<^sub>M T) = A \<times> space T"
      by (auto simp: space_pair_measure dest!: sets.sets_into_space)
    with A have "emeasure (S \<Otimes>\<^sub>M T) (fst -` A \<inter> space (S \<Otimes>\<^sub>M T)) = 0"
      by (simp add: emeasure_pair_measure_Times) }
  then show ?thesis
    unfolding absolutely_continuous_def
    apply (auto simp: null_sets_distr_iff)
    apply (auto simp: null_sets_def intro!: measurable_sets)
    done
qed

lemma ac_snd:
  assumes "sigma_finite_measure T"
  shows "absolutely_continuous T (distr (S \<Otimes>\<^sub>M T) T snd)"
proof -
  interpret sigma_finite_measure T by fact
  { fix A assume A: "A \<in> sets T" "emeasure T A = 0"
    then have "snd -` A \<inter> space (S \<Otimes>\<^sub>M T) = space S \<times> A"
      by (auto simp: space_pair_measure dest!: sets.sets_into_space)
    with A have "emeasure (S \<Otimes>\<^sub>M T) (snd -` A \<inter> space (S \<Otimes>\<^sub>M T)) = 0"
      by (simp add: emeasure_pair_measure_Times) }
  then show ?thesis
    unfolding absolutely_continuous_def
    apply (auto simp: null_sets_distr_iff)
    apply (auto simp: null_sets_def intro!: measurable_sets)
    done
qed

lemma integrable_cong_AE_imp:
  "integrable M g \<Longrightarrow> f \<in> borel_measurable M \<Longrightarrow> (AE x in M. g x = f x) \<Longrightarrow> integrable M f"
  using integrable_cong_AE[of f M g] by (auto simp: eq_commute)

lemma (in information_space) finite_entropy_integrable:
  "finite_entropy S X Px \<Longrightarrow> integrable S (\<lambda>x. Px x * log b (Px x))"
  unfolding finite_entropy_def by auto

lemma (in information_space) finite_entropy_distributed:
  "finite_entropy S X Px \<Longrightarrow> distributed M S X Px"
  unfolding finite_entropy_def by auto

lemma (in information_space) finite_entropy_integrable_transform:
  assumes Fx: "finite_entropy S X Px"
  assumes Fy: "distributed M T Y Py"
    and "X = (\<lambda>x. f (Y x))"
    and "f \<in> measurable T S"
  shows "integrable T (\<lambda>x. Py x * log b (Px (f x)))"
  using assms unfolding finite_entropy_def
  using distributed_transform_integrable[of M T Y Py S X Px f "\<lambda>x. log b (Px x)"]
  by auto

subsection {* Mutual Information *}

definition (in prob_space)
  "mutual_information b S T X Y =
    KL_divergence b (distr M S X \<Otimes>\<^sub>M distr M T Y) (distr M (S \<Otimes>\<^sub>M T) (\<lambda>x. (X x, Y x)))"

lemma (in information_space) mutual_information_indep_vars:
  fixes S T X Y
  defines "P \<equiv> distr M S X \<Otimes>\<^sub>M distr M T Y"
  defines "Q \<equiv> distr M (S \<Otimes>\<^sub>M T) (\<lambda>x. (X x, Y x))"
  shows "indep_var S X T Y \<longleftrightarrow>
    (random_variable S X \<and> random_variable T Y \<and>
      absolutely_continuous P Q \<and> integrable Q (entropy_density b P Q) \<and>
      mutual_information b S T X Y = 0)"
  unfolding indep_var_distribution_eq
proof safe
  assume rv[measurable]: "random_variable S X" "random_variable T Y"

  interpret X: prob_space "distr M S X"
    by (rule prob_space_distr) fact
  interpret Y: prob_space "distr M T Y"
    by (rule prob_space_distr) fact
  interpret XY: pair_prob_space "distr M S X" "distr M T Y" by default
  interpret P: information_space P b unfolding P_def by default (rule b_gt_1)

  interpret Q: prob_space Q unfolding Q_def
    by (rule prob_space_distr) simp

  { assume "distr M S X \<Otimes>\<^sub>M distr M T Y = distr M (S \<Otimes>\<^sub>M T) (\<lambda>x. (X x, Y x))"
    then have [simp]: "Q = P"  unfolding Q_def P_def by simp

    show ac: "absolutely_continuous P Q" by (simp add: absolutely_continuous_def)
    then have ed: "entropy_density b P Q \<in> borel_measurable P"
      by simp

    have "AE x in P. 1 = RN_deriv P Q x"
    proof (rule P.RN_deriv_unique)
      show "density P (\<lambda>x. 1) = Q"
        unfolding `Q = P` by (intro measure_eqI) (auto simp: emeasure_density)
    qed auto
    then have ae_0: "AE x in P. entropy_density b P Q x = 0"
      by eventually_elim (auto simp: entropy_density_def)
    then have "integrable P (entropy_density b P Q) \<longleftrightarrow> integrable Q (\<lambda>x. 0::real)"
      using ed unfolding `Q = P` by (intro integrable_cong_AE) auto
    then show "integrable Q (entropy_density b P Q)" by simp

    from ae_0 have "mutual_information b S T X Y = (\<integral>x. 0 \<partial>P)"
      unfolding mutual_information_def KL_divergence_def P_def[symmetric] Q_def[symmetric] `Q = P`
      by (intro integral_cong_AE) auto
    then show "mutual_information b S T X Y = 0"
      by simp }

  { assume ac: "absolutely_continuous P Q"
    assume int: "integrable Q (entropy_density b P Q)"
    assume I_eq_0: "mutual_information b S T X Y = 0"

    have eq: "Q = P"
    proof (rule P.KL_eq_0_iff_eq_ac[THEN iffD1])
      show "prob_space Q" by unfold_locales
      show "absolutely_continuous P Q" by fact
      show "integrable Q (entropy_density b P Q)" by fact
      show "sets Q = sets P" by (simp add: P_def Q_def sets_pair_measure)
      show "KL_divergence b P Q = 0"
        using I_eq_0 unfolding mutual_information_def by (simp add: P_def Q_def)
    qed
    then show "distr M S X \<Otimes>\<^sub>M distr M T Y = distr M (S \<Otimes>\<^sub>M T) (\<lambda>x. (X x, Y x))"
      unfolding P_def Q_def .. }
qed

abbreviation (in information_space)
  mutual_information_Pow ("\<I>'(_ ; _')") where
  "\<I>(X ; Y) \<equiv> mutual_information b (count_space (X`space M)) (count_space (Y`space M)) X Y"

lemma (in information_space)
  fixes Pxy :: "'b \<times> 'c \<Rightarrow> real" and Px :: "'b \<Rightarrow> real" and Py :: "'c \<Rightarrow> real"
  assumes S: "sigma_finite_measure S" and T: "sigma_finite_measure T"
  assumes Fx: "finite_entropy S X Px" and Fy: "finite_entropy T Y Py"
  assumes Fxy: "finite_entropy (S \<Otimes>\<^sub>M T) (\<lambda>x. (X x, Y x)) Pxy"
  defines "f \<equiv> \<lambda>x. Pxy x * log b (Pxy x / (Px (fst x) * Py (snd x)))"
  shows mutual_information_distr': "mutual_information b S T X Y = integral\<^sup>L (S \<Otimes>\<^sub>M T) f" (is "?M = ?R")
    and mutual_information_nonneg': "0 \<le> mutual_information b S T X Y"
proof -
  have Px: "distributed M S X Px"
    using Fx by (auto simp: finite_entropy_def)
  have Py: "distributed M T Y Py"
    using Fy by (auto simp: finite_entropy_def)
  have Pxy: "distributed M (S \<Otimes>\<^sub>M T) (\<lambda>x. (X x, Y x)) Pxy"
    using Fxy by (auto simp: finite_entropy_def)

  have X: "random_variable S X"
    using Px by auto
  have Y: "random_variable T Y"
    using Py by auto
  interpret S: sigma_finite_measure S by fact
  interpret T: sigma_finite_measure T by fact
  interpret ST: pair_sigma_finite S T ..
  interpret X: prob_space "distr M S X" using X by (rule prob_space_distr)
  interpret Y: prob_space "distr M T Y" using Y by (rule prob_space_distr)
  interpret XY: pair_prob_space "distr M S X" "distr M T Y" ..
  let ?P = "S \<Otimes>\<^sub>M T"
  let ?D = "distr M ?P (\<lambda>x. (X x, Y x))"

  { fix A assume "A \<in> sets S"
    with X Y have "emeasure (distr M S X) A = emeasure ?D (A \<times> space T)"
      by (auto simp: emeasure_distr measurable_Pair measurable_space
               intro!: arg_cong[where f="emeasure M"]) }
  note marginal_eq1 = this
  { fix A assume "A \<in> sets T"
    with X Y have "emeasure (distr M T Y) A = emeasure ?D (space S \<times> A)"
      by (auto simp: emeasure_distr measurable_Pair measurable_space
               intro!: arg_cong[where f="emeasure M"]) }
  note marginal_eq2 = this

  have eq: "(\<lambda>x. ereal (Px (fst x) * Py (snd x))) = (\<lambda>(x, y). ereal (Px x) * ereal (Py y))"
    by auto

  have distr_eq: "distr M S X \<Otimes>\<^sub>M distr M T Y = density ?P (\<lambda>x. ereal (Px (fst x) * Py (snd x)))"
    unfolding Px(1)[THEN distributed_distr_eq_density] Py(1)[THEN distributed_distr_eq_density] eq
  proof (subst pair_measure_density)
    show "(\<lambda>x. ereal (Px x)) \<in> borel_measurable S" "(\<lambda>y. ereal (Py y)) \<in> borel_measurable T"
      "AE x in S. 0 \<le> ereal (Px x)" "AE y in T. 0 \<le> ereal (Py y)"
      using Px Py by (auto simp: distributed_def)
    show "sigma_finite_measure (density T Py)" unfolding Py(1)[THEN distributed_distr_eq_density, symmetric] ..
  qed (fact | simp)+
  
  have M: "?M = KL_divergence b (density ?P (\<lambda>x. ereal (Px (fst x) * Py (snd x)))) (density ?P (\<lambda>x. ereal (Pxy x)))"
    unfolding mutual_information_def distr_eq Pxy(1)[THEN distributed_distr_eq_density] ..

  from Px Py have f: "(\<lambda>x. Px (fst x) * Py (snd x)) \<in> borel_measurable ?P"
    by (intro borel_measurable_times) (auto intro: distributed_real_measurable measurable_fst'' measurable_snd'')
  have PxPy_nonneg: "AE x in ?P. 0 \<le> Px (fst x) * Py (snd x)"
  proof (rule ST.AE_pair_measure)
    show "{x \<in> space ?P. 0 \<le> Px (fst x) * Py (snd x)} \<in> sets ?P"
      using f by auto
    show "AE x in S. AE y in T. 0 \<le> Px (fst (x, y)) * Py (snd (x, y))"
      using Px Py by (auto simp: zero_le_mult_iff dest!: distributed_real_AE)
  qed

  have "(AE x in ?P. Px (fst x) = 0 \<longrightarrow> Pxy x = 0)"
    by (rule subdensity_real[OF measurable_fst Pxy Px]) auto
  moreover
  have "(AE x in ?P. Py (snd x) = 0 \<longrightarrow> Pxy x = 0)"
    by (rule subdensity_real[OF measurable_snd Pxy Py]) auto
  ultimately have ac: "AE x in ?P. Px (fst x) * Py (snd x) = 0 \<longrightarrow> Pxy x = 0"
    by eventually_elim auto

  show "?M = ?R"
    unfolding M f_def
    using b_gt_1 f PxPy_nonneg Pxy[THEN distributed_real_measurable] Pxy[THEN distributed_real_AE] ac
    by (rule ST.KL_density_density)

  have X: "X = fst \<circ> (\<lambda>x. (X x, Y x))" and Y: "Y = snd \<circ> (\<lambda>x. (X x, Y x))"
    by auto

  have "integrable (S \<Otimes>\<^sub>M T) (\<lambda>x. Pxy x * log b (Pxy x) - Pxy x * log b (Px (fst x)) - Pxy x * log b (Py (snd x)))"
    using finite_entropy_integrable[OF Fxy]
    using finite_entropy_integrable_transform[OF Fx Pxy, of fst]
    using finite_entropy_integrable_transform[OF Fy Pxy, of snd]
    by simp
  moreover have "f \<in> borel_measurable (S \<Otimes>\<^sub>M T)"
    unfolding f_def using Px Py Pxy
    by (auto intro: distributed_real_measurable measurable_fst'' measurable_snd''
      intro!: borel_measurable_times borel_measurable_log borel_measurable_divide)
  ultimately have int: "integrable (S \<Otimes>\<^sub>M T) f"
    apply (rule integrable_cong_AE_imp)
    using
      distributed_transform_AE[OF measurable_fst ac_fst, of T, OF T Px]
      distributed_transform_AE[OF measurable_snd ac_snd, of _ _ _ _ S, OF T Py]
      subdensity_real[OF measurable_fst Pxy Px X]
      subdensity_real[OF measurable_snd Pxy Py Y]
      distributed_real_AE[OF Pxy]
    by eventually_elim
       (auto simp: f_def log_divide_eq log_mult_eq field_simps zero_less_mult_iff)

  show "0 \<le> ?M" unfolding M
  proof (rule ST.KL_density_density_nonneg
    [OF b_gt_1 f PxPy_nonneg _ Pxy[THEN distributed_real_measurable] Pxy[THEN distributed_real_AE] _ ac int[unfolded f_def]])
    show "prob_space (density (S \<Otimes>\<^sub>M T) (\<lambda>x. ereal (Pxy x))) "
      unfolding distributed_distr_eq_density[OF Pxy, symmetric]
      using distributed_measurable[OF Pxy] by (rule prob_space_distr)
    show "prob_space (density (S \<Otimes>\<^sub>M T) (\<lambda>x. ereal (Px (fst x) * Py (snd x))))"
      unfolding distr_eq[symmetric] by unfold_locales
  qed
qed


lemma (in information_space)
  fixes Pxy :: "'b \<times> 'c \<Rightarrow> real" and Px :: "'b \<Rightarrow> real" and Py :: "'c \<Rightarrow> real"
  assumes "sigma_finite_measure S" "sigma_finite_measure T"
  assumes Px: "distributed M S X Px" and Py: "distributed M T Y Py"
  assumes Pxy: "distributed M (S \<Otimes>\<^sub>M T) (\<lambda>x. (X x, Y x)) Pxy"
  defines "f \<equiv> \<lambda>x. Pxy x * log b (Pxy x / (Px (fst x) * Py (snd x)))"
  shows mutual_information_distr: "mutual_information b S T X Y = integral\<^sup>L (S \<Otimes>\<^sub>M T) f" (is "?M = ?R")
    and mutual_information_nonneg: "integrable (S \<Otimes>\<^sub>M T) f \<Longrightarrow> 0 \<le> mutual_information b S T X Y"
proof -
  have X: "random_variable S X"
    using Px by (auto simp: distributed_def)
  have Y: "random_variable T Y"
    using Py by (auto simp: distributed_def)
  interpret S: sigma_finite_measure S by fact
  interpret T: sigma_finite_measure T by fact
  interpret ST: pair_sigma_finite S T ..
  interpret X: prob_space "distr M S X" using X by (rule prob_space_distr)
  interpret Y: prob_space "distr M T Y" using Y by (rule prob_space_distr)
  interpret XY: pair_prob_space "distr M S X" "distr M T Y" ..
  let ?P = "S \<Otimes>\<^sub>M T"
  let ?D = "distr M ?P (\<lambda>x. (X x, Y x))"

  { fix A assume "A \<in> sets S"
    with X Y have "emeasure (distr M S X) A = emeasure ?D (A \<times> space T)"
      by (auto simp: emeasure_distr measurable_Pair measurable_space
               intro!: arg_cong[where f="emeasure M"]) }
  note marginal_eq1 = this
  { fix A assume "A \<in> sets T"
    with X Y have "emeasure (distr M T Y) A = emeasure ?D (space S \<times> A)"
      by (auto simp: emeasure_distr measurable_Pair measurable_space
               intro!: arg_cong[where f="emeasure M"]) }
  note marginal_eq2 = this

  have eq: "(\<lambda>x. ereal (Px (fst x) * Py (snd x))) = (\<lambda>(x, y). ereal (Px x) * ereal (Py y))"
    by auto

  have distr_eq: "distr M S X \<Otimes>\<^sub>M distr M T Y = density ?P (\<lambda>x. ereal (Px (fst x) * Py (snd x)))"
    unfolding Px(1)[THEN distributed_distr_eq_density] Py(1)[THEN distributed_distr_eq_density] eq
  proof (subst pair_measure_density)
    show "(\<lambda>x. ereal (Px x)) \<in> borel_measurable S" "(\<lambda>y. ereal (Py y)) \<in> borel_measurable T"
      "AE x in S. 0 \<le> ereal (Px x)" "AE y in T. 0 \<le> ereal (Py y)"
      using Px Py by (auto simp: distributed_def)
    show "sigma_finite_measure (density T Py)" unfolding Py(1)[THEN distributed_distr_eq_density, symmetric] ..
  qed (fact | simp)+
  
  have M: "?M = KL_divergence b (density ?P (\<lambda>x. ereal (Px (fst x) * Py (snd x)))) (density ?P (\<lambda>x. ereal (Pxy x)))"
    unfolding mutual_information_def distr_eq Pxy(1)[THEN distributed_distr_eq_density] ..

  from Px Py have f: "(\<lambda>x. Px (fst x) * Py (snd x)) \<in> borel_measurable ?P"
    by (intro borel_measurable_times) (auto intro: distributed_real_measurable measurable_fst'' measurable_snd'')
  have PxPy_nonneg: "AE x in ?P. 0 \<le> Px (fst x) * Py (snd x)"
  proof (rule ST.AE_pair_measure)
    show "{x \<in> space ?P. 0 \<le> Px (fst x) * Py (snd x)} \<in> sets ?P"
      using f by auto
    show "AE x in S. AE y in T. 0 \<le> Px (fst (x, y)) * Py (snd (x, y))"
      using Px Py by (auto simp: zero_le_mult_iff dest!: distributed_real_AE)
  qed

  have "(AE x in ?P. Px (fst x) = 0 \<longrightarrow> Pxy x = 0)"
    by (rule subdensity_real[OF measurable_fst Pxy Px]) auto
  moreover
  have "(AE x in ?P. Py (snd x) = 0 \<longrightarrow> Pxy x = 0)"
    by (rule subdensity_real[OF measurable_snd Pxy Py]) auto
  ultimately have ac: "AE x in ?P. Px (fst x) * Py (snd x) = 0 \<longrightarrow> Pxy x = 0"
    by eventually_elim auto

  show "?M = ?R"
    unfolding M f_def
    using b_gt_1 f PxPy_nonneg Pxy[THEN distributed_real_measurable] Pxy[THEN distributed_real_AE] ac
    by (rule ST.KL_density_density)

  assume int: "integrable (S \<Otimes>\<^sub>M T) f"
  show "0 \<le> ?M" unfolding M
  proof (rule ST.KL_density_density_nonneg
    [OF b_gt_1 f PxPy_nonneg _ Pxy[THEN distributed_real_measurable] Pxy[THEN distributed_real_AE] _ ac int[unfolded f_def]])
    show "prob_space (density (S \<Otimes>\<^sub>M T) (\<lambda>x. ereal (Pxy x))) "
      unfolding distributed_distr_eq_density[OF Pxy, symmetric]
      using distributed_measurable[OF Pxy] by (rule prob_space_distr)
    show "prob_space (density (S \<Otimes>\<^sub>M T) (\<lambda>x. ereal (Px (fst x) * Py (snd x))))"
      unfolding distr_eq[symmetric] by unfold_locales
  qed
qed

lemma (in information_space)
  fixes Pxy :: "'b \<times> 'c \<Rightarrow> real" and Px :: "'b \<Rightarrow> real" and Py :: "'c \<Rightarrow> real"
  assumes "sigma_finite_measure S" "sigma_finite_measure T"
  assumes Px[measurable]: "distributed M S X Px" and Py[measurable]: "distributed M T Y Py"
  assumes Pxy[measurable]: "distributed M (S \<Otimes>\<^sub>M T) (\<lambda>x. (X x, Y x)) Pxy"
  assumes ae: "AE x in S. AE y in T. Pxy (x, y) = Px x * Py y"
  shows mutual_information_eq_0: "mutual_information b S T X Y = 0"
proof -
  interpret S: sigma_finite_measure S by fact
  interpret T: sigma_finite_measure T by fact
  interpret ST: pair_sigma_finite S T ..

  have "AE x in S \<Otimes>\<^sub>M T. Px (fst x) = 0 \<longrightarrow> Pxy x = 0"
    by (rule subdensity_real[OF measurable_fst Pxy Px]) auto
  moreover
  have "AE x in S \<Otimes>\<^sub>M T. Py (snd x) = 0 \<longrightarrow> Pxy x = 0"
    by (rule subdensity_real[OF measurable_snd Pxy Py]) auto
  moreover 
  have "AE x in S \<Otimes>\<^sub>M T. Pxy x = Px (fst x) * Py (snd x)"
    using distributed_real_measurable[OF Px] distributed_real_measurable[OF Py] distributed_real_measurable[OF Pxy]
    by (intro ST.AE_pair_measure) (auto simp: ae intro!: measurable_snd'' measurable_fst'')
  ultimately have "AE x in S \<Otimes>\<^sub>M T. Pxy x * log b (Pxy x / (Px (fst x) * Py (snd x))) = 0"
    by eventually_elim simp
  then have "(\<integral>x. Pxy x * log b (Pxy x / (Px (fst x) * Py (snd x))) \<partial>(S \<Otimes>\<^sub>M T)) = (\<integral>x. 0 \<partial>(S \<Otimes>\<^sub>M T))"
    by (intro integral_cong_AE) auto
  then show ?thesis
    by (subst mutual_information_distr[OF assms(1-5)]) simp
qed

lemma (in information_space) mutual_information_simple_distributed:
  assumes X: "simple_distributed M X Px" and Y: "simple_distributed M Y Py"
  assumes XY: "simple_distributed M (\<lambda>x. (X x, Y x)) Pxy"
  shows "\<I>(X ; Y) = (\<Sum>(x, y)\<in>(\<lambda>x. (X x, Y x))`space M. Pxy (x, y) * log b (Pxy (x, y) / (Px x * Py y)))"
proof (subst mutual_information_distr[OF _ _ simple_distributed[OF X] simple_distributed[OF Y] simple_distributed_joint[OF XY]])
  note fin = simple_distributed_joint_finite[OF XY, simp]
  show "sigma_finite_measure (count_space (X ` space M))"
    by (simp add: sigma_finite_measure_count_space_finite)
  show "sigma_finite_measure (count_space (Y ` space M))"
    by (simp add: sigma_finite_measure_count_space_finite)
  let ?Pxy = "\<lambda>x. (if x \<in> (\<lambda>x. (X x, Y x)) ` space M then Pxy x else 0)"
  let ?f = "\<lambda>x. ?Pxy x * log b (?Pxy x / (Px (fst x) * Py (snd x)))"
  have "\<And>x. ?f x = (if x \<in> (\<lambda>x. (X x, Y x)) ` space M then Pxy x * log b (Pxy x / (Px (fst x) * Py (snd x))) else 0)"
    by auto
  with fin show "(\<integral> x. ?f x \<partial>(count_space (X ` space M) \<Otimes>\<^sub>M count_space (Y ` space M))) =
    (\<Sum>(x, y)\<in>(\<lambda>x. (X x, Y x)) ` space M. Pxy (x, y) * log b (Pxy (x, y) / (Px x * Py y)))"
    by (auto simp add: pair_measure_count_space lebesgue_integral_count_space_finite setsum.If_cases split_beta'
             intro!: setsum.cong)
qed

lemma (in information_space)
  fixes Pxy :: "'b \<times> 'c \<Rightarrow> real" and Px :: "'b \<Rightarrow> real" and Py :: "'c \<Rightarrow> real"
  assumes Px: "simple_distributed M X Px" and Py: "simple_distributed M Y Py"
  assumes Pxy: "simple_distributed M (\<lambda>x. (X x, Y x)) Pxy"
  assumes ae: "\<forall>x\<in>space M. Pxy (X x, Y x) = Px (X x) * Py (Y x)"
  shows mutual_information_eq_0_simple: "\<I>(X ; Y) = 0"
proof (subst mutual_information_simple_distributed[OF Px Py Pxy])
  have "(\<Sum>(x, y)\<in>(\<lambda>x. (X x, Y x)) ` space M. Pxy (x, y) * log b (Pxy (x, y) / (Px x * Py y))) =
    (\<Sum>(x, y)\<in>(\<lambda>x. (X x, Y x)) ` space M. 0)"
    by (intro setsum.cong) (auto simp: ae)
  then show "(\<Sum>(x, y)\<in>(\<lambda>x. (X x, Y x)) ` space M.
    Pxy (x, y) * log b (Pxy (x, y) / (Px x * Py y))) = 0" by simp
qed

subsection {* Entropy *}

definition (in prob_space) entropy :: "real \<Rightarrow> 'b measure \<Rightarrow> ('a \<Rightarrow> 'b) \<Rightarrow> real" where
  "entropy b S X = - KL_divergence b S (distr M S X)"

abbreviation (in information_space)
  entropy_Pow ("\<H>'(_')") where
  "\<H>(X) \<equiv> entropy b (count_space (X`space M)) X"

lemma (in prob_space) distributed_RN_deriv:
  assumes X: "distributed M S X Px"
  shows "AE x in S. RN_deriv S (density S Px) x = Px x"
proof -
  note D = distributed_measurable[OF X] distributed_borel_measurable[OF X] distributed_AE[OF X]
  interpret X: prob_space "distr M S X"
    using D(1) by (rule prob_space_distr)

  have sf: "sigma_finite_measure (distr M S X)" by default
  show ?thesis
    using D
    apply (subst eq_commute)
    apply (intro RN_deriv_unique_sigma_finite)
    apply (auto simp: distributed_distr_eq_density[symmetric, OF X] sf measure_nonneg)
    done
qed

lemma (in information_space)
  fixes X :: "'a \<Rightarrow> 'b"
  assumes X[measurable]: "distributed M MX X f"
  shows entropy_distr: "entropy b MX X = - (\<integral>x. f x * log b (f x) \<partial>MX)" (is ?eq)
proof -
  note D = distributed_measurable[OF X] distributed_borel_measurable[OF X] distributed_AE[OF X]
  note ae = distributed_RN_deriv[OF X]

  have ae_eq: "AE x in distr M MX X. log b (real (RN_deriv MX (distr M MX X) x)) =
    log b (f x)"
    unfolding distributed_distr_eq_density[OF X]
    apply (subst AE_density)
    using D apply simp
    using ae apply eventually_elim
    apply auto
    done

  have int_eq: "(\<integral> x. f x * log b (f x) \<partial>MX) = (\<integral> x. log b (f x) \<partial>distr M MX X)"
    unfolding distributed_distr_eq_density[OF X]
    using D
    by (subst integral_density)
       (auto simp: borel_measurable_ereal_iff)

  show ?eq
    unfolding entropy_def KL_divergence_def entropy_density_def comp_def int_eq neg_equal_iff_equal
    using ae_eq by (intro integral_cong_AE) auto
qed

lemma (in prob_space) distributed_imp_emeasure_nonzero:
  assumes X: "distributed M MX X Px"
  shows "emeasure MX {x \<in> space MX. Px x \<noteq> 0} \<noteq> 0"
proof
  note Px = distributed_borel_measurable[OF X] distributed_AE[OF X]
  interpret X: prob_space "distr M MX X"
    using distributed_measurable[OF X] by (rule prob_space_distr)

  assume "emeasure MX {x \<in> space MX. Px x \<noteq> 0} = 0"
  with Px have "AE x in MX. Px x = 0"
    by (intro AE_I[OF subset_refl]) (auto simp: borel_measurable_ereal_iff)
  moreover
  from X.emeasure_space_1 have "(\<integral>\<^sup>+x. Px x \<partial>MX) = 1"
    unfolding distributed_distr_eq_density[OF X] using Px
    by (subst (asm) emeasure_density)
       (auto simp: borel_measurable_ereal_iff intro!: integral_cong cong: nn_integral_cong)
  ultimately show False
    by (simp add: nn_integral_cong_AE)
qed

lemma (in information_space) entropy_le:
  fixes Px :: "'b \<Rightarrow> real" and MX :: "'b measure"
  assumes X[measurable]: "distributed M MX X Px"
  and fin: "emeasure MX {x \<in> space MX. Px x \<noteq> 0} \<noteq> \<infinity>"
  and int: "integrable MX (\<lambda>x. - Px x * log b (Px x))"
  shows "entropy b MX X \<le> log b (measure MX {x \<in> space MX. Px x \<noteq> 0})"
proof -
  note Px = distributed_borel_measurable[OF X] distributed_AE[OF X]
  interpret X: prob_space "distr M MX X"
    using distributed_measurable[OF X] by (rule prob_space_distr)

  have " - log b (measure MX {x \<in> space MX. Px x \<noteq> 0}) = 
    - log b (\<integral> x. indicator {x \<in> space MX. Px x \<noteq> 0} x \<partial>MX)"
    using Px fin
    by (auto simp: measure_def borel_measurable_ereal_iff)
  also have "- log b (\<integral> x. indicator {x \<in> space MX. Px x \<noteq> 0} x \<partial>MX) = - log b (\<integral> x. 1 / Px x \<partial>distr M MX X)"
    unfolding distributed_distr_eq_density[OF X] using Px
    apply (intro arg_cong[where f="log b"] arg_cong[where f=uminus])
    by (subst integral_density) (auto simp: borel_measurable_ereal_iff simp del: integral_indicator intro!: integral_cong)
  also have "\<dots> \<le> (\<integral> x. - log b (1 / Px x) \<partial>distr M MX X)"
  proof (rule X.jensens_inequality[of "\<lambda>x. 1 / Px x" "{0<..}" 0 1 "\<lambda>x. - log b x"])
    show "AE x in distr M MX X. 1 / Px x \<in> {0<..}"
      unfolding distributed_distr_eq_density[OF X]
      using Px by (auto simp: AE_density)
    have [simp]: "\<And>x. x \<in> space MX \<Longrightarrow> ereal (if Px x = 0 then 0 else 1) = indicator {x \<in> space MX. Px x \<noteq> 0} x"
      by (auto simp: one_ereal_def)
    have "(\<integral>\<^sup>+ x. max 0 (ereal (- (if Px x = 0 then 0 else 1))) \<partial>MX) = (\<integral>\<^sup>+ x. 0 \<partial>MX)"
      by (intro nn_integral_cong) (auto split: split_max)
    then show "integrable (distr M MX X) (\<lambda>x. 1 / Px x)"
      unfolding distributed_distr_eq_density[OF X] using Px
      by (auto simp: nn_integral_density real_integrable_def borel_measurable_ereal_iff fin nn_integral_max_0
              cong: nn_integral_cong)
    have "integrable MX (\<lambda>x. Px x * log b (1 / Px x)) =
      integrable MX (\<lambda>x. - Px x * log b (Px x))"
      using Px
      by (intro integrable_cong_AE)
         (auto simp: borel_measurable_ereal_iff log_divide_eq
                  intro!: measurable_If)
    then show "integrable (distr M MX X) (\<lambda>x. - log b (1 / Px x))"
      unfolding distributed_distr_eq_density[OF X]
      using Px int
      by (subst integrable_real_density) (auto simp: borel_measurable_ereal_iff)
  qed (auto simp: minus_log_convex[OF b_gt_1])
  also have "\<dots> = (\<integral> x. log b (Px x) \<partial>distr M MX X)"
    unfolding distributed_distr_eq_density[OF X] using Px
    by (intro integral_cong_AE) (auto simp: AE_density log_divide_eq)
  also have "\<dots> = - entropy b MX X"
    unfolding distributed_distr_eq_density[OF X] using Px
    by (subst entropy_distr[OF X]) (auto simp: borel_measurable_ereal_iff integral_density)
  finally show ?thesis
    by simp
qed

lemma (in information_space) entropy_le_space:
  fixes Px :: "'b \<Rightarrow> real" and MX :: "'b measure"
  assumes X: "distributed M MX X Px"
  and fin: "finite_measure MX"
  and int: "integrable MX (\<lambda>x. - Px x * log b (Px x))"
  shows "entropy b MX X \<le> log b (measure MX (space MX))"
proof -
  note Px = distributed_borel_measurable[OF X] distributed_AE[OF X]
  interpret finite_measure MX by fact
  have "entropy b MX X \<le> log b (measure MX {x \<in> space MX. Px x \<noteq> 0})"
    using int X by (intro entropy_le) auto
  also have "\<dots> \<le> log b (measure MX (space MX))"
    using Px distributed_imp_emeasure_nonzero[OF X]
    by (intro log_le)
       (auto intro!: borel_measurable_ereal_iff finite_measure_mono b_gt_1
                     less_le[THEN iffD2] measure_nonneg simp: emeasure_eq_measure)
  finally show ?thesis .
qed

lemma (in information_space) entropy_uniform:
  assumes X: "distributed M MX X (\<lambda>x. indicator A x / measure MX A)" (is "distributed _ _ _ ?f")
  shows "entropy b MX X = log b (measure MX A)"
proof (subst entropy_distr[OF X])
  have [simp]: "emeasure MX A \<noteq> \<infinity>"
    using uniform_distributed_params[OF X] by (auto simp add: measure_def)
  have eq: "(\<integral> x. indicator A x / measure MX A * log b (indicator A x / measure MX A) \<partial>MX) =
    (\<integral> x. (- log b (measure MX A) / measure MX A) * indicator A x \<partial>MX)"
    using measure_nonneg[of MX A] uniform_distributed_params[OF X]
    by (intro integral_cong) (auto split: split_indicator simp: log_divide_eq)
  show "- (\<integral> x. indicator A x / measure MX A * log b (indicator A x / measure MX A) \<partial>MX) =
    log b (measure MX A)"
    unfolding eq using uniform_distributed_params[OF X]
    by (subst integral_mult_right) (auto simp: measure_def)
qed

lemma (in information_space) entropy_simple_distributed:
  "simple_distributed M X f \<Longrightarrow> \<H>(X) = - (\<Sum>x\<in>X`space M. f x * log b (f x))"
  by (subst entropy_distr[OF simple_distributed])
     (auto simp add: lebesgue_integral_count_space_finite)

lemma (in information_space) entropy_le_card_not_0:
  assumes X: "simple_distributed M X f"
  shows "\<H>(X) \<le> log b (card (X ` space M \<inter> {x. f x \<noteq> 0}))"
proof -
  let ?X = "count_space (X`space M)"
  have "\<H>(X) \<le> log b (measure ?X {x \<in> space ?X. f x \<noteq> 0})"
    by (rule entropy_le[OF simple_distributed[OF X]])
       (simp_all add: simple_distributed_finite[OF X] subset_eq integrable_count_space emeasure_count_space)
  also have "measure ?X {x \<in> space ?X. f x \<noteq> 0} = card (X ` space M \<inter> {x. f x \<noteq> 0})"
    by (simp_all add: simple_distributed_finite[OF X] subset_eq emeasure_count_space measure_def Int_def)
  finally show ?thesis .
qed

lemma (in information_space) entropy_le_card:
  assumes X: "simple_distributed M X f"
  shows "\<H>(X) \<le> log b (real (card (X ` space M)))"
proof -
  let ?X = "count_space (X`space M)"
  have "\<H>(X) \<le> log b (measure ?X (space ?X))"
    by (rule entropy_le_space[OF simple_distributed[OF X]])
       (simp_all add: simple_distributed_finite[OF X] subset_eq integrable_count_space emeasure_count_space finite_measure_count_space)
  also have "measure ?X (space ?X) = card (X ` space M)"
    by (simp_all add: simple_distributed_finite[OF X] subset_eq emeasure_count_space measure_def)
  finally show ?thesis .
qed

subsection {* Conditional Mutual Information *}

definition (in prob_space)
  "conditional_mutual_information b MX MY MZ X Y Z \<equiv>
    mutual_information b MX (MY \<Otimes>\<^sub>M MZ) X (\<lambda>x. (Y x, Z x)) -
    mutual_information b MX MZ X Z"

abbreviation (in information_space)
  conditional_mutual_information_Pow ("\<I>'( _ ; _ | _ ')") where
  "\<I>(X ; Y | Z) \<equiv> conditional_mutual_information b
    (count_space (X ` space M)) (count_space (Y ` space M)) (count_space (Z ` space M)) X Y Z"

lemma (in information_space)
  assumes S: "sigma_finite_measure S" and T: "sigma_finite_measure T" and P: "sigma_finite_measure P"
  assumes Px[measurable]: "distributed M S X Px"
  assumes Pz[measurable]: "distributed M P Z Pz"
  assumes Pyz[measurable]: "distributed M (T \<Otimes>\<^sub>M P) (\<lambda>x. (Y x, Z x)) Pyz"
  assumes Pxz[measurable]: "distributed M (S \<Otimes>\<^sub>M P) (\<lambda>x. (X x, Z x)) Pxz"
  assumes Pxyz[measurable]: "distributed M (S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P) (\<lambda>x. (X x, Y x, Z x)) Pxyz"
  assumes I1: "integrable (S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P) (\<lambda>(x, y, z). Pxyz (x, y, z) * log b (Pxyz (x, y, z) / (Px x * Pyz (y, z))))"
  assumes I2: "integrable (S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P) (\<lambda>(x, y, z). Pxyz (x, y, z) * log b (Pxz (x, z) / (Px x * Pz z)))"
  shows conditional_mutual_information_generic_eq: "conditional_mutual_information b S T P X Y Z
    = (\<integral>(x, y, z). Pxyz (x, y, z) * log b (Pxyz (x, y, z) / (Pxz (x, z) * (Pyz (y,z) / Pz z))) \<partial>(S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P))" (is "?eq")
    and conditional_mutual_information_generic_nonneg: "0 \<le> conditional_mutual_information b S T P X Y Z" (is "?nonneg")
proof -
  interpret S: sigma_finite_measure S by fact
  interpret T: sigma_finite_measure T by fact
  interpret P: sigma_finite_measure P by fact
  interpret TP: pair_sigma_finite T P ..
  interpret SP: pair_sigma_finite S P ..
  interpret ST: pair_sigma_finite S T ..
  interpret SPT: pair_sigma_finite "S \<Otimes>\<^sub>M P" T ..
  interpret STP: pair_sigma_finite S "T \<Otimes>\<^sub>M P" ..
  interpret TPS: pair_sigma_finite "T \<Otimes>\<^sub>M P" S ..
  have TP: "sigma_finite_measure (T \<Otimes>\<^sub>M P)" ..
  have SP: "sigma_finite_measure (S \<Otimes>\<^sub>M P)" ..
  have YZ: "random_variable (T \<Otimes>\<^sub>M P) (\<lambda>x. (Y x, Z x))"
    using Pyz by (simp add: distributed_measurable)
  
  from Pxz Pxyz have distr_eq: "distr M (S \<Otimes>\<^sub>M P) (\<lambda>x. (X x, Z x)) =
    distr (distr M (S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P) (\<lambda>x. (X x, Y x, Z x))) (S \<Otimes>\<^sub>M P) (\<lambda>(x, y, z). (x, z))"
    by (simp add: comp_def distr_distr)

  have "mutual_information b S P X Z =
    (\<integral>x. Pxz x * log b (Pxz x / (Px (fst x) * Pz (snd x))) \<partial>(S \<Otimes>\<^sub>M P))"
    by (rule mutual_information_distr[OF S P Px Pz Pxz])
  also have "\<dots> = (\<integral>(x,y,z). Pxyz (x,y,z) * log b (Pxz (x,z) / (Px x * Pz z)) \<partial>(S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P))"
    using b_gt_1 Pxz Px Pz
    by (subst distributed_transform_integral[OF Pxyz Pxz, where T="\<lambda>(x, y, z). (x, z)"]) (auto simp: split_beta')
  finally have mi_eq:
    "mutual_information b S P X Z = (\<integral>(x,y,z). Pxyz (x,y,z) * log b (Pxz (x,z) / (Px x * Pz z)) \<partial>(S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P))" .
  
  have ae1: "AE x in S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P. Px (fst x) = 0 \<longrightarrow> Pxyz x = 0"
    by (intro subdensity_real[of fst, OF _ Pxyz Px]) auto
  moreover have ae2: "AE x in S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P. Pz (snd (snd x)) = 0 \<longrightarrow> Pxyz x = 0"
    by (intro subdensity_real[of "\<lambda>x. snd (snd x)", OF _ Pxyz Pz]) auto
  moreover have ae3: "AE x in S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P. Pxz (fst x, snd (snd x)) = 0 \<longrightarrow> Pxyz x = 0"
    by (intro subdensity_real[of "\<lambda>x. (fst x, snd (snd x))", OF _ Pxyz Pxz]) auto
  moreover have ae4: "AE x in S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P. Pyz (snd x) = 0 \<longrightarrow> Pxyz x = 0"
    by (intro subdensity_real[of snd, OF _ Pxyz Pyz]) auto
  moreover have ae5: "AE x in S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P. 0 \<le> Px (fst x)"
    using Px by (intro STP.AE_pair_measure) (auto simp: comp_def dest: distributed_real_AE)
  moreover have ae6: "AE x in S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P. 0 \<le> Pyz (snd x)"
    using Pyz by (intro STP.AE_pair_measure) (auto simp: comp_def dest: distributed_real_AE)
  moreover have ae7: "AE x in S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P. 0 \<le> Pz (snd (snd x))"
    using Pz Pz[THEN distributed_real_measurable]
    by (auto intro!: TP.AE_pair_measure STP.AE_pair_measure AE_I2[of S] dest: distributed_real_AE)
  moreover have ae8: "AE x in S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P. 0 \<le> Pxz (fst x, snd (snd x))"
    using Pxz[THEN distributed_real_AE, THEN SP.AE_pair]
    by (auto intro!: TP.AE_pair_measure STP.AE_pair_measure)
  moreover note Pxyz[THEN distributed_real_AE]
  ultimately have ae: "AE x in S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P.
    Pxyz x * log b (Pxyz x / (Px (fst x) * Pyz (snd x))) -
    Pxyz x * log b (Pxz (fst x, snd (snd x)) / (Px (fst x) * Pz (snd (snd x)))) =
    Pxyz x * log b (Pxyz x * Pz (snd (snd x)) / (Pxz (fst x, snd (snd x)) * Pyz (snd x))) "
  proof eventually_elim
    case (goal1 x)
    show ?case
    proof cases
      assume "Pxyz x \<noteq> 0"
      with goal1 have "0 < Px (fst x)" "0 < Pz (snd (snd x))" "0 < Pxz (fst x, snd (snd x))" "0 < Pyz (snd x)" "0 < Pxyz x"
        by auto
      then show ?thesis
        using b_gt_1 by (simp add: log_simps less_imp_le field_simps)
    qed simp
  qed
  with I1 I2 show ?eq
    unfolding conditional_mutual_information_def
    apply (subst mi_eq)
    apply (subst mutual_information_distr[OF S TP Px Pyz Pxyz])
    apply (subst integral_diff[symmetric])
    apply (auto intro!: integral_cong_AE simp: split_beta' simp del: integral_diff)
    done

  let ?P = "density (S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P) Pxyz"
  interpret P: prob_space ?P
    unfolding distributed_distr_eq_density[OF Pxyz, symmetric]
    by (rule prob_space_distr) simp

  let ?Q = "density (T \<Otimes>\<^sub>M P) Pyz"
  interpret Q: prob_space ?Q
    unfolding distributed_distr_eq_density[OF Pyz, symmetric]
    by (rule prob_space_distr) simp

  let ?f = "\<lambda>(x, y, z). Pxz (x, z) * (Pyz (y, z) / Pz z) / Pxyz (x, y, z)"

  from subdensity_real[of snd, OF _ Pyz Pz]
  have aeX1: "AE x in T \<Otimes>\<^sub>M P. Pz (snd x) = 0 \<longrightarrow> Pyz x = 0" by (auto simp: comp_def)
  have aeX2: "AE x in T \<Otimes>\<^sub>M P. 0 \<le> Pz (snd x)"
    using Pz by (intro TP.AE_pair_measure) (auto simp: comp_def dest: distributed_real_AE)

  have aeX3: "AE y in T \<Otimes>\<^sub>M P. (\<integral>\<^sup>+ x. ereal (Pxz (x, snd y)) \<partial>S) = ereal (Pz (snd y))"
    using Pz distributed_marginal_eq_joint2[OF P S Pz Pxz]
    by (intro TP.AE_pair_measure) (auto dest: distributed_real_AE)

  have "(\<integral>\<^sup>+ x. ?f x \<partial>?P) \<le> (\<integral>\<^sup>+ (x, y, z). Pxz (x, z) * (Pyz (y, z) / Pz z) \<partial>(S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P))"
    apply (subst nn_integral_density)
    apply simp
    apply (rule distributed_AE[OF Pxyz])
    apply auto []
    apply (rule nn_integral_mono_AE)
    using ae5 ae6 ae7 ae8
    apply eventually_elim
    apply auto
    done
  also have "\<dots> = (\<integral>\<^sup>+(y, z). \<integral>\<^sup>+ x. ereal (Pxz (x, z)) * ereal (Pyz (y, z) / Pz z) \<partial>S \<partial>T \<Otimes>\<^sub>M P)"
    by (subst STP.nn_integral_snd[symmetric]) (auto simp add: split_beta')
  also have "\<dots> = (\<integral>\<^sup>+x. ereal (Pyz x) * 1 \<partial>T \<Otimes>\<^sub>M P)"
    apply (rule nn_integral_cong_AE)
    using aeX1 aeX2 aeX3 distributed_AE[OF Pyz] AE_space
    apply eventually_elim
  proof (case_tac x, simp del: times_ereal.simps add: space_pair_measure)
    fix a b assume "Pz b = 0 \<longrightarrow> Pyz (a, b) = 0" "0 \<le> Pz b" "a \<in> space T \<and> b \<in> space P"
      "(\<integral>\<^sup>+ x. ereal (Pxz (x, b)) \<partial>S) = ereal (Pz b)" "0 \<le> Pyz (a, b)" 
    then show "(\<integral>\<^sup>+ x. ereal (Pxz (x, b)) * ereal (Pyz (a, b) / Pz b) \<partial>S) = ereal (Pyz (a, b))"
      by (subst nn_integral_multc)
         (auto split: prod.split)
  qed
  also have "\<dots> = 1"
    using Q.emeasure_space_1 distributed_AE[OF Pyz] distributed_distr_eq_density[OF Pyz]
    by (subst nn_integral_density[symmetric]) auto
  finally have le1: "(\<integral>\<^sup>+ x. ?f x \<partial>?P) \<le> 1" .
  also have "\<dots> < \<infinity>" by simp
  finally have fin: "(\<integral>\<^sup>+ x. ?f x \<partial>?P) \<noteq> \<infinity>" by simp

  have pos: "(\<integral>\<^sup>+x. ?f x \<partial>?P) \<noteq> 0"
    apply (subst nn_integral_density)
    apply simp
    apply (rule distributed_AE[OF Pxyz])
    apply auto []
    apply (simp add: split_beta')
  proof
    let ?g = "\<lambda>x. ereal (if Pxyz x = 0 then 0 else Pxz (fst x, snd (snd x)) * Pyz (snd x) / Pz (snd (snd x)))"
    assume "(\<integral>\<^sup>+x. ?g x \<partial>(S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P)) = 0"
    then have "AE x in S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P. ?g x \<le> 0"
      by (intro nn_integral_0_iff_AE[THEN iffD1]) auto
    then have "AE x in S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P. Pxyz x = 0"
      using ae1 ae2 ae3 ae4 ae5 ae6 ae7 ae8 Pxyz[THEN distributed_real_AE]
      by eventually_elim (auto split: split_if_asm simp: mult_le_0_iff divide_le_0_iff)
    then have "(\<integral>\<^sup>+ x. ereal (Pxyz x) \<partial>S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P) = 0"
      by (subst nn_integral_cong_AE[of _ "\<lambda>x. 0"]) auto
    with P.emeasure_space_1 show False
      by (subst (asm) emeasure_density) (auto cong: nn_integral_cong)
  qed

  have neg: "(\<integral>\<^sup>+ x. - ?f x \<partial>?P) = 0"
    apply (rule nn_integral_0_iff_AE[THEN iffD2])
    apply simp
    apply (subst AE_density)
    apply simp
    using ae5 ae6 ae7 ae8
    apply eventually_elim
    apply auto
    done

  have I3: "integrable (S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P) (\<lambda>(x, y, z). Pxyz (x, y, z) * log b (Pxyz (x, y, z) / (Pxz (x, z) * (Pyz (y,z) / Pz z))))"
    apply (rule integrable_cong_AE[THEN iffD1, OF _ _ _ integrable_diff[OF I1 I2]])
    using ae
    apply (auto simp: split_beta')
    done

  have "- log b 1 \<le> - log b (integral\<^sup>L ?P ?f)"
  proof (intro le_imp_neg_le log_le[OF b_gt_1])
    have If: "integrable ?P ?f"
      unfolding real_integrable_def
    proof (intro conjI)
      from neg show "(\<integral>\<^sup>+ x. - ?f x \<partial>?P) \<noteq> \<infinity>"
        by simp
      from fin show "(\<integral>\<^sup>+ x. ?f x \<partial>?P) \<noteq> \<infinity>"
        by simp
    qed simp
    then have "(\<integral>\<^sup>+ x. ?f x \<partial>?P) = (\<integral>x. ?f x \<partial>?P)"
      apply (rule nn_integral_eq_integral)
      apply (subst AE_density)
      apply simp
      using ae5 ae6 ae7 ae8
      apply eventually_elim
      apply auto
      done
    with nn_integral_nonneg[of ?P ?f] pos le1
    show "0 < (\<integral>x. ?f x \<partial>?P)" "(\<integral>x. ?f x \<partial>?P) \<le> 1"
      by (simp_all add: one_ereal_def)
  qed
  also have "- log b (integral\<^sup>L ?P ?f) \<le> (\<integral> x. - log b (?f x) \<partial>?P)"
  proof (rule P.jensens_inequality[where a=0 and b=1 and I="{0<..}"])
    show "AE x in ?P. ?f x \<in> {0<..}"
      unfolding AE_density[OF distributed_borel_measurable[OF Pxyz]]
      using ae1 ae2 ae3 ae4 ae5 ae6 ae7 ae8 Pxyz[THEN distributed_real_AE]
      by eventually_elim (auto)
    show "integrable ?P ?f"
      unfolding real_integrable_def 
      using fin neg by (auto simp: split_beta')
    show "integrable ?P (\<lambda>x. - log b (?f x))"
      apply (subst integrable_real_density)
      apply simp
      apply (auto intro!: distributed_real_AE[OF Pxyz]) []
      apply simp
      apply (rule integrable_cong_AE[THEN iffD1, OF _ _ _ I3])
      apply simp
      apply simp
      using ae1 ae2 ae3 ae4 ae5 ae6 ae7 ae8 Pxyz[THEN distributed_real_AE]
      apply eventually_elim
      apply (auto simp: log_divide_eq log_mult_eq zero_le_mult_iff zero_less_mult_iff zero_less_divide_iff field_simps)
      done
  qed (auto simp: b_gt_1 minus_log_convex)
  also have "\<dots> = conditional_mutual_information b S T P X Y Z"
    unfolding `?eq`
    apply (subst integral_real_density)
    apply simp
    apply (auto intro!: distributed_real_AE[OF Pxyz]) []
    apply simp
    apply (intro integral_cong_AE)
    using ae1 ae2 ae3 ae4 ae5 ae6 ae7 ae8 Pxyz[THEN distributed_real_AE]
    apply (auto simp: log_divide_eq zero_less_mult_iff zero_less_divide_iff field_simps)
    done
  finally show ?nonneg
    by simp
qed

lemma (in information_space)
  fixes Px :: "_ \<Rightarrow> real"
  assumes S: "sigma_finite_measure S" and T: "sigma_finite_measure T" and P: "sigma_finite_measure P"
  assumes Fx: "finite_entropy S X Px"
  assumes Fz: "finite_entropy P Z Pz"
  assumes Fyz: "finite_entropy (T \<Otimes>\<^sub>M P) (\<lambda>x. (Y x, Z x)) Pyz"
  assumes Fxz: "finite_entropy (S \<Otimes>\<^sub>M P) (\<lambda>x. (X x, Z x)) Pxz"
  assumes Fxyz: "finite_entropy (S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P) (\<lambda>x. (X x, Y x, Z x)) Pxyz"
  shows conditional_mutual_information_generic_eq': "conditional_mutual_information b S T P X Y Z
    = (\<integral>(x, y, z). Pxyz (x, y, z) * log b (Pxyz (x, y, z) / (Pxz (x, z) * (Pyz (y,z) / Pz z))) \<partial>(S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P))" (is "?eq")
    and conditional_mutual_information_generic_nonneg': "0 \<le> conditional_mutual_information b S T P X Y Z" (is "?nonneg")
proof -
  note Px = Fx[THEN finite_entropy_distributed, measurable]
  note Pz = Fz[THEN finite_entropy_distributed, measurable]
  note Pyz = Fyz[THEN finite_entropy_distributed, measurable]
  note Pxz = Fxz[THEN finite_entropy_distributed, measurable]
  note Pxyz = Fxyz[THEN finite_entropy_distributed, measurable]

  interpret S: sigma_finite_measure S by fact
  interpret T: sigma_finite_measure T by fact
  interpret P: sigma_finite_measure P by fact
  interpret TP: pair_sigma_finite T P ..
  interpret SP: pair_sigma_finite S P ..
  interpret ST: pair_sigma_finite S T ..
  interpret SPT: pair_sigma_finite "S \<Otimes>\<^sub>M P" T ..
  interpret STP: pair_sigma_finite S "T \<Otimes>\<^sub>M P" ..
  interpret TPS: pair_sigma_finite "T \<Otimes>\<^sub>M P" S ..
  have TP: "sigma_finite_measure (T \<Otimes>\<^sub>M P)" ..
  have SP: "sigma_finite_measure (S \<Otimes>\<^sub>M P)" ..

  from Pxz Pxyz have distr_eq: "distr M (S \<Otimes>\<^sub>M P) (\<lambda>x. (X x, Z x)) =
    distr (distr M (S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P) (\<lambda>x. (X x, Y x, Z x))) (S \<Otimes>\<^sub>M P) (\<lambda>(x, y, z). (x, z))"
    by (simp add: distr_distr comp_def)

  have "mutual_information b S P X Z =
    (\<integral>x. Pxz x * log b (Pxz x / (Px (fst x) * Pz (snd x))) \<partial>(S \<Otimes>\<^sub>M P))"
    by (rule mutual_information_distr[OF S P Px Pz Pxz])
  also have "\<dots> = (\<integral>(x,y,z). Pxyz (x,y,z) * log b (Pxz (x,z) / (Px x * Pz z)) \<partial>(S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P))"
    using b_gt_1 Pxz Px Pz
    by (subst distributed_transform_integral[OF Pxyz Pxz, where T="\<lambda>(x, y, z). (x, z)"])
       (auto simp: split_beta')
  finally have mi_eq:
    "mutual_information b S P X Z = (\<integral>(x,y,z). Pxyz (x,y,z) * log b (Pxz (x,z) / (Px x * Pz z)) \<partial>(S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P))" .
  
  have ae1: "AE x in S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P. Px (fst x) = 0 \<longrightarrow> Pxyz x = 0"
    by (intro subdensity_real[of fst, OF _ Pxyz Px]) auto
  moreover have ae2: "AE x in S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P. Pz (snd (snd x)) = 0 \<longrightarrow> Pxyz x = 0"
    by (intro subdensity_real[of "\<lambda>x. snd (snd x)", OF _ Pxyz Pz]) auto
  moreover have ae3: "AE x in S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P. Pxz (fst x, snd (snd x)) = 0 \<longrightarrow> Pxyz x = 0"
    by (intro subdensity_real[of "\<lambda>x. (fst x, snd (snd x))", OF _ Pxyz Pxz]) auto
  moreover have ae4: "AE x in S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P. Pyz (snd x) = 0 \<longrightarrow> Pxyz x = 0"
    by (intro subdensity_real[of snd, OF _ Pxyz Pyz]) auto
  moreover have ae5: "AE x in S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P. 0 \<le> Px (fst x)"
    using Px by (intro STP.AE_pair_measure) (auto dest: distributed_real_AE)
  moreover have ae6: "AE x in S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P. 0 \<le> Pyz (snd x)"
    using Pyz by (intro STP.AE_pair_measure) (auto dest: distributed_real_AE)
  moreover have ae7: "AE x in S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P. 0 \<le> Pz (snd (snd x))"
    using Pz Pz[THEN distributed_real_measurable] by (auto intro!: TP.AE_pair_measure STP.AE_pair_measure AE_I2[of S] dest: distributed_real_AE)
  moreover have ae8: "AE x in S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P. 0 \<le> Pxz (fst x, snd (snd x))"
    using Pxz[THEN distributed_real_AE, THEN SP.AE_pair]
    by (auto intro!: TP.AE_pair_measure STP.AE_pair_measure simp: comp_def)
  moreover note ae9 = Pxyz[THEN distributed_real_AE]
  ultimately have ae: "AE x in S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P.
    Pxyz x * log b (Pxyz x / (Px (fst x) * Pyz (snd x))) -
    Pxyz x * log b (Pxz (fst x, snd (snd x)) / (Px (fst x) * Pz (snd (snd x)))) =
    Pxyz x * log b (Pxyz x * Pz (snd (snd x)) / (Pxz (fst x, snd (snd x)) * Pyz (snd x))) "
  proof eventually_elim
    case (goal1 x)
    show ?case
    proof cases
      assume "Pxyz x \<noteq> 0"
      with goal1 have "0 < Px (fst x)" "0 < Pz (snd (snd x))" "0 < Pxz (fst x, snd (snd x))" "0 < Pyz (snd x)" "0 < Pxyz x"
        by auto
      then show ?thesis
        using b_gt_1 by (simp add: log_simps less_imp_le field_simps)
    qed simp
  qed

  have "integrable (S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P)
    (\<lambda>x. Pxyz x * log b (Pxyz x) - Pxyz x * log b (Px (fst x)) - Pxyz x * log b (Pyz (snd x)))"
    using finite_entropy_integrable[OF Fxyz]
    using finite_entropy_integrable_transform[OF Fx Pxyz, of fst]
    using finite_entropy_integrable_transform[OF Fyz Pxyz, of snd]
    by simp
  moreover have "(\<lambda>(x, y, z). Pxyz (x, y, z) * log b (Pxyz (x, y, z) / (Px x * Pyz (y, z)))) \<in> borel_measurable (S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P)"
    using Pxyz Px Pyz by simp
  ultimately have I1: "integrable (S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P) (\<lambda>(x, y, z). Pxyz (x, y, z) * log b (Pxyz (x, y, z) / (Px x * Pyz (y, z))))"
    apply (rule integrable_cong_AE_imp)
    using ae1 ae4 ae5 ae6 ae9
    by eventually_elim
       (auto simp: log_divide_eq log_mult_eq field_simps zero_less_mult_iff)

  have "integrable (S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P)
    (\<lambda>x. Pxyz x * log b (Pxz (fst x, snd (snd x))) - Pxyz x * log b (Px (fst x)) - Pxyz x * log b (Pz (snd (snd x))))"
    using finite_entropy_integrable_transform[OF Fxz Pxyz, of "\<lambda>x. (fst x, snd (snd x))"]
    using finite_entropy_integrable_transform[OF Fx Pxyz, of fst]
    using finite_entropy_integrable_transform[OF Fz Pxyz, of "snd \<circ> snd"]
    by simp
  moreover have "(\<lambda>(x, y, z). Pxyz (x, y, z) * log b (Pxz (x, z) / (Px x * Pz z))) \<in> borel_measurable (S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P)"
    using Pxyz Px Pz
    by auto
  ultimately have I2: "integrable (S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P) (\<lambda>(x, y, z). Pxyz (x, y, z) * log b (Pxz (x, z) / (Px x * Pz z)))"
    apply (rule integrable_cong_AE_imp)
    using ae1 ae2 ae3 ae4 ae5 ae6 ae7 ae8 ae9
    by eventually_elim
       (auto simp: log_divide_eq log_mult_eq field_simps zero_less_mult_iff)

  from ae I1 I2 show ?eq
    unfolding conditional_mutual_information_def
    apply (subst mi_eq)
    apply (subst mutual_information_distr[OF S TP Px Pyz Pxyz])
    apply (subst integral_diff[symmetric])
    apply (auto intro!: integral_cong_AE simp: split_beta' simp del: integral_diff)
    done

  let ?P = "density (S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P) Pxyz"
  interpret P: prob_space ?P
    unfolding distributed_distr_eq_density[OF Pxyz, symmetric] by (rule prob_space_distr) simp

  let ?Q = "density (T \<Otimes>\<^sub>M P) Pyz"
  interpret Q: prob_space ?Q
    unfolding distributed_distr_eq_density[OF Pyz, symmetric] by (rule prob_space_distr) simp

  let ?f = "\<lambda>(x, y, z). Pxz (x, z) * (Pyz (y, z) / Pz z) / Pxyz (x, y, z)"

  from subdensity_real[of snd, OF _ Pyz Pz]
  have aeX1: "AE x in T \<Otimes>\<^sub>M P. Pz (snd x) = 0 \<longrightarrow> Pyz x = 0" by (auto simp: comp_def)
  have aeX2: "AE x in T \<Otimes>\<^sub>M P. 0 \<le> Pz (snd x)"
    using Pz by (intro TP.AE_pair_measure) (auto dest: distributed_real_AE)

  have aeX3: "AE y in T \<Otimes>\<^sub>M P. (\<integral>\<^sup>+ x. ereal (Pxz (x, snd y)) \<partial>S) = ereal (Pz (snd y))"
    using Pz distributed_marginal_eq_joint2[OF P S Pz Pxz]
    by (intro TP.AE_pair_measure) (auto dest: distributed_real_AE)
  have "(\<integral>\<^sup>+ x. ?f x \<partial>?P) \<le> (\<integral>\<^sup>+ (x, y, z). Pxz (x, z) * (Pyz (y, z) / Pz z) \<partial>(S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P))"
    apply (subst nn_integral_density)
    apply (rule distributed_borel_measurable[OF Pxyz])
    apply (rule distributed_AE[OF Pxyz])
    apply simp
    apply (rule nn_integral_mono_AE)
    using ae5 ae6 ae7 ae8
    apply eventually_elim
    apply auto
    done
  also have "\<dots> = (\<integral>\<^sup>+(y, z). \<integral>\<^sup>+ x. ereal (Pxz (x, z)) * ereal (Pyz (y, z) / Pz z) \<partial>S \<partial>T \<Otimes>\<^sub>M P)"
    by (subst STP.nn_integral_snd[symmetric]) (auto simp add: split_beta')
  also have "\<dots> = (\<integral>\<^sup>+x. ereal (Pyz x) * 1 \<partial>T \<Otimes>\<^sub>M P)"
    apply (rule nn_integral_cong_AE)
    using aeX1 aeX2 aeX3 distributed_AE[OF Pyz] AE_space
    apply eventually_elim
  proof (case_tac x, simp del: times_ereal.simps add: space_pair_measure)
    fix a b assume "Pz b = 0 \<longrightarrow> Pyz (a, b) = 0" "0 \<le> Pz b" "a \<in> space T \<and> b \<in> space P"
      "(\<integral>\<^sup>+ x. ereal (Pxz (x, b)) \<partial>S) = ereal (Pz b)" "0 \<le> Pyz (a, b)" 
    then show "(\<integral>\<^sup>+ x. ereal (Pxz (x, b)) * ereal (Pyz (a, b) / Pz b) \<partial>S) = ereal (Pyz (a, b))"
      by (subst nn_integral_multc) auto
  qed
  also have "\<dots> = 1"
    using Q.emeasure_space_1 distributed_AE[OF Pyz] distributed_distr_eq_density[OF Pyz]
    by (subst nn_integral_density[symmetric]) auto
  finally have le1: "(\<integral>\<^sup>+ x. ?f x \<partial>?P) \<le> 1" .
  also have "\<dots> < \<infinity>" by simp
  finally have fin: "(\<integral>\<^sup>+ x. ?f x \<partial>?P) \<noteq> \<infinity>" by simp

  have pos: "(\<integral>\<^sup>+ x. ?f x \<partial>?P) \<noteq> 0"
    apply (subst nn_integral_density)
    apply simp
    apply (rule distributed_AE[OF Pxyz])
    apply simp
    apply (simp add: split_beta')
  proof
    let ?g = "\<lambda>x. ereal (if Pxyz x = 0 then 0 else Pxz (fst x, snd (snd x)) * Pyz (snd x) / Pz (snd (snd x)))"
    assume "(\<integral>\<^sup>+ x. ?g x \<partial>(S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P)) = 0"
    then have "AE x in S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P. ?g x \<le> 0"
      by (intro nn_integral_0_iff_AE[THEN iffD1]) (auto intro!: borel_measurable_ereal measurable_If)
    then have "AE x in S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P. Pxyz x = 0"
      using ae1 ae2 ae3 ae4 ae5 ae6 ae7 ae8 Pxyz[THEN distributed_real_AE]
      by eventually_elim (auto split: split_if_asm simp: mult_le_0_iff divide_le_0_iff)
    then have "(\<integral>\<^sup>+ x. ereal (Pxyz x) \<partial>S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P) = 0"
      by (subst nn_integral_cong_AE[of _ "\<lambda>x. 0"]) auto
    with P.emeasure_space_1 show False
      by (subst (asm) emeasure_density) (auto cong: nn_integral_cong)
  qed

  have neg: "(\<integral>\<^sup>+ x. - ?f x \<partial>?P) = 0"
    apply (rule nn_integral_0_iff_AE[THEN iffD2])
    apply (auto simp: split_beta') []
    apply (subst AE_density)
    apply (auto simp: split_beta') []
    using ae5 ae6 ae7 ae8
    apply eventually_elim
    apply auto
    done

  have I3: "integrable (S \<Otimes>\<^sub>M T \<Otimes>\<^sub>M P) (\<lambda>(x, y, z). Pxyz (x, y, z) * log b (Pxyz (x, y, z) / (Pxz (x, z) * (Pyz (y,z) / Pz z))))"
    apply (rule integrable_cong_AE[THEN iffD1, OF _ _ _ integrable_diff[OF I1 I2]])
    using ae
    apply (auto simp: split_beta')
    done

  have "- log b 1 \<le> - log b (integral\<^sup>L ?P ?f)"
  proof (intro le_imp_neg_le log_le[OF b_gt_1])
    have If: "integrable ?P ?f"
      unfolding real_integrable_def
    proof (intro conjI)
      from neg show "(\<integral>\<^sup>+ x. - ?f x \<partial>?P) \<noteq> \<infinity>"
        by simp
      from fin show "(\<integral>\<^sup>+ x. ?f x \<partial>?P) \<noteq> \<infinity>"
        by simp
    qed simp
    then have "(\<integral>\<^sup>+ x. ?f x \<partial>?P) = (\<integral>x. ?f x \<partial>?P)"
      apply (rule nn_integral_eq_integral)
      apply (subst AE_density)
      apply simp
      using ae5 ae6 ae7 ae8
      apply eventually_elim
      apply auto
      done
    with nn_integral_nonneg[of ?P ?f] pos le1
    show "0 < (\<integral>x. ?f x \<partial>?P)" "(\<integral>x. ?f x \<partial>?P) \<le> 1"
      by (simp_all add: one_ereal_def)
  qed
  also have "- log b (integral\<^sup>L ?P ?f) \<le> (\<integral> x. - log b (?f x) \<partial>?P)"
  proof (rule P.jensens_inequality[where a=0 and b=1 and I="{0<..}"])
    show "AE x in ?P. ?f x \<in> {0<..}"
      unfolding AE_density[OF distributed_borel_measurable[OF Pxyz]]
      using ae1 ae2 ae3 ae4 ae5 ae6 ae7 ae8 Pxyz[THEN distributed_real_AE]
      by eventually_elim (auto)
    show "integrable ?P ?f"
      unfolding real_integrable_def
      using fin neg by (auto simp: split_beta')
    show "integrable ?P (\<lambda>x. - log b (?f x))"
      apply (subst integrable_real_density)
      apply simp
      apply (auto intro!: distributed_real_AE[OF Pxyz]) []
      apply simp
      apply (rule integrable_cong_AE[THEN iffD1, OF _ _ _ I3])
      apply simp
      apply simp
      using ae1 ae2 ae3 ae4 ae5 ae6 ae7 ae8 Pxyz[THEN distributed_real_AE]
      apply eventually_elim
      apply (auto simp: log_divide_eq log_mult_eq zero_le_mult_iff zero_less_mult_iff zero_less_divide_iff field_simps)
      done
  qed (auto simp: b_gt_1 minus_log_convex)
  also have "\<dots> = conditional_mutual_information b S T P X Y Z"
    unfolding `?eq`
    apply (subst integral_real_density)
    apply simp
    apply (auto intro!: distributed_real_AE[OF Pxyz]) []
    apply simp
    apply (intro integral_cong_AE)
    using ae1 ae2 ae3 ae4 ae5 ae6 ae7 ae8 Pxyz[THEN distributed_real_AE]
    apply (auto simp: log_divide_eq zero_less_mult_iff zero_less_divide_iff field_simps)
    done
  finally show ?nonneg
    by simp
qed

lemma (in information_space) conditional_mutual_information_eq:
  assumes Pz: "simple_distributed M Z Pz"
  assumes Pyz: "simple_distributed M (\<lambda>x. (Y x, Z x)) Pyz"
  assumes Pxz: "simple_distributed M (\<lambda>x. (X x, Z x)) Pxz"
  assumes Pxyz: "simple_distributed M (\<lambda>x. (X x, Y x, Z x)) Pxyz"
  shows "\<I>(X ; Y | Z) =
   (\<Sum>(x, y, z)\<in>(\<lambda>x. (X x, Y x, Z x))`space M. Pxyz (x, y, z) * log b (Pxyz (x, y, z) / (Pxz (x, z) * (Pyz (y,z) / Pz z))))"
proof (subst conditional_mutual_information_generic_eq[OF _ _ _ _
    simple_distributed[OF Pz] simple_distributed_joint[OF Pyz] simple_distributed_joint[OF Pxz]
    simple_distributed_joint2[OF Pxyz]])
  note simple_distributed_joint2_finite[OF Pxyz, simp]
  show "sigma_finite_measure (count_space (X ` space M))"
    by (simp add: sigma_finite_measure_count_space_finite)
  show "sigma_finite_measure (count_space (Y ` space M))"
    by (simp add: sigma_finite_measure_count_space_finite)
  show "sigma_finite_measure (count_space (Z ` space M))"
    by (simp add: sigma_finite_measure_count_space_finite)
  have "count_space (X ` space M) \<Otimes>\<^sub>M count_space (Y ` space M) \<Otimes>\<^sub>M count_space (Z ` space M) =
      count_space (X`space M \<times> Y`space M \<times> Z`space M)"
    (is "?P = ?C")
    by (simp add: pair_measure_count_space)

  let ?Px = "\<lambda>x. measure M (X -` {x} \<inter> space M)"
  have "(\<lambda>x. (X x, Z x)) \<in> measurable M (count_space (X ` space M) \<Otimes>\<^sub>M count_space (Z ` space M))"
    using simple_distributed_joint[OF Pxz] by (rule distributed_measurable)
  from measurable_comp[OF this measurable_fst]
  have "random_variable (count_space (X ` space M)) X"
    by (simp add: comp_def)
  then have "simple_function M X"    
    unfolding simple_function_def by (auto simp: measurable_count_space_eq2)
  then have "simple_distributed M X ?Px"
    by (rule simple_distributedI) auto
  then show "distributed M (count_space (X ` space M)) X ?Px"
    by (rule simple_distributed)

  let ?f = "(\<lambda>x. if x \<in> (\<lambda>x. (X x, Y x, Z x)) ` space M then Pxyz x else 0)"
  let ?g = "(\<lambda>x. if x \<in> (\<lambda>x. (Y x, Z x)) ` space M then Pyz x else 0)"
  let ?h = "(\<lambda>x. if x \<in> (\<lambda>x. (X x, Z x)) ` space M then Pxz x else 0)"
  show
      "integrable ?P (\<lambda>(x, y, z). ?f (x, y, z) * log b (?f (x, y, z) / (?Px x * ?g (y, z))))"
      "integrable ?P (\<lambda>(x, y, z). ?f (x, y, z) * log b (?h (x, z) / (?Px x * Pz z)))"
    by (auto intro!: integrable_count_space simp: pair_measure_count_space)
  let ?i = "\<lambda>x y z. ?f (x, y, z) * log b (?f (x, y, z) / (?h (x, z) * (?g (y, z) / Pz z)))"
  let ?j = "\<lambda>x y z. Pxyz (x, y, z) * log b (Pxyz (x, y, z) / (Pxz (x, z) * (Pyz (y,z) / Pz z)))"
  have "(\<lambda>(x, y, z). ?i x y z) = (\<lambda>x. if x \<in> (\<lambda>x. (X x, Y x, Z x)) ` space M then ?j (fst x) (fst (snd x)) (snd (snd x)) else 0)"
    by (auto intro!: ext)
  then show "(\<integral> (x, y, z). ?i x y z \<partial>?P) = (\<Sum>(x, y, z)\<in>(\<lambda>x. (X x, Y x, Z x)) ` space M. ?j x y z)"
    by (auto intro!: setsum.cong simp add: `?P = ?C` lebesgue_integral_count_space_finite simple_distributed_finite setsum.If_cases split_beta')
qed

lemma (in information_space) conditional_mutual_information_nonneg:
  assumes X: "simple_function M X" and Y: "simple_function M Y" and Z: "simple_function M Z"
  shows "0 \<le> \<I>(X ; Y | Z)"
proof -
  have [simp]: "count_space (X ` space M) \<Otimes>\<^sub>M count_space (Y ` space M) \<Otimes>\<^sub>M count_space (Z ` space M) =
      count_space (X`space M \<times> Y`space M \<times> Z`space M)"
    by (simp add: pair_measure_count_space X Y Z simple_functionD)
  note sf = sigma_finite_measure_count_space_finite[OF simple_functionD(1)]
  note sd = simple_distributedI[OF _ refl]
  note sp = simple_function_Pair
  show ?thesis
   apply (rule conditional_mutual_information_generic_nonneg[OF sf[OF X] sf[OF Y] sf[OF Z]])
   apply (rule simple_distributed[OF sd[OF X]])
   apply (rule simple_distributed[OF sd[OF Z]])
   apply (rule simple_distributed_joint[OF sd[OF sp[OF Y Z]]])
   apply (rule simple_distributed_joint[OF sd[OF sp[OF X Z]]])
   apply (rule simple_distributed_joint2[OF sd[OF sp[OF X sp[OF Y Z]]]])
   apply (auto intro!: integrable_count_space simp: X Y Z simple_functionD)
   done
qed

subsection {* Conditional Entropy *}

definition (in prob_space)
  "conditional_entropy b S T X Y = - (\<integral>(x, y). log b (real (RN_deriv (S \<Otimes>\<^sub>M T) (distr M (S \<Otimes>\<^sub>M T) (\<lambda>x. (X x, Y x))) (x, y)) / 
    real (RN_deriv T (distr M T Y) y)) \<partial>distr M (S \<Otimes>\<^sub>M T) (\<lambda>x. (X x, Y x)))"

abbreviation (in information_space)
  conditional_entropy_Pow ("\<H>'(_ | _')") where
  "\<H>(X | Y) \<equiv> conditional_entropy b (count_space (X`space M)) (count_space (Y`space M)) X Y"

lemma (in information_space) conditional_entropy_generic_eq:
  fixes Pxy :: "_ \<Rightarrow> real" and Py :: "'c \<Rightarrow> real"
  assumes S: "sigma_finite_measure S" and T: "sigma_finite_measure T"
  assumes Py[measurable]: "distributed M T Y Py"
  assumes Pxy[measurable]: "distributed M (S \<Otimes>\<^sub>M T) (\<lambda>x. (X x, Y x)) Pxy"
  shows "conditional_entropy b S T X Y = - (\<integral>(x, y). Pxy (x, y) * log b (Pxy (x, y) / Py y) \<partial>(S \<Otimes>\<^sub>M T))"
proof -
  interpret S: sigma_finite_measure S by fact
  interpret T: sigma_finite_measure T by fact
  interpret ST: pair_sigma_finite S T ..

  have "AE x in density (S \<Otimes>\<^sub>M T) (\<lambda>x. ereal (Pxy x)). Pxy x = real (RN_deriv (S \<Otimes>\<^sub>M T) (distr M (S \<Otimes>\<^sub>M T) (\<lambda>x. (X x, Y x))) x)"
    unfolding AE_density[OF distributed_borel_measurable, OF Pxy]
    unfolding distributed_distr_eq_density[OF Pxy]
    using distributed_RN_deriv[OF Pxy]
    by auto
  moreover
  have "AE x in density (S \<Otimes>\<^sub>M T) (\<lambda>x. ereal (Pxy x)). Py (snd x) = real (RN_deriv T (distr M T Y) (snd x))"
    unfolding AE_density[OF distributed_borel_measurable, OF Pxy]
    unfolding distributed_distr_eq_density[OF Py]
    apply (rule ST.AE_pair_measure)
    apply auto
    using distributed_RN_deriv[OF Py]
    apply auto
    done    
  ultimately
  have "conditional_entropy b S T X Y = - (\<integral>x. Pxy x * log b (Pxy x / Py (snd x)) \<partial>(S \<Otimes>\<^sub>M T))"
    unfolding conditional_entropy_def neg_equal_iff_equal
    apply (subst integral_real_density[symmetric])
    apply (auto simp: distributed_real_AE[OF Pxy] distributed_distr_eq_density[OF Pxy]
                intro!: integral_cong_AE)
    done
  then show ?thesis by (simp add: split_beta')
qed

lemma (in information_space) conditional_entropy_eq_entropy:
  fixes Px :: "'b \<Rightarrow> real" and Py :: "'c \<Rightarrow> real"
  assumes S: "sigma_finite_measure S" and T: "sigma_finite_measure T"
  assumes Py[measurable]: "distributed M T Y Py"
  assumes Pxy[measurable]: "distributed M (S \<Otimes>\<^sub>M T) (\<lambda>x. (X x, Y x)) Pxy"
  assumes I1: "integrable (S \<Otimes>\<^sub>M T) (\<lambda>x. Pxy x * log b (Pxy x))"
  assumes I2: "integrable (S \<Otimes>\<^sub>M T) (\<lambda>x. Pxy x * log b (Py (snd x)))"
  shows "conditional_entropy b S T X Y = entropy b (S \<Otimes>\<^sub>M T) (\<lambda>x. (X x, Y x)) - entropy b T Y"
proof -
  interpret S: sigma_finite_measure S by fact
  interpret T: sigma_finite_measure T by fact
  interpret ST: pair_sigma_finite S T ..

  have "entropy b T Y = - (\<integral>y. Py y * log b (Py y) \<partial>T)"
    by (rule entropy_distr[OF Py])
  also have "\<dots> = - (\<integral>(x,y). Pxy (x,y) * log b (Py y) \<partial>(S \<Otimes>\<^sub>M T))"
    using b_gt_1 Py[THEN distributed_real_measurable]
    by (subst distributed_transform_integral[OF Pxy Py, where T=snd]) (auto intro!: integral_cong)
  finally have e_eq: "entropy b T Y = - (\<integral>(x,y). Pxy (x,y) * log b (Py y) \<partial>(S \<Otimes>\<^sub>M T))" .

  have ae2: "AE x in S \<Otimes>\<^sub>M T. Py (snd x) = 0 \<longrightarrow> Pxy x = 0"
    by (intro subdensity_real[of snd, OF _ Pxy Py]) (auto intro: measurable_Pair)
  moreover have ae4: "AE x in S \<Otimes>\<^sub>M T. 0 \<le> Py (snd x)"
    using Py by (intro ST.AE_pair_measure) (auto simp: comp_def intro!: measurable_snd'' dest: distributed_real_AE distributed_real_measurable)
  moreover note ae5 = Pxy[THEN distributed_real_AE]
  ultimately have "AE x in S \<Otimes>\<^sub>M T. 0 \<le> Pxy x \<and> 0 \<le> Py (snd x) \<and>
    (Pxy x = 0 \<or> (Pxy x \<noteq> 0 \<longrightarrow> 0 < Pxy x \<and> 0 < Py (snd x)))"
    by eventually_elim auto
  then have ae: "AE x in S \<Otimes>\<^sub>M T.
     Pxy x * log b (Pxy x) - Pxy x * log b (Py (snd x)) = Pxy x * log b (Pxy x / Py (snd x))"
    by eventually_elim (auto simp: log_simps field_simps b_gt_1)
  have "conditional_entropy b S T X Y = 
    - (\<integral>x. Pxy x * log b (Pxy x) - Pxy x * log b (Py (snd x)) \<partial>(S \<Otimes>\<^sub>M T))"
    unfolding conditional_entropy_generic_eq[OF S T Py Pxy] neg_equal_iff_equal
    apply (intro integral_cong_AE)
    using ae
    apply auto
    done
  also have "\<dots> = - (\<integral>x. Pxy x * log b (Pxy x) \<partial>(S \<Otimes>\<^sub>M T)) - - (\<integral>x.  Pxy x * log b (Py (snd x)) \<partial>(S \<Otimes>\<^sub>M T))"
    by (simp add: integral_diff[OF I1 I2])
  finally show ?thesis 
    unfolding conditional_entropy_generic_eq[OF S T Py Pxy] entropy_distr[OF Pxy] e_eq
    by (simp add: split_beta')
qed

lemma (in information_space) conditional_entropy_eq_entropy_simple:
  assumes X: "simple_function M X" and Y: "simple_function M Y"
  shows "\<H>(X | Y) = entropy b (count_space (X`space M) \<Otimes>\<^sub>M count_space (Y`space M)) (\<lambda>x. (X x, Y x)) - \<H>(Y)"
proof -
  have "count_space (X ` space M) \<Otimes>\<^sub>M count_space (Y ` space M) = count_space (X`space M \<times> Y`space M)"
    (is "?P = ?C") using X Y by (simp add: simple_functionD pair_measure_count_space)
  show ?thesis
    by (rule conditional_entropy_eq_entropy sigma_finite_measure_count_space_finite
                 simple_functionD  X Y simple_distributed simple_distributedI[OF _ refl]
                 simple_distributed_joint simple_function_Pair integrable_count_space)+
       (auto simp: `?P = ?C` intro!: integrable_count_space simple_functionD  X Y)
qed

lemma (in information_space) conditional_entropy_eq:
  assumes Y: "simple_distributed M Y Py"
  assumes XY: "simple_distributed M (\<lambda>x. (X x, Y x)) Pxy"
    shows "\<H>(X | Y) = - (\<Sum>(x, y)\<in>(\<lambda>x. (X x, Y x)) ` space M. Pxy (x, y) * log b (Pxy (x, y) / Py y))"
proof (subst conditional_entropy_generic_eq[OF _ _
  simple_distributed[OF Y] simple_distributed_joint[OF XY]])
  have "finite ((\<lambda>x. (X x, Y x))`space M)"
    using XY unfolding simple_distributed_def by auto
  from finite_imageI[OF this, of fst]
  have [simp]: "finite (X`space M)"
    by (simp add: image_comp comp_def)
  note Y[THEN simple_distributed_finite, simp]
  show "sigma_finite_measure (count_space (X ` space M))"
    by (simp add: sigma_finite_measure_count_space_finite)
  show "sigma_finite_measure (count_space (Y ` space M))"
    by (simp add: sigma_finite_measure_count_space_finite)
  let ?f = "(\<lambda>x. if x \<in> (\<lambda>x. (X x, Y x)) ` space M then Pxy x else 0)"
  have "count_space (X ` space M) \<Otimes>\<^sub>M count_space (Y ` space M) = count_space (X`space M \<times> Y`space M)"
    (is "?P = ?C")
    using Y by (simp add: simple_distributed_finite pair_measure_count_space)
  have eq: "(\<lambda>(x, y). ?f (x, y) * log b (?f (x, y) / Py y)) =
    (\<lambda>x. if x \<in> (\<lambda>x. (X x, Y x)) ` space M then Pxy x * log b (Pxy x / Py (snd x)) else 0)"
    by auto
  from Y show "- (\<integral> (x, y). ?f (x, y) * log b (?f (x, y) / Py y) \<partial>?P) =
    - (\<Sum>(x, y)\<in>(\<lambda>x. (X x, Y x)) ` space M. Pxy (x, y) * log b (Pxy (x, y) / Py y))"
    by (auto intro!: setsum.cong simp add: `?P = ?C` lebesgue_integral_count_space_finite simple_distributed_finite eq setsum.If_cases split_beta')
qed

lemma (in information_space) conditional_mutual_information_eq_conditional_entropy:
  assumes X: "simple_function M X" and Y: "simple_function M Y"
  shows "\<I>(X ; X | Y) = \<H>(X | Y)"
proof -
  def Py \<equiv> "\<lambda>x. if x \<in> Y`space M then measure M (Y -` {x} \<inter> space M) else 0"
  def Pxy \<equiv> "\<lambda>x. if x \<in> (\<lambda>x. (X x, Y x))`space M then measure M ((\<lambda>x. (X x, Y x)) -` {x} \<inter> space M) else 0"
  def Pxxy \<equiv> "\<lambda>x. if x \<in> (\<lambda>x. (X x, X x, Y x))`space M then measure M ((\<lambda>x. (X x, X x, Y x)) -` {x} \<inter> space M) else 0"
  let ?M = "X`space M \<times> X`space M \<times> Y`space M"

  note XY = simple_function_Pair[OF X Y]
  note XXY = simple_function_Pair[OF X XY]
  have Py: "simple_distributed M Y Py"
    using Y by (rule simple_distributedI) (auto simp: Py_def)
  have Pxy: "simple_distributed M (\<lambda>x. (X x, Y x)) Pxy"
    using XY by (rule simple_distributedI) (auto simp: Pxy_def)
  have Pxxy: "simple_distributed M (\<lambda>x. (X x, X x, Y x)) Pxxy"
    using XXY by (rule simple_distributedI) (auto simp: Pxxy_def)
  have eq: "(\<lambda>x. (X x, X x, Y x)) ` space M = (\<lambda>(x, y). (x, x, y)) ` (\<lambda>x. (X x, Y x)) ` space M"
    by auto
  have inj: "\<And>A. inj_on (\<lambda>(x, y). (x, x, y)) A"
    by (auto simp: inj_on_def)
  have Pxxy_eq: "\<And>x y. Pxxy (x, x, y) = Pxy (x, y)"
    by (auto simp: Pxxy_def Pxy_def intro!: arg_cong[where f=prob])
  have "AE x in count_space ((\<lambda>x. (X x, Y x))`space M). Py (snd x) = 0 \<longrightarrow> Pxy x = 0"
    by (intro subdensity_real[of snd, OF _ Pxy[THEN simple_distributed] Py[THEN simple_distributed]]) (auto intro: measurable_Pair)
  then show ?thesis
    apply (subst conditional_mutual_information_eq[OF Py Pxy Pxy Pxxy])
    apply (subst conditional_entropy_eq[OF Py Pxy])
    apply (auto intro!: setsum.cong simp: Pxxy_eq setsum_negf[symmetric] eq setsum.reindex[OF inj]
                log_simps zero_less_mult_iff zero_le_mult_iff field_simps mult_less_0_iff AE_count_space)
    using Py[THEN simple_distributed, THEN distributed_real_AE] Pxy[THEN simple_distributed, THEN distributed_real_AE]
  apply (auto simp add: not_le[symmetric] AE_count_space)
    done
qed

lemma (in information_space) conditional_entropy_nonneg:
  assumes X: "simple_function M X" and Y: "simple_function M Y" shows "0 \<le> \<H>(X | Y)"
  using conditional_mutual_information_eq_conditional_entropy[OF X Y] conditional_mutual_information_nonneg[OF X X Y]
  by simp

subsection {* Equalities *}

lemma (in information_space) mutual_information_eq_entropy_conditional_entropy_distr:
  fixes Px :: "'b \<Rightarrow> real" and Py :: "'c \<Rightarrow> real" and Pxy :: "('b \<times> 'c) \<Rightarrow> real"
  assumes S: "sigma_finite_measure S" and T: "sigma_finite_measure T"
  assumes Px[measurable]: "distributed M S X Px" and Py[measurable]: "distributed M T Y Py"
  assumes Pxy[measurable]: "distributed M (S \<Otimes>\<^sub>M T) (\<lambda>x. (X x, Y x)) Pxy"
  assumes Ix: "integrable(S \<Otimes>\<^sub>M T) (\<lambda>x. Pxy x * log b (Px (fst x)))"
  assumes Iy: "integrable(S \<Otimes>\<^sub>M T) (\<lambda>x. Pxy x * log b (Py (snd x)))"
  assumes Ixy: "integrable(S \<Otimes>\<^sub>M T) (\<lambda>x. Pxy x * log b (Pxy x))"
  shows  "mutual_information b S T X Y = entropy b S X + entropy b T Y - entropy b (S \<Otimes>\<^sub>M T) (\<lambda>x. (X x, Y x))"
proof -
  have X: "entropy b S X = - (\<integral>x. Pxy x * log b (Px (fst x)) \<partial>(S \<Otimes>\<^sub>M T))"
    using b_gt_1 Px[THEN distributed_real_measurable]
    apply (subst entropy_distr[OF Px])
    apply (subst distributed_transform_integral[OF Pxy Px, where T=fst])
    apply (auto intro!: integral_cong)
    done

  have Y: "entropy b T Y = - (\<integral>x. Pxy x * log b (Py (snd x)) \<partial>(S \<Otimes>\<^sub>M T))"
    using b_gt_1 Py[THEN distributed_real_measurable]
    apply (subst entropy_distr[OF Py])
    apply (subst distributed_transform_integral[OF Pxy Py, where T=snd])
    apply (auto intro!: integral_cong)
    done

  interpret S: sigma_finite_measure S by fact
  interpret T: sigma_finite_measure T by fact
  interpret ST: pair_sigma_finite S T ..
  have ST: "sigma_finite_measure (S \<Otimes>\<^sub>M T)" ..

  have XY: "entropy b (S \<Otimes>\<^sub>M T) (\<lambda>x. (X x, Y x)) = - (\<integral>x. Pxy x * log b (Pxy x) \<partial>(S \<Otimes>\<^sub>M T))"
    by (subst entropy_distr[OF Pxy]) (auto intro!: integral_cong)
  
  have "AE x in S \<Otimes>\<^sub>M T. Px (fst x) = 0 \<longrightarrow> Pxy x = 0"
    by (intro subdensity_real[of fst, OF _ Pxy Px]) (auto intro: measurable_Pair)
  moreover have "AE x in S \<Otimes>\<^sub>M T. Py (snd x) = 0 \<longrightarrow> Pxy x = 0"
    by (intro subdensity_real[of snd, OF _ Pxy Py]) (auto intro: measurable_Pair)
  moreover have "AE x in S \<Otimes>\<^sub>M T. 0 \<le> Px (fst x)"
    using Px by (intro ST.AE_pair_measure) (auto simp: comp_def intro!: measurable_fst'' dest: distributed_real_AE distributed_real_measurable)
  moreover have "AE x in S \<Otimes>\<^sub>M T. 0 \<le> Py (snd x)"
    using Py by (intro ST.AE_pair_measure) (auto simp: comp_def intro!: measurable_snd'' dest: distributed_real_AE distributed_real_measurable)
  moreover note Pxy[THEN distributed_real_AE]
  ultimately have "AE x in S \<Otimes>\<^sub>M T. Pxy x * log b (Pxy x) - Pxy x * log b (Px (fst x)) - Pxy x * log b (Py (snd x)) = 
    Pxy x * log b (Pxy x / (Px (fst x) * Py (snd x)))"
    (is "AE x in _. ?f x = ?g x")
  proof eventually_elim
    case (goal1 x)
    show ?case
    proof cases
      assume "Pxy x \<noteq> 0"
      with goal1 have "0 < Px (fst x)" "0 < Py (snd x)" "0 < Pxy x"
        by auto
      then show ?thesis
        using b_gt_1 by (simp add: log_simps less_imp_le field_simps)
    qed simp
  qed

  have "entropy b S X + entropy b T Y - entropy b (S \<Otimes>\<^sub>M T) (\<lambda>x. (X x, Y x)) = integral\<^sup>L (S \<Otimes>\<^sub>M T) ?f"
    unfolding X Y XY
    apply (subst integral_diff)
    apply (intro integrable_diff Ixy Ix Iy)+
    apply (subst integral_diff)
    apply (intro Ixy Ix Iy)+
    apply (simp add: field_simps)
    done
  also have "\<dots> = integral\<^sup>L (S \<Otimes>\<^sub>M T) ?g"
    using `AE x in _. ?f x = ?g x` by (intro integral_cong_AE) auto
  also have "\<dots> = mutual_information b S T X Y"
    by (rule mutual_information_distr[OF S T Px Py Pxy, symmetric])
  finally show ?thesis ..
qed

lemma (in information_space) mutual_information_eq_entropy_conditional_entropy':
  fixes Px :: "'b \<Rightarrow> real" and Py :: "'c \<Rightarrow> real" and Pxy :: "('b \<times> 'c) \<Rightarrow> real"
  assumes S: "sigma_finite_measure S" and T: "sigma_finite_measure T"
  assumes Px: "distributed M S X Px" and Py: "distributed M T Y Py"
  assumes Pxy: "distributed M (S \<Otimes>\<^sub>M T) (\<lambda>x. (X x, Y x)) Pxy"
  assumes Ix: "integrable(S \<Otimes>\<^sub>M T) (\<lambda>x. Pxy x * log b (Px (fst x)))"
  assumes Iy: "integrable(S \<Otimes>\<^sub>M T) (\<lambda>x. Pxy x * log b (Py (snd x)))"
  assumes Ixy: "integrable(S \<Otimes>\<^sub>M T) (\<lambda>x. Pxy x * log b (Pxy x))"
  shows  "mutual_information b S T X Y = entropy b S X - conditional_entropy b S T X Y"
  using
    mutual_information_eq_entropy_conditional_entropy_distr[OF S T Px Py Pxy Ix Iy Ixy]
    conditional_entropy_eq_entropy[OF S T Py Pxy Ixy Iy]
  by simp

lemma (in information_space) mutual_information_eq_entropy_conditional_entropy:
  assumes sf_X: "simple_function M X" and sf_Y: "simple_function M Y"
  shows  "\<I>(X ; Y) = \<H>(X) - \<H>(X | Y)"
proof -
  have X: "simple_distributed M X (\<lambda>x. measure M (X -` {x} \<inter> space M))"
    using sf_X by (rule simple_distributedI) auto
  have Y: "simple_distributed M Y (\<lambda>x. measure M (Y -` {x} \<inter> space M))"
    using sf_Y by (rule simple_distributedI) auto
  have sf_XY: "simple_function M (\<lambda>x. (X x, Y x))"
    using sf_X sf_Y by (rule simple_function_Pair)
  then have XY: "simple_distributed M (\<lambda>x. (X x, Y x)) (\<lambda>x. measure M ((\<lambda>x. (X x, Y x)) -` {x} \<inter> space M))"
    by (rule simple_distributedI) auto
  from simple_distributed_joint_finite[OF this, simp]
  have eq: "count_space (X ` space M) \<Otimes>\<^sub>M count_space (Y ` space M) = count_space (X ` space M \<times> Y ` space M)"
    by (simp add: pair_measure_count_space)

  have "\<I>(X ; Y) = \<H>(X) + \<H>(Y) - entropy b (count_space (X`space M) \<Otimes>\<^sub>M count_space (Y`space M)) (\<lambda>x. (X x, Y x))"
    using sigma_finite_measure_count_space_finite sigma_finite_measure_count_space_finite simple_distributed[OF X] simple_distributed[OF Y] simple_distributed_joint[OF XY]
    by (rule mutual_information_eq_entropy_conditional_entropy_distr) (auto simp: eq integrable_count_space)
  then show ?thesis
    unfolding conditional_entropy_eq_entropy_simple[OF sf_X sf_Y] by simp
qed

lemma (in information_space) mutual_information_nonneg_simple:
  assumes sf_X: "simple_function M X" and sf_Y: "simple_function M Y"
  shows  "0 \<le> \<I>(X ; Y)"
proof -
  have X: "simple_distributed M X (\<lambda>x. measure M (X -` {x} \<inter> space M))"
    using sf_X by (rule simple_distributedI) auto
  have Y: "simple_distributed M Y (\<lambda>x. measure M (Y -` {x} \<inter> space M))"
    using sf_Y by (rule simple_distributedI) auto

  have sf_XY: "simple_function M (\<lambda>x. (X x, Y x))"
    using sf_X sf_Y by (rule simple_function_Pair)
  then have XY: "simple_distributed M (\<lambda>x. (X x, Y x)) (\<lambda>x. measure M ((\<lambda>x. (X x, Y x)) -` {x} \<inter> space M))"
    by (rule simple_distributedI) auto

  from simple_distributed_joint_finite[OF this, simp]
  have eq: "count_space (X ` space M) \<Otimes>\<^sub>M count_space (Y ` space M) = count_space (X ` space M \<times> Y ` space M)"
    by (simp add: pair_measure_count_space)

  show ?thesis
    by (rule mutual_information_nonneg[OF _ _ simple_distributed[OF X] simple_distributed[OF Y] simple_distributed_joint[OF XY]])
       (simp_all add: eq integrable_count_space sigma_finite_measure_count_space_finite)
qed

lemma (in information_space) conditional_entropy_less_eq_entropy:
  assumes X: "simple_function M X" and Z: "simple_function M Z"
  shows "\<H>(X | Z) \<le> \<H>(X)"
proof -
  have "0 \<le> \<I>(X ; Z)" using X Z by (rule mutual_information_nonneg_simple)
  also have "\<I>(X ; Z) = \<H>(X) - \<H>(X | Z)" using mutual_information_eq_entropy_conditional_entropy[OF assms] .
  finally show ?thesis by auto
qed

lemma (in information_space) 
  fixes Px :: "'b \<Rightarrow> real" and Py :: "'c \<Rightarrow> real" and Pxy :: "('b \<times> 'c) \<Rightarrow> real"
  assumes S: "sigma_finite_measure S" and T: "sigma_finite_measure T"
  assumes Px: "finite_entropy S X Px" and Py: "finite_entropy T Y Py"
  assumes Pxy: "finite_entropy (S \<Otimes>\<^sub>M T) (\<lambda>x. (X x, Y x)) Pxy"
  shows "conditional_entropy b S T X Y \<le> entropy b S X"
proof -

  have "0 \<le> mutual_information b S T X Y" 
    by (rule mutual_information_nonneg') fact+
  also have "\<dots> = entropy b S X - conditional_entropy b S T X Y"
    apply (rule mutual_information_eq_entropy_conditional_entropy')
    using assms
    by (auto intro!: finite_entropy_integrable finite_entropy_distributed
      finite_entropy_integrable_transform[OF Px]
      finite_entropy_integrable_transform[OF Py])
  finally show ?thesis by auto
qed

lemma (in information_space) entropy_chain_rule:
  assumes X: "simple_function M X" and Y: "simple_function M Y"
  shows  "\<H>(\<lambda>x. (X x, Y x)) = \<H>(X) + \<H>(Y|X)"
proof -
  note XY = simple_distributedI[OF simple_function_Pair[OF X Y] refl]
  note YX = simple_distributedI[OF simple_function_Pair[OF Y X] refl]
  note simple_distributed_joint_finite[OF this, simp]
  let ?f = "\<lambda>x. prob ((\<lambda>x. (X x, Y x)) -` {x} \<inter> space M)"
  let ?g = "\<lambda>x. prob ((\<lambda>x. (Y x, X x)) -` {x} \<inter> space M)"
  let ?h = "\<lambda>x. if x \<in> (\<lambda>x. (Y x, X x)) ` space M then prob ((\<lambda>x. (Y x, X x)) -` {x} \<inter> space M) else 0"
  have "\<H>(\<lambda>x. (X x, Y x)) = - (\<Sum>x\<in>(\<lambda>x. (X x, Y x)) ` space M. ?f x * log b (?f x))"
    using XY by (rule entropy_simple_distributed)
  also have "\<dots> = - (\<Sum>x\<in>(\<lambda>(x, y). (y, x)) ` (\<lambda>x. (X x, Y x)) ` space M. ?g x * log b (?g x))"
    by (subst (2) setsum.reindex) (auto simp: inj_on_def intro!: setsum.cong arg_cong[where f="\<lambda>A. prob A * log b (prob A)"])
  also have "\<dots> = - (\<Sum>x\<in>(\<lambda>x. (Y x, X x)) ` space M. ?h x * log b (?h x))"
    by (auto intro!: setsum.cong)
  also have "\<dots> = entropy b (count_space (Y ` space M) \<Otimes>\<^sub>M count_space (X ` space M)) (\<lambda>x. (Y x, X x))"
    by (subst entropy_distr[OF simple_distributed_joint[OF YX]])
       (auto simp: pair_measure_count_space sigma_finite_measure_count_space_finite lebesgue_integral_count_space_finite
             cong del: setsum.cong  intro!: setsum.mono_neutral_left)
  finally have "\<H>(\<lambda>x. (X x, Y x)) = entropy b (count_space (Y ` space M) \<Otimes>\<^sub>M count_space (X ` space M)) (\<lambda>x. (Y x, X x))" .
  then show ?thesis
    unfolding conditional_entropy_eq_entropy_simple[OF Y X] by simp
qed

lemma (in information_space) entropy_partition:
  assumes X: "simple_function M X"
  shows "\<H>(X) = \<H>(f \<circ> X) + \<H>(X|f \<circ> X)"
proof -
  note fX = simple_function_compose[OF X, of f]  
  have eq: "(\<lambda>x. ((f \<circ> X) x, X x)) ` space M = (\<lambda>x. (f x, x)) ` X ` space M" by auto
  have inj: "\<And>A. inj_on (\<lambda>x. (f x, x)) A"
    by (auto simp: inj_on_def)
  show ?thesis
    apply (subst entropy_chain_rule[symmetric, OF fX X])
    apply (subst entropy_simple_distributed[OF simple_distributedI[OF simple_function_Pair[OF fX X] refl]])
    apply (subst entropy_simple_distributed[OF simple_distributedI[OF X refl]])
    unfolding eq
    apply (subst setsum.reindex[OF inj])
    apply (auto intro!: setsum.cong arg_cong[where f="\<lambda>A. prob A * log b (prob A)"])
    done
qed

corollary (in information_space) entropy_data_processing:
  assumes X: "simple_function M X" shows "\<H>(f \<circ> X) \<le> \<H>(X)"
proof -
  note fX = simple_function_compose[OF X, of f]
  from X have "\<H>(X) = \<H>(f\<circ>X) + \<H>(X|f\<circ>X)" by (rule entropy_partition)
  then show "\<H>(f \<circ> X) \<le> \<H>(X)"
    by (auto intro: conditional_entropy_nonneg[OF X fX])
qed

corollary (in information_space) entropy_of_inj:
  assumes X: "simple_function M X" and inj: "inj_on f (X`space M)"
  shows "\<H>(f \<circ> X) = \<H>(X)"
proof (rule antisym)
  show "\<H>(f \<circ> X) \<le> \<H>(X)" using entropy_data_processing[OF X] .
next
  have sf: "simple_function M (f \<circ> X)"
    using X by auto
  have "\<H>(X) = \<H>(the_inv_into (X`space M) f \<circ> (f \<circ> X))"
    unfolding o_assoc
    apply (subst entropy_simple_distributed[OF simple_distributedI[OF X refl]])
    apply (subst entropy_simple_distributed[OF simple_distributedI[OF simple_function_compose[OF X]], where f="\<lambda>x. prob (X -` {x} \<inter> space M)"])
    apply (auto intro!: setsum.cong arg_cong[where f=prob] image_eqI simp: the_inv_into_f_f[OF inj] comp_def)
    done
  also have "... \<le> \<H>(f \<circ> X)"
    using entropy_data_processing[OF sf] .
  finally show "\<H>(X) \<le> \<H>(f \<circ> X)" .
qed

end
