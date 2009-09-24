(* Author:     Johannes Hoelzl <hoelzl@in.tum.de> 2008 / 2009 *)

header {* Prove Real Valued Inequalities by Computation *}

theory Approximation
imports Complex_Main Float Reflection Dense_Linear_Order Efficient_Nat
begin

section "Horner Scheme"

subsection {* Define auxiliary helper @{text horner} function *}

primrec horner :: "(nat \<Rightarrow> nat) \<Rightarrow> (nat \<Rightarrow> nat \<Rightarrow> nat) \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> real \<Rightarrow> real" where
"horner F G 0 i k x       = 0" |
"horner F G (Suc n) i k x = 1 / real k - x * horner F G n (F i) (G i k) x"

lemma horner_schema': fixes x :: real  and a :: "nat \<Rightarrow> real"
  shows "a 0 - x * (\<Sum> i=0..<n. (-1)^i * a (Suc i) * x^i) = (\<Sum> i=0..<Suc n. (-1)^i * a i * x^i)"
proof -
  have shift_pow: "\<And>i. - (x * ((-1)^i * a (Suc i) * x ^ i)) = (-1)^(Suc i) * a (Suc i) * x ^ (Suc i)" by auto
  show ?thesis unfolding setsum_right_distrib shift_pow real_diff_def setsum_negf[symmetric] setsum_head_upt_Suc[OF zero_less_Suc]
    setsum_reindex[OF inj_Suc, unfolded comp_def, symmetric, of "\<lambda> n. (-1)^n  *a n * x^n"] by auto
qed

lemma horner_schema: fixes f :: "nat \<Rightarrow> nat" and G :: "nat \<Rightarrow> nat \<Rightarrow> nat" and F :: "nat \<Rightarrow> nat"
  assumes f_Suc: "\<And>n. f (Suc n) = G ((F ^^ n) s) (f n)"
  shows "horner F G n ((F ^^ j') s) (f j') x = (\<Sum> j = 0..< n. -1 ^ j * (1 / real (f (j' + j))) * x ^ j)"
proof (induct n arbitrary: i k j')
  case (Suc n)

  show ?case unfolding horner.simps Suc[where j'="Suc j'", unfolded funpow.simps comp_def f_Suc]
    using horner_schema'[of "\<lambda> j. 1 / real (f (j' + j))"] by auto
qed auto

lemma horner_bounds':
  assumes "0 \<le> real x" and f_Suc: "\<And>n. f (Suc n) = G ((F ^^ n) s) (f n)"
  and lb_0: "\<And> i k x. lb 0 i k x = 0"
  and lb_Suc: "\<And> n i k x. lb (Suc n) i k x = lapprox_rat prec 1 (int k) - x * (ub n (F i) (G i k) x)"
  and ub_0: "\<And> i k x. ub 0 i k x = 0"
  and ub_Suc: "\<And> n i k x. ub (Suc n) i k x = rapprox_rat prec 1 (int k) - x * (lb n (F i) (G i k) x)"
  shows "real (lb n ((F ^^ j') s) (f j') x) \<le> horner F G n ((F ^^ j') s) (f j') (real x) \<and>
         horner F G n ((F ^^ j') s) (f j') (real x) \<le> real (ub n ((F ^^ j') s) (f j') x)"
  (is "?lb n j' \<le> ?horner n j' \<and> ?horner n j' \<le> ?ub n j'")
proof (induct n arbitrary: j')
  case 0 thus ?case unfolding lb_0 ub_0 horner.simps by auto
next
  case (Suc n)
  have "?lb (Suc n) j' \<le> ?horner (Suc n) j'" unfolding lb_Suc ub_Suc horner.simps real_of_float_sub diff_def
  proof (rule add_mono)
    show "real (lapprox_rat prec 1 (int (f j'))) \<le> 1 / real (f j')" using lapprox_rat[of prec 1  "int (f j')"] by auto
    from Suc[where j'="Suc j'", unfolded funpow.simps comp_def f_Suc, THEN conjunct2] `0 \<le> real x`
    show "- real (x * ub n (F ((F ^^ j') s)) (G ((F ^^ j') s) (f j')) x) \<le> - (real x * horner F G n (F ((F ^^ j') s)) (G ((F ^^ j') s) (f j')) (real x))"
      unfolding real_of_float_mult neg_le_iff_le by (rule mult_left_mono)
  qed
  moreover have "?horner (Suc n) j' \<le> ?ub (Suc n) j'" unfolding ub_Suc ub_Suc horner.simps real_of_float_sub diff_def
  proof (rule add_mono)
    show "1 / real (f j') \<le> real (rapprox_rat prec 1 (int (f j')))" using rapprox_rat[of 1 "int (f j')" prec] by auto
    from Suc[where j'="Suc j'", unfolded funpow.simps comp_def f_Suc, THEN conjunct1] `0 \<le> real x`
    show "- (real x * horner F G n (F ((F ^^ j') s)) (G ((F ^^ j') s) (f j')) (real x)) \<le>
          - real (x * lb n (F ((F ^^ j') s)) (G ((F ^^ j') s) (f j')) x)"
      unfolding real_of_float_mult neg_le_iff_le by (rule mult_left_mono)
  qed
  ultimately show ?case by blast
qed

subsection "Theorems for floating point functions implementing the horner scheme"

text {*

Here @{term_type "f :: nat \<Rightarrow> nat"} is the sequence defining the Taylor series, the coefficients are
all alternating and reciprocs. We use @{term G} and @{term F} to describe the computation of @{term f}.

*}

lemma horner_bounds: fixes F :: "nat \<Rightarrow> nat" and G :: "nat \<Rightarrow> nat \<Rightarrow> nat"
  assumes "0 \<le> real x" and f_Suc: "\<And>n. f (Suc n) = G ((F ^^ n) s) (f n)"
  and lb_0: "\<And> i k x. lb 0 i k x = 0"
  and lb_Suc: "\<And> n i k x. lb (Suc n) i k x = lapprox_rat prec 1 (int k) - x * (ub n (F i) (G i k) x)"
  and ub_0: "\<And> i k x. ub 0 i k x = 0"
  and ub_Suc: "\<And> n i k x. ub (Suc n) i k x = rapprox_rat prec 1 (int k) - x * (lb n (F i) (G i k) x)"
  shows "real (lb n ((F ^^ j') s) (f j') x) \<le> (\<Sum>j=0..<n. -1 ^ j * (1 / real (f (j' + j))) * real x ^ j)" (is "?lb") and
    "(\<Sum>j=0..<n. -1 ^ j * (1 / real (f (j' + j))) * (real x ^ j)) \<le> real (ub n ((F ^^ j') s) (f j') x)" (is "?ub")
proof -
  have "?lb  \<and> ?ub"
    using horner_bounds'[where lb=lb, OF `0 \<le> real x` f_Suc lb_0 lb_Suc ub_0 ub_Suc]
    unfolding horner_schema[where f=f, OF f_Suc] .
  thus "?lb" and "?ub" by auto
qed

lemma horner_bounds_nonpos: fixes F :: "nat \<Rightarrow> nat" and G :: "nat \<Rightarrow> nat \<Rightarrow> nat"
  assumes "real x \<le> 0" and f_Suc: "\<And>n. f (Suc n) = G ((F ^^ n) s) (f n)"
  and lb_0: "\<And> i k x. lb 0 i k x = 0"
  and lb_Suc: "\<And> n i k x. lb (Suc n) i k x = lapprox_rat prec 1 (int k) + x * (ub n (F i) (G i k) x)"
  and ub_0: "\<And> i k x. ub 0 i k x = 0"
  and ub_Suc: "\<And> n i k x. ub (Suc n) i k x = rapprox_rat prec 1 (int k) + x * (lb n (F i) (G i k) x)"
  shows "real (lb n ((F ^^ j') s) (f j') x) \<le> (\<Sum>j=0..<n. (1 / real (f (j' + j))) * real x ^ j)" (is "?lb") and
    "(\<Sum>j=0..<n. (1 / real (f (j' + j))) * (real x ^ j)) \<le> real (ub n ((F ^^ j') s) (f j') x)" (is "?ub")
proof -
  { fix x y z :: float have "x - y * z = x + - y * z"
      by (cases x, cases y, cases z, simp add: plus_float.simps minus_float_def uminus_float.simps times_float.simps algebra_simps)
  } note diff_mult_minus = this

  { fix x :: float have "- (- x) = x" by (cases x, auto simp add: uminus_float.simps) } note minus_minus = this

  have move_minus: "real (-x) = -1 * real x" by auto

  have sum_eq: "(\<Sum>j=0..<n. (1 / real (f (j' + j))) * real x ^ j) =
    (\<Sum>j = 0..<n. -1 ^ j * (1 / real (f (j' + j))) * real (- x) ^ j)"
  proof (rule setsum_cong, simp)
    fix j assume "j \<in> {0 ..< n}"
    show "1 / real (f (j' + j)) * real x ^ j = -1 ^ j * (1 / real (f (j' + j))) * real (- x) ^ j"
      unfolding move_minus power_mult_distrib real_mult_assoc[symmetric]
      unfolding real_mult_commute unfolding real_mult_assoc[of "-1 ^ j", symmetric] power_mult_distrib[symmetric]
      by auto
  qed

  have "0 \<le> real (-x)" using assms by auto
  from horner_bounds[where G=G and F=F and f=f and s=s and prec=prec
    and lb="\<lambda> n i k x. lb n i k (-x)" and ub="\<lambda> n i k x. ub n i k (-x)", unfolded lb_Suc ub_Suc diff_mult_minus,
    OF this f_Suc lb_0 refl ub_0 refl]
  show "?lb" and "?ub" unfolding minus_minus sum_eq
    by auto
qed

subsection {* Selectors for next even or odd number *}

text {*

The horner scheme computes alternating series. To get the upper and lower bounds we need to
guarantee to access a even or odd member. To do this we use @{term get_odd} and @{term get_even}.

*}

definition get_odd :: "nat \<Rightarrow> nat" where
  "get_odd n = (if odd n then n else (Suc n))"

definition get_even :: "nat \<Rightarrow> nat" where
  "get_even n = (if even n then n else (Suc n))"

lemma get_odd[simp]: "odd (get_odd n)" unfolding get_odd_def by (cases "odd n", auto)
lemma get_even[simp]: "even (get_even n)" unfolding get_even_def by (cases "even n", auto)
lemma get_odd_ex: "\<exists> k. Suc k = get_odd n \<and> odd (Suc k)"
proof (cases "odd n")
  case True hence "0 < n" by (rule odd_pos)
  from gr0_implies_Suc[OF this] obtain k where "Suc k = n" by auto
  thus ?thesis unfolding get_odd_def if_P[OF True] using True[unfolded `Suc k = n`[symmetric]] by blast
next
  case False hence "odd (Suc n)" by auto
  thus ?thesis unfolding get_odd_def if_not_P[OF False] by blast
qed

lemma get_even_double: "\<exists>i. get_even n = 2 * i" using get_even[unfolded even_mult_two_ex] .
lemma get_odd_double: "\<exists>i. get_odd n = 2 * i + 1" using get_odd[unfolded odd_Suc_mult_two_ex] by auto

section "Power function"

definition float_power_bnds :: "nat \<Rightarrow> float \<Rightarrow> float \<Rightarrow> float * float" where
"float_power_bnds n l u = (if odd n \<or> 0 < l then (l ^ n, u ^ n)
                      else if u < 0         then (u ^ n, l ^ n)
                                            else (0, (max (-l) u) ^ n))"

lemma float_power_bnds: assumes "(l1, u1) = float_power_bnds n l u" and "x \<in> {real l .. real u}"
  shows "x ^ n \<in> {real l1..real u1}"
proof (cases "even n")
  case True
  show ?thesis
  proof (cases "0 < l")
    case True hence "odd n \<or> 0 < l" and "0 \<le> real l" unfolding less_float_def by auto
    have u1: "u1 = u ^ n" and l1: "l1 = l ^ n" using assms unfolding float_power_bnds_def if_P[OF `odd n \<or> 0 < l`] by auto
    have "real l ^ n \<le> x ^ n" and "x ^ n \<le> real u ^ n " using `0 \<le> real l` and assms unfolding atLeastAtMost_iff using power_mono[of "real l" x] power_mono[of x "real u"] by auto
    thus ?thesis using assms `0 < l` unfolding atLeastAtMost_iff l1 u1 float_power less_float_def by auto
  next
    case False hence P: "\<not> (odd n \<or> 0 < l)" using `even n` by auto
    show ?thesis
    proof (cases "u < 0")
      case True hence "0 \<le> - real u" and "- real u \<le> - x" and "0 \<le> - x" and "-x \<le> - real l" using assms unfolding less_float_def by auto
      hence "real u ^ n \<le> x ^ n" and "x ^ n \<le> real l ^ n" using power_mono[of  "-x" "-real l" n] power_mono[of "-real u" "-x" n]
	unfolding power_minus_even[OF `even n`] by auto
      moreover have u1: "u1 = l ^ n" and l1: "l1 = u ^ n" using assms unfolding float_power_bnds_def if_not_P[OF P] if_P[OF True] by auto
      ultimately show ?thesis using float_power by auto
    next
      case False
      have "\<bar>x\<bar> \<le> real (max (-l) u)"
      proof (cases "-l \<le> u")
	case True thus ?thesis unfolding max_def if_P[OF True] using assms unfolding le_float_def by auto
      next
	case False thus ?thesis unfolding max_def if_not_P[OF False] using assms unfolding le_float_def by auto
      qed
      hence x_abs: "\<bar>x\<bar> \<le> \<bar>real (max (-l) u)\<bar>" by auto
      have u1: "u1 = (max (-l) u) ^ n" and l1: "l1 = 0" using assms unfolding float_power_bnds_def if_not_P[OF P] if_not_P[OF False] by auto
      show ?thesis unfolding atLeastAtMost_iff l1 u1 float_power using zero_le_even_power[OF `even n`] power_mono_even[OF `even n` x_abs] by auto
    qed
  qed
next
  case False hence "odd n \<or> 0 < l" by auto
  have u1: "u1 = u ^ n" and l1: "l1 = l ^ n" using assms unfolding float_power_bnds_def if_P[OF `odd n \<or> 0 < l`] by auto
  have "real l ^ n \<le> x ^ n" and "x ^ n \<le> real u ^ n " using assms unfolding atLeastAtMost_iff using power_mono_odd[OF False] by auto
  thus ?thesis unfolding atLeastAtMost_iff l1 u1 float_power less_float_def by auto
qed

lemma bnds_power: "\<forall> x l u. (l1, u1) = float_power_bnds n l u \<and> x \<in> {real l .. real u} \<longrightarrow> real l1 \<le> x ^ n \<and> x ^ n \<le> real u1"
  using float_power_bnds by auto

section "Square root"

text {*

The square root computation is implemented as newton iteration. As first first step we use the
nearest power of two greater than the square root.

*}

fun sqrt_iteration :: "nat \<Rightarrow> nat \<Rightarrow> float \<Rightarrow> float" where
"sqrt_iteration prec 0 (Float m e) = Float 1 ((e + bitlen m) div 2 + 1)" |
"sqrt_iteration prec (Suc m) x = (let y = sqrt_iteration prec m x
                                  in Float 1 -1 * (y + float_divr prec x y))"

function ub_sqrt lb_sqrt :: "nat \<Rightarrow> float \<Rightarrow> float" where
"ub_sqrt prec x = (if 0 < x then (sqrt_iteration prec prec x)
              else if x < 0 then - lb_sqrt prec (- x)
                            else 0)" |
"lb_sqrt prec x = (if 0 < x then (float_divl prec x (sqrt_iteration prec prec x))
              else if x < 0 then - ub_sqrt prec (- x)
                            else 0)"
by pat_completeness auto
termination by (relation "measure (\<lambda> v. let (prec, x) = sum_case id id v in (if x < 0 then 1 else 0))", auto simp add: less_float_def)

declare lb_sqrt.simps[simp del]
declare ub_sqrt.simps[simp del]

lemma sqrt_ub_pos_pos_1:
  assumes "sqrt x < b" and "0 < b" and "0 < x"
  shows "sqrt x < (b + x / b)/2"
proof -
  from assms have "0 < (b - sqrt x) ^ 2 " by simp
  also have "\<dots> = b ^ 2 - 2 * b * sqrt x + (sqrt x) ^ 2" by algebra
  also have "\<dots> = b ^ 2 - 2 * b * sqrt x + x" using assms by (simp add: real_sqrt_pow2)
  finally have "0 < b ^ 2 - 2 * b * sqrt x + x" by assumption
  hence "0 < b / 2 - sqrt x + x / (2 * b)" using assms
    by (simp add: field_simps power2_eq_square)
  thus ?thesis by (simp add: field_simps)
qed

lemma sqrt_iteration_bound: assumes "0 < real x"
  shows "sqrt (real x) < real (sqrt_iteration prec n x)"
proof (induct n)
  case 0
  show ?case
  proof (cases x)
    case (Float m e)
    hence "0 < m" using float_pos_m_pos[unfolded less_float_def] assms by auto
    hence "0 < sqrt (real m)" by auto

    have int_nat_bl: "int (nat (bitlen m)) = bitlen m" using bitlen_ge0 by auto

    have "real x = (real m / 2^nat (bitlen m)) * pow2 (e + int (nat (bitlen m)))"
      unfolding pow2_add pow2_int Float real_of_float_simp by auto
    also have "\<dots> < 1 * pow2 (e + int (nat (bitlen m)))"
    proof (rule mult_strict_right_mono, auto)
      show "real m < 2^nat (bitlen m)" using bitlen_bounds[OF `0 < m`, THEN conjunct2]
	unfolding real_of_int_less_iff[of m, symmetric] by auto
    qed
    finally have "sqrt (real x) < sqrt (pow2 (e + bitlen m))" unfolding int_nat_bl by auto
    also have "\<dots> \<le> pow2 ((e + bitlen m) div 2 + 1)"
    proof -
      let ?E = "e + bitlen m"
      have E_mod_pow: "pow2 (?E mod 2) < 4"
      proof (cases "?E mod 2 = 1")
	case True thus ?thesis by auto
      next
	case False
	have "0 \<le> ?E mod 2" by auto
	have "?E mod 2 < 2" by auto
	from this[THEN zless_imp_add1_zle]
	have "?E mod 2 \<le> 0" using False by auto
	from xt1(5)[OF `0 \<le> ?E mod 2` this]
	show ?thesis by auto
      qed
      hence "sqrt (pow2 (?E mod 2)) < sqrt (2 * 2)" by auto
      hence E_mod_pow: "sqrt (pow2 (?E mod 2)) < 2" unfolding real_sqrt_abs2 by auto

      have E_eq: "pow2 ?E = pow2 (?E div 2 + ?E div 2 + ?E mod 2)" by auto
      have "sqrt (pow2 ?E) = sqrt (pow2 (?E div 2) * pow2 (?E div 2) * pow2 (?E mod 2))"
	unfolding E_eq unfolding pow2_add ..
      also have "\<dots> = pow2 (?E div 2) * sqrt (pow2 (?E mod 2))"
	unfolding real_sqrt_mult[of _ "pow2 (?E mod 2)"] real_sqrt_abs2 by auto
      also have "\<dots> < pow2 (?E div 2) * 2"
	by (rule mult_strict_left_mono, auto intro: E_mod_pow)
      also have "\<dots> = pow2 (?E div 2 + 1)" unfolding zadd_commute[of _ 1] pow2_add1 by auto
      finally show ?thesis by auto
    qed
    finally show ?thesis
      unfolding Float sqrt_iteration.simps real_of_float_simp by auto
  qed
next
  case (Suc n)
  let ?b = "sqrt_iteration prec n x"
  have "0 < sqrt (real x)" using `0 < real x` by auto
  also have "\<dots> < real ?b" using Suc .
  finally have "sqrt (real x) < (real ?b + real x / real ?b)/2" using sqrt_ub_pos_pos_1[OF Suc _ `0 < real x`] by auto
  also have "\<dots> \<le> (real ?b + real (float_divr prec x ?b))/2" by (rule divide_right_mono, auto simp add: float_divr)
  also have "\<dots> = real (Float 1 -1) * (real ?b + real (float_divr prec x ?b))" by auto
  finally show ?case unfolding sqrt_iteration.simps Let_def real_of_float_mult real_of_float_add right_distrib .
qed

lemma sqrt_iteration_lower_bound: assumes "0 < real x"
  shows "0 < real (sqrt_iteration prec n x)" (is "0 < ?sqrt")
proof -
  have "0 < sqrt (real x)" using assms by auto
  also have "\<dots> < ?sqrt" using sqrt_iteration_bound[OF assms] .
  finally show ?thesis .
qed

lemma lb_sqrt_lower_bound: assumes "0 \<le> real x"
  shows "0 \<le> real (lb_sqrt prec x)"
proof (cases "0 < x")
  case True hence "0 < real x" and "0 \<le> x" using `0 \<le> real x` unfolding less_float_def le_float_def by auto
  hence "0 < sqrt_iteration prec prec x" unfolding less_float_def using sqrt_iteration_lower_bound by auto
  hence "0 \<le> real (float_divl prec x (sqrt_iteration prec prec x))" using float_divl_lower_bound[OF `0 \<le> x`] unfolding le_float_def by auto
  thus ?thesis unfolding lb_sqrt.simps using True by auto
next
  case False with `0 \<le> real x` have "real x = 0" unfolding less_float_def by auto
  thus ?thesis unfolding lb_sqrt.simps less_float_def by auto
qed

lemma bnds_sqrt':
  shows "sqrt (real x) \<in> { real (lb_sqrt prec x) .. real (ub_sqrt prec x) }"
proof -
  { fix x :: float assume "0 < x"
    hence "0 < real x" and "0 \<le> real x" unfolding less_float_def by auto
    hence sqrt_gt0: "0 < sqrt (real x)" by auto
    hence sqrt_ub: "sqrt (real x) < real (sqrt_iteration prec prec x)" using sqrt_iteration_bound by auto

    have "real (float_divl prec x (sqrt_iteration prec prec x)) \<le>
          real x / real (sqrt_iteration prec prec x)" by (rule float_divl)
    also have "\<dots> < real x / sqrt (real x)"
      by (rule divide_strict_left_mono[OF sqrt_ub `0 < real x`
               mult_pos_pos[OF order_less_trans[OF sqrt_gt0 sqrt_ub] sqrt_gt0]])
    also have "\<dots> = sqrt (real x)"
      unfolding inverse_eq_iff_eq[of _ "sqrt (real x)", symmetric]
	        sqrt_divide_self_eq[OF `0 \<le> real x`, symmetric] by auto
    finally have "real (lb_sqrt prec x) \<le> sqrt (real x)"
      unfolding lb_sqrt.simps if_P[OF `0 < x`] by auto }
  note lb = this

  { fix x :: float assume "0 < x"
    hence "0 < real x" unfolding less_float_def by auto
    hence "0 < sqrt (real x)" by auto
    hence "sqrt (real x) < real (sqrt_iteration prec prec x)"
      using sqrt_iteration_bound by auto
    hence "sqrt (real x) \<le> real (ub_sqrt prec x)"
      unfolding ub_sqrt.simps if_P[OF `0 < x`] by auto }
  note ub = this

  show ?thesis
  proof (cases "0 < x")
    case True with lb ub show ?thesis by auto
  next case False show ?thesis
  proof (cases "real x = 0")
    case True thus ?thesis
      by (auto simp add: less_float_def lb_sqrt.simps ub_sqrt.simps)
  next
    case False with `\<not> 0 < x` have "x < 0" and "0 < -x"
      by (auto simp add: less_float_def)

    with `\<not> 0 < x`
    show ?thesis using lb[OF `0 < -x`] ub[OF `0 < -x`]
      by (auto simp add: real_sqrt_minus lb_sqrt.simps ub_sqrt.simps)
  qed qed
qed

lemma bnds_sqrt: "\<forall> x lx ux. (l, u) = (lb_sqrt prec lx, ub_sqrt prec ux) \<and> x \<in> {real lx .. real ux} \<longrightarrow> real l \<le> sqrt x \<and> sqrt x \<le> real u"
proof ((rule allI) +, rule impI, erule conjE, rule conjI)
  fix x lx ux
  assume "(l, u) = (lb_sqrt prec lx, ub_sqrt prec ux)"
    and x: "x \<in> {real lx .. real ux}"
  hence l: "l = lb_sqrt prec lx " and u: "u = ub_sqrt prec ux" by auto

  have "sqrt (real lx) \<le> sqrt x" using x by auto
  from order_trans[OF _ this]
  show "real l \<le> sqrt x" unfolding l using bnds_sqrt'[of lx prec] by auto

  have "sqrt x \<le> sqrt (real ux)" using x by auto
  from order_trans[OF this]
  show "sqrt x \<le> real u" unfolding u using bnds_sqrt'[of ux prec] by auto
qed

section "Arcus tangens and \<pi>"

subsection "Compute arcus tangens series"

text {*

As first step we implement the computation of the arcus tangens series. This is only valid in the range
@{term "{-1 :: real .. 1}"}. This is used to compute \<pi> and then the entire arcus tangens.

*}

fun ub_arctan_horner :: "nat \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> float \<Rightarrow> float"
and lb_arctan_horner :: "nat \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> float \<Rightarrow> float" where
  "ub_arctan_horner prec 0 k x = 0"
| "ub_arctan_horner prec (Suc n) k x =
    (rapprox_rat prec 1 (int k)) - x * (lb_arctan_horner prec n (k + 2) x)"
| "lb_arctan_horner prec 0 k x = 0"
| "lb_arctan_horner prec (Suc n) k x =
    (lapprox_rat prec 1 (int k)) - x * (ub_arctan_horner prec n (k + 2) x)"

lemma arctan_0_1_bounds': assumes "0 \<le> real x" "real x \<le> 1" and "even n"
  shows "arctan (real x) \<in> {real (x * lb_arctan_horner prec n 1 (x * x)) .. real (x * ub_arctan_horner prec (Suc n) 1 (x * x))}"
proof -
  let "?c i" = "-1^i * (1 / real (i * 2 + 1) * real x ^ (i * 2 + 1))"
  let "?S n" = "\<Sum> i=0..<n. ?c i"

  have "0 \<le> real (x * x)" by auto
  from `even n` obtain m where "2 * m = n" unfolding even_mult_two_ex by auto

  have "arctan (real x) \<in> { ?S n .. ?S (Suc n) }"
  proof (cases "real x = 0")
    case False
    hence "0 < real x" using `0 \<le> real x` by auto
    hence prem: "0 < 1 / real (0 * 2 + (1::nat)) * real x ^ (0 * 2 + 1)" by auto

    have "\<bar> real x \<bar> \<le> 1"  using `0 \<le> real x` `real x \<le> 1` by auto
    from mp[OF summable_Leibniz(2)[OF zeroseq_arctan_series[OF this] monoseq_arctan_series[OF this]] prem, THEN spec, of m, unfolded `2 * m = n`]
    show ?thesis unfolding arctan_series[OF `\<bar> real x \<bar> \<le> 1`] Suc_eq_plus1  .
  qed auto
  note arctan_bounds = this[unfolded atLeastAtMost_iff]

  have F: "\<And>n. 2 * Suc n + 1 = 2 * n + 1 + 2" by auto

  note bounds = horner_bounds[where s=1 and f="\<lambda>i. 2 * i + 1" and j'=0
    and lb="\<lambda>n i k x. lb_arctan_horner prec n k x"
    and ub="\<lambda>n i k x. ub_arctan_horner prec n k x",
    OF `0 \<le> real (x*x)` F lb_arctan_horner.simps ub_arctan_horner.simps]

  { have "real (x * lb_arctan_horner prec n 1 (x*x)) \<le> ?S n"
      using bounds(1) `0 \<le> real x`
      unfolding real_of_float_mult power_add power_one_right real_mult_assoc[symmetric] setsum_left_distrib[symmetric]
      unfolding real_mult_commute mult_commute[of _ "2::nat"] power_mult power2_eq_square[of "real x"]
      by (auto intro!: mult_left_mono)
    also have "\<dots> \<le> arctan (real x)" using arctan_bounds ..
    finally have "real (x * lb_arctan_horner prec n 1 (x*x)) \<le> arctan (real x)" . }
  moreover
  { have "arctan (real x) \<le> ?S (Suc n)" using arctan_bounds ..
    also have "\<dots> \<le> real (x * ub_arctan_horner prec (Suc n) 1 (x*x))"
      using bounds(2)[of "Suc n"] `0 \<le> real x`
      unfolding real_of_float_mult power_add power_one_right real_mult_assoc[symmetric] setsum_left_distrib[symmetric]
      unfolding real_mult_commute mult_commute[of _ "2::nat"] power_mult power2_eq_square[of "real x"]
      by (auto intro!: mult_left_mono)
    finally have "arctan (real x) \<le> real (x * ub_arctan_horner prec (Suc n) 1 (x*x))" . }
  ultimately show ?thesis by auto
qed

lemma arctan_0_1_bounds: assumes "0 \<le> real x" "real x \<le> 1"
  shows "arctan (real x) \<in> {real (x * lb_arctan_horner prec (get_even n) 1 (x * x)) .. real (x * ub_arctan_horner prec (get_odd n) 1 (x * x))}"
proof (cases "even n")
  case True
  obtain n' where "Suc n' = get_odd n" and "odd (Suc n')" using get_odd_ex by auto
  hence "even n'" unfolding even_Suc by auto
  have "arctan (real x) \<le> real (x * ub_arctan_horner prec (get_odd n) 1 (x * x))"
    unfolding `Suc n' = get_odd n`[symmetric] using arctan_0_1_bounds'[OF `0 \<le> real x` `real x \<le> 1` `even n'`] by auto
  moreover
  have "real (x * lb_arctan_horner prec (get_even n) 1 (x * x)) \<le> arctan (real x)"
    unfolding get_even_def if_P[OF True] using arctan_0_1_bounds'[OF `0 \<le> real x` `real x \<le> 1` `even n`] by auto
  ultimately show ?thesis by auto
next
  case False hence "0 < n" by (rule odd_pos)
  from gr0_implies_Suc[OF this] obtain n' where "n = Suc n'" ..
  from False[unfolded this even_Suc]
  have "even n'" and "even (Suc (Suc n'))" by auto
  have "get_odd n = Suc n'" unfolding get_odd_def if_P[OF False] using `n = Suc n'` .

  have "arctan (real x) \<le> real (x * ub_arctan_horner prec (get_odd n) 1 (x * x))"
    unfolding `get_odd n = Suc n'` using arctan_0_1_bounds'[OF `0 \<le> real x` `real x \<le> 1` `even n'`] by auto
  moreover
  have "real (x * lb_arctan_horner prec (get_even n) 1 (x * x)) \<le> arctan (real x)"
    unfolding get_even_def if_not_P[OF False] unfolding `n = Suc n'` using arctan_0_1_bounds'[OF `0 \<le> real x` `real x \<le> 1` `even (Suc (Suc n'))`] by auto
  ultimately show ?thesis by auto
qed

subsection "Compute \<pi>"

definition ub_pi :: "nat \<Rightarrow> float" where
  "ub_pi prec = (let A = rapprox_rat prec 1 5 ;
                     B = lapprox_rat prec 1 239
                 in ((Float 1 2) * ((Float 1 2) * A * (ub_arctan_horner prec (get_odd (prec div 4 + 1)) 1 (A * A)) -
                                                  B * (lb_arctan_horner prec (get_even (prec div 14 + 1)) 1 (B * B)))))"

definition lb_pi :: "nat \<Rightarrow> float" where
  "lb_pi prec = (let A = lapprox_rat prec 1 5 ;
                     B = rapprox_rat prec 1 239
                 in ((Float 1 2) * ((Float 1 2) * A * (lb_arctan_horner prec (get_even (prec div 4 + 1)) 1 (A * A)) -
                                                  B * (ub_arctan_horner prec (get_odd (prec div 14 + 1)) 1 (B * B)))))"

lemma pi_boundaries: "pi \<in> {real (lb_pi n) .. real (ub_pi n)}"
proof -
  have machin_pi: "pi = 4 * (4 * arctan (1 / 5) - arctan (1 / 239))" unfolding machin[symmetric] by auto

  { fix prec n :: nat fix k :: int assume "1 < k" hence "0 \<le> k" and "0 < k" and "1 \<le> k" by auto
    let ?k = "rapprox_rat prec 1 k"
    have "1 div k = 0" using div_pos_pos_trivial[OF _ `1 < k`] by auto

    have "0 \<le> real ?k" by (rule order_trans[OF _ rapprox_rat], auto simp add: `0 \<le> k`)
    have "real ?k \<le> 1" unfolding rapprox_rat.simps(2)[OF zero_le_one `0 < k`]
      by (rule rapprox_posrat_le1, auto simp add: `0 < k` `1 \<le> k`)

    have "1 / real k \<le> real ?k" using rapprox_rat[where x=1 and y=k] by auto
    hence "arctan (1 / real k) \<le> arctan (real ?k)" by (rule arctan_monotone')
    also have "\<dots> \<le> real (?k * ub_arctan_horner prec (get_odd n) 1 (?k * ?k))"
      using arctan_0_1_bounds[OF `0 \<le> real ?k` `real ?k \<le> 1`] by auto
    finally have "arctan (1 / (real k)) \<le> real (?k * ub_arctan_horner prec (get_odd n) 1 (?k * ?k))" .
  } note ub_arctan = this

  { fix prec n :: nat fix k :: int assume "1 < k" hence "0 \<le> k" and "0 < k" by auto
    let ?k = "lapprox_rat prec 1 k"
    have "1 div k = 0" using div_pos_pos_trivial[OF _ `1 < k`] by auto
    have "1 / real k \<le> 1" using `1 < k` by auto

    have "\<And>n. 0 \<le> real ?k" using lapprox_rat_bottom[where x=1 and y=k, OF zero_le_one `0 < k`] by (auto simp add: `1 div k = 0`)
    have "\<And>n. real ?k \<le> 1" using lapprox_rat by (rule order_trans, auto simp add: `1 / real k \<le> 1`)

    have "real ?k \<le> 1 / real k" using lapprox_rat[where x=1 and y=k] by auto

    have "real (?k * lb_arctan_horner prec (get_even n) 1 (?k * ?k)) \<le> arctan (real ?k)"
      using arctan_0_1_bounds[OF `0 \<le> real ?k` `real ?k \<le> 1`] by auto
    also have "\<dots> \<le> arctan (1 / real k)" using `real ?k \<le> 1 / real k` by (rule arctan_monotone')
    finally have "real (?k * lb_arctan_horner prec (get_even n) 1 (?k * ?k)) \<le> arctan (1 / (real k))" .
  } note lb_arctan = this

  have "pi \<le> real (ub_pi n)"
    unfolding ub_pi_def machin_pi Let_def real_of_float_mult real_of_float_sub unfolding Float_num
    using lb_arctan[of 239] ub_arctan[of 5]
    by (auto intro!: mult_left_mono add_mono simp add: diff_minus simp del: lapprox_rat.simps rapprox_rat.simps)
  moreover
  have "real (lb_pi n) \<le> pi"
    unfolding lb_pi_def machin_pi Let_def real_of_float_mult real_of_float_sub Float_num
    using lb_arctan[of 5] ub_arctan[of 239]
    by (auto intro!: mult_left_mono add_mono simp add: diff_minus simp del: lapprox_rat.simps rapprox_rat.simps)
  ultimately show ?thesis by auto
qed

subsection "Compute arcus tangens in the entire domain"

function lb_arctan :: "nat \<Rightarrow> float \<Rightarrow> float" and ub_arctan :: "nat \<Rightarrow> float \<Rightarrow> float" where
  "lb_arctan prec x = (let ub_horner = \<lambda> x. x * ub_arctan_horner prec (get_odd (prec div 4 + 1)) 1 (x * x) ;
                           lb_horner = \<lambda> x. x * lb_arctan_horner prec (get_even (prec div 4 + 1)) 1 (x * x)
    in (if x < 0          then - ub_arctan prec (-x) else
        if x \<le> Float 1 -1 then lb_horner x else
        if x \<le> Float 1 1  then Float 1 1 * lb_horner (float_divl prec x (1 + ub_sqrt prec (1 + x * x)))
                          else (let inv = float_divr prec 1 x
                                in if inv > 1 then 0
                                              else lb_pi prec * Float 1 -1 - ub_horner inv)))"

| "ub_arctan prec x = (let lb_horner = \<lambda> x. x * lb_arctan_horner prec (get_even (prec div 4 + 1)) 1 (x * x) ;
                           ub_horner = \<lambda> x. x * ub_arctan_horner prec (get_odd (prec div 4 + 1)) 1 (x * x)
    in (if x < 0          then - lb_arctan prec (-x) else
        if x \<le> Float 1 -1 then ub_horner x else
        if x \<le> Float 1 1  then let y = float_divr prec x (1 + lb_sqrt prec (1 + x * x))
                               in if y > 1 then ub_pi prec * Float 1 -1
                                           else Float 1 1 * ub_horner y
                          else ub_pi prec * Float 1 -1 - lb_horner (float_divl prec 1 x)))"
by pat_completeness auto
termination by (relation "measure (\<lambda> v. let (prec, x) = sum_case id id v in (if x < 0 then 1 else 0))", auto simp add: less_float_def)

declare ub_arctan_horner.simps[simp del]
declare lb_arctan_horner.simps[simp del]

lemma lb_arctan_bound': assumes "0 \<le> real x"
  shows "real (lb_arctan prec x) \<le> arctan (real x)"
proof -
  have "\<not> x < 0" and "0 \<le> x" unfolding less_float_def le_float_def using `0 \<le> real x` by auto
  let "?ub_horner x" = "x * ub_arctan_horner prec (get_odd (prec div 4 + 1)) 1 (x * x)"
    and "?lb_horner x" = "x * lb_arctan_horner prec (get_even (prec div 4 + 1)) 1 (x * x)"

  show ?thesis
  proof (cases "x \<le> Float 1 -1")
    case True hence "real x \<le> 1" unfolding le_float_def Float_num by auto
    show ?thesis unfolding lb_arctan.simps Let_def if_not_P[OF `\<not> x < 0`] if_P[OF True]
      using arctan_0_1_bounds[OF `0 \<le> real x` `real x \<le> 1`] by auto
  next
    case False hence "0 < real x" unfolding le_float_def Float_num by auto
    let ?R = "1 + sqrt (1 + real x * real x)"
    let ?fR = "1 + ub_sqrt prec (1 + x * x)"
    let ?DIV = "float_divl prec x ?fR"

    have sqr_ge0: "0 \<le> 1 + real x * real x" using sum_power2_ge_zero[of 1 "real x", unfolded numeral_2_eq_2] by auto
    hence divisor_gt0: "0 < ?R" by (auto intro: add_pos_nonneg)

    have "sqrt (real (1 + x * x)) \<le> real (ub_sqrt prec (1 + x * x))"
      using bnds_sqrt'[of "1 + x * x"] by auto

    hence "?R \<le> real ?fR" by auto
    hence "0 < ?fR" and "0 < real ?fR" unfolding less_float_def using `0 < ?R` by auto

    have monotone: "real (float_divl prec x ?fR) \<le> real x / ?R"
    proof -
      have "real ?DIV \<le> real x / real ?fR" by (rule float_divl)
      also have "\<dots> \<le> real x / ?R" by (rule divide_left_mono[OF `?R \<le> real ?fR` `0 \<le> real x` mult_pos_pos[OF order_less_le_trans[OF divisor_gt0 `?R \<le> real ?fR`] divisor_gt0]])
      finally show ?thesis .
    qed

    show ?thesis
    proof (cases "x \<le> Float 1 1")
      case True

      have "real x \<le> sqrt (real (1 + x * x))" using real_sqrt_sum_squares_ge2[where x=1, unfolded numeral_2_eq_2] by auto
      also have "\<dots> \<le> real (ub_sqrt prec (1 + x * x))"
	using bnds_sqrt'[of "1 + x * x"] by auto
      finally have "real x \<le> real ?fR" by auto
      moreover have "real ?DIV \<le> real x / real ?fR" by (rule float_divl)
      ultimately have "real ?DIV \<le> 1" unfolding divide_le_eq_1_pos[OF `0 < real ?fR`, symmetric] by auto

      have "0 \<le> real ?DIV" using float_divl_lower_bound[OF `0 \<le> x` `0 < ?fR`] unfolding le_float_def by auto

      have "real (Float 1 1 * ?lb_horner ?DIV) \<le> 2 * arctan (real (float_divl prec x ?fR))" unfolding real_of_float_mult[of "Float 1 1"] Float_num
	using arctan_0_1_bounds[OF `0 \<le> real ?DIV` `real ?DIV \<le> 1`] by auto
      also have "\<dots> \<le> 2 * arctan (real x / ?R)"
	using arctan_monotone'[OF monotone] by (auto intro!: mult_left_mono)
      also have "2 * arctan (real x / ?R) = arctan (real x)" using arctan_half[symmetric] unfolding numeral_2_eq_2 power_Suc2 power_0 real_mult_1 .
      finally show ?thesis unfolding lb_arctan.simps Let_def if_not_P[OF `\<not> x < 0`] if_not_P[OF `\<not> x \<le> Float 1 -1`] if_P[OF True] .
    next
      case False
      hence "2 < real x" unfolding le_float_def Float_num by auto
      hence "1 \<le> real x" by auto

      let "?invx" = "float_divr prec 1 x"
      have "0 \<le> arctan (real x)" using arctan_monotone'[OF `0 \<le> real x`] using arctan_tan[of 0, unfolded tan_zero] by auto

      show ?thesis
      proof (cases "1 < ?invx")
	case True
	show ?thesis unfolding lb_arctan.simps Let_def if_not_P[OF `\<not> x < 0`] if_not_P[OF `\<not> x \<le> Float 1 -1`] if_not_P[OF False] if_P[OF True]
	  using `0 \<le> arctan (real x)` by auto
      next
	case False
	hence "real ?invx \<le> 1" unfolding less_float_def by auto
	have "0 \<le> real ?invx" by (rule order_trans[OF _ float_divr], auto simp add: `0 \<le> real x`)

	have "1 / real x \<noteq> 0" and "0 < 1 / real x" using `0 < real x` by auto

	have "arctan (1 / real x) \<le> arctan (real ?invx)" unfolding real_of_float_1[symmetric] by (rule arctan_monotone', rule float_divr)
	also have "\<dots> \<le> real (?ub_horner ?invx)" using arctan_0_1_bounds[OF `0 \<le> real ?invx` `real ?invx \<le> 1`] by auto
	finally have "pi / 2 - real (?ub_horner ?invx) \<le> arctan (real x)"
	  using `0 \<le> arctan (real x)` arctan_inverse[OF `1 / real x \<noteq> 0`]
	  unfolding real_sgn_pos[OF `0 < 1 / real x`] le_diff_eq by auto
	moreover
	have "real (lb_pi prec * Float 1 -1) \<le> pi / 2" unfolding real_of_float_mult Float_num times_divide_eq_right real_mult_1 using pi_boundaries by auto
	ultimately
	show ?thesis unfolding lb_arctan.simps Let_def if_not_P[OF `\<not> x < 0`] if_not_P[OF `\<not> x \<le> Float 1 -1`] if_not_P[OF `\<not> x \<le> Float 1 1`] if_not_P[OF False]
	  by auto
      qed
    qed
  qed
qed

lemma ub_arctan_bound': assumes "0 \<le> real x"
  shows "arctan (real x) \<le> real (ub_arctan prec x)"
proof -
  have "\<not> x < 0" and "0 \<le> x" unfolding less_float_def le_float_def using `0 \<le> real x` by auto

  let "?ub_horner x" = "x * ub_arctan_horner prec (get_odd (prec div 4 + 1)) 1 (x * x)"
    and "?lb_horner x" = "x * lb_arctan_horner prec (get_even (prec div 4 + 1)) 1 (x * x)"

  show ?thesis
  proof (cases "x \<le> Float 1 -1")
    case True hence "real x \<le> 1" unfolding le_float_def Float_num by auto
    show ?thesis unfolding ub_arctan.simps Let_def if_not_P[OF `\<not> x < 0`] if_P[OF True]
      using arctan_0_1_bounds[OF `0 \<le> real x` `real x \<le> 1`] by auto
  next
    case False hence "0 < real x" unfolding le_float_def Float_num by auto
    let ?R = "1 + sqrt (1 + real x * real x)"
    let ?fR = "1 + lb_sqrt prec (1 + x * x)"
    let ?DIV = "float_divr prec x ?fR"

    have sqr_ge0: "0 \<le> 1 + real x * real x" using sum_power2_ge_zero[of 1 "real x", unfolded numeral_2_eq_2] by auto
    hence "0 \<le> real (1 + x*x)" by auto

    hence divisor_gt0: "0 < ?R" by (auto intro: add_pos_nonneg)

    have "real (lb_sqrt prec (1 + x * x)) \<le> sqrt (real (1 + x * x))"
      using bnds_sqrt'[of "1 + x * x"] by auto
    hence "real ?fR \<le> ?R" by auto
    have "0 < real ?fR" unfolding real_of_float_add real_of_float_1 by (rule order_less_le_trans[OF zero_less_one], auto simp add: lb_sqrt_lower_bound[OF `0 \<le> real (1 + x*x)`])

    have monotone: "real x / ?R \<le> real (float_divr prec x ?fR)"
    proof -
      from divide_left_mono[OF `real ?fR \<le> ?R` `0 \<le> real x` mult_pos_pos[OF divisor_gt0 `0 < real ?fR`]]
      have "real x / ?R \<le> real x / real ?fR" .
      also have "\<dots> \<le> real ?DIV" by (rule float_divr)
      finally show ?thesis .
    qed

    show ?thesis
    proof (cases "x \<le> Float 1 1")
      case True
      show ?thesis
      proof (cases "?DIV > 1")
	case True
	have "pi / 2 \<le> real (ub_pi prec * Float 1 -1)" unfolding real_of_float_mult Float_num times_divide_eq_right real_mult_1 using pi_boundaries by auto
	from order_less_le_trans[OF arctan_ubound this, THEN less_imp_le]
	show ?thesis unfolding ub_arctan.simps Let_def if_not_P[OF `\<not> x < 0`] if_not_P[OF `\<not> x \<le> Float 1 -1`] if_P[OF `x \<le> Float 1 1`] if_P[OF True] .
      next
	case False
	hence "real ?DIV \<le> 1" unfolding less_float_def by auto

	have "0 \<le> real x / ?R" using `0 \<le> real x` `0 < ?R` unfolding real_0_le_divide_iff by auto
	hence "0 \<le> real ?DIV" using monotone by (rule order_trans)

	have "arctan (real x) = 2 * arctan (real x / ?R)" using arctan_half unfolding numeral_2_eq_2 power_Suc2 power_0 real_mult_1 .
	also have "\<dots> \<le> 2 * arctan (real ?DIV)"
	  using arctan_monotone'[OF monotone] by (auto intro!: mult_left_mono)
	also have "\<dots> \<le> real (Float 1 1 * ?ub_horner ?DIV)" unfolding real_of_float_mult[of "Float 1 1"] Float_num
	  using arctan_0_1_bounds[OF `0 \<le> real ?DIV` `real ?DIV \<le> 1`] by auto
	finally show ?thesis unfolding ub_arctan.simps Let_def if_not_P[OF `\<not> x < 0`] if_not_P[OF `\<not> x \<le> Float 1 -1`] if_P[OF `x \<le> Float 1 1`] if_not_P[OF False] .
      qed
    next
      case False
      hence "2 < real x" unfolding le_float_def Float_num by auto
      hence "1 \<le> real x" by auto
      hence "0 < real x" by auto
      hence "0 < x" unfolding less_float_def by auto

      let "?invx" = "float_divl prec 1 x"
      have "0 \<le> arctan (real x)" using arctan_monotone'[OF `0 \<le> real x`] using arctan_tan[of 0, unfolded tan_zero] by auto

      have "real ?invx \<le> 1" unfolding less_float_def by (rule order_trans[OF float_divl], auto simp add: `1 \<le> real x` divide_le_eq_1_pos[OF `0 < real x`])
      have "0 \<le> real ?invx" unfolding real_of_float_0[symmetric] by (rule float_divl_lower_bound[unfolded le_float_def], auto simp add: `0 < x`)

      have "1 / real x \<noteq> 0" and "0 < 1 / real x" using `0 < real x` by auto

      have "real (?lb_horner ?invx) \<le> arctan (real ?invx)" using arctan_0_1_bounds[OF `0 \<le> real ?invx` `real ?invx \<le> 1`] by auto
      also have "\<dots> \<le> arctan (1 / real x)" unfolding real_of_float_1[symmetric] by (rule arctan_monotone', rule float_divl)
      finally have "arctan (real x) \<le> pi / 2 - real (?lb_horner ?invx)"
	using `0 \<le> arctan (real x)` arctan_inverse[OF `1 / real x \<noteq> 0`]
	unfolding real_sgn_pos[OF `0 < 1 / real x`] le_diff_eq by auto
      moreover
      have "pi / 2 \<le> real (ub_pi prec * Float 1 -1)" unfolding real_of_float_mult Float_num times_divide_eq_right mult_1_right using pi_boundaries by auto
      ultimately
      show ?thesis unfolding ub_arctan.simps Let_def if_not_P[OF `\<not> x < 0`] if_not_P[OF `\<not> x \<le> Float 1 -1`] if_not_P[OF `\<not> x \<le> Float 1 1`] if_not_P[OF False]
	by auto
    qed
  qed
qed

lemma arctan_boundaries:
  "arctan (real x) \<in> {real (lb_arctan prec x) .. real (ub_arctan prec x)}"
proof (cases "0 \<le> x")
  case True hence "0 \<le> real x" unfolding le_float_def by auto
  show ?thesis using ub_arctan_bound'[OF `0 \<le> real x`] lb_arctan_bound'[OF `0 \<le> real x`] unfolding atLeastAtMost_iff by auto
next
  let ?mx = "-x"
  case False hence "x < 0" and "0 \<le> real ?mx" unfolding le_float_def less_float_def by auto
  hence bounds: "real (lb_arctan prec ?mx) \<le> arctan (real ?mx) \<and> arctan (real ?mx) \<le> real (ub_arctan prec ?mx)"
    using ub_arctan_bound'[OF `0 \<le> real ?mx`] lb_arctan_bound'[OF `0 \<le> real ?mx`] by auto
  show ?thesis unfolding real_of_float_minus arctan_minus lb_arctan.simps[where x=x] ub_arctan.simps[where x=x] Let_def if_P[OF `x < 0`]
    unfolding atLeastAtMost_iff using bounds[unfolded real_of_float_minus arctan_minus] by auto
qed

lemma bnds_arctan: "\<forall> x lx ux. (l, u) = (lb_arctan prec lx, ub_arctan prec ux) \<and> x \<in> {real lx .. real ux} \<longrightarrow> real l \<le> arctan x \<and> arctan x \<le> real u"
proof (rule allI, rule allI, rule allI, rule impI)
  fix x lx ux
  assume "(l, u) = (lb_arctan prec lx, ub_arctan prec ux) \<and> x \<in> {real lx .. real ux}"
  hence l: "lb_arctan prec lx = l " and u: "ub_arctan prec ux = u" and x: "x \<in> {real lx .. real ux}" by auto

  { from arctan_boundaries[of lx prec, unfolded l]
    have "real l \<le> arctan (real lx)" by (auto simp del: lb_arctan.simps)
    also have "\<dots> \<le> arctan x" using x by (auto intro: arctan_monotone')
    finally have "real l \<le> arctan x" .
  } moreover
  { have "arctan x \<le> arctan (real ux)" using x by (auto intro: arctan_monotone')
    also have "\<dots> \<le> real u" using arctan_boundaries[of ux prec, unfolded u] by (auto simp del: ub_arctan.simps)
    finally have "arctan x \<le> real u" .
  } ultimately show "real l \<le> arctan x \<and> arctan x \<le> real u" ..
qed

section "Sinus and Cosinus"

subsection "Compute the cosinus and sinus series"

fun ub_sin_cos_aux :: "nat \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> float \<Rightarrow> float"
and lb_sin_cos_aux :: "nat \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> float \<Rightarrow> float" where
  "ub_sin_cos_aux prec 0 i k x = 0"
| "ub_sin_cos_aux prec (Suc n) i k x =
    (rapprox_rat prec 1 (int k)) - x * (lb_sin_cos_aux prec n (i + 2) (k * i * (i + 1)) x)"
| "lb_sin_cos_aux prec 0 i k x = 0"
| "lb_sin_cos_aux prec (Suc n) i k x =
    (lapprox_rat prec 1 (int k)) - x * (ub_sin_cos_aux prec n (i + 2) (k * i * (i + 1)) x)"

lemma cos_aux:
  shows "real (lb_sin_cos_aux prec n 1 1 (x * x)) \<le> (\<Sum> i=0..<n. -1^i * (1/real (fact (2 * i))) * (real x)^(2 * i))" (is "?lb")
  and "(\<Sum> i=0..<n. -1^i * (1/real (fact (2 * i))) * (real x)^(2 * i)) \<le> real (ub_sin_cos_aux prec n 1 1 (x * x))" (is "?ub")
proof -
  have "0 \<le> real (x * x)" unfolding real_of_float_mult by auto
  let "?f n" = "fact (2 * n)"

  { fix n
    have F: "\<And>m. ((\<lambda>i. i + 2) ^^ n) m = m + 2 * n" by (induct n arbitrary: m, auto)
    have "?f (Suc n) = ?f n * ((\<lambda>i. i + 2) ^^ n) 1 * (((\<lambda>i. i + 2) ^^ n) 1 + 1)"
      unfolding F by auto } note f_eq = this

  from horner_bounds[where lb="lb_sin_cos_aux prec" and ub="ub_sin_cos_aux prec" and j'=0,
    OF `0 \<le> real (x * x)` f_eq lb_sin_cos_aux.simps ub_sin_cos_aux.simps]
  show "?lb" and "?ub" by (auto simp add: power_mult power2_eq_square[of "real x"])
qed

lemma cos_boundaries: assumes "0 \<le> real x" and "real x \<le> pi / 2"
  shows "cos (real x) \<in> {real (lb_sin_cos_aux prec (get_even n) 1 1 (x * x)) .. real (ub_sin_cos_aux prec (get_odd n) 1 1 (x * x))}"
proof (cases "real x = 0")
  case False hence "real x \<noteq> 0" by auto
  hence "0 < x" and "0 < real x" using `0 \<le> real x` unfolding less_float_def by auto
  have "0 < x * x" using `0 < x` unfolding less_float_def real_of_float_mult real_of_float_0
    using mult_pos_pos[where a="real x" and b="real x"] by auto

  { fix x n have "(\<Sum> i=0..<n. -1^i * (1/real (fact (2 * i))) * x ^ (2 * i))
    = (\<Sum> i = 0 ..< 2 * n. (if even(i) then (-1 ^ (i div 2))/(real (fact i)) else 0) * x ^ i)" (is "?sum = ?ifsum")
  proof -
    have "?sum = ?sum + (\<Sum> j = 0 ..< n. 0)" by auto
    also have "\<dots> =
      (\<Sum> j = 0 ..< n. -1 ^ ((2 * j) div 2) / (real (fact (2 * j))) * x ^(2 * j)) + (\<Sum> j = 0 ..< n. 0)" by auto
    also have "\<dots> = (\<Sum> i = 0 ..< 2 * n. if even i then -1 ^ (i div 2) / (real (fact i)) * x ^ i else 0)"
      unfolding sum_split_even_odd ..
    also have "\<dots> = (\<Sum> i = 0 ..< 2 * n. (if even i then -1 ^ (i div 2) / (real (fact i)) else 0) * x ^ i)"
      by (rule setsum_cong2) auto
    finally show ?thesis by assumption
  qed } note morph_to_if_power = this


  { fix n :: nat assume "0 < n"
    hence "0 < 2 * n" by auto
    obtain t where "0 < t" and "t < real x" and
      cos_eq: "cos (real x) = (\<Sum> i = 0 ..< 2 * n. (if even(i) then (-1 ^ (i div 2))/(real (fact i)) else 0) * (real x) ^ i)
      + (cos (t + 1/2 * real (2 * n) * pi) / real (fact (2*n))) * (real x)^(2*n)"
      (is "_ = ?SUM + ?rest / ?fact * ?pow")
      using Maclaurin_cos_expansion2[OF `0 < real x` `0 < 2 * n`] by auto

    have "cos t * -1^n = cos t * cos (real n * pi) + sin t * sin (real n * pi)" by auto
    also have "\<dots> = cos (t + real n * pi)"  using cos_add by auto
    also have "\<dots> = ?rest" by auto
    finally have "cos t * -1^n = ?rest" .
    moreover
    have "t \<le> pi / 2" using `t < real x` and `real x \<le> pi / 2` by auto
    hence "0 \<le> cos t" using `0 < t` and cos_ge_zero by auto
    ultimately have even: "even n \<Longrightarrow> 0 \<le> ?rest" and odd: "odd n \<Longrightarrow> 0 \<le> - ?rest " by auto

    have "0 < ?fact" by auto
    have "0 < ?pow" using `0 < real x` by auto

    {
      assume "even n"
      have "real (lb_sin_cos_aux prec n 1 1 (x * x)) \<le> ?SUM"
	unfolding morph_to_if_power[symmetric] using cos_aux by auto
      also have "\<dots> \<le> cos (real x)"
      proof -
	from even[OF `even n`] `0 < ?fact` `0 < ?pow`
	have "0 \<le> (?rest / ?fact) * ?pow" by (metis mult_nonneg_nonneg divide_nonneg_pos less_imp_le)
	thus ?thesis unfolding cos_eq by auto
      qed
      finally have "real (lb_sin_cos_aux prec n 1 1 (x * x)) \<le> cos (real x)" .
    } note lb = this

    {
      assume "odd n"
      have "cos (real x) \<le> ?SUM"
      proof -
	from `0 < ?fact` and `0 < ?pow` and odd[OF `odd n`]
	have "0 \<le> (- ?rest) / ?fact * ?pow"
	  by (metis mult_nonneg_nonneg divide_nonneg_pos less_imp_le)
	thus ?thesis unfolding cos_eq by auto
      qed
      also have "\<dots> \<le> real (ub_sin_cos_aux prec n 1 1 (x * x))"
	unfolding morph_to_if_power[symmetric] using cos_aux by auto
      finally have "cos (real x) \<le> real (ub_sin_cos_aux prec n 1 1 (x * x))" .
    } note ub = this and lb
  } note ub = this(1) and lb = this(2)

  have "cos (real x) \<le> real (ub_sin_cos_aux prec (get_odd n) 1 1 (x * x))" using ub[OF odd_pos[OF get_odd] get_odd] .
  moreover have "real (lb_sin_cos_aux prec (get_even n) 1 1 (x * x)) \<le> cos (real x)"
  proof (cases "0 < get_even n")
    case True show ?thesis using lb[OF True get_even] .
  next
    case False
    hence "get_even n = 0" by auto
    have "- (pi / 2) \<le> real x" by (rule order_trans[OF _ `0 < real x`[THEN less_imp_le]], auto)
    with `real x \<le> pi / 2`
    show ?thesis unfolding `get_even n = 0` lb_sin_cos_aux.simps real_of_float_minus real_of_float_0 using cos_ge_zero by auto
  qed
  ultimately show ?thesis by auto
next
  case True
  show ?thesis
  proof (cases "n = 0")
    case True
    thus ?thesis unfolding `n = 0` get_even_def get_odd_def using `real x = 0` lapprox_rat[where x="-1" and y=1] by auto
  next
    case False with not0_implies_Suc obtain m where "n = Suc m" by blast
    thus ?thesis unfolding `n = Suc m` get_even_def get_odd_def using `real x = 0` rapprox_rat[where x=1 and y=1] lapprox_rat[where x=1 and y=1] by (cases "even (Suc m)", auto)
  qed
qed

lemma sin_aux: assumes "0 \<le> real x"
  shows "real (x * lb_sin_cos_aux prec n 2 1 (x * x)) \<le> (\<Sum> i=0..<n. -1^i * (1/real (fact (2 * i + 1))) * (real x)^(2 * i + 1))" (is "?lb")
  and "(\<Sum> i=0..<n. -1^i * (1/real (fact (2 * i + 1))) * (real x)^(2 * i + 1)) \<le> real (x * ub_sin_cos_aux prec n 2 1 (x * x))" (is "?ub")
proof -
  have "0 \<le> real (x * x)" unfolding real_of_float_mult by auto
  let "?f n" = "fact (2 * n + 1)"

  { fix n
    have F: "\<And>m. ((\<lambda>i. i + 2) ^^ n) m = m + 2 * n" by (induct n arbitrary: m, auto)
    have "?f (Suc n) = ?f n * ((\<lambda>i. i + 2) ^^ n) 2 * (((\<lambda>i. i + 2) ^^ n) 2 + 1)"
      unfolding F by auto } note f_eq = this

  from horner_bounds[where lb="lb_sin_cos_aux prec" and ub="ub_sin_cos_aux prec" and j'=0,
    OF `0 \<le> real (x * x)` f_eq lb_sin_cos_aux.simps ub_sin_cos_aux.simps]
  show "?lb" and "?ub" using `0 \<le> real x` unfolding real_of_float_mult
    unfolding power_add power_one_right real_mult_assoc[symmetric] setsum_left_distrib[symmetric]
    unfolding real_mult_commute
    by (auto intro!: mult_left_mono simp add: power_mult power2_eq_square[of "real x"])
qed

lemma sin_boundaries: assumes "0 \<le> real x" and "real x \<le> pi / 2"
  shows "sin (real x) \<in> {real (x * lb_sin_cos_aux prec (get_even n) 2 1 (x * x)) .. real (x * ub_sin_cos_aux prec (get_odd n) 2 1 (x * x))}"
proof (cases "real x = 0")
  case False hence "real x \<noteq> 0" by auto
  hence "0 < x" and "0 < real x" using `0 \<le> real x` unfolding less_float_def by auto
  have "0 < x * x" using `0 < x` unfolding less_float_def real_of_float_mult real_of_float_0
    using mult_pos_pos[where a="real x" and b="real x"] by auto

  { fix x n have "(\<Sum> j = 0 ..< n. -1 ^ (((2 * j + 1) - Suc 0) div 2) / (real (fact (2 * j + 1))) * x ^(2 * j + 1))
    = (\<Sum> i = 0 ..< 2 * n. (if even(i) then 0 else (-1 ^ ((i - Suc 0) div 2))/(real (fact i))) * x ^ i)" (is "?SUM = _")
    proof -
      have pow: "!!i. x ^ (2 * i + 1) = x * x ^ (2 * i)" by auto
      have "?SUM = (\<Sum> j = 0 ..< n. 0) + ?SUM" by auto
      also have "\<dots> = (\<Sum> i = 0 ..< 2 * n. if even i then 0 else -1 ^ ((i - Suc 0) div 2) / (real (fact i)) * x ^ i)"
	unfolding sum_split_even_odd ..
      also have "\<dots> = (\<Sum> i = 0 ..< 2 * n. (if even i then 0 else -1 ^ ((i - Suc 0) div 2) / (real (fact i))) * x ^ i)"
	by (rule setsum_cong2) auto
      finally show ?thesis by assumption
    qed } note setsum_morph = this

  { fix n :: nat assume "0 < n"
    hence "0 < 2 * n + 1" by auto
    obtain t where "0 < t" and "t < real x" and
      sin_eq: "sin (real x) = (\<Sum> i = 0 ..< 2 * n + 1. (if even(i) then 0 else (-1 ^ ((i - Suc 0) div 2))/(real (fact i))) * (real x) ^ i)
      + (sin (t + 1/2 * real (2 * n + 1) * pi) / real (fact (2*n + 1))) * (real x)^(2*n + 1)"
      (is "_ = ?SUM + ?rest / ?fact * ?pow")
      using Maclaurin_sin_expansion3[OF `0 < 2 * n + 1` `0 < real x`] by auto

    have "?rest = cos t * -1^n" unfolding sin_add cos_add real_of_nat_add left_distrib right_distrib by auto
    moreover
    have "t \<le> pi / 2" using `t < real x` and `real x \<le> pi / 2` by auto
    hence "0 \<le> cos t" using `0 < t` and cos_ge_zero by auto
    ultimately have even: "even n \<Longrightarrow> 0 \<le> ?rest" and odd: "odd n \<Longrightarrow> 0 \<le> - ?rest " by auto

    have "0 < ?fact" by (rule real_of_nat_fact_gt_zero)
    have "0 < ?pow" using `0 < real x` by (rule zero_less_power)

    {
      assume "even n"
      have "real (x * lb_sin_cos_aux prec n 2 1 (x * x)) \<le>
            (\<Sum> i = 0 ..< 2 * n. (if even(i) then 0 else (-1 ^ ((i - Suc 0) div 2))/(real (fact i))) * (real x) ^ i)"
	using sin_aux[OF `0 \<le> real x`] unfolding setsum_morph[symmetric] by auto
      also have "\<dots> \<le> ?SUM" by auto
      also have "\<dots> \<le> sin (real x)"
      proof -
	from even[OF `even n`] `0 < ?fact` `0 < ?pow`
	have "0 \<le> (?rest / ?fact) * ?pow" by (metis mult_nonneg_nonneg divide_nonneg_pos less_imp_le)
	thus ?thesis unfolding sin_eq by auto
      qed
      finally have "real (x * lb_sin_cos_aux prec n 2 1 (x * x)) \<le> sin (real x)" .
    } note lb = this

    {
      assume "odd n"
      have "sin (real x) \<le> ?SUM"
      proof -
	from `0 < ?fact` and `0 < ?pow` and odd[OF `odd n`]
	have "0 \<le> (- ?rest) / ?fact * ?pow"
	  by (metis mult_nonneg_nonneg divide_nonneg_pos less_imp_le)
	thus ?thesis unfolding sin_eq by auto
      qed
      also have "\<dots> \<le> (\<Sum> i = 0 ..< 2 * n. (if even(i) then 0 else (-1 ^ ((i - Suc 0) div 2))/(real (fact i))) * (real x) ^ i)"
	 by auto
      also have "\<dots> \<le> real (x * ub_sin_cos_aux prec n 2 1 (x * x))"
	using sin_aux[OF `0 \<le> real x`] unfolding setsum_morph[symmetric] by auto
      finally have "sin (real x) \<le> real (x * ub_sin_cos_aux prec n 2 1 (x * x))" .
    } note ub = this and lb
  } note ub = this(1) and lb = this(2)

  have "sin (real x) \<le> real (x * ub_sin_cos_aux prec (get_odd n) 2 1 (x * x))" using ub[OF odd_pos[OF get_odd] get_odd] .
  moreover have "real (x * lb_sin_cos_aux prec (get_even n) 2 1 (x * x)) \<le> sin (real x)"
  proof (cases "0 < get_even n")
    case True show ?thesis using lb[OF True get_even] .
  next
    case False
    hence "get_even n = 0" by auto
    with `real x \<le> pi / 2` `0 \<le> real x`
    show ?thesis unfolding `get_even n = 0` ub_sin_cos_aux.simps real_of_float_minus real_of_float_0 using sin_ge_zero by auto
  qed
  ultimately show ?thesis by auto
next
  case True
  show ?thesis
  proof (cases "n = 0")
    case True
    thus ?thesis unfolding `n = 0` get_even_def get_odd_def using `real x = 0` lapprox_rat[where x="-1" and y=1] by auto
  next
    case False with not0_implies_Suc obtain m where "n = Suc m" by blast
    thus ?thesis unfolding `n = Suc m` get_even_def get_odd_def using `real x = 0` rapprox_rat[where x=1 and y=1] lapprox_rat[where x=1 and y=1] by (cases "even (Suc m)", auto)
  qed
qed

subsection "Compute the cosinus in the entire domain"

definition lb_cos :: "nat \<Rightarrow> float \<Rightarrow> float" where
"lb_cos prec x = (let
    horner = \<lambda> x. lb_sin_cos_aux prec (get_even (prec div 4 + 1)) 1 1 (x * x) ;
    half = \<lambda> x. if x < 0 then - 1 else Float 1 1 * x * x - 1
  in if x < Float 1 -1 then horner x
else if x < 1          then half (horner (x * Float 1 -1))
                       else half (half (horner (x * Float 1 -2))))"

definition ub_cos :: "nat \<Rightarrow> float \<Rightarrow> float" where
"ub_cos prec x = (let
    horner = \<lambda> x. ub_sin_cos_aux prec (get_odd (prec div 4 + 1)) 1 1 (x * x) ;
    half = \<lambda> x. Float 1 1 * x * x - 1
  in if x < Float 1 -1 then horner x
else if x < 1          then half (horner (x * Float 1 -1))
                       else half (half (horner (x * Float 1 -2))))"

lemma lb_cos: assumes "0 \<le> real x" and "real x \<le> pi"
  shows "cos (real x) \<in> {real (lb_cos prec x) .. real (ub_cos prec x)}" (is "?cos x \<in> { real (?lb x) .. real (?ub x) }")
proof -
  { fix x :: real
    have "cos x = cos (x / 2 + x / 2)" by auto
    also have "\<dots> = cos (x / 2) * cos (x / 2) + sin (x / 2) * sin (x / 2) - sin (x / 2) * sin (x / 2) + cos (x / 2) * cos (x / 2) - 1"
      unfolding cos_add by auto
    also have "\<dots> = 2 * cos (x / 2) * cos (x / 2) - 1" by algebra
    finally have "cos x = 2 * cos (x / 2) * cos (x / 2) - 1" .
  } note x_half = this[symmetric]

  have "\<not> x < 0" using `0 \<le> real x` unfolding less_float_def by auto
  let "?ub_horner x" = "ub_sin_cos_aux prec (get_odd (prec div 4 + 1)) 1 1 (x * x)"
  let "?lb_horner x" = "lb_sin_cos_aux prec (get_even (prec div 4 + 1)) 1 1 (x * x)"
  let "?ub_half x" = "Float 1 1 * x * x - 1"
  let "?lb_half x" = "if x < 0 then - 1 else Float 1 1 * x * x - 1"

  show ?thesis
  proof (cases "x < Float 1 -1")
    case True hence "real x \<le> pi / 2" unfolding less_float_def using pi_ge_two by auto
    show ?thesis unfolding lb_cos_def[where x=x] ub_cos_def[where x=x] if_not_P[OF `\<not> x < 0`] if_P[OF `x < Float 1 -1`] Let_def
      using cos_boundaries[OF `0 \<le> real x` `real x \<le> pi / 2`] .
  next
    case False
    { fix y x :: float let ?x2 = "real (x * Float 1 -1)"
      assume "real y \<le> cos ?x2" and "-pi \<le> real x" and "real x \<le> pi"
      hence "- (pi / 2) \<le> ?x2" and "?x2 \<le> pi / 2" using pi_ge_two unfolding real_of_float_mult Float_num by auto
      hence "0 \<le> cos ?x2" by (rule cos_ge_zero)

      have "real (?lb_half y) \<le> cos (real x)"
      proof (cases "y < 0")
	case True show ?thesis using cos_ge_minus_one unfolding if_P[OF True] by auto
      next
	case False
	hence "0 \<le> real y" unfolding less_float_def by auto
	from mult_mono[OF `real y \<le> cos ?x2` `real y \<le> cos ?x2` `0 \<le> cos ?x2` this]
	have "real y * real y \<le> cos ?x2 * cos ?x2" .
	hence "2 * real y * real y \<le> 2 * cos ?x2 * cos ?x2" by auto
	hence "2 * real y * real y - 1 \<le> 2 * cos (real x / 2) * cos (real x / 2) - 1" unfolding Float_num real_of_float_mult by auto
	thus ?thesis unfolding if_not_P[OF False] x_half Float_num real_of_float_mult real_of_float_sub by auto
      qed
    } note lb_half = this

    { fix y x :: float let ?x2 = "real (x * Float 1 -1)"
      assume ub: "cos ?x2 \<le> real y" and "- pi \<le> real x" and "real x \<le> pi"
      hence "- (pi / 2) \<le> ?x2" and "?x2 \<le> pi / 2" using pi_ge_two unfolding real_of_float_mult Float_num by auto
      hence "0 \<le> cos ?x2" by (rule cos_ge_zero)

      have "cos (real x) \<le> real (?ub_half y)"
      proof -
	have "0 \<le> real y" using `0 \<le> cos ?x2` ub by (rule order_trans)
	from mult_mono[OF ub ub this `0 \<le> cos ?x2`]
	have "cos ?x2 * cos ?x2 \<le> real y * real y" .
	hence "2 * cos ?x2 * cos ?x2 \<le> 2 * real y * real y" by auto
	hence "2 * cos (real x / 2) * cos (real x / 2) - 1 \<le> 2 * real y * real y - 1" unfolding Float_num real_of_float_mult by auto
	thus ?thesis unfolding x_half real_of_float_mult Float_num real_of_float_sub by auto
      qed
    } note ub_half = this

    let ?x2 = "x * Float 1 -1"
    let ?x4 = "x * Float 1 -1 * Float 1 -1"

    have "-pi \<le> real x" using pi_ge_zero[THEN le_imp_neg_le, unfolded minus_zero] `0 \<le> real x` by (rule order_trans)

    show ?thesis
    proof (cases "x < 1")
      case True hence "real x \<le> 1" unfolding less_float_def by auto
      have "0 \<le> real ?x2" and "real ?x2 \<le> pi / 2" using pi_ge_two `0 \<le> real x` unfolding real_of_float_mult Float_num using assms by auto
      from cos_boundaries[OF this]
      have lb: "real (?lb_horner ?x2) \<le> ?cos ?x2" and ub: "?cos ?x2 \<le> real (?ub_horner ?x2)" by auto

      have "real (?lb x) \<le> ?cos x"
      proof -
	from lb_half[OF lb `-pi \<le> real x` `real x \<le> pi`]
	show ?thesis unfolding lb_cos_def[where x=x] Let_def using `\<not> x < 0` `\<not> x < Float 1 -1` `x < 1` by auto
      qed
      moreover have "?cos x \<le> real (?ub x)"
      proof -
	from ub_half[OF ub `-pi \<le> real x` `real x \<le> pi`]
	show ?thesis unfolding ub_cos_def[where x=x] Let_def using `\<not> x < 0` `\<not> x < Float 1 -1` `x < 1` by auto
      qed
      ultimately show ?thesis by auto
    next
      case False
      have "0 \<le> real ?x4" and "real ?x4 \<le> pi / 2" using pi_ge_two `0 \<le> real x` `real x \<le> pi` unfolding real_of_float_mult Float_num by auto
      from cos_boundaries[OF this]
      have lb: "real (?lb_horner ?x4) \<le> ?cos ?x4" and ub: "?cos ?x4 \<le> real (?ub_horner ?x4)" by auto

      have eq_4: "?x2 * Float 1 -1 = x * Float 1 -2" by (cases x, auto simp add: times_float.simps)

      have "real (?lb x) \<le> ?cos x"
      proof -
	have "-pi \<le> real ?x2" and "real ?x2 \<le> pi" unfolding real_of_float_mult Float_num using pi_ge_two `0 \<le> real x` `real x \<le> pi` by auto
	from lb_half[OF lb_half[OF lb this] `-pi \<le> real x` `real x \<le> pi`, unfolded eq_4]
	show ?thesis unfolding lb_cos_def[where x=x] if_not_P[OF `\<not> x < 0`] if_not_P[OF `\<not> x < Float 1 -1`] if_not_P[OF `\<not> x < 1`] Let_def .
      qed
      moreover have "?cos x \<le> real (?ub x)"
      proof -
	have "-pi \<le> real ?x2" and "real ?x2 \<le> pi" unfolding real_of_float_mult Float_num using pi_ge_two `0 \<le> real x` `real x \<le> pi` by auto
	from ub_half[OF ub_half[OF ub this] `-pi \<le> real x` `real x \<le> pi`, unfolded eq_4]
	show ?thesis unfolding ub_cos_def[where x=x] if_not_P[OF `\<not> x < 0`] if_not_P[OF `\<not> x < Float 1 -1`] if_not_P[OF `\<not> x < 1`] Let_def .
      qed
      ultimately show ?thesis by auto
    qed
  qed
qed

lemma lb_cos_minus: assumes "-pi \<le> real x" and "real x \<le> 0"
  shows "cos (real (-x)) \<in> {real (lb_cos prec (-x)) .. real (ub_cos prec (-x))}"
proof -
  have "0 \<le> real (-x)" and "real (-x) \<le> pi" using `-pi \<le> real x` `real x \<le> 0` by auto
  from lb_cos[OF this] show ?thesis .
qed

definition bnds_cos :: "nat \<Rightarrow> float \<Rightarrow> float \<Rightarrow> float * float" where
"bnds_cos prec lx ux = (let
    lpi = round_down prec (lb_pi prec) ;
    upi = round_up prec (ub_pi prec) ;
    k = floor_fl (float_divr prec (lx + lpi) (2 * lpi)) ;
    lx = lx - k * 2 * (if k < 0 then lpi else upi) ;
    ux = ux - k * 2 * (if k < 0 then upi else lpi)
  in   if - lpi \<le> lx \<and> ux \<le> 0    then (lb_cos prec (-lx), ub_cos prec (-ux))
  else if 0 \<le> lx \<and> ux \<le> lpi      then (lb_cos prec ux, ub_cos prec lx)
  else if - lpi \<le> lx \<and> ux \<le> lpi  then (min (lb_cos prec (-lx)) (lb_cos prec ux), Float 1 0)
  else if 0 \<le> lx \<and> ux \<le> 2 * lpi  then (Float -1 0, max (ub_cos prec lx) (ub_cos prec (- (ux - 2 * lpi))))
  else if -2 * lpi \<le> lx \<and> ux \<le> 0 then (Float -1 0, max (ub_cos prec (lx + 2 * lpi)) (ub_cos prec (-ux)))
                                 else (Float -1 0, Float 1 0))"

lemma floor_int:
  obtains k :: int where "real k = real (floor_fl f)"
proof -
  assume *: "\<And> k :: int. real k = real (floor_fl f) \<Longrightarrow> thesis"
  obtain m e where fl: "Float m e = floor_fl f" by (cases "floor_fl f", auto)
  from floor_pos_exp[OF this]
  have "real (m* 2^(nat e)) = real (floor_fl f)"
    by (auto simp add: fl[symmetric] real_of_float_def pow2_def)
  from *[OF this] show thesis by blast
qed

lemma float_remove_real_numeral[simp]: "real (number_of k :: float) = number_of k"
proof -
  have "real (number_of k :: float) = real k"
    unfolding number_of_float_def real_of_float_def pow2_def by auto
  also have "\<dots> = real (number_of k :: int)"
    by (simp add: number_of_is_id)
  finally show ?thesis by auto
qed

lemma cos_periodic_nat[simp]: fixes n :: nat shows "cos (x + real n * 2 * pi) = cos x"
proof (induct n arbitrary: x)
  case (Suc n)
  have split_pi_off: "x + real (Suc n) * 2 * pi = (x + real n * 2 * pi) + 2 * pi"
    unfolding Suc_eq_plus1 real_of_nat_add real_of_one real_add_mult_distrib by auto
  show ?case unfolding split_pi_off using Suc by auto
qed auto

lemma cos_periodic_int[simp]: fixes i :: int shows "cos (x + real i * 2 * pi) = cos x"
proof (cases "0 \<le> i")
  case True hence i_nat: "real i = real (nat i)" by auto
  show ?thesis unfolding i_nat by auto
next
  case False hence i_nat: "real i = - real (nat (-i))" by auto
  have "cos x = cos (x + real i * 2 * pi - real i * 2 * pi)" by auto
  also have "\<dots> = cos (x + real i * 2 * pi)"
    unfolding i_nat mult_minus_left diff_minus_eq_add by (rule cos_periodic_nat)
  finally show ?thesis by auto
qed

lemma bnds_cos: "\<forall> x lx ux. (l, u) = bnds_cos prec lx ux \<and> x \<in> {real lx .. real ux} \<longrightarrow> real l \<le> cos x \<and> cos x \<le> real u"
proof ((rule allI | rule impI | erule conjE) +)
  fix x lx ux
  assume bnds: "(l, u) = bnds_cos prec lx ux" and x: "x \<in> {real lx .. real ux}"

  let ?lpi = "round_down prec (lb_pi prec)"
  let ?upi = "round_up prec (ub_pi prec)"
  let ?k = "floor_fl (float_divr prec (lx + ?lpi) (2 * ?lpi))"
  let ?lx = "lx - ?k * 2 * (if ?k < 0 then ?lpi else ?upi)"
  let ?ux = "ux - ?k * 2 * (if ?k < 0 then ?upi else ?lpi)"

  obtain k :: int where k: "real k = real ?k" using floor_int .

  have upi: "pi \<le> real ?upi" and lpi: "real ?lpi \<le> pi"
    using round_up[of "ub_pi prec" prec] pi_boundaries[of prec]
          round_down[of prec "lb_pi prec"] by auto
  hence "real ?lx \<le> x - real k * 2 * pi \<and> x - real k * 2 * pi \<le> real ?ux"
    using x by (cases "k = 0") (auto intro!: add_mono
                simp add: real_diff_def k[symmetric] less_float_def)
  note lx = this[THEN conjunct1] and ux = this[THEN conjunct2]
  hence lx_less_ux: "real ?lx \<le> real ?ux" by (rule order_trans)

  { assume "- ?lpi \<le> ?lx" and x_le_0: "x - real k * 2 * pi \<le> 0"
    with lpi[THEN le_imp_neg_le] lx
    have pi_lx: "- pi \<le> real ?lx" and lx_0: "real ?lx \<le> 0"
      by (simp_all add: le_float_def)

    have "real (lb_cos prec (- ?lx)) \<le> cos (real (- ?lx))"
      using lb_cos_minus[OF pi_lx lx_0] by simp
    also have "\<dots> \<le> cos (x + real (-k) * 2 * pi)"
      using cos_monotone_minus_pi_0'[OF pi_lx lx x_le_0]
      by (simp only: real_of_float_minus real_of_int_minus
	cos_minus real_diff_def mult_minus_left)
    finally have "real (lb_cos prec (- ?lx)) \<le> cos x"
      unfolding cos_periodic_int . }
  note negative_lx = this

  { assume "0 \<le> ?lx" and pi_x: "x - real k * 2 * pi \<le> pi"
    with lx
    have pi_lx: "real ?lx \<le> pi" and lx_0: "0 \<le> real ?lx"
      by (auto simp add: le_float_def)

    have "cos (x + real (-k) * 2 * pi) \<le> cos (real ?lx)"
      using cos_monotone_0_pi'[OF lx_0 lx pi_x]
      by (simp only: real_of_float_minus real_of_int_minus
	cos_minus real_diff_def mult_minus_left)
    also have "\<dots> \<le> real (ub_cos prec ?lx)"
      using lb_cos[OF lx_0 pi_lx] by simp
    finally have "cos x \<le> real (ub_cos prec ?lx)"
      unfolding cos_periodic_int . }
  note positive_lx = this

  { assume pi_x: "- pi \<le> x - real k * 2 * pi" and "?ux \<le> 0"
    with ux
    have pi_ux: "- pi \<le> real ?ux" and ux_0: "real ?ux \<le> 0"
      by (simp_all add: le_float_def)

    have "cos (x + real (-k) * 2 * pi) \<le> cos (real (- ?ux))"
      using cos_monotone_minus_pi_0'[OF pi_x ux ux_0]
      by (simp only: real_of_float_minus real_of_int_minus
	  cos_minus real_diff_def mult_minus_left)
    also have "\<dots> \<le> real (ub_cos prec (- ?ux))"
      using lb_cos_minus[OF pi_ux ux_0, of prec] by simp
    finally have "cos x \<le> real (ub_cos prec (- ?ux))"
      unfolding cos_periodic_int . }
  note negative_ux = this

  { assume "?ux \<le> ?lpi" and x_ge_0: "0 \<le> x - real k * 2 * pi"
    with lpi ux
    have pi_ux: "real ?ux \<le> pi" and ux_0: "0 \<le> real ?ux"
      by (simp_all add: le_float_def)

    have "real (lb_cos prec ?ux) \<le> cos (real ?ux)"
      using lb_cos[OF ux_0 pi_ux] by simp
    also have "\<dots> \<le> cos (x + real (-k) * 2 * pi)"
      using cos_monotone_0_pi'[OF x_ge_0 ux pi_ux]
      by (simp only: real_of_float_minus real_of_int_minus
	cos_minus real_diff_def mult_minus_left)
    finally have "real (lb_cos prec ?ux) \<le> cos x"
      unfolding cos_periodic_int . }
  note positive_ux = this

  show "real l \<le> cos x \<and> cos x \<le> real u"
  proof (cases "- ?lpi \<le> ?lx \<and> ?ux \<le> 0")
    case True with bnds
    have l: "l = lb_cos prec (-?lx)"
      and u: "u = ub_cos prec (-?ux)"
      by (auto simp add: bnds_cos_def Let_def)

    from True lpi[THEN le_imp_neg_le] lx ux
    have "- pi \<le> x - real k * 2 * pi"
      and "x - real k * 2 * pi \<le> 0"
      by (auto simp add: le_float_def)
    with True negative_ux negative_lx
    show ?thesis unfolding l u by simp
  next case False note 1 = this show ?thesis
  proof (cases "0 \<le> ?lx \<and> ?ux \<le> ?lpi")
    case True with bnds 1
    have l: "l = lb_cos prec ?ux"
      and u: "u = ub_cos prec ?lx"
      by (auto simp add: bnds_cos_def Let_def)

    from True lpi lx ux
    have "0 \<le> x - real k * 2 * pi"
      and "x - real k * 2 * pi \<le> pi"
      by (auto simp add: le_float_def)
    with True positive_ux positive_lx
    show ?thesis unfolding l u by simp
  next case False note 2 = this show ?thesis
  proof (cases "- ?lpi \<le> ?lx \<and> ?ux \<le> ?lpi")
    case True note Cond = this with bnds 1 2
    have l: "l = min (lb_cos prec (-?lx)) (lb_cos prec ?ux)"
      and u: "u = Float 1 0"
      by (auto simp add: bnds_cos_def Let_def)

    show ?thesis unfolding u l using negative_lx positive_ux Cond
      by (cases "x - real k * 2 * pi < 0", simp_all add: real_of_float_min)
  next case False note 3 = this show ?thesis
  proof (cases "0 \<le> ?lx \<and> ?ux \<le> 2 * ?lpi")
    case True note Cond = this with bnds 1 2 3
    have l: "l = Float -1 0"
      and u: "u = max (ub_cos prec ?lx) (ub_cos prec (- (?ux - 2 * ?lpi)))"
      by (auto simp add: bnds_cos_def Let_def)

    have "cos x \<le> real u"
    proof (cases "x - real k * 2 * pi < pi")
      case True hence "x - real k * 2 * pi \<le> pi" by simp
      from positive_lx[OF Cond[THEN conjunct1] this]
      show ?thesis unfolding u by (simp add: real_of_float_max)
    next
      case False hence "pi \<le> x - real k * 2 * pi" by simp
      hence pi_x: "- pi \<le> x - real k * 2 * pi - 2 * pi" by simp

      have "real ?ux \<le> 2 * pi" using Cond lpi by (auto simp add: le_float_def)
      hence "x - real k * 2 * pi - 2 * pi \<le> 0" using ux by simp

      have ux_0: "real (?ux - 2 * ?lpi) \<le> 0"
	using Cond by (auto simp add: le_float_def)

      from 2 and Cond have "\<not> ?ux \<le> ?lpi" by auto
      hence "- ?lpi \<le> ?ux - 2 * ?lpi" by (auto simp add: le_float_def)
      hence pi_ux: "- pi \<le> real (?ux - 2 * ?lpi)"
	using lpi[THEN le_imp_neg_le] by (auto simp add: le_float_def)

      have x_le_ux: "x - real k * 2 * pi - 2 * pi \<le> real (?ux - 2 * ?lpi)"
	using ux lpi by auto

      have "cos x = cos (x + real (-k) * 2 * pi + real (-1 :: int) * 2 * pi)"
	unfolding cos_periodic_int ..
      also have "\<dots> \<le> cos (real (?ux - 2 * ?lpi))"
	using cos_monotone_minus_pi_0'[OF pi_x x_le_ux ux_0]
	by (simp only: real_of_float_minus real_of_int_minus real_of_one
	    number_of_Min real_diff_def mult_minus_left real_mult_1)
      also have "\<dots> = cos (real (- (?ux - 2 * ?lpi)))"
	unfolding real_of_float_minus cos_minus ..
      also have "\<dots> \<le> real (ub_cos prec (- (?ux - 2 * ?lpi)))"
	using lb_cos_minus[OF pi_ux ux_0] by simp
      finally show ?thesis unfolding u by (simp add: real_of_float_max)
    qed
    thus ?thesis unfolding l by auto
  next case False note 4 = this show ?thesis
  proof (cases "-2 * ?lpi \<le> ?lx \<and> ?ux \<le> 0")
    case True note Cond = this with bnds 1 2 3 4
    have l: "l = Float -1 0"
      and u: "u = max (ub_cos prec (?lx + 2 * ?lpi)) (ub_cos prec (-?ux))"
      by (auto simp add: bnds_cos_def Let_def)

    have "cos x \<le> real u"
    proof (cases "-pi < x - real k * 2 * pi")
      case True hence "-pi \<le> x - real k * 2 * pi" by simp
      from negative_ux[OF this Cond[THEN conjunct2]]
      show ?thesis unfolding u by (simp add: real_of_float_max)
    next
      case False hence "x - real k * 2 * pi \<le> -pi" by simp
      hence pi_x: "x - real k * 2 * pi + 2 * pi \<le> pi" by simp

      have "-2 * pi \<le> real ?lx" using Cond lpi by (auto simp add: le_float_def)

      hence "0 \<le> x - real k * 2 * pi + 2 * pi" using lx by simp

      have lx_0: "0 \<le> real (?lx + 2 * ?lpi)"
	using Cond lpi by (auto simp add: le_float_def)

      from 1 and Cond have "\<not> -?lpi \<le> ?lx" by auto
      hence "?lx + 2 * ?lpi \<le> ?lpi" by (auto simp add: le_float_def)
      hence pi_lx: "real (?lx + 2 * ?lpi) \<le> pi"
	using lpi[THEN le_imp_neg_le] by (auto simp add: le_float_def)

      have lx_le_x: "real (?lx + 2 * ?lpi) \<le> x - real k * 2 * pi + 2 * pi"
	using lx lpi by auto

      have "cos x = cos (x + real (-k) * 2 * pi + real (1 :: int) * 2 * pi)"
	unfolding cos_periodic_int ..
      also have "\<dots> \<le> cos (real (?lx + 2 * ?lpi))"
	using cos_monotone_0_pi'[OF lx_0 lx_le_x pi_x]
	by (simp only: real_of_float_minus real_of_int_minus real_of_one
	  number_of_Min real_diff_def mult_minus_left real_mult_1)
      also have "\<dots> \<le> real (ub_cos prec (?lx + 2 * ?lpi))"
	using lb_cos[OF lx_0 pi_lx] by simp
      finally show ?thesis unfolding u by (simp add: real_of_float_max)
    qed
    thus ?thesis unfolding l by auto
  next
    case False with bnds 1 2 3 4 show ?thesis by (auto simp add: bnds_cos_def Let_def)
  qed qed qed qed qed
qed

section "Exponential function"

subsection "Compute the series of the exponential function"

fun ub_exp_horner :: "nat \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> float \<Rightarrow> float" and lb_exp_horner :: "nat \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> float \<Rightarrow> float" where
"ub_exp_horner prec 0 i k x       = 0" |
"ub_exp_horner prec (Suc n) i k x = rapprox_rat prec 1 (int k) + x * lb_exp_horner prec n (i + 1) (k * i) x" |
"lb_exp_horner prec 0 i k x       = 0" |
"lb_exp_horner prec (Suc n) i k x = lapprox_rat prec 1 (int k) + x * ub_exp_horner prec n (i + 1) (k * i) x"

lemma bnds_exp_horner: assumes "real x \<le> 0"
  shows "exp (real x) \<in> { real (lb_exp_horner prec (get_even n) 1 1 x) .. real (ub_exp_horner prec (get_odd n) 1 1 x) }"
proof -
  { fix n
    have F: "\<And> m. ((\<lambda>i. i + 1) ^^ n) m = n + m" by (induct n, auto)
    have "fact (Suc n) = fact n * ((\<lambda>i. i + 1) ^^ n) 1" unfolding F by auto } note f_eq = this

  note bounds = horner_bounds_nonpos[where f="fact" and lb="lb_exp_horner prec" and ub="ub_exp_horner prec" and j'=0 and s=1,
    OF assms f_eq lb_exp_horner.simps ub_exp_horner.simps]

  { have "real (lb_exp_horner prec (get_even n) 1 1 x) \<le> (\<Sum>j = 0..<get_even n. 1 / real (fact j) * real x ^ j)"
      using bounds(1) by auto
    also have "\<dots> \<le> exp (real x)"
    proof -
      obtain t where "\<bar>t\<bar> \<le> \<bar>real x\<bar>" and "exp (real x) = (\<Sum>m = 0..<get_even n. (real x) ^ m / real (fact m)) + exp t / real (fact (get_even n)) * (real x) ^ (get_even n)"
	using Maclaurin_exp_le by blast
      moreover have "0 \<le> exp t / real (fact (get_even n)) * (real x) ^ (get_even n)"
	by (auto intro!: mult_nonneg_nonneg divide_nonneg_pos simp add: get_even zero_le_even_power exp_gt_zero)
      ultimately show ?thesis
	using get_odd exp_gt_zero by (auto intro!: pordered_cancel_semiring_class.mult_nonneg_nonneg)
    qed
    finally have "real (lb_exp_horner prec (get_even n) 1 1 x) \<le> exp (real x)" .
  } moreover
  {
    have x_less_zero: "real x ^ get_odd n \<le> 0"
    proof (cases "real x = 0")
      case True
      have "(get_odd n) \<noteq> 0" using get_odd[THEN odd_pos] by auto
      thus ?thesis unfolding True power_0_left by auto
    next
      case False hence "real x < 0" using `real x \<le> 0` by auto
      show ?thesis by (rule less_imp_le, auto simp add: power_less_zero_eq get_odd `real x < 0`)
    qed

    obtain t where "\<bar>t\<bar> \<le> \<bar>real x\<bar>" and "exp (real x) = (\<Sum>m = 0..<get_odd n. (real x) ^ m / real (fact m)) + exp t / real (fact (get_odd n)) * (real x) ^ (get_odd n)"
      using Maclaurin_exp_le by blast
    moreover have "exp t / real (fact (get_odd n)) * (real x) ^ (get_odd n) \<le> 0"
      by (auto intro!: mult_nonneg_nonpos divide_nonpos_pos simp add: x_less_zero exp_gt_zero)
    ultimately have "exp (real x) \<le> (\<Sum>j = 0..<get_odd n. 1 / real (fact j) * real x ^ j)"
      using get_odd exp_gt_zero by (auto intro!: pordered_cancel_semiring_class.mult_nonneg_nonneg)
    also have "\<dots> \<le> real (ub_exp_horner prec (get_odd n) 1 1 x)"
      using bounds(2) by auto
    finally have "exp (real x) \<le> real (ub_exp_horner prec (get_odd n) 1 1 x)" .
  } ultimately show ?thesis by auto
qed

subsection "Compute the exponential function on the entire domain"

function ub_exp :: "nat \<Rightarrow> float \<Rightarrow> float" and lb_exp :: "nat \<Rightarrow> float \<Rightarrow> float" where
"lb_exp prec x = (if 0 < x then float_divl prec 1 (ub_exp prec (-x))
             else let
                horner = (\<lambda> x. let  y = lb_exp_horner prec (get_even (prec + 2)) 1 1 x  in if y \<le> 0 then Float 1 -2 else y)
             in if x < - 1 then (case floor_fl x of (Float m e) \<Rightarrow> (horner (float_divl prec x (- Float m e))) ^ (nat (-m) * 2 ^ nat e))
                           else horner x)" |
"ub_exp prec x = (if 0 < x    then float_divr prec 1 (lb_exp prec (-x))
             else if x < - 1  then (case floor_fl x of (Float m e) \<Rightarrow>
                                    (ub_exp_horner prec (get_odd (prec + 2)) 1 1 (float_divr prec x (- Float m e))) ^ (nat (-m) * 2 ^ nat e))
                              else ub_exp_horner prec (get_odd (prec + 2)) 1 1 x)"
by pat_completeness auto
termination by (relation "measure (\<lambda> v. let (prec, x) = sum_case id id v in (if 0 < x then 1 else 0))", auto simp add: less_float_def)

lemma exp_m1_ge_quarter: "(1 / 4 :: real) \<le> exp (- 1)"
proof -
  have eq4: "4 = Suc (Suc (Suc (Suc 0)))" by auto

  have "1 / 4 = real (Float 1 -2)" unfolding Float_num by auto
  also have "\<dots> \<le> real (lb_exp_horner 1 (get_even 4) 1 1 (- 1))"
    unfolding get_even_def eq4
    by (auto simp add: lapprox_posrat_def rapprox_posrat_def normfloat.simps)
  also have "\<dots> \<le> exp (real (- 1 :: float))" using bnds_exp_horner[where x="- 1"] by auto
  finally show ?thesis unfolding real_of_float_minus real_of_float_1 .
qed

lemma lb_exp_pos: assumes "\<not> 0 < x" shows "0 < lb_exp prec x"
proof -
  let "?lb_horner x" = "lb_exp_horner prec (get_even (prec + 2)) 1 1 x"
  let "?horner x" = "let  y = ?lb_horner x  in if y \<le> 0 then Float 1 -2 else y"
  have pos_horner: "\<And> x. 0 < ?horner x" unfolding Let_def by (cases "?lb_horner x \<le> 0", auto simp add: le_float_def less_float_def)
  moreover { fix x :: float fix num :: nat
    have "0 < real (?horner x) ^ num" using `0 < ?horner x`[unfolded less_float_def real_of_float_0] by (rule zero_less_power)
    also have "\<dots> = real ((?horner x) ^ num)" using float_power by auto
    finally have "0 < real ((?horner x) ^ num)" .
  }
  ultimately show ?thesis
    unfolding lb_exp.simps if_not_P[OF `\<not> 0 < x`] Let_def
    by (cases "floor_fl x", cases "x < - 1", auto simp add: float_power le_float_def less_float_def)
qed

lemma exp_boundaries': assumes "x \<le> 0"
  shows "exp (real x) \<in> { real (lb_exp prec x) .. real (ub_exp prec x)}"
proof -
  let "?lb_exp_horner x" = "lb_exp_horner prec (get_even (prec + 2)) 1 1 x"
  let "?ub_exp_horner x" = "ub_exp_horner prec (get_odd (prec + 2)) 1 1 x"

  have "real x \<le> 0" and "\<not> x > 0" using `x \<le> 0` unfolding le_float_def less_float_def by auto
  show ?thesis
  proof (cases "x < - 1")
    case False hence "- 1 \<le> real x" unfolding less_float_def by auto
    show ?thesis
    proof (cases "?lb_exp_horner x \<le> 0")
      from `\<not> x < - 1` have "- 1 \<le> real x" unfolding less_float_def by auto
      hence "exp (- 1) \<le> exp (real x)" unfolding exp_le_cancel_iff .
      from order_trans[OF exp_m1_ge_quarter this]
      have "real (Float 1 -2) \<le> exp (real x)" unfolding Float_num .
      moreover case True
      ultimately show ?thesis using bnds_exp_horner `real x \<le> 0` `\<not> x > 0` `\<not> x < - 1` by auto
    next
      case False thus ?thesis using bnds_exp_horner `real x \<le> 0` `\<not> x > 0` `\<not> x < - 1` by (auto simp add: Let_def)
    qed
  next
    case True

    obtain m e where Float_floor: "floor_fl x = Float m e" by (cases "floor_fl x", auto)
    let ?num = "nat (- m) * 2 ^ nat e"

    have "real (floor_fl x) < - 1" using floor_fl `x < - 1` unfolding le_float_def less_float_def real_of_float_minus real_of_float_1 by (rule order_le_less_trans)
    hence "real (floor_fl x) < 0" unfolding Float_floor real_of_float_simp using zero_less_pow2[of xe] by auto
    hence "m < 0"
      unfolding less_float_def real_of_float_0 Float_floor real_of_float_simp
      unfolding pos_prod_lt[OF zero_less_pow2[of e], unfolded real_mult_commute] by auto
    hence "1 \<le> - m" by auto
    hence "0 < nat (- m)" by auto
    moreover
    have "0 \<le> e" using floor_pos_exp Float_floor[symmetric] by auto
    hence "(0::nat) < 2 ^ nat e" by auto
    ultimately have "0 < ?num"  by auto
    hence "real ?num \<noteq> 0" by auto
    have e_nat: "int (nat e) = e" using `0 \<le> e` by auto
    have num_eq: "real ?num = real (- floor_fl x)" using `0 < nat (- m)`
      unfolding Float_floor real_of_float_minus real_of_float_simp real_of_nat_mult pow2_int[of "nat e", unfolded e_nat] realpow_real_of_nat[symmetric] by auto
    have "0 < - floor_fl x" using `0 < ?num`[unfolded real_of_nat_less_iff[symmetric]] unfolding less_float_def num_eq[symmetric] real_of_float_0 real_of_nat_zero .
    hence "real (floor_fl x) < 0" unfolding less_float_def by auto

    have "exp (real x) \<le> real (ub_exp prec x)"
    proof -
      have div_less_zero: "real (float_divr prec x (- floor_fl x)) \<le> 0"
	using float_divr_nonpos_pos_upper_bound[OF `x \<le> 0` `0 < - floor_fl x`] unfolding le_float_def real_of_float_0 .

      have "exp (real x) = exp (real ?num * (real x / real ?num))" using `real ?num \<noteq> 0` by auto
      also have "\<dots> = exp (real x / real ?num) ^ ?num" unfolding exp_real_of_nat_mult ..
      also have "\<dots> \<le> exp (real (float_divr prec x (- floor_fl x))) ^ ?num" unfolding num_eq
	by (rule power_mono, rule exp_le_cancel_iff[THEN iffD2], rule float_divr) auto
      also have "\<dots> \<le> real ((?ub_exp_horner (float_divr prec x (- floor_fl x))) ^ ?num)" unfolding float_power
	by (rule power_mono, rule bnds_exp_horner[OF div_less_zero, unfolded atLeastAtMost_iff, THEN conjunct2], auto)
      finally show ?thesis unfolding ub_exp.simps if_not_P[OF `\<not> 0 < x`] if_P[OF `x < - 1`] float.cases Float_floor Let_def .
    qed
    moreover
    have "real (lb_exp prec x) \<le> exp (real x)"
    proof -
      let ?divl = "float_divl prec x (- Float m e)"
      let ?horner = "?lb_exp_horner ?divl"

      show ?thesis
      proof (cases "?horner \<le> 0")
	case False hence "0 \<le> real ?horner" unfolding le_float_def by auto

	have div_less_zero: "real (float_divl prec x (- floor_fl x)) \<le> 0"
	  using `real (floor_fl x) < 0` `real x \<le> 0` by (auto intro!: order_trans[OF float_divl] divide_nonpos_neg)

	have "real ((?lb_exp_horner (float_divl prec x (- floor_fl x))) ^ ?num) \<le>
          exp (real (float_divl prec x (- floor_fl x))) ^ ?num" unfolding float_power
	  using `0 \<le> real ?horner`[unfolded Float_floor[symmetric]] bnds_exp_horner[OF div_less_zero, unfolded atLeastAtMost_iff, THEN conjunct1] by (auto intro!: power_mono)
	also have "\<dots> \<le> exp (real x / real ?num) ^ ?num" unfolding num_eq
	  using float_divl by (auto intro!: power_mono simp del: real_of_float_minus)
	also have "\<dots> = exp (real ?num * (real x / real ?num))" unfolding exp_real_of_nat_mult ..
	also have "\<dots> = exp (real x)" using `real ?num \<noteq> 0` by auto
	finally show ?thesis
	  unfolding lb_exp.simps if_not_P[OF `\<not> 0 < x`] if_P[OF `x < - 1`] float.cases Float_floor Let_def if_not_P[OF False] by auto
      next
	case True
	have "real (floor_fl x) \<noteq> 0" and "real (floor_fl x) \<le> 0" using `real (floor_fl x) < 0` by auto
	from divide_right_mono_neg[OF floor_fl[of x] `real (floor_fl x) \<le> 0`, unfolded divide_self[OF `real (floor_fl x) \<noteq> 0`]]
	have "- 1 \<le> real x / real (- floor_fl x)" unfolding real_of_float_minus by auto
	from order_trans[OF exp_m1_ge_quarter this[unfolded exp_le_cancel_iff[where x="- 1", symmetric]]]
	have "real (Float 1 -2) \<le> exp (real x / real (- floor_fl x))" unfolding Float_num .
	hence "real (Float 1 -2) ^ ?num \<le> exp (real x / real (- floor_fl x)) ^ ?num"
	  by (auto intro!: power_mono simp add: Float_num)
	also have "\<dots> = exp (real x)" unfolding num_eq exp_real_of_nat_mult[symmetric] using `real (floor_fl x) \<noteq> 0` by auto
	finally show ?thesis
	  unfolding lb_exp.simps if_not_P[OF `\<not> 0 < x`] if_P[OF `x < - 1`] float.cases Float_floor Let_def if_P[OF True] float_power .
      qed
    qed
    ultimately show ?thesis by auto
  qed
qed

lemma exp_boundaries: "exp (real x) \<in> { real (lb_exp prec x) .. real (ub_exp prec x)}"
proof -
  show ?thesis
  proof (cases "0 < x")
    case False hence "x \<le> 0" unfolding less_float_def le_float_def by auto
    from exp_boundaries'[OF this] show ?thesis .
  next
    case True hence "-x \<le> 0" unfolding less_float_def le_float_def by auto

    have "real (lb_exp prec x) \<le> exp (real x)"
    proof -
      from exp_boundaries'[OF `-x \<le> 0`]
      have ub_exp: "exp (- real x) \<le> real (ub_exp prec (-x))" unfolding atLeastAtMost_iff real_of_float_minus by auto

      have "real (float_divl prec 1 (ub_exp prec (-x))) \<le> 1 / real (ub_exp prec (-x))" using float_divl[where x=1] by auto
      also have "\<dots> \<le> exp (real x)"
	using ub_exp[unfolded inverse_le_iff_le[OF order_less_le_trans[OF exp_gt_zero ub_exp] exp_gt_zero, symmetric]]
	unfolding exp_minus nonzero_inverse_inverse_eq[OF exp_not_eq_zero] inverse_eq_divide by auto
      finally show ?thesis unfolding lb_exp.simps if_P[OF True] .
    qed
    moreover
    have "exp (real x) \<le> real (ub_exp prec x)"
    proof -
      have "\<not> 0 < -x" using `0 < x` unfolding less_float_def by auto

      from exp_boundaries'[OF `-x \<le> 0`]
      have lb_exp: "real (lb_exp prec (-x)) \<le> exp (- real x)" unfolding atLeastAtMost_iff real_of_float_minus by auto

      have "exp (real x) \<le> real (1 :: float) / real (lb_exp prec (-x))"
	using lb_exp[unfolded inverse_le_iff_le[OF exp_gt_zero lb_exp_pos[OF `\<not> 0 < -x`, unfolded less_float_def real_of_float_0],
	                                        symmetric]]
	unfolding exp_minus nonzero_inverse_inverse_eq[OF exp_not_eq_zero] inverse_eq_divide real_of_float_1 by auto
      also have "\<dots> \<le> real (float_divr prec 1 (lb_exp prec (-x)))" using float_divr .
      finally show ?thesis unfolding ub_exp.simps if_P[OF True] .
    qed
    ultimately show ?thesis by auto
  qed
qed

lemma bnds_exp: "\<forall> x lx ux. (l, u) = (lb_exp prec lx, ub_exp prec ux) \<and> x \<in> {real lx .. real ux} \<longrightarrow> real l \<le> exp x \<and> exp x \<le> real u"
proof (rule allI, rule allI, rule allI, rule impI)
  fix x lx ux
  assume "(l, u) = (lb_exp prec lx, ub_exp prec ux) \<and> x \<in> {real lx .. real ux}"
  hence l: "lb_exp prec lx = l " and u: "ub_exp prec ux = u" and x: "x \<in> {real lx .. real ux}" by auto

  { from exp_boundaries[of lx prec, unfolded l]
    have "real l \<le> exp (real lx)" by (auto simp del: lb_exp.simps)
    also have "\<dots> \<le> exp x" using x by auto
    finally have "real l \<le> exp x" .
  } moreover
  { have "exp x \<le> exp (real ux)" using x by auto
    also have "\<dots> \<le> real u" using exp_boundaries[of ux prec, unfolded u] by (auto simp del: ub_exp.simps)
    finally have "exp x \<le> real u" .
  } ultimately show "real l \<le> exp x \<and> exp x \<le> real u" ..
qed

section "Logarithm"

subsection "Compute the logarithm series"

fun ub_ln_horner :: "nat \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> float \<Rightarrow> float"
and lb_ln_horner :: "nat \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> float \<Rightarrow> float" where
"ub_ln_horner prec 0 i x       = 0" |
"ub_ln_horner prec (Suc n) i x = rapprox_rat prec 1 (int i) - x * lb_ln_horner prec n (Suc i) x" |
"lb_ln_horner prec 0 i x       = 0" |
"lb_ln_horner prec (Suc n) i x = lapprox_rat prec 1 (int i) - x * ub_ln_horner prec n (Suc i) x"

lemma ln_bounds:
  assumes "0 \<le> x" and "x < 1"
  shows "(\<Sum>i=0..<2*n. -1^i * (1 / real (i + 1)) * x ^ (Suc i)) \<le> ln (x + 1)" (is "?lb")
  and "ln (x + 1) \<le> (\<Sum>i=0..<2*n + 1. -1^i * (1 / real (i + 1)) * x ^ (Suc i))" (is "?ub")
proof -
  let "?a n" = "(1/real (n +1)) * x ^ (Suc n)"

  have ln_eq: "(\<Sum> i. -1^i * ?a i) = ln (x + 1)"
    using ln_series[of "x + 1"] `0 \<le> x` `x < 1` by auto

  have "norm x < 1" using assms by auto
  have "?a ----> 0" unfolding Suc_eq_plus1[symmetric] inverse_eq_divide[symmetric]
    using LIMSEQ_mult[OF LIMSEQ_inverse_real_of_nat LIMSEQ_Suc[OF LIMSEQ_power_zero[OF `norm x < 1`]]] by auto
  { fix n have "0 \<le> ?a n" by (rule mult_nonneg_nonneg, auto intro!: mult_nonneg_nonneg simp add: `0 \<le> x`) }
  { fix n have "?a (Suc n) \<le> ?a n" unfolding inverse_eq_divide[symmetric]
    proof (rule mult_mono)
      show "0 \<le> x ^ Suc (Suc n)" by (auto intro!: mult_nonneg_nonneg simp add: `0 \<le> x`)
      have "x ^ Suc (Suc n) \<le> x ^ Suc n * 1" unfolding power_Suc2 real_mult_assoc[symmetric]
	by (rule mult_left_mono, fact less_imp_le[OF `x < 1`], auto intro!: mult_nonneg_nonneg simp add: `0 \<le> x`)
      thus "x ^ Suc (Suc n) \<le> x ^ Suc n" by auto
    qed auto }
  from summable_Leibniz'(2,4)[OF `?a ----> 0` `\<And>n. 0 \<le> ?a n`, OF `\<And>n. ?a (Suc n) \<le> ?a n`, unfolded ln_eq]
  show "?lb" and "?ub" by auto
qed

lemma ln_float_bounds:
  assumes "0 \<le> real x" and "real x < 1"
  shows "real (x * lb_ln_horner prec (get_even n) 1 x) \<le> ln (real x + 1)" (is "?lb \<le> ?ln")
  and "ln (real x + 1) \<le> real (x * ub_ln_horner prec (get_odd n) 1 x)" (is "?ln \<le> ?ub")
proof -
  obtain ev where ev: "get_even n = 2 * ev" using get_even_double ..
  obtain od where od: "get_odd n = 2 * od + 1" using get_odd_double ..

  let "?s n" = "-1^n * (1 / real (1 + n)) * (real x)^(Suc n)"

  have "?lb \<le> setsum ?s {0 ..< 2 * ev}" unfolding power_Suc2 real_mult_assoc[symmetric] real_of_float_mult setsum_left_distrib[symmetric] unfolding real_mult_commute[of "real x"] ev
    using horner_bounds(1)[where G="\<lambda> i k. Suc k" and F="\<lambda>x. x" and f="\<lambda>x. x" and lb="\<lambda>n i k x. lb_ln_horner prec n k x" and ub="\<lambda>n i k x. ub_ln_horner prec n k x" and j'=1 and n="2*ev",
      OF `0 \<le> real x` refl lb_ln_horner.simps ub_ln_horner.simps] `0 \<le> real x`
    by (rule mult_right_mono)
  also have "\<dots> \<le> ?ln" using ln_bounds(1)[OF `0 \<le> real x` `real x < 1`] by auto
  finally show "?lb \<le> ?ln" .

  have "?ln \<le> setsum ?s {0 ..< 2 * od + 1}" using ln_bounds(2)[OF `0 \<le> real x` `real x < 1`] by auto
  also have "\<dots> \<le> ?ub" unfolding power_Suc2 real_mult_assoc[symmetric] real_of_float_mult setsum_left_distrib[symmetric] unfolding real_mult_commute[of "real x"] od
    using horner_bounds(2)[where G="\<lambda> i k. Suc k" and F="\<lambda>x. x" and f="\<lambda>x. x" and lb="\<lambda>n i k x. lb_ln_horner prec n k x" and ub="\<lambda>n i k x. ub_ln_horner prec n k x" and j'=1 and n="2*od+1",
      OF `0 \<le> real x` refl lb_ln_horner.simps ub_ln_horner.simps] `0 \<le> real x`
    by (rule mult_right_mono)
  finally show "?ln \<le> ?ub" .
qed

lemma ln_add: assumes "0 < x" and "0 < y" shows "ln (x + y) = ln x + ln (1 + y / x)"
proof -
  have "x \<noteq> 0" using assms by auto
  have "x + y = x * (1 + y / x)" unfolding right_distrib times_divide_eq_right nonzero_mult_divide_cancel_left[OF `x \<noteq> 0`] by auto
  moreover
  have "0 < y / x" using assms divide_pos_pos by auto
  hence "0 < 1 + y / x" by auto
  ultimately show ?thesis using ln_mult assms by auto
qed

subsection "Compute the logarithm of 2"

definition ub_ln2 where "ub_ln2 prec = (let third = rapprox_rat (max prec 1) 1 3
                                        in (Float 1 -1 * ub_ln_horner prec (get_odd prec) 1 (Float 1 -1)) +
                                           (third * ub_ln_horner prec (get_odd prec) 1 third))"
definition lb_ln2 where "lb_ln2 prec = (let third = lapprox_rat prec 1 3
                                        in (Float 1 -1 * lb_ln_horner prec (get_even prec) 1 (Float 1 -1)) +
                                           (third * lb_ln_horner prec (get_even prec) 1 third))"

lemma ub_ln2: "ln 2 \<le> real (ub_ln2 prec)" (is "?ub_ln2")
  and lb_ln2: "real (lb_ln2 prec) \<le> ln 2" (is "?lb_ln2")
proof -
  let ?uthird = "rapprox_rat (max prec 1) 1 3"
  let ?lthird = "lapprox_rat prec 1 3"

  have ln2_sum: "ln 2 = ln (1/2 + 1) + ln (1 / 3 + 1)"
    using ln_add[of "3 / 2" "1 / 2"] by auto
  have lb3: "real ?lthird \<le> 1 / 3" using lapprox_rat[of prec 1 3] by auto
  hence lb3_ub: "real ?lthird < 1" by auto
  have lb3_lb: "0 \<le> real ?lthird" using lapprox_rat_bottom[of 1 3] by auto
  have ub3: "1 / 3 \<le> real ?uthird" using rapprox_rat[of 1 3] by auto
  hence ub3_lb: "0 \<le> real ?uthird" by auto

  have lb2: "0 \<le> real (Float 1 -1)" and ub2: "real (Float 1 -1) < 1" unfolding Float_num by auto

  have "0 \<le> (1::int)" and "0 < (3::int)" by auto
  have ub3_ub: "real ?uthird < 1" unfolding rapprox_rat.simps(2)[OF `0 \<le> 1` `0 < 3`]
    by (rule rapprox_posrat_less1, auto)

  have third_gt0: "(0 :: real) < 1 / 3 + 1" by auto
  have uthird_gt0: "0 < real ?uthird + 1" using ub3_lb by auto
  have lthird_gt0: "0 < real ?lthird + 1" using lb3_lb by auto

  show ?ub_ln2 unfolding ub_ln2_def Let_def real_of_float_add ln2_sum Float_num(4)[symmetric]
  proof (rule add_mono, fact ln_float_bounds(2)[OF lb2 ub2])
    have "ln (1 / 3 + 1) \<le> ln (real ?uthird + 1)" unfolding ln_le_cancel_iff[OF third_gt0 uthird_gt0] using ub3 by auto
    also have "\<dots> \<le> real (?uthird * ub_ln_horner prec (get_odd prec) 1 ?uthird)"
      using ln_float_bounds(2)[OF ub3_lb ub3_ub] .
    finally show "ln (1 / 3 + 1) \<le> real (?uthird * ub_ln_horner prec (get_odd prec) 1 ?uthird)" .
  qed
  show ?lb_ln2 unfolding lb_ln2_def Let_def real_of_float_add ln2_sum Float_num(4)[symmetric]
  proof (rule add_mono, fact ln_float_bounds(1)[OF lb2 ub2])
    have "real (?lthird * lb_ln_horner prec (get_even prec) 1 ?lthird) \<le> ln (real ?lthird + 1)"
      using ln_float_bounds(1)[OF lb3_lb lb3_ub] .
    also have "\<dots> \<le> ln (1 / 3 + 1)" unfolding ln_le_cancel_iff[OF lthird_gt0 third_gt0] using lb3 by auto
    finally show "real (?lthird * lb_ln_horner prec (get_even prec) 1 ?lthird) \<le> ln (1 / 3 + 1)" .
  qed
qed

subsection "Compute the logarithm in the entire domain"

function ub_ln :: "nat \<Rightarrow> float \<Rightarrow> float option" and lb_ln :: "nat \<Rightarrow> float \<Rightarrow> float option" where
"ub_ln prec x = (if x \<le> 0          then None
            else if x < 1          then Some (- the (lb_ln prec (float_divl (max prec 1) 1 x)))
            else let horner = \<lambda>x. x * ub_ln_horner prec (get_odd prec) 1 x in
                 if x \<le> Float 3 -1 then Some (horner (x - 1))
            else if x < Float 1 1  then Some (horner (Float 1 -1) + horner (x * rapprox_rat prec 2 3 - 1))
                                   else let l = bitlen (mantissa x) - 1 in
                                        Some (ub_ln2 prec * (Float (scale x + l) 0) + horner (Float (mantissa x) (- l) - 1)))" |
"lb_ln prec x = (if x \<le> 0          then None
            else if x < 1          then Some (- the (ub_ln prec (float_divr prec 1 x)))
            else let horner = \<lambda>x. x * lb_ln_horner prec (get_even prec) 1 x in
                 if x \<le> Float 3 -1 then Some (horner (x - 1))
            else if x < Float 1 1  then Some (horner (Float 1 -1) +
                                              horner (max (x * lapprox_rat prec 2 3 - 1) 0))
                                   else let l = bitlen (mantissa x) - 1 in
                                        Some (lb_ln2 prec * (Float (scale x + l) 0) + horner (Float (mantissa x) (- l) - 1)))"
by pat_completeness auto

termination proof (relation "measure (\<lambda> v. let (prec, x) = sum_case id id v in (if x < 1 then 1 else 0))", auto)
  fix prec x assume "\<not> x \<le> 0" and "x < 1" and "float_divl (max prec (Suc 0)) 1 x < 1"
  hence "0 < x" and "0 < max prec (Suc 0)" unfolding less_float_def le_float_def by auto
  from float_divl_pos_less1_bound[OF `0 < x` `x < 1` `0 < max prec (Suc 0)`]
  show False using `float_divl (max prec (Suc 0)) 1 x < 1` unfolding less_float_def le_float_def by auto
next
  fix prec x assume "\<not> x \<le> 0" and "x < 1" and "float_divr prec 1 x < 1"
  hence "0 < x" unfolding less_float_def le_float_def by auto
  from float_divr_pos_less1_lower_bound[OF `0 < x` `x < 1`, of prec]
  show False using `float_divr prec 1 x < 1` unfolding less_float_def le_float_def by auto
qed

lemma ln_shifted_float: assumes "0 < m" shows "ln (real (Float m e)) = ln 2 * real (e + (bitlen m - 1)) + ln (real (Float m (- (bitlen m - 1))))"
proof -
  let ?B = "2^nat (bitlen m - 1)"
  have "0 < real m" and "\<And>X. (0 :: real) < 2^X" and "0 < (2 :: real)" and "m \<noteq> 0" using assms by auto
  hence "0 \<le> bitlen m - 1" using bitlen_ge1[OF `m \<noteq> 0`] by auto
  show ?thesis
  proof (cases "0 \<le> e")
    case True
    show ?thesis unfolding normalized_float[OF `m \<noteq> 0`]
      unfolding ln_div[OF `0 < real m` `0 < ?B`] real_of_int_add ln_realpow[OF `0 < 2`]
      unfolding real_of_float_ge0_exp[OF True] ln_mult[OF `0 < real m` `0 < 2^nat e`]
      ln_realpow[OF `0 < 2`] algebra_simps using `0 \<le> bitlen m - 1` True by auto
  next
    case False hence "0 < -e" by auto
    hence pow_gt0: "(0::real) < 2^nat (-e)" by auto
    hence inv_gt0: "(0::real) < inverse (2^nat (-e))" by auto
    show ?thesis unfolding normalized_float[OF `m \<noteq> 0`]
      unfolding ln_div[OF `0 < real m` `0 < ?B`] real_of_int_add ln_realpow[OF `0 < 2`]
      unfolding real_of_float_nge0_exp[OF False] ln_mult[OF `0 < real m` inv_gt0] ln_inverse[OF pow_gt0]
      ln_realpow[OF `0 < 2`] algebra_simps using `0 \<le> bitlen m - 1` False by auto
  qed
qed

lemma ub_ln_lb_ln_bounds': assumes "1 \<le> x"
  shows "real (the (lb_ln prec x)) \<le> ln (real x) \<and> ln (real x) \<le> real (the (ub_ln prec x))"
  (is "?lb \<le> ?ln \<and> ?ln \<le> ?ub")
proof (cases "x < Float 1 1")
  case True
  hence "real (x - 1) < 1" and "real x < 2" unfolding less_float_def Float_num by auto
  have "\<not> x \<le> 0" and "\<not> x < 1" using `1 \<le> x` unfolding less_float_def le_float_def by auto
  hence "0 \<le> real (x - 1)" using `1 \<le> x` unfolding less_float_def Float_num by auto

  have [simp]: "real (Float 3 -1) = 3 / 2" by (simp add: real_of_float_def pow2_def)

  show ?thesis
  proof (cases "x \<le> Float 3 -1")
    case True
    show ?thesis unfolding lb_ln.simps unfolding ub_ln.simps Let_def
      using ln_float_bounds[OF `0 \<le> real (x - 1)` `real (x - 1) < 1`, of prec] `\<not> x \<le> 0` `\<not> x < 1` True
      by auto
  next
    case False hence *: "3 / 2 < real x" by (auto simp add: le_float_def)

    with ln_add[of "3 / 2" "real x - 3 / 2"]
    have add: "ln (real x) = ln (3 / 2) + ln (real x * 2 / 3)"
      by (auto simp add: algebra_simps diff_divide_distrib)

    let "?ub_horner x" = "x * ub_ln_horner prec (get_odd prec) 1 x"
    let "?lb_horner x" = "x * lb_ln_horner prec (get_even prec) 1 x"

    { have up: "real (rapprox_rat prec 2 3) \<le> 1"
	by (rule rapprox_rat_le1) simp_all
      have low: "2 / 3 \<le> real (rapprox_rat prec 2 3)"
	by (rule order_trans[OF _ rapprox_rat]) simp
      from mult_less_le_imp_less[OF * low] *
      have pos: "0 < real (x * rapprox_rat prec 2 3 - 1)" by auto

      have "ln (real x * 2/3)
	\<le> ln (real (x * rapprox_rat prec 2 3 - 1) + 1)"
      proof (rule ln_le_cancel_iff[symmetric, THEN iffD1])
	show "real x * 2 / 3 \<le> real (x * rapprox_rat prec 2 3 - 1) + 1"
	  using * low by auto
	show "0 < real x * 2 / 3" using * by simp
	show "0 < real (x * rapprox_rat prec 2 3 - 1) + 1" using pos by auto
      qed
      also have "\<dots> \<le> real (?ub_horner (x * rapprox_rat prec 2 3 - 1))"
      proof (rule ln_float_bounds(2))
	from mult_less_le_imp_less[OF `real x < 2` up] low *
	show "real (x * rapprox_rat prec 2 3 - 1) < 1" by auto
	show "0 \<le> real (x * rapprox_rat prec 2 3 - 1)" using pos by auto
      qed
      finally have "ln (real x)
	\<le> real (?ub_horner (Float 1 -1))
	  + real (?ub_horner (x * rapprox_rat prec 2 3 - 1))"
	using ln_float_bounds(2)[of "Float 1 -1" prec prec] add by auto }
    moreover
    { let ?max = "max (x * lapprox_rat prec 2 3 - 1) 0"

      have up: "real (lapprox_rat prec 2 3) \<le> 2/3"
	by (rule order_trans[OF lapprox_rat], simp)

      have low: "0 \<le> real (lapprox_rat prec 2 3)"
	using lapprox_rat_bottom[of 2 3 prec] by simp

      have "real (?lb_horner ?max)
	\<le> ln (real ?max + 1)"
      proof (rule ln_float_bounds(1))
	from mult_less_le_imp_less[OF `real x < 2` up] * low
	show "real ?max < 1" by (cases "real (lapprox_rat prec 2 3) = 0",
	  auto simp add: real_of_float_max)
	show "0 \<le> real ?max" by (auto simp add: real_of_float_max)
      qed
      also have "\<dots> \<le> ln (real x * 2/3)"
      proof (rule ln_le_cancel_iff[symmetric, THEN iffD1])
	show "0 < real ?max + 1" by (auto simp add: real_of_float_max)
	show "0 < real x * 2/3" using * by auto
	show "real ?max + 1 \<le> real x * 2/3" using * up
	  by (cases "0 < real x * real (lapprox_posrat prec 2 3) - 1",
	      auto simp add: real_of_float_max min_max.sup_absorb1)
      qed
      finally have "real (?lb_horner (Float 1 -1)) + real (?lb_horner ?max)
	\<le> ln (real x)"
	using ln_float_bounds(1)[of "Float 1 -1" prec prec] add by auto }
    ultimately
    show ?thesis unfolding lb_ln.simps unfolding ub_ln.simps Let_def
      using `\<not> x \<le> 0` `\<not> x < 1` True False by auto
  qed
next
  case False
  hence "\<not> x \<le> 0" and "\<not> x < 1" "0 < x" "\<not> x \<le> Float 3 -1"
    using `1 \<le> x` unfolding less_float_def le_float_def real_of_float_simp pow2_def
    by auto
  show ?thesis
  proof (cases x)
    case (Float m e)
    let ?s = "Float (e + (bitlen m - 1)) 0"
    let ?x = "Float m (- (bitlen m - 1))"

    have "0 < m" and "m \<noteq> 0" using float_pos_m_pos `0 < x` Float by auto

    {
      have "real (lb_ln2 prec * ?s) \<le> ln 2 * real (e + (bitlen m - 1))" (is "?lb2 \<le> _")
	unfolding real_of_float_mult real_of_float_ge0_exp[OF order_refl] nat_0 power_0 mult_1_right
	using lb_ln2[of prec]
      proof (rule mult_right_mono)
	have "1 \<le> Float m e" using `1 \<le> x` Float unfolding le_float_def by auto
	from float_gt1_scale[OF this]
	show "0 \<le> real (e + (bitlen m - 1))" by auto
      qed
      moreover
      from bitlen_div[OF `0 < m`, unfolded normalized_float[OF `m \<noteq> 0`, symmetric]]
      have "0 \<le> real (?x - 1)" and "real (?x - 1) < 1" by auto
      from ln_float_bounds(1)[OF this]
      have "real ((?x - 1) * lb_ln_horner prec (get_even prec) 1 (?x - 1)) \<le> ln (real ?x)" (is "?lb_horner \<le> _") by auto
      ultimately have "?lb2 + ?lb_horner \<le> ln (real x)"
	unfolding Float ln_shifted_float[OF `0 < m`, of e] by auto
    }
    moreover
    {
      from bitlen_div[OF `0 < m`, unfolded normalized_float[OF `m \<noteq> 0`, symmetric]]
      have "0 \<le> real (?x - 1)" and "real (?x - 1) < 1" by auto
      from ln_float_bounds(2)[OF this]
      have "ln (real ?x) \<le> real ((?x - 1) * ub_ln_horner prec (get_odd prec) 1 (?x - 1))" (is "_ \<le> ?ub_horner") by auto
      moreover
      have "ln 2 * real (e + (bitlen m - 1)) \<le> real (ub_ln2 prec * ?s)" (is "_ \<le> ?ub2")
	unfolding real_of_float_mult real_of_float_ge0_exp[OF order_refl] nat_0 power_0 mult_1_right
	using ub_ln2[of prec]
      proof (rule mult_right_mono)
	have "1 \<le> Float m e" using `1 \<le> x` Float unfolding le_float_def by auto
	from float_gt1_scale[OF this]
	show "0 \<le> real (e + (bitlen m - 1))" by auto
      qed
      ultimately have "ln (real x) \<le> ?ub2 + ?ub_horner"
	unfolding Float ln_shifted_float[OF `0 < m`, of e] by auto
    }
    ultimately show ?thesis unfolding lb_ln.simps unfolding ub_ln.simps
      unfolding if_not_P[OF `\<not> x \<le> 0`] if_not_P[OF `\<not> x < 1`] if_not_P[OF False] if_not_P[OF `\<not> x \<le> Float 3 -1`] Let_def
      unfolding scale.simps[of m e, unfolded Float[symmetric]] mantissa.simps[of m e, unfolded Float[symmetric]] real_of_float_add
      by auto
  qed
qed

lemma ub_ln_lb_ln_bounds: assumes "0 < x"
  shows "real (the (lb_ln prec x)) \<le> ln (real x) \<and> ln (real x) \<le> real (the (ub_ln prec x))"
  (is "?lb \<le> ?ln \<and> ?ln \<le> ?ub")
proof (cases "x < 1")
  case False hence "1 \<le> x" unfolding less_float_def le_float_def by auto
  show ?thesis using ub_ln_lb_ln_bounds'[OF `1 \<le> x`] .
next
  case True have "\<not> x \<le> 0" using `0 < x` unfolding less_float_def le_float_def by auto

  have "0 < real x" and "real x \<noteq> 0" using `0 < x` unfolding less_float_def by auto
  hence A: "0 < 1 / real x" by auto

  {
    let ?divl = "float_divl (max prec 1) 1 x"
    have A': "1 \<le> ?divl" using float_divl_pos_less1_bound[OF `0 < x` `x < 1`] unfolding le_float_def less_float_def by auto
    hence B: "0 < real ?divl" unfolding le_float_def by auto

    have "ln (real ?divl) \<le> ln (1 / real x)" unfolding ln_le_cancel_iff[OF B A] using float_divl[of _ 1 x] by auto
    hence "ln (real x) \<le> - ln (real ?divl)" unfolding nonzero_inverse_eq_divide[OF `real x \<noteq> 0`, symmetric] ln_inverse[OF `0 < real x`] by auto
    from this ub_ln_lb_ln_bounds'[OF A', THEN conjunct1, THEN le_imp_neg_le]
    have "?ln \<le> real (- the (lb_ln prec ?divl))" unfolding real_of_float_minus by (rule order_trans)
  } moreover
  {
    let ?divr = "float_divr prec 1 x"
    have A': "1 \<le> ?divr" using float_divr_pos_less1_lower_bound[OF `0 < x` `x < 1`] unfolding le_float_def less_float_def by auto
    hence B: "0 < real ?divr" unfolding le_float_def by auto

    have "ln (1 / real x) \<le> ln (real ?divr)" unfolding ln_le_cancel_iff[OF A B] using float_divr[of 1 x] by auto
    hence "- ln (real ?divr) \<le> ln (real x)" unfolding nonzero_inverse_eq_divide[OF `real x \<noteq> 0`, symmetric] ln_inverse[OF `0 < real x`] by auto
    from ub_ln_lb_ln_bounds'[OF A', THEN conjunct2, THEN le_imp_neg_le] this
    have "real (- the (ub_ln prec ?divr)) \<le> ?ln" unfolding real_of_float_minus by (rule order_trans)
  }
  ultimately show ?thesis unfolding lb_ln.simps[where x=x]  ub_ln.simps[where x=x]
    unfolding if_not_P[OF `\<not> x \<le> 0`] if_P[OF True] by auto
qed

lemma lb_ln: assumes "Some y = lb_ln prec x"
  shows "real y \<le> ln (real x)" and "0 < real x"
proof -
  have "0 < x"
  proof (rule ccontr)
    assume "\<not> 0 < x" hence "x \<le> 0" unfolding le_float_def less_float_def by auto
    thus False using assms by auto
  qed
  thus "0 < real x" unfolding less_float_def by auto
  have "real (the (lb_ln prec x)) \<le> ln (real x)" using ub_ln_lb_ln_bounds[OF `0 < x`] ..
  thus "real y \<le> ln (real x)" unfolding assms[symmetric] by auto
qed

lemma ub_ln: assumes "Some y = ub_ln prec x"
  shows "ln (real x) \<le> real y" and "0 < real x"
proof -
  have "0 < x"
  proof (rule ccontr)
    assume "\<not> 0 < x" hence "x \<le> 0" unfolding le_float_def less_float_def by auto
    thus False using assms by auto
  qed
  thus "0 < real x" unfolding less_float_def by auto
  have "ln (real x) \<le> real (the (ub_ln prec x))" using ub_ln_lb_ln_bounds[OF `0 < x`] ..
  thus "ln (real x) \<le> real y" unfolding assms[symmetric] by auto
qed

lemma bnds_ln: "\<forall> x lx ux. (Some l, Some u) = (lb_ln prec lx, ub_ln prec ux) \<and> x \<in> {real lx .. real ux} \<longrightarrow> real l \<le> ln x \<and> ln x \<le> real u"
proof (rule allI, rule allI, rule allI, rule impI)
  fix x lx ux
  assume "(Some l, Some u) = (lb_ln prec lx, ub_ln prec ux) \<and> x \<in> {real lx .. real ux}"
  hence l: "Some l = lb_ln prec lx " and u: "Some u = ub_ln prec ux" and x: "x \<in> {real lx .. real ux}" by auto

  have "ln (real ux) \<le> real u" and "0 < real ux" using ub_ln u by auto
  have "real l \<le> ln (real lx)" and "0 < real lx" and "0 < x" using lb_ln[OF l] x by auto

  from ln_le_cancel_iff[OF `0 < real lx` `0 < x`] `real l \<le> ln (real lx)`
  have "real l \<le> ln x" using x unfolding atLeastAtMost_iff by auto
  moreover
  from ln_le_cancel_iff[OF `0 < x` `0 < real ux`] `ln (real ux) \<le> real u`
  have "ln x \<le> real u" using x unfolding atLeastAtMost_iff by auto
  ultimately show "real l \<le> ln x \<and> ln x \<le> real u" ..
qed

section "Implement floatarith"

subsection "Define syntax and semantics"

datatype floatarith
  = Add floatarith floatarith
  | Minus floatarith
  | Mult floatarith floatarith
  | Inverse floatarith
  | Cos floatarith
  | Arctan floatarith
  | Abs floatarith
  | Max floatarith floatarith
  | Min floatarith floatarith
  | Pi
  | Sqrt floatarith
  | Exp floatarith
  | Ln floatarith
  | Power floatarith nat
  | Atom nat
  | Num float

fun interpret_floatarith :: "floatarith \<Rightarrow> real list \<Rightarrow> real" where
"interpret_floatarith (Add a b) vs   = (interpret_floatarith a vs) + (interpret_floatarith b vs)" |
"interpret_floatarith (Minus a) vs    = - (interpret_floatarith a vs)" |
"interpret_floatarith (Mult a b) vs   = (interpret_floatarith a vs) * (interpret_floatarith b vs)" |
"interpret_floatarith (Inverse a) vs  = inverse (interpret_floatarith a vs)" |
"interpret_floatarith (Cos a) vs      = cos (interpret_floatarith a vs)" |
"interpret_floatarith (Arctan a) vs   = arctan (interpret_floatarith a vs)" |
"interpret_floatarith (Min a b) vs    = min (interpret_floatarith a vs) (interpret_floatarith b vs)" |
"interpret_floatarith (Max a b) vs    = max (interpret_floatarith a vs) (interpret_floatarith b vs)" |
"interpret_floatarith (Abs a) vs      = abs (interpret_floatarith a vs)" |
"interpret_floatarith Pi vs           = pi" |
"interpret_floatarith (Sqrt a) vs     = sqrt (interpret_floatarith a vs)" |
"interpret_floatarith (Exp a) vs      = exp (interpret_floatarith a vs)" |
"interpret_floatarith (Ln a) vs       = ln (interpret_floatarith a vs)" |
"interpret_floatarith (Power a n) vs  = (interpret_floatarith a vs)^n" |
"interpret_floatarith (Num f) vs      = real f" |
"interpret_floatarith (Atom n) vs     = vs ! n"

lemma interpret_floatarith_divide: "interpret_floatarith (Mult a (Inverse b)) vs = (interpret_floatarith a vs) / (interpret_floatarith b vs)"
  unfolding real_divide_def interpret_floatarith.simps ..

lemma interpret_floatarith_diff: "interpret_floatarith (Add a (Minus b)) vs = (interpret_floatarith a vs) - (interpret_floatarith b vs)"
  unfolding real_diff_def interpret_floatarith.simps ..

lemma interpret_floatarith_sin: "interpret_floatarith (Cos (Add (Mult Pi (Num (Float 1 -1))) (Minus a))) vs =
  sin (interpret_floatarith a vs)"
  unfolding sin_cos_eq interpret_floatarith.simps
            interpret_floatarith_divide interpret_floatarith_diff real_diff_def
  by auto

lemma interpret_floatarith_tan:
  "interpret_floatarith (Mult (Cos (Add (Mult Pi (Num (Float 1 -1))) (Minus a))) (Inverse (Cos a))) vs =
   tan (interpret_floatarith a vs)"
  unfolding interpret_floatarith.simps(3,4) interpret_floatarith_sin tan_def real_divide_def
  by auto

lemma interpret_floatarith_powr: "interpret_floatarith (Exp (Mult b (Ln a))) vs = (interpret_floatarith a vs) powr (interpret_floatarith b vs)"
  unfolding powr_def interpret_floatarith.simps ..

lemma interpret_floatarith_log: "interpret_floatarith ((Mult (Ln x) (Inverse (Ln b)))) vs = log (interpret_floatarith b vs) (interpret_floatarith x vs)"
  unfolding log_def interpret_floatarith.simps real_divide_def ..

lemma interpret_floatarith_num:
  shows "interpret_floatarith (Num (Float 0 0)) vs = 0"
  and "interpret_floatarith (Num (Float 1 0)) vs = 1"
  and "interpret_floatarith (Num (Float (number_of a) 0)) vs = number_of a" by auto

subsection "Implement approximation function"

fun lift_bin' :: "(float * float) option \<Rightarrow> (float * float) option \<Rightarrow> (float \<Rightarrow> float \<Rightarrow> float \<Rightarrow> float \<Rightarrow> (float * float)) \<Rightarrow> (float * float) option" where
"lift_bin' (Some (l1, u1)) (Some (l2, u2)) f = Some (f l1 u1 l2 u2)" |
"lift_bin' a b f = None"

fun lift_un :: "(float * float) option \<Rightarrow> (float \<Rightarrow> float \<Rightarrow> ((float option) * (float option))) \<Rightarrow> (float * float) option" where
"lift_un (Some (l1, u1)) f = (case (f l1 u1) of (Some l, Some u) \<Rightarrow> Some (l, u)
                                             | t \<Rightarrow> None)" |
"lift_un b f = None"

fun lift_un' :: "(float * float) option \<Rightarrow> (float \<Rightarrow> float \<Rightarrow> (float * float)) \<Rightarrow> (float * float) option" where
"lift_un' (Some (l1, u1)) f = Some (f l1 u1)" |
"lift_un' b f = None"

definition
"bounded_by xs vs \<longleftrightarrow>
  (\<forall> i < length vs. case vs ! i of None \<Rightarrow> True
         | Some (l, u) \<Rightarrow> xs ! i \<in> { real l .. real u })"

lemma bounded_byE:
  assumes "bounded_by xs vs"
  shows "\<And> i. i < length vs \<Longrightarrow> case vs ! i of None \<Rightarrow> True
         | Some (l, u) \<Rightarrow> xs ! i \<in> { real l .. real u }"
  using assms bounded_by_def by blast

lemma bounded_by_update:
  assumes "bounded_by xs vs"
  and bnd: "xs ! i \<in> { real l .. real u }"
  shows "bounded_by xs (vs[i := Some (l,u)])"
proof -
{ fix j
  let ?vs = "vs[i := Some (l,u)]"
  assume "j < length ?vs" hence [simp]: "j < length vs" by simp
  have "case ?vs ! j of None \<Rightarrow> True | Some (l, u) \<Rightarrow> xs ! j \<in> { real l .. real u }"
  proof (cases "?vs ! j")
    case (Some b)
    thus ?thesis
    proof (cases "i = j")
      case True
      thus ?thesis using `?vs ! j = Some b` and bnd by auto
    next
      case False
      thus ?thesis using `bounded_by xs vs` unfolding bounded_by_def by auto
    qed
  qed auto }
  thus ?thesis unfolding bounded_by_def by auto
qed

lemma bounded_by_None:
  shows "bounded_by xs (replicate (length xs) None)"
  unfolding bounded_by_def by auto

fun approx approx' :: "nat \<Rightarrow> floatarith \<Rightarrow> (float * float) option list \<Rightarrow> (float * float) option" where
"approx' prec a bs          = (case (approx prec a bs) of Some (l, u) \<Rightarrow> Some (round_down prec l, round_up prec u) | None \<Rightarrow> None)" |
"approx prec (Add a b) bs   = lift_bin' (approx' prec a bs) (approx' prec b bs) (\<lambda> l1 u1 l2 u2. (l1 + l2, u1 + u2))" |
"approx prec (Minus a) bs   = lift_un' (approx' prec a bs) (\<lambda> l u. (-u, -l))" |
"approx prec (Mult a b) bs  = lift_bin' (approx' prec a bs) (approx' prec b bs)
                                    (\<lambda> a1 a2 b1 b2. (float_nprt a1 * float_pprt b2 + float_nprt a2 * float_nprt b2 + float_pprt a1 * float_pprt b1 + float_pprt a2 * float_nprt b1,
                                                     float_pprt a2 * float_pprt b2 + float_pprt a1 * float_nprt b2 + float_nprt a2 * float_pprt b1 + float_nprt a1 * float_nprt b1))" |
"approx prec (Inverse a) bs = lift_un (approx' prec a bs) (\<lambda> l u. if (0 < l \<or> u < 0) then (Some (float_divl prec 1 u), Some (float_divr prec 1 l)) else (None, None))" |
"approx prec (Cos a) bs     = lift_un' (approx' prec a bs) (bnds_cos prec)" |
"approx prec Pi bs          = Some (lb_pi prec, ub_pi prec)" |
"approx prec (Min a b) bs   = lift_bin' (approx' prec a bs) (approx' prec b bs) (\<lambda> l1 u1 l2 u2. (min l1 l2, min u1 u2))" |
"approx prec (Max a b) bs   = lift_bin' (approx' prec a bs) (approx' prec b bs) (\<lambda> l1 u1 l2 u2. (max l1 l2, max u1 u2))" |
"approx prec (Abs a) bs     = lift_un' (approx' prec a bs) (\<lambda>l u. (if l < 0 \<and> 0 < u then 0 else min \<bar>l\<bar> \<bar>u\<bar>, max \<bar>l\<bar> \<bar>u\<bar>))" |
"approx prec (Arctan a) bs  = lift_un' (approx' prec a bs) (\<lambda> l u. (lb_arctan prec l, ub_arctan prec u))" |
"approx prec (Sqrt a) bs    = lift_un' (approx' prec a bs) (\<lambda> l u. (lb_sqrt prec l, ub_sqrt prec u))" |
"approx prec (Exp a) bs     = lift_un' (approx' prec a bs) (\<lambda> l u. (lb_exp prec l, ub_exp prec u))" |
"approx prec (Ln a) bs      = lift_un (approx' prec a bs) (\<lambda> l u. (lb_ln prec l, ub_ln prec u))" |
"approx prec (Power a n) bs = lift_un' (approx' prec a bs) (float_power_bnds n)" |
"approx prec (Num f) bs     = Some (f, f)" |
"approx prec (Atom i) bs    = (if i < length bs then bs ! i else None)"

lemma lift_bin'_ex:
  assumes lift_bin'_Some: "Some (l, u) = lift_bin' a b f"
  shows "\<exists> l1 u1 l2 u2. Some (l1, u1) = a \<and> Some (l2, u2) = b"
proof (cases a)
  case None hence "None = lift_bin' a b f" unfolding None lift_bin'.simps ..
  thus ?thesis using lift_bin'_Some by auto
next
  case (Some a')
  show ?thesis
  proof (cases b)
    case None hence "None = lift_bin' a b f" unfolding None lift_bin'.simps ..
    thus ?thesis using lift_bin'_Some by auto
  next
    case (Some b')
    obtain la ua where a': "a' = (la, ua)" by (cases a', auto)
    obtain lb ub where b': "b' = (lb, ub)" by (cases b', auto)
    thus ?thesis unfolding `a = Some a'` `b = Some b'` a' b' by auto
  qed
qed

lemma lift_bin'_f:
  assumes lift_bin'_Some: "Some (l, u) = lift_bin' (g a) (g b) f"
  and Pa: "\<And>l u. Some (l, u) = g a \<Longrightarrow> P l u a" and Pb: "\<And>l u. Some (l, u) = g b \<Longrightarrow> P l u b"
  shows "\<exists> l1 u1 l2 u2. P l1 u1 a \<and> P l2 u2 b \<and> l = fst (f l1 u1 l2 u2) \<and> u = snd (f l1 u1 l2 u2)"
proof -
  obtain l1 u1 l2 u2
    where Sa: "Some (l1, u1) = g a" and Sb: "Some (l2, u2) = g b" using lift_bin'_ex[OF assms(1)] by auto
  have lu: "(l, u) = f l1 u1 l2 u2" using lift_bin'_Some[unfolded Sa[symmetric] Sb[symmetric] lift_bin'.simps] by auto
  have "l = fst (f l1 u1 l2 u2)" and "u = snd (f l1 u1 l2 u2)" unfolding lu[symmetric] by auto
  thus ?thesis using Pa[OF Sa] Pb[OF Sb] by auto
qed

lemma approx_approx':
  assumes Pa: "\<And>l u. Some (l, u) = approx prec a vs \<Longrightarrow> real l \<le> interpret_floatarith a xs \<and> interpret_floatarith a xs \<le> real u"
  and approx': "Some (l, u) = approx' prec a vs"
  shows "real l \<le> interpret_floatarith a xs \<and> interpret_floatarith a xs \<le> real u"
proof -
  obtain l' u' where S: "Some (l', u') = approx prec a vs"
    using approx' unfolding approx'.simps by (cases "approx prec a vs", auto)
  have l': "l = round_down prec l'" and u': "u = round_up prec u'"
    using approx' unfolding approx'.simps S[symmetric] by auto
  show ?thesis unfolding l' u'
    using order_trans[OF Pa[OF S, THEN conjunct2] round_up[of u']]
    using order_trans[OF round_down[of _ l'] Pa[OF S, THEN conjunct1]] by auto
qed

lemma lift_bin':
  assumes lift_bin'_Some: "Some (l, u) = lift_bin' (approx' prec a bs) (approx' prec b bs) f"
  and Pa: "\<And>l u. Some (l, u) = approx prec a bs \<Longrightarrow> real l \<le> interpret_floatarith a xs \<and> interpret_floatarith a xs \<le> real u" (is "\<And>l u. _ = ?g a \<Longrightarrow> ?P l u a")
  and Pb: "\<And>l u. Some (l, u) = approx prec b bs \<Longrightarrow> real l \<le> interpret_floatarith b xs \<and> interpret_floatarith b xs \<le> real u"
  shows "\<exists> l1 u1 l2 u2. (real l1 \<le> interpret_floatarith a xs \<and> interpret_floatarith a xs \<le> real u1) \<and>
                        (real l2 \<le> interpret_floatarith b xs \<and> interpret_floatarith b xs \<le> real u2) \<and>
                        l = fst (f l1 u1 l2 u2) \<and> u = snd (f l1 u1 l2 u2)"
proof -
  { fix l u assume "Some (l, u) = approx' prec a bs"
    with approx_approx'[of prec a bs, OF _ this] Pa
    have "real l \<le> interpret_floatarith a xs \<and> interpret_floatarith a xs \<le> real u" by auto } note Pa = this
  { fix l u assume "Some (l, u) = approx' prec b bs"
    with approx_approx'[of prec b bs, OF _ this] Pb
    have "real l \<le> interpret_floatarith b xs \<and> interpret_floatarith b xs \<le> real u" by auto } note Pb = this

  from lift_bin'_f[where g="\<lambda>a. approx' prec a bs" and P = ?P, OF lift_bin'_Some, OF Pa Pb]
  show ?thesis by auto
qed

lemma lift_un'_ex:
  assumes lift_un'_Some: "Some (l, u) = lift_un' a f"
  shows "\<exists> l u. Some (l, u) = a"
proof (cases a)
  case None hence "None = lift_un' a f" unfolding None lift_un'.simps ..
  thus ?thesis using lift_un'_Some by auto
next
  case (Some a')
  obtain la ua where a': "a' = (la, ua)" by (cases a', auto)
  thus ?thesis unfolding `a = Some a'` a' by auto
qed

lemma lift_un'_f:
  assumes lift_un'_Some: "Some (l, u) = lift_un' (g a) f"
  and Pa: "\<And>l u. Some (l, u) = g a \<Longrightarrow> P l u a"
  shows "\<exists> l1 u1. P l1 u1 a \<and> l = fst (f l1 u1) \<and> u = snd (f l1 u1)"
proof -
  obtain l1 u1 where Sa: "Some (l1, u1) = g a" using lift_un'_ex[OF assms(1)] by auto
  have lu: "(l, u) = f l1 u1" using lift_un'_Some[unfolded Sa[symmetric] lift_un'.simps] by auto
  have "l = fst (f l1 u1)" and "u = snd (f l1 u1)" unfolding lu[symmetric] by auto
  thus ?thesis using Pa[OF Sa] by auto
qed

lemma lift_un':
  assumes lift_un'_Some: "Some (l, u) = lift_un' (approx' prec a bs) f"
  and Pa: "\<And>l u. Some (l, u) = approx prec a bs \<Longrightarrow> real l \<le> interpret_floatarith a xs \<and> interpret_floatarith a xs \<le> real u" (is "\<And>l u. _ = ?g a \<Longrightarrow> ?P l u a")
  shows "\<exists> l1 u1. (real l1 \<le> interpret_floatarith a xs \<and> interpret_floatarith a xs \<le> real u1) \<and>
                        l = fst (f l1 u1) \<and> u = snd (f l1 u1)"
proof -
  { fix l u assume "Some (l, u) = approx' prec a bs"
    with approx_approx'[of prec a bs, OF _ this] Pa
    have "real l \<le> interpret_floatarith a xs \<and> interpret_floatarith a xs \<le> real u" by auto } note Pa = this
  from lift_un'_f[where g="\<lambda>a. approx' prec a bs" and P = ?P, OF lift_un'_Some, OF Pa]
  show ?thesis by auto
qed

lemma lift_un'_bnds:
  assumes bnds: "\<forall> x lx ux. (l, u) = f lx ux \<and> x \<in> { real lx .. real ux } \<longrightarrow> real l \<le> f' x \<and> f' x \<le> real u"
  and lift_un'_Some: "Some (l, u) = lift_un' (approx' prec a bs) f"
  and Pa: "\<And>l u. Some (l, u) = approx prec a bs \<Longrightarrow> real l \<le> interpret_floatarith a xs \<and> interpret_floatarith a xs \<le> real u"
  shows "real l \<le> f' (interpret_floatarith a xs) \<and> f' (interpret_floatarith a xs) \<le> real u"
proof -
  from lift_un'[OF lift_un'_Some Pa]
  obtain l1 u1 where "real l1 \<le> interpret_floatarith a xs" and "interpret_floatarith a xs \<le> real u1" and "l = fst (f l1 u1)" and "u = snd (f l1 u1)" by blast
  hence "(l, u) = f l1 u1" and "interpret_floatarith a xs \<in> {real l1 .. real u1}" by auto
  thus ?thesis using bnds by auto
qed

lemma lift_un_ex:
  assumes lift_un_Some: "Some (l, u) = lift_un a f"
  shows "\<exists> l u. Some (l, u) = a"
proof (cases a)
  case None hence "None = lift_un a f" unfolding None lift_un.simps ..
  thus ?thesis using lift_un_Some by auto
next
  case (Some a')
  obtain la ua where a': "a' = (la, ua)" by (cases a', auto)
  thus ?thesis unfolding `a = Some a'` a' by auto
qed

lemma lift_un_f:
  assumes lift_un_Some: "Some (l, u) = lift_un (g a) f"
  and Pa: "\<And>l u. Some (l, u) = g a \<Longrightarrow> P l u a"
  shows "\<exists> l1 u1. P l1 u1 a \<and> Some l = fst (f l1 u1) \<and> Some u = snd (f l1 u1)"
proof -
  obtain l1 u1 where Sa: "Some (l1, u1) = g a" using lift_un_ex[OF assms(1)] by auto
  have "fst (f l1 u1) \<noteq> None \<and> snd (f l1 u1) \<noteq> None"
  proof (rule ccontr)
    assume "\<not> (fst (f l1 u1) \<noteq> None \<and> snd (f l1 u1) \<noteq> None)"
    hence or: "fst (f l1 u1) = None \<or> snd (f l1 u1) = None" by auto
    hence "lift_un (g a) f = None"
    proof (cases "fst (f l1 u1) = None")
      case True
      then obtain b where b: "f l1 u1 = (None, b)" by (cases "f l1 u1", auto)
      thus ?thesis unfolding Sa[symmetric] lift_un.simps b by auto
    next
      case False hence "snd (f l1 u1) = None" using or by auto
      with False obtain b where b: "f l1 u1 = (Some b, None)" by (cases "f l1 u1", auto)
      thus ?thesis unfolding Sa[symmetric] lift_un.simps b by auto
    qed
    thus False using lift_un_Some by auto
  qed
  then obtain a' b' where f: "f l1 u1 = (Some a', Some b')" by (cases "f l1 u1", auto)
  from lift_un_Some[unfolded Sa[symmetric] lift_un.simps f]
  have "Some l = fst (f l1 u1)" and "Some u = snd (f l1 u1)" unfolding f by auto
  thus ?thesis unfolding Sa[symmetric] lift_un.simps using Pa[OF Sa] by auto
qed

lemma lift_un:
  assumes lift_un_Some: "Some (l, u) = lift_un (approx' prec a bs) f"
  and Pa: "\<And>l u. Some (l, u) = approx prec a bs \<Longrightarrow> real l \<le> interpret_floatarith a xs \<and> interpret_floatarith a xs \<le> real u" (is "\<And>l u. _ = ?g a \<Longrightarrow> ?P l u a")
  shows "\<exists> l1 u1. (real l1 \<le> interpret_floatarith a xs \<and> interpret_floatarith a xs \<le> real u1) \<and>
                  Some l = fst (f l1 u1) \<and> Some u = snd (f l1 u1)"
proof -
  { fix l u assume "Some (l, u) = approx' prec a bs"
    with approx_approx'[of prec a bs, OF _ this] Pa
    have "real l \<le> interpret_floatarith a xs \<and> interpret_floatarith a xs \<le> real u" by auto } note Pa = this
  from lift_un_f[where g="\<lambda>a. approx' prec a bs" and P = ?P, OF lift_un_Some, OF Pa]
  show ?thesis by auto
qed

lemma lift_un_bnds:
  assumes bnds: "\<forall> x lx ux. (Some l, Some u) = f lx ux \<and> x \<in> { real lx .. real ux } \<longrightarrow> real l \<le> f' x \<and> f' x \<le> real u"
  and lift_un_Some: "Some (l, u) = lift_un (approx' prec a bs) f"
  and Pa: "\<And>l u. Some (l, u) = approx prec a bs \<Longrightarrow> real l \<le> interpret_floatarith a xs \<and> interpret_floatarith a xs \<le> real u"
  shows "real l \<le> f' (interpret_floatarith a xs) \<and> f' (interpret_floatarith a xs) \<le> real u"
proof -
  from lift_un[OF lift_un_Some Pa]
  obtain l1 u1 where "real l1 \<le> interpret_floatarith a xs" and "interpret_floatarith a xs \<le> real u1" and "Some l = fst (f l1 u1)" and "Some u = snd (f l1 u1)" by blast
  hence "(Some l, Some u) = f l1 u1" and "interpret_floatarith a xs \<in> {real l1 .. real u1}" by auto
  thus ?thesis using bnds by auto
qed

lemma approx:
  assumes "bounded_by xs vs"
  and "Some (l, u) = approx prec arith vs" (is "_ = ?g arith")
  shows "real l \<le> interpret_floatarith arith xs \<and> interpret_floatarith arith xs \<le> real u" (is "?P l u arith")
  using `Some (l, u) = approx prec arith vs`
proof (induct arith arbitrary: l u x)
  case (Add a b)
  from lift_bin'[OF Add.prems[unfolded approx.simps]] Add.hyps
  obtain l1 u1 l2 u2 where "l = l1 + l2" and "u = u1 + u2"
    "real l1 \<le> interpret_floatarith a xs" and "interpret_floatarith a xs \<le> real u1"
    "real l2 \<le> interpret_floatarith b xs" and "interpret_floatarith b xs \<le> real u2" unfolding fst_conv snd_conv by blast
  thus ?case unfolding interpret_floatarith.simps by auto
next
  case (Minus a)
  from lift_un'[OF Minus.prems[unfolded approx.simps]] Minus.hyps
  obtain l1 u1 where "l = -u1" and "u = -l1"
    "real l1 \<le> interpret_floatarith a xs" and "interpret_floatarith a xs \<le> real u1" unfolding fst_conv snd_conv by blast
  thus ?case unfolding interpret_floatarith.simps using real_of_float_minus by auto
next
  case (Mult a b)
  from lift_bin'[OF Mult.prems[unfolded approx.simps]] Mult.hyps
  obtain l1 u1 l2 u2
    where l: "l = float_nprt l1 * float_pprt u2 + float_nprt u1 * float_nprt u2 + float_pprt l1 * float_pprt l2 + float_pprt u1 * float_nprt l2"
    and u: "u = float_pprt u1 * float_pprt u2 + float_pprt l1 * float_nprt u2 + float_nprt u1 * float_pprt l2 + float_nprt l1 * float_nprt l2"
    and "real l1 \<le> interpret_floatarith a xs" and "interpret_floatarith a xs \<le> real u1"
    and "real l2 \<le> interpret_floatarith b xs" and "interpret_floatarith b xs \<le> real u2" unfolding fst_conv snd_conv by blast
  thus ?case unfolding interpret_floatarith.simps l u real_of_float_add real_of_float_mult real_of_float_nprt real_of_float_pprt
    using mult_le_prts mult_ge_prts by auto
next
  case (Inverse a)
  from lift_un[OF Inverse.prems[unfolded approx.simps], unfolded if_distrib[of fst] if_distrib[of snd] fst_conv snd_conv] Inverse.hyps
  obtain l1 u1 where l': "Some l = (if 0 < l1 \<or> u1 < 0 then Some (float_divl prec 1 u1) else None)"
    and u': "Some u = (if 0 < l1 \<or> u1 < 0 then Some (float_divr prec 1 l1) else None)"
    and l1: "real l1 \<le> interpret_floatarith a xs" and u1: "interpret_floatarith a xs \<le> real u1" by blast
  have either: "0 < l1 \<or> u1 < 0" proof (rule ccontr) assume P: "\<not> (0 < l1 \<or> u1 < 0)" show False using l' unfolding if_not_P[OF P] by auto qed
  moreover have l1_le_u1: "real l1 \<le> real u1" using l1 u1 by auto
  ultimately have "real l1 \<noteq> 0" and "real u1 \<noteq> 0" unfolding less_float_def by auto

  have inv: "inverse (real u1) \<le> inverse (interpret_floatarith a xs)
           \<and> inverse (interpret_floatarith a xs) \<le> inverse (real l1)"
  proof (cases "0 < l1")
    case True hence "0 < real u1" and "0 < real l1" "0 < interpret_floatarith a xs"
      unfolding less_float_def using l1_le_u1 l1 by auto
    show ?thesis
      unfolding inverse_le_iff_le[OF `0 < real u1` `0 < interpret_floatarith a xs`]
	inverse_le_iff_le[OF `0 < interpret_floatarith a xs` `0 < real l1`]
      using l1 u1 by auto
  next
    case False hence "u1 < 0" using either by blast
    hence "real u1 < 0" and "real l1 < 0" "interpret_floatarith a xs < 0"
      unfolding less_float_def using l1_le_u1 u1 by auto
    show ?thesis
      unfolding inverse_le_iff_le_neg[OF `real u1 < 0` `interpret_floatarith a xs < 0`]
	inverse_le_iff_le_neg[OF `interpret_floatarith a xs < 0` `real l1 < 0`]
      using l1 u1 by auto
  qed

  from l' have "l = float_divl prec 1 u1" by (cases "0 < l1 \<or> u1 < 0", auto)
  hence "real l \<le> inverse (real u1)" unfolding nonzero_inverse_eq_divide[OF `real u1 \<noteq> 0`] using float_divl[of prec 1 u1] by auto
  also have "\<dots> \<le> inverse (interpret_floatarith a xs)" using inv by auto
  finally have "real l \<le> inverse (interpret_floatarith a xs)" .
  moreover
  from u' have "u = float_divr prec 1 l1" by (cases "0 < l1 \<or> u1 < 0", auto)
  hence "inverse (real l1) \<le> real u" unfolding nonzero_inverse_eq_divide[OF `real l1 \<noteq> 0`] using float_divr[of 1 l1 prec] by auto
  hence "inverse (interpret_floatarith a xs) \<le> real u" by (rule order_trans[OF inv[THEN conjunct2]])
  ultimately show ?case unfolding interpret_floatarith.simps using l1 u1 by auto
next
  case (Abs x)
  from lift_un'[OF Abs.prems[unfolded approx.simps], unfolded fst_conv snd_conv] Abs.hyps
  obtain l1 u1 where l': "l = (if l1 < 0 \<and> 0 < u1 then 0 else min \<bar>l1\<bar> \<bar>u1\<bar>)" and u': "u = max \<bar>l1\<bar> \<bar>u1\<bar>"
    and l1: "real l1 \<le> interpret_floatarith x xs" and u1: "interpret_floatarith x xs \<le> real u1" by blast
  thus ?case unfolding l' u' by (cases "l1 < 0 \<and> 0 < u1", auto simp add: real_of_float_min real_of_float_max real_of_float_abs less_float_def)
next
  case (Min a b)
  from lift_bin'[OF Min.prems[unfolded approx.simps], unfolded fst_conv snd_conv] Min.hyps
  obtain l1 u1 l2 u2 where l': "l = min l1 l2" and u': "u = min u1 u2"
    and l1: "real l1 \<le> interpret_floatarith a xs" and u1: "interpret_floatarith a xs \<le> real u1"
    and l1: "real l2 \<le> interpret_floatarith b xs" and u1: "interpret_floatarith b xs \<le> real u2" by blast
  thus ?case unfolding l' u' by (auto simp add: real_of_float_min)
next
  case (Max a b)
  from lift_bin'[OF Max.prems[unfolded approx.simps], unfolded fst_conv snd_conv] Max.hyps
  obtain l1 u1 l2 u2 where l': "l = max l1 l2" and u': "u = max u1 u2"
    and l1: "real l1 \<le> interpret_floatarith a xs" and u1: "interpret_floatarith a xs \<le> real u1"
    and l1: "real l2 \<le> interpret_floatarith b xs" and u1: "interpret_floatarith b xs \<le> real u2" by blast
  thus ?case unfolding l' u' by (auto simp add: real_of_float_max)
next case (Cos a) with lift_un'_bnds[OF bnds_cos] show ?case by auto
next case (Arctan a) with lift_un'_bnds[OF bnds_arctan] show ?case by auto
next case Pi with pi_boundaries show ?case by auto
next case (Sqrt a) with lift_un'_bnds[OF bnds_sqrt] show ?case by auto
next case (Exp a) with lift_un'_bnds[OF bnds_exp] show ?case by auto
next case (Ln a) with lift_un_bnds[OF bnds_ln] show ?case by auto
next case (Power a n) with lift_un'_bnds[OF bnds_power] show ?case by auto
next case (Num f) thus ?case by auto
next
  case (Atom n)
  from this[symmetric] `bounded_by xs vs`[THEN bounded_byE, of n]
  show ?case by (cases "n < length vs", auto)
qed

datatype form = Bound floatarith floatarith floatarith form
              | Assign floatarith floatarith form
              | Less floatarith floatarith
              | LessEqual floatarith floatarith
              | AtLeastAtMost floatarith floatarith floatarith

fun interpret_form :: "form \<Rightarrow> real list \<Rightarrow> bool" where
"interpret_form (Bound x a b f) vs = (interpret_floatarith x vs \<in> { interpret_floatarith a vs .. interpret_floatarith b vs } \<longrightarrow> interpret_form f vs)" |
"interpret_form (Assign x a f) vs  = (interpret_floatarith x vs = interpret_floatarith a vs \<longrightarrow> interpret_form f vs)" |
"interpret_form (Less a b) vs      = (interpret_floatarith a vs < interpret_floatarith b vs)" |
"interpret_form (LessEqual a b) vs = (interpret_floatarith a vs \<le> interpret_floatarith b vs)" |
"interpret_form (AtLeastAtMost x a b) vs = (interpret_floatarith x vs \<in> { interpret_floatarith a vs .. interpret_floatarith b vs })"

fun approx_form' and approx_form :: "nat \<Rightarrow> form \<Rightarrow> (float * float) option list \<Rightarrow> nat list \<Rightarrow> bool" where
"approx_form' prec f 0 n l u bs ss = approx_form prec f (bs[n := Some (l, u)]) ss" |
"approx_form' prec f (Suc s) n l u bs ss =
  (let m = (l + u) * Float 1 -1
   in approx_form' prec f s n l m bs ss \<and>
      approx_form' prec f s n m u bs ss)" |
"approx_form prec (Bound (Atom n) a b f) bs ss =
   (case (approx prec a bs, approx prec b bs)
   of (Some (l, _), Some (_, u)) \<Rightarrow> approx_form' prec f (ss ! n) n l u bs ss
    | _ \<Rightarrow> False)" |
"approx_form prec (Assign (Atom n) a f) bs ss =
   (case (approx prec a bs)
   of (Some (l, u)) \<Rightarrow> approx_form' prec f (ss ! n) n l u bs ss
    | _ \<Rightarrow> False)" |
"approx_form prec (Less a b) bs ss =
   (case (approx prec a bs, approx prec b bs)
   of (Some (l, u), Some (l', u')) \<Rightarrow> u < l'
    | _ \<Rightarrow> False)" |
"approx_form prec (LessEqual a b) bs ss =
   (case (approx prec a bs, approx prec b bs)
   of (Some (l, u), Some (l', u')) \<Rightarrow> u \<le> l'
    | _ \<Rightarrow> False)" |
"approx_form prec (AtLeastAtMost x a b) bs ss =
   (case (approx prec x bs, approx prec a bs, approx prec b bs)
   of (Some (lx, ux), Some (l, u), Some (l', u')) \<Rightarrow> u \<le> lx \<and> ux \<le> l'
    | _ \<Rightarrow> False)" |
"approx_form _ _ _ _ = False"

lemma approx_form_approx_form':
  assumes "approx_form' prec f s n l u bs ss" and "x \<in> { real l .. real u }"
  obtains l' u' where "x \<in> { real l' .. real u' }"
  and "approx_form prec f (bs[n := Some (l', u')]) ss"
using assms proof (induct s arbitrary: l u)
  case 0
  from this(1)[of l u] this(2,3)
  show thesis by auto
next
  case (Suc s)

  let ?m = "(l + u) * Float 1 -1"
  have "real l \<le> real ?m" and "real ?m \<le> real u"
    unfolding le_float_def using Suc.prems by auto

  with `x \<in> { real l .. real u }`
  have "x \<in> { real l .. real ?m} \<or> x \<in> { real ?m .. real u }" by auto
  thus thesis
  proof (rule disjE)
    assume *: "x \<in> { real l .. real ?m }"
    with Suc.hyps[OF _ _ *] Suc.prems
    show thesis by (simp add: Let_def)
  next
    assume *: "x \<in> { real ?m .. real u }"
    with Suc.hyps[OF _ _ *] Suc.prems
    show thesis by (simp add: Let_def)
  qed
qed

lemma approx_form_aux:
  assumes "approx_form prec f vs ss"
  and "bounded_by xs vs"
  shows "interpret_form f xs"
using assms proof (induct f arbitrary: vs)
  case (Bound x a b f)
  then obtain n
    where x_eq: "x = Atom n" by (cases x) auto

  with Bound.prems obtain l u' l' u
    where l_eq: "Some (l, u') = approx prec a vs"
    and u_eq: "Some (l', u) = approx prec b vs"
    and approx_form': "approx_form' prec f (ss ! n) n l u vs ss"
    by (cases "approx prec a vs", simp,
        cases "approx prec b vs", auto) blast

  { assume "xs ! n \<in> { interpret_floatarith a xs .. interpret_floatarith b xs }"
    with approx[OF Bound.prems(2) l_eq] and approx[OF Bound.prems(2) u_eq]
    have "xs ! n \<in> { real l .. real u}" by auto

    from approx_form_approx_form'[OF approx_form' this]
    obtain lx ux where bnds: "xs ! n \<in> { real lx .. real ux }"
      and approx_form: "approx_form prec f (vs[n := Some (lx, ux)]) ss" .

    from `bounded_by xs vs` bnds
    have "bounded_by xs (vs[n := Some (lx, ux)])" by (rule bounded_by_update)
    with Bound.hyps[OF approx_form]
    have "interpret_form f xs" by blast }
  thus ?case using interpret_form.simps x_eq and interpret_floatarith.simps by simp
next
  case (Assign x a f)
  then obtain n
    where x_eq: "x = Atom n" by (cases x) auto

  with Assign.prems obtain l u' l' u
    where bnd_eq: "Some (l, u) = approx prec a vs"
    and x_eq: "x = Atom n"
    and approx_form': "approx_form' prec f (ss ! n) n l u vs ss"
    by (cases "approx prec a vs") auto

  { assume bnds: "xs ! n = interpret_floatarith a xs"
    with approx[OF Assign.prems(2) bnd_eq]
    have "xs ! n \<in> { real l .. real u}" by auto
    from approx_form_approx_form'[OF approx_form' this]
    obtain lx ux where bnds: "xs ! n \<in> { real lx .. real ux }"
      and approx_form: "approx_form prec f (vs[n := Some (lx, ux)]) ss" .

    from `bounded_by xs vs` bnds
    have "bounded_by xs (vs[n := Some (lx, ux)])" by (rule bounded_by_update)
    with Assign.hyps[OF approx_form]
    have "interpret_form f xs" by blast }
  thus ?case using interpret_form.simps x_eq and interpret_floatarith.simps by simp
next
  case (Less a b)
  then obtain l u l' u'
    where l_eq: "Some (l, u) = approx prec a vs"
    and u_eq: "Some (l', u') = approx prec b vs"
    and inequality: "u < l'"
    by (cases "approx prec a vs", auto,
      cases "approx prec b vs", auto)
  from inequality[unfolded less_float_def] approx[OF Less.prems(2) l_eq] approx[OF Less.prems(2) u_eq]
  show ?case by auto
next
  case (LessEqual a b)
  then obtain l u l' u'
    where l_eq: "Some (l, u) = approx prec a vs"
    and u_eq: "Some (l', u') = approx prec b vs"
    and inequality: "u \<le> l'"
    by (cases "approx prec a vs", auto,
      cases "approx prec b vs", auto)
  from inequality[unfolded le_float_def] approx[OF LessEqual.prems(2) l_eq] approx[OF LessEqual.prems(2) u_eq]
  show ?case by auto
next
  case (AtLeastAtMost x a b)
  then obtain lx ux l u l' u'
    where x_eq: "Some (lx, ux) = approx prec x vs"
    and l_eq: "Some (l, u) = approx prec a vs"
    and u_eq: "Some (l', u') = approx prec b vs"
    and inequality: "u \<le> lx \<and> ux \<le> l'"
    by (cases "approx prec x vs", auto,
      cases "approx prec a vs", auto,
      cases "approx prec b vs", auto, blast)
  from inequality[unfolded le_float_def] approx[OF AtLeastAtMost.prems(2) l_eq] approx[OF AtLeastAtMost.prems(2) u_eq] approx[OF AtLeastAtMost.prems(2) x_eq]
  show ?case by auto
qed

lemma approx_form:
  assumes "n = length xs"
  assumes "approx_form prec f (replicate n None) ss"
  shows "interpret_form f xs"
  using approx_form_aux[OF _ bounded_by_None] assms by auto

subsection {* Implementing Taylor series expansion *}

fun isDERIV :: "nat \<Rightarrow> floatarith \<Rightarrow> real list \<Rightarrow> bool" where
"isDERIV x (Add a b) vs         = (isDERIV x a vs \<and> isDERIV x b vs)" |
"isDERIV x (Mult a b) vs        = (isDERIV x a vs \<and> isDERIV x b vs)" |
"isDERIV x (Minus a) vs         = isDERIV x a vs" |
"isDERIV x (Inverse a) vs       = (isDERIV x a vs \<and> interpret_floatarith a vs \<noteq> 0)" |
"isDERIV x (Cos a) vs           = isDERIV x a vs" |
"isDERIV x (Arctan a) vs        = isDERIV x a vs" |
"isDERIV x (Min a b) vs         = False" |
"isDERIV x (Max a b) vs         = False" |
"isDERIV x (Abs a) vs           = False" |
"isDERIV x Pi vs                = True" |
"isDERIV x (Sqrt a) vs          = (isDERIV x a vs \<and> interpret_floatarith a vs > 0)" |
"isDERIV x (Exp a) vs           = isDERIV x a vs" |
"isDERIV x (Ln a) vs            = (isDERIV x a vs \<and> interpret_floatarith a vs > 0)" |
"isDERIV x (Power a 0) vs       = True" |
"isDERIV x (Power a (Suc n)) vs = isDERIV x a vs" |
"isDERIV x (Num f) vs           = True" |
"isDERIV x (Atom n) vs          = True"

fun DERIV_floatarith :: "nat \<Rightarrow> floatarith \<Rightarrow> floatarith" where
"DERIV_floatarith x (Add a b)         = Add (DERIV_floatarith x a) (DERIV_floatarith x b)" |
"DERIV_floatarith x (Mult a b)        = Add (Mult a (DERIV_floatarith x b)) (Mult (DERIV_floatarith x a) b)" |
"DERIV_floatarith x (Minus a)         = Minus (DERIV_floatarith x a)" |
"DERIV_floatarith x (Inverse a)       = Minus (Mult (DERIV_floatarith x a) (Inverse (Power a 2)))" |
"DERIV_floatarith x (Cos a)           = Minus (Mult (Cos (Add (Mult Pi (Num (Float 1 -1))) (Minus a))) (DERIV_floatarith x a))" |
"DERIV_floatarith x (Arctan a)        = Mult (Inverse (Add (Num 1) (Power a 2))) (DERIV_floatarith x a)" |
"DERIV_floatarith x (Min a b)         = Num 0" |
"DERIV_floatarith x (Max a b)         = Num 0" |
"DERIV_floatarith x (Abs a)           = Num 0" |
"DERIV_floatarith x Pi                = Num 0" |
"DERIV_floatarith x (Sqrt a)          = (Mult (Inverse (Mult (Sqrt a) (Num 2))) (DERIV_floatarith x a))" |
"DERIV_floatarith x (Exp a)           = Mult (Exp a) (DERIV_floatarith x a)" |
"DERIV_floatarith x (Ln a)            = Mult (Inverse a) (DERIV_floatarith x a)" |
"DERIV_floatarith x (Power a 0)       = Num 0" |
"DERIV_floatarith x (Power a (Suc n)) = Mult (Num (Float (int (Suc n)) 0)) (Mult (Power a n) (DERIV_floatarith x a))" |
"DERIV_floatarith x (Num f)           = Num 0" |
"DERIV_floatarith x (Atom n)          = (if x = n then Num 1 else Num 0)"

lemma DERIV_floatarith:
  assumes "n < length vs"
  assumes isDERIV: "isDERIV n f (vs[n := x])"
  shows "DERIV (\<lambda> x'. interpret_floatarith f (vs[n := x'])) x :>
               interpret_floatarith (DERIV_floatarith n f) (vs[n := x])"
   (is "DERIV (?i f) x :> _")
using isDERIV proof (induct f arbitrary: x)
     case (Inverse a) thus ?case
    by (auto intro!: DERIV_intros
             simp add: algebra_simps power2_eq_square)
next case (Cos a) thus ?case
  by (auto intro!: DERIV_intros
           simp del: interpret_floatarith.simps(5)
           simp add: interpret_floatarith_sin interpret_floatarith.simps(5)[of a])
next case (Power a n) thus ?case
  by (cases n, auto intro!: DERIV_intros
                    simp del: power_Suc simp add: real_eq_of_nat)
next case (Ln a) thus ?case
    by (auto intro!: DERIV_intros simp add: divide_inverse)
next case (Atom i) thus ?case using `n < length vs` by auto
qed (auto intro!: DERIV_intros)

declare approx.simps[simp del]

fun isDERIV_approx :: "nat \<Rightarrow> nat \<Rightarrow> floatarith \<Rightarrow> (float * float) option list \<Rightarrow> bool" where
"isDERIV_approx prec x (Add a b) vs         = (isDERIV_approx prec x a vs \<and> isDERIV_approx prec x b vs)" |
"isDERIV_approx prec x (Mult a b) vs        = (isDERIV_approx prec x a vs \<and> isDERIV_approx prec x b vs)" |
"isDERIV_approx prec x (Minus a) vs         = isDERIV_approx prec x a vs" |
"isDERIV_approx prec x (Inverse a) vs       =
  (isDERIV_approx prec x a vs \<and> (case approx prec a vs of Some (l, u) \<Rightarrow> 0 < l \<or> u < 0 | None \<Rightarrow> False))" |
"isDERIV_approx prec x (Cos a) vs           = isDERIV_approx prec x a vs" |
"isDERIV_approx prec x (Arctan a) vs        = isDERIV_approx prec x a vs" |
"isDERIV_approx prec x (Min a b) vs         = False" |
"isDERIV_approx prec x (Max a b) vs         = False" |
"isDERIV_approx prec x (Abs a) vs           = False" |
"isDERIV_approx prec x Pi vs                = True" |
"isDERIV_approx prec x (Sqrt a) vs          =
  (isDERIV_approx prec x a vs \<and> (case approx prec a vs of Some (l, u) \<Rightarrow> 0 < l | None \<Rightarrow> False))" |
"isDERIV_approx prec x (Exp a) vs           = isDERIV_approx prec x a vs" |
"isDERIV_approx prec x (Ln a) vs            =
  (isDERIV_approx prec x a vs \<and> (case approx prec a vs of Some (l, u) \<Rightarrow> 0 < l | None \<Rightarrow> False))" |
"isDERIV_approx prec x (Power a 0) vs       = True" |
"isDERIV_approx prec x (Power a (Suc n)) vs = isDERIV_approx prec x a vs" |
"isDERIV_approx prec x (Num f) vs           = True" |
"isDERIV_approx prec x (Atom n) vs          = True"

lemma isDERIV_approx:
  assumes "bounded_by xs vs"
  and isDERIV_approx: "isDERIV_approx prec x f vs"
  shows "isDERIV x f xs"
using isDERIV_approx proof (induct f)
  case (Inverse a)
  then obtain l u where approx_Some: "Some (l, u) = approx prec a vs"
    and *: "0 < l \<or> u < 0"
    by (cases "approx prec a vs", auto)
  with approx[OF `bounded_by xs vs` approx_Some]
  have "interpret_floatarith a xs \<noteq> 0" unfolding less_float_def by auto
  thus ?case using Inverse by auto
next
  case (Ln a)
  then obtain l u where approx_Some: "Some (l, u) = approx prec a vs"
    and *: "0 < l"
    by (cases "approx prec a vs", auto)
  with approx[OF `bounded_by xs vs` approx_Some]
  have "0 < interpret_floatarith a xs" unfolding less_float_def by auto
  thus ?case using Ln by auto
next
  case (Sqrt a)
  then obtain l u where approx_Some: "Some (l, u) = approx prec a vs"
    and *: "0 < l"
    by (cases "approx prec a vs", auto)
  with approx[OF `bounded_by xs vs` approx_Some]
  have "0 < interpret_floatarith a xs" unfolding less_float_def by auto
  thus ?case using Sqrt by auto
next
  case (Power a n) thus ?case by (cases n, auto)
qed auto

lemma bounded_by_update_var:
  assumes "bounded_by xs vs" and "vs ! i = Some (l, u)"
  and bnd: "x \<in> { real l .. real u }"
  shows "bounded_by (xs[i := x]) vs"
proof (cases "i < length xs")
  case False thus ?thesis using `bounded_by xs vs` by auto
next
  let ?xs = "xs[i := x]"
  case True hence "i < length ?xs" by auto
{ fix j
  assume "j < length vs"
  have "case vs ! j of None \<Rightarrow> True | Some (l, u) \<Rightarrow> ?xs ! j \<in> { real l .. real u }"
  proof (cases "vs ! j")
    case (Some b)
    thus ?thesis
    proof (cases "i = j")
      case True
      thus ?thesis using `vs ! i = Some (l, u)` Some and bnd `i < length ?xs`
	by auto
    next
      case False
      thus ?thesis using `bounded_by xs vs`[THEN bounded_byE, OF `j < length vs`] Some
	by auto
    qed
  qed auto }
  thus ?thesis unfolding bounded_by_def by auto
qed

lemma isDERIV_approx':
  assumes "bounded_by xs vs"
  and vs_x: "vs ! x = Some (l, u)" and X_in: "X \<in> { real l .. real u }"
  and approx: "isDERIV_approx prec x f vs"
  shows "isDERIV x f (xs[x := X])"
proof -
  note bounded_by_update_var[OF `bounded_by xs vs` vs_x X_in] approx
  thus ?thesis by (rule isDERIV_approx)
qed

lemma DERIV_approx:
  assumes "n < length xs" and bnd: "bounded_by xs vs"
  and isD: "isDERIV_approx prec n f vs"
  and app: "Some (l, u) = approx prec (DERIV_floatarith n f) vs" (is "_ = approx _ ?D _")
  shows "\<exists>x. real l \<le> x \<and> x \<le> real u \<and>
             DERIV (\<lambda> x. interpret_floatarith f (xs[n := x])) (xs!n) :> x"
         (is "\<exists> x. _ \<and> _ \<and> DERIV (?i f) _ :> _")
proof (rule exI[of _ "?i ?D (xs!n)"], rule conjI[OF _ conjI])
  let "?i f x" = "interpret_floatarith f (xs[n := x])"
  from approx[OF bnd app]
  show "real l \<le> ?i ?D (xs!n)" and "?i ?D (xs!n) \<le> real u"
    using `n < length xs` by auto
  from DERIV_floatarith[OF `n < length xs`, of f "xs!n"] isDERIV_approx[OF bnd isD]
  show "DERIV (?i f) (xs!n) :> (?i ?D (xs!n))" by simp
qed

fun lift_bin :: "(float * float) option \<Rightarrow> (float * float) option \<Rightarrow> (float \<Rightarrow> float \<Rightarrow> float \<Rightarrow> float \<Rightarrow> (float * float) option) \<Rightarrow> (float * float) option" where
"lift_bin (Some (l1, u1)) (Some (l2, u2)) f = f l1 u1 l2 u2" |
"lift_bin a b f = None"

lemma lift_bin:
  assumes lift_bin_Some: "Some (l, u) = lift_bin a b f"
  obtains l1 u1 l2 u2
  where "a = Some (l1, u1)"
  and "b = Some (l2, u2)"
  and "f l1 u1 l2 u2 = Some (l, u)"
using assms by (cases a, simp, cases b, simp, auto)

fun approx_tse where
"approx_tse prec n 0 c k f bs = approx prec f bs" |
"approx_tse prec n (Suc s) c k f bs =
  (if isDERIV_approx prec n f bs then
    lift_bin (approx prec f (bs[n := Some (c,c)]))
             (approx_tse prec n s c (Suc k) (DERIV_floatarith n f) bs)
             (\<lambda> l1 u1 l2 u2. approx prec
                 (Add (Atom 0)
                      (Mult (Inverse (Num (Float (int k) 0)))
                                 (Mult (Add (Atom (Suc (Suc 0))) (Minus (Num c)))
                                       (Atom (Suc 0))))) [Some (l1, u1), Some (l2, u2), bs!n])
  else approx prec f bs)"

lemma bounded_by_Cons:
  assumes bnd: "bounded_by xs vs"
  and x: "x \<in> { real l .. real u }"
  shows "bounded_by (x#xs) ((Some (l, u))#vs)"
proof -
  { fix i assume *: "i < length ((Some (l, u))#vs)"
    have "case ((Some (l,u))#vs) ! i of Some (l, u) \<Rightarrow> (x#xs)!i \<in> { real l .. real u } | None \<Rightarrow> True"
    proof (cases i)
      case 0 with x show ?thesis by auto
    next
      case (Suc i) with * have "i < length vs" by auto
      from bnd[THEN bounded_byE, OF this]
      show ?thesis unfolding Suc nth_Cons_Suc .
    qed }
  thus ?thesis by (auto simp add: bounded_by_def)
qed

lemma approx_tse_generic:
  assumes "bounded_by xs vs"
  and bnd_c: "bounded_by (xs[x := real c]) vs" and "x < length vs" and "x < length xs"
  and bnd_x: "vs ! x = Some (lx, ux)"
  and ate: "Some (l, u) = approx_tse prec x s c k f vs"
  shows "\<exists> n. (\<forall> m < n. \<forall> z \<in> {real lx .. real ux}.
      DERIV (\<lambda> y. interpret_floatarith ((DERIV_floatarith x ^^ m) f) (xs[x := y])) z :>
            (interpret_floatarith ((DERIV_floatarith x ^^ (Suc m)) f) (xs[x := z])))
   \<and> (\<forall> t \<in> {real lx .. real ux}.  (\<Sum> i = 0..<n. inverse (real (\<Prod> j \<in> {k..<k+i}. j)) *
                  interpret_floatarith ((DERIV_floatarith x ^^ i) f) (xs[x := real c]) *
                  (xs!x - real c)^i) +
      inverse (real (\<Prod> j \<in> {k..<k+n}. j)) *
      interpret_floatarith ((DERIV_floatarith x ^^ n) f) (xs[x := t]) *
      (xs!x - real c)^n \<in> {real l .. real u})" (is "\<exists> n. ?taylor f k l u n")
using ate proof (induct s arbitrary: k f l u)
  case 0
  { fix t assume "t \<in> {real lx .. real ux}"
    note bounded_by_update_var[OF `bounded_by xs vs` bnd_x this]
    from approx[OF this 0[unfolded approx_tse.simps]]
    have "(interpret_floatarith f (xs[x := t])) \<in> {real l .. real u}"
      by (auto simp add: algebra_simps)
  } thus ?case by (auto intro!: exI[of _ 0])
next
  case (Suc s)
  show ?case
  proof (cases "isDERIV_approx prec x f vs")
    case False
    note ap = Suc.prems[unfolded approx_tse.simps if_not_P[OF False]]

    { fix t assume "t \<in> {real lx .. real ux}"
      note bounded_by_update_var[OF `bounded_by xs vs` bnd_x this]
      from approx[OF this ap]
      have "(interpret_floatarith f (xs[x := t])) \<in> {real l .. real u}"
	by (auto simp add: algebra_simps)
    } thus ?thesis by (auto intro!: exI[of _ 0])
  next
    case True
    with Suc.prems
    obtain l1 u1 l2 u2
      where a: "Some (l1, u1) = approx prec f (vs[x := Some (c,c)])"
      and ate: "Some (l2, u2) = approx_tse prec x s c (Suc k) (DERIV_floatarith x f) vs"
      and final: "Some (l, u) = approx prec
        (Add (Atom 0)
             (Mult (Inverse (Num (Float (int k) 0)))
                   (Mult (Add (Atom (Suc (Suc 0))) (Minus (Num c)))
                         (Atom (Suc 0))))) [Some (l1, u1), Some (l2, u2), vs!x]"
      by (auto elim!: lift_bin) blast

    from bnd_c `x < length xs`
    have bnd: "bounded_by (xs[x:=real c]) (vs[x:= Some (c,c)])"
      by (auto intro!: bounded_by_update)

    from approx[OF this a]
    have f_c: "interpret_floatarith ((DERIV_floatarith x ^^ 0) f) (xs[x := real c]) \<in> { real l1 .. real u1 }"
              (is "?f 0 (real c) \<in> _")
      by auto

    { fix f :: "'a \<Rightarrow> 'a" fix n :: nat fix x :: 'a
      have "(f ^^ Suc n) x = (f ^^ n) (f x)"
	by (induct n, auto) }
    note funpow_Suc = this[symmetric]
    from Suc.hyps[OF ate, unfolded this]
    obtain n
      where DERIV_hyp: "\<And> m z. \<lbrakk> m < n ; z \<in> { real lx .. real ux } \<rbrakk> \<Longrightarrow> DERIV (?f (Suc m)) z :> ?f (Suc (Suc m)) z"
      and hyp: "\<forall> t \<in> {real lx .. real ux}. (\<Sum> i = 0..<n. inverse (real (\<Prod> j \<in> {Suc k..<Suc k + i}. j)) * ?f (Suc i) (real c) * (xs!x - real c)^i) +
           inverse (real (\<Prod> j \<in> {Suc k..<Suc k + n}. j)) * ?f (Suc n) t * (xs!x - real c)^n \<in> {real l2 .. real u2}"
          (is "\<forall> t \<in> _. ?X (Suc k) f n t \<in> _")
      by blast

    { fix m z
      assume "m < Suc n" and bnd_z: "z \<in> { real lx .. real ux }"
      have "DERIV (?f m) z :> ?f (Suc m) z"
      proof (cases m)
	case 0
	with DERIV_floatarith[OF `x < length xs` isDERIV_approx'[OF `bounded_by xs vs` bnd_x bnd_z True]]
	show ?thesis by simp
      next
	case (Suc m')
	hence "m' < n" using `m < Suc n` by auto
	from DERIV_hyp[OF this bnd_z]
	show ?thesis using Suc by simp
      qed } note DERIV = this

    have "\<And> k i. k < i \<Longrightarrow> {k ..< i} = insert k {Suc k ..< i}" by auto
    hence setprod_head_Suc: "\<And> k i. \<Prod> {k ..< k + Suc i} = k * \<Prod> {Suc k ..< Suc k + i}" by auto
    have setsum_move0: "\<And> k F. setsum F {0..<Suc k} = F 0 + setsum (\<lambda> k. F (Suc k)) {0..<k}"
      unfolding setsum_shift_bounds_Suc_ivl[symmetric]
      unfolding setsum_head_upt_Suc[OF zero_less_Suc] ..
    def C \<equiv> "xs!x - real c"

    { fix t assume t: "t \<in> {real lx .. real ux}"
      hence "bounded_by [xs!x] [vs!x]"
	using `bounded_by xs vs`[THEN bounded_byE, OF `x < length vs`]
	by (cases "vs!x", auto simp add: bounded_by_def)

      with hyp[THEN bspec, OF t] f_c
      have "bounded_by [?f 0 (real c), ?X (Suc k) f n t, xs!x] [Some (l1, u1), Some (l2, u2), vs!x]"
	by (auto intro!: bounded_by_Cons)
      from approx[OF this final, unfolded atLeastAtMost_iff[symmetric]]
      have "?X (Suc k) f n t * (xs!x - real c) * inverse (real k) + ?f 0 (real c) \<in> {real l .. real u}"
	by (auto simp add: algebra_simps)
      also have "?X (Suc k) f n t * (xs!x - real c) * inverse (real k) + ?f 0 (real c) =
               (\<Sum> i = 0..<Suc n. inverse (real (\<Prod> j \<in> {k..<k+i}. j)) * ?f i (real c) * (xs!x - real c)^i) +
               inverse (real (\<Prod> j \<in> {k..<k+Suc n}. j)) * ?f (Suc n) t * (xs!x - real c)^Suc n" (is "_ = ?T")
	unfolding funpow_Suc C_def[symmetric] setsum_move0 setprod_head_Suc
	by (auto simp add: algebra_simps setsum_right_distrib[symmetric])
      finally have "?T \<in> {real l .. real u}" . }
    thus ?thesis using DERIV by blast
  qed
qed

lemma setprod_fact: "\<Prod> {1..<1 + k} = fact (k :: nat)"
proof (induct k)
  case (Suc k)
  have "{ 1 ..< Suc (Suc k) } = insert (Suc k) { 1 ..< Suc k }" by auto
  hence "\<Prod> { 1 ..< Suc (Suc k) } = (Suc k) * \<Prod> { 1 ..< Suc k }" by auto
  thus ?case using Suc by auto
qed simp

lemma approx_tse:
  assumes "bounded_by xs vs"
  and bnd_x: "vs ! x = Some (lx, ux)" and bnd_c: "real c \<in> {real lx .. real ux}"
  and "x < length vs" and "x < length xs"
  and ate: "Some (l, u) = approx_tse prec x s c 1 f vs"
  shows "interpret_floatarith f xs \<in> { real l .. real u }"
proof -
  def F \<equiv> "\<lambda> n z. interpret_floatarith ((DERIV_floatarith x ^^ n) f) (xs[x := z])"
  hence F0: "F 0 = (\<lambda> z. interpret_floatarith f (xs[x := z]))" by auto

  hence "bounded_by (xs[x := real c]) vs" and "x < length vs" "x < length xs"
    using `bounded_by xs vs` bnd_x bnd_c `x < length vs` `x < length xs`
    by (auto intro!: bounded_by_update_var)

  from approx_tse_generic[OF `bounded_by xs vs` this bnd_x ate]
  obtain n
    where DERIV: "\<forall> m z. m < n \<and> real lx \<le> z \<and> z \<le> real ux \<longrightarrow> DERIV (F m) z :> F (Suc m) z"
    and hyp: "\<And> t. t \<in> {real lx .. real ux} \<Longrightarrow>
           (\<Sum> j = 0..<n. inverse (real (fact j)) * F j (real c) * (xs!x - real c)^j) +
             inverse (real (fact n)) * F n t * (xs!x - real c)^n
             \<in> {real l .. real u}" (is "\<And> t. _ \<Longrightarrow> ?taylor t \<in> _")
    unfolding F_def atLeastAtMost_iff[symmetric] setprod_fact by blast

  have bnd_xs: "xs ! x \<in> { real lx .. real ux }"
    using `bounded_by xs vs`[THEN bounded_byE, OF `x < length vs`] bnd_x by auto

  show ?thesis
  proof (cases n)
    case 0 thus ?thesis using hyp[OF bnd_xs] unfolding F_def by auto
  next
    case (Suc n')
    show ?thesis
    proof (cases "xs ! x = real c")
      case True
      from True[symmetric] hyp[OF bnd_xs] Suc show ?thesis
	unfolding F_def Suc setsum_head_upt_Suc[OF zero_less_Suc] setsum_shift_bounds_Suc_ivl by auto
    next
      case False

      have "real lx \<le> real c" "real c \<le> real ux" "real lx \<le> xs!x" "xs!x \<le> real ux"
	using Suc bnd_c `bounded_by xs vs`[THEN bounded_byE, OF `x < length vs`] bnd_x by auto
      from Taylor.taylor[OF zero_less_Suc, of F, OF F0 DERIV[unfolded Suc] this False]
      obtain t where t_bnd: "if xs ! x < real c then xs ! x < t \<and> t < real c else real c < t \<and> t < xs ! x"
	and fl_eq: "interpret_floatarith f (xs[x := xs ! x]) =
	   (\<Sum>m = 0..<Suc n'. F m (real c) / real (fact m) * (xs ! x - real c) ^ m) +
           F (Suc n') t / real (fact (Suc n')) * (xs ! x - real c) ^ Suc n'"
	by blast

      from t_bnd bnd_xs bnd_c have *: "t \<in> {real lx .. real ux}"
	by (cases "xs ! x < real c", auto)

      have "interpret_floatarith f (xs[x := xs ! x]) = ?taylor t"
	unfolding fl_eq Suc by (auto simp add: algebra_simps divide_inverse)
      also have "\<dots> \<in> {real l .. real u}" using * by (rule hyp)
      finally show ?thesis by simp
    qed
  qed
qed

fun approx_tse_form' where
"approx_tse_form' prec t f 0 l u cmp =
  (case approx_tse prec 0 t ((l + u) * Float 1 -1) 1 f [Some (l, u)]
     of Some (l, u) \<Rightarrow> cmp l u | None \<Rightarrow> False)" |
"approx_tse_form' prec t f (Suc s) l u cmp =
  (let m = (l + u) * Float 1 -1
   in approx_tse_form' prec t f s l m cmp \<and>
      approx_tse_form' prec t f s m u cmp)"

lemma approx_tse_form':
  assumes "approx_tse_form' prec t f s l u cmp" and "x \<in> {real l .. real u}"
  shows "\<exists> l' u' ly uy. x \<in> { real l' .. real u' } \<and> real l \<le> real l' \<and> real u' \<le> real u \<and> cmp ly uy \<and>
                  approx_tse prec 0 t ((l' + u') * Float 1 -1) 1 f [Some (l', u')] = Some (ly, uy)"
using assms proof (induct s arbitrary: l u)
  case 0
  then obtain ly uy
    where *: "approx_tse prec 0 t ((l + u) * Float 1 -1) 1 f [Some (l, u)] = Some (ly, uy)"
    and **: "cmp ly uy" by (auto elim!: option_caseE)
  with 0 show ?case by (auto intro!: exI)
next
  case (Suc s)
  let ?m = "(l + u) * Float 1 -1"
  from Suc.prems
  have l: "approx_tse_form' prec t f s l ?m cmp"
    and u: "approx_tse_form' prec t f s ?m u cmp"
    by (auto simp add: Let_def)

  have m_l: "real l \<le> real ?m" and m_u: "real ?m \<le> real u"
    unfolding le_float_def using Suc.prems by auto

  with `x \<in> { real l .. real u }`
  have "x \<in> { real l .. real ?m} \<or> x \<in> { real ?m .. real u }" by auto
  thus ?case
  proof (rule disjE)
    assume "x \<in> { real l .. real ?m}"
    from Suc.hyps[OF l this]
    obtain l' u' ly uy
      where "x \<in> { real l' .. real u' } \<and> real l \<le> real l' \<and> real u' \<le> real ?m \<and> cmp ly uy \<and>
                  approx_tse prec 0 t ((l' + u') * Float 1 -1) 1 f [Some (l', u')] = Some (ly, uy)" by blast
    with m_u show ?thesis by (auto intro!: exI)
  next
    assume "x \<in> { real ?m .. real u }"
    from Suc.hyps[OF u this]
    obtain l' u' ly uy
      where "x \<in> { real l' .. real u' } \<and> real ?m \<le> real l' \<and> real u' \<le> real u \<and> cmp ly uy \<and>
                  approx_tse prec 0 t ((l' + u') * Float 1 -1) 1 f [Some (l', u')] = Some (ly, uy)" by blast
    with m_u show ?thesis by (auto intro!: exI)
  qed
qed

lemma approx_tse_form'_less:
  assumes tse: "approx_tse_form' prec t (Add a (Minus b)) s l u (\<lambda> l u. 0 < l)"
  and x: "x \<in> {real l .. real u}"
  shows "interpret_floatarith b [x] < interpret_floatarith a [x]"
proof -
  from approx_tse_form'[OF tse x]
  obtain l' u' ly uy
    where x': "x \<in> { real l' .. real u' }" and "real l \<le> real l'"
    and "real u' \<le> real u" and "0 < ly"
    and tse: "approx_tse prec 0 t ((l' + u') * Float 1 -1) 1 (Add a (Minus b)) [Some (l', u')] = Some (ly, uy)"
    by blast

  hence "bounded_by [x] [Some (l', u')]" by (auto simp add: bounded_by_def)

  from approx_tse[OF this _ _ _ _ tse[symmetric], of l' u'] x'
  have "real ly \<le> interpret_floatarith a [x] - interpret_floatarith b [x]"
    by (auto simp add: diff_minus)
  from order_less_le_trans[OF `0 < ly`[unfolded less_float_def] this]
  show ?thesis by auto
qed

lemma approx_tse_form'_le:
  assumes tse: "approx_tse_form' prec t (Add a (Minus b)) s l u (\<lambda> l u. 0 \<le> l)"
  and x: "x \<in> {real l .. real u}"
  shows "interpret_floatarith b [x] \<le> interpret_floatarith a [x]"
proof -
  from approx_tse_form'[OF tse x]
  obtain l' u' ly uy
    where x': "x \<in> { real l' .. real u' }" and "real l \<le> real l'"
    and "real u' \<le> real u" and "0 \<le> ly"
    and tse: "approx_tse prec 0 t ((l' + u') * Float 1 -1) 1 (Add a (Minus b)) [Some (l', u')] = Some (ly, uy)"
    by blast

  hence "bounded_by [x] [Some (l', u')]" by (auto simp add: bounded_by_def)

  from approx_tse[OF this _ _ _ _ tse[symmetric], of l' u'] x'
  have "real ly \<le> interpret_floatarith a [x] - interpret_floatarith b [x]"
    by (auto simp add: diff_minus)
  from order_trans[OF `0 \<le> ly`[unfolded le_float_def] this]
  show ?thesis by auto
qed

definition
"approx_tse_form prec t s f =
  (case f
   of (Bound x a b f) \<Rightarrow> x = Atom 0 \<and>
     (case (approx prec a [None], approx prec b [None])
      of (Some (l, u), Some (l', u')) \<Rightarrow>
        (case f
         of Less lf rt \<Rightarrow> approx_tse_form' prec t (Add rt (Minus lf)) s l u' (\<lambda> l u. 0 < l)
          | LessEqual lf rt \<Rightarrow> approx_tse_form' prec t (Add rt (Minus lf)) s l u' (\<lambda> l u. 0 \<le> l)
          | AtLeastAtMost x lf rt \<Rightarrow>
            approx_tse_form' prec t (Add x (Minus lf)) s l u' (\<lambda> l u. 0 \<le> l) \<and>
            approx_tse_form' prec t (Add rt (Minus x)) s l u' (\<lambda> l u. 0 \<le> l)
          | _ \<Rightarrow> False)
       | _ \<Rightarrow> False)
   | _ \<Rightarrow> False)"

lemma approx_tse_form:
  assumes "approx_tse_form prec t s f"
  shows "interpret_form f [x]"
proof (cases f)
  case (Bound i a b f') note f_def = this
  with assms obtain l u l' u'
    where a: "approx prec a [None] = Some (l, u)"
    and b: "approx prec b [None] = Some (l', u')"
    unfolding approx_tse_form_def by (auto elim!: option_caseE)

  from Bound assms have "i = Atom 0" unfolding approx_tse_form_def by auto
  hence i: "interpret_floatarith i [x] = x" by auto

  { let "?f z" = "interpret_floatarith z [x]"
    assume "?f i \<in> { ?f a .. ?f b }"
    with approx[OF _ a[symmetric], of "[x]"] approx[OF _ b[symmetric], of "[x]"]
    have bnd: "x \<in> { real l .. real u'}" unfolding bounded_by_def i by auto

    have "interpret_form f' [x]"
    proof (cases f')
      case (Less lf rt)
      with Bound a b assms
      have "approx_tse_form' prec t (Add rt (Minus lf)) s l u' (\<lambda> l u. 0 < l)"
	unfolding approx_tse_form_def by auto
      from approx_tse_form'_less[OF this bnd]
      show ?thesis using Less by auto
    next
      case (LessEqual lf rt)
      with Bound a b assms
      have "approx_tse_form' prec t (Add rt (Minus lf)) s l u' (\<lambda> l u. 0 \<le> l)"
	unfolding approx_tse_form_def by auto
      from approx_tse_form'_le[OF this bnd]
      show ?thesis using LessEqual by auto
    next
      case (AtLeastAtMost x lf rt)
      with Bound a b assms
      have "approx_tse_form' prec t (Add rt (Minus x)) s l u' (\<lambda> l u. 0 \<le> l)"
	and "approx_tse_form' prec t (Add x (Minus lf)) s l u' (\<lambda> l u. 0 \<le> l)"
	unfolding approx_tse_form_def by auto
      from approx_tse_form'_le[OF this(1) bnd] approx_tse_form'_le[OF this(2) bnd]
      show ?thesis using AtLeastAtMost by auto
    next
      case (Bound x a b f') with assms
      show ?thesis by (auto elim!: option_caseE simp add: f_def approx_tse_form_def)
    next
      case (Assign x a f') with assms
      show ?thesis by (auto elim!: option_caseE simp add: f_def approx_tse_form_def)
    qed } thus ?thesis unfolding f_def by auto
next case Assign with assms show ?thesis by (auto simp add: approx_tse_form_def)
next case LessEqual with assms show ?thesis by (auto simp add: approx_tse_form_def)
next case Less with assms show ?thesis by (auto simp add: approx_tse_form_def)
next case AtLeastAtMost with assms show ?thesis by (auto simp add: approx_tse_form_def)
qed

subsection {* Implement proof method \texttt{approximation} *}

lemmas interpret_form_equations = interpret_form.simps interpret_floatarith.simps interpret_floatarith_num
  interpret_floatarith_divide interpret_floatarith_diff interpret_floatarith_tan interpret_floatarith_powr interpret_floatarith_log
  interpret_floatarith_sin

ML {*
structure Float_Arith =
struct

@{code_datatype float = Float}
@{code_datatype floatarith = Add | Minus | Mult | Inverse | Cos | Arctan
                           | Abs | Max | Min | Pi | Sqrt | Exp | Ln | Power | Atom | Num }
@{code_datatype form = Bound | Assign | Less | LessEqual | AtLeastAtMost}

val approx_form = @{code approx_form}
val approx_tse_form = @{code approx_tse_form}
val approx' = @{code approx'}

end
*}

code_reserved Eval Float_Arith

code_type float (Eval "Float'_Arith.float")
code_const Float (Eval "Float'_Arith.Float/ (_,/ _)")

code_type floatarith (Eval "Float'_Arith.floatarith")
code_const Add and Minus and Mult and Inverse and Cos and Arctan and Abs and Max and Min and
           Pi and Sqrt  and Exp and Ln and Power and Atom and Num
  (Eval "Float'_Arith.Add/ (_,/ _)" and "Float'_Arith.Minus" and "Float'_Arith.Mult/ (_,/ _)" and
        "Float'_Arith.Inverse" and "Float'_Arith.Cos" and
        "Float'_Arith.Arctan" and "Float'_Arith.Abs" and "Float'_Arith.Max/ (_,/ _)" and
        "Float'_Arith.Min/ (_,/ _)" and "Float'_Arith.Pi" and "Float'_Arith.Sqrt" and
        "Float'_Arith.Exp" and "Float'_Arith.Ln" and "Float'_Arith.Power/ (_,/ _)" and
        "Float'_Arith.Atom" and "Float'_Arith.Num")

code_type form (Eval "Float'_Arith.form")
code_const Bound and Assign and Less and LessEqual and AtLeastAtMost
      (Eval "Float'_Arith.Bound/ (_,/ _,/ _,/ _)" and "Float'_Arith.Assign/ (_,/ _,/ _)" and
            "Float'_Arith.Less/ (_,/ _)" and "Float'_Arith.LessEqual/ (_,/ _)"  and
            "Float'_Arith.AtLeastAtMost/ (_,/ _,/ _)")

code_const approx_form (Eval "Float'_Arith.approx'_form")
code_const approx_tse_form (Eval "Float'_Arith.approx'_tse'_form")
code_const approx' (Eval "Float'_Arith.approx'")

ML {*
  fun reorder_bounds_tac prems i =
    let
      fun variable_of_bound (Const ("Trueprop", _) $
                             (Const (@{const_name "op :"}, _) $
                              Free (name, _) $ _)) = name
        | variable_of_bound (Const ("Trueprop", _) $
                             (Const ("op =", _) $
                              Free (name, _) $ _)) = name
        | variable_of_bound t = raise TERM ("variable_of_bound", [t])

      val variable_bounds
        = map (` (variable_of_bound o prop_of)) prems

      fun add_deps (name, bnds)
        = Graph.add_deps_acyclic (name,
            remove (op =) name (Term.add_free_names (prop_of bnds) []))

      val order = Graph.empty
                  |> fold Graph.new_node variable_bounds
                  |> fold add_deps variable_bounds
                  |> Graph.strong_conn |> map the_single |> rev
                  |> map_filter (AList.lookup (op =) variable_bounds)

      fun prepend_prem th tac
        = tac THEN rtac (th RSN (2, @{thm mp})) i
    in
      fold prepend_prem order all_tac
    end

  (* Should be in HOL.thy ? *)
  fun gen_eval_tac conv ctxt = CONVERSION (Conv.params_conv (~1) (K (Conv.concl_conv (~1) conv)) ctxt)
                               THEN' rtac TrueI

  val form_equations = PureThy.get_thms @{theory} "interpret_form_equations";

  fun rewrite_interpret_form_tac ctxt prec splitting taylor i st = let
      fun lookup_splitting (Free (name, typ))
        = case AList.lookup (op =) splitting name
          of SOME s => HOLogic.mk_number @{typ nat} s
           | NONE => @{term "0 :: nat"}
      val vs = nth (prems_of st) (i - 1)
               |> Logic.strip_imp_concl
               |> HOLogic.dest_Trueprop
               |> Term.strip_comb |> snd |> List.last
               |> HOLogic.dest_list
      val p = prec
              |> HOLogic.mk_number @{typ nat}
              |> Thm.cterm_of (ProofContext.theory_of ctxt)
    in case taylor
    of NONE => let
         val n = vs |> length
                 |> HOLogic.mk_number @{typ nat}
                 |> Thm.cterm_of (ProofContext.theory_of ctxt)
         val s = vs
                 |> map lookup_splitting
                 |> HOLogic.mk_list @{typ nat}
                 |> Thm.cterm_of (ProofContext.theory_of ctxt)
       in
         (rtac (Thm.instantiate ([], [(@{cpat "?n::nat"}, n),
                                     (@{cpat "?prec::nat"}, p),
                                     (@{cpat "?ss::nat list"}, s)])
              @{thm "approx_form"}) i
          THEN simp_tac @{simpset} i) st
       end

     | SOME t => if length vs <> 1 then raise (TERM ("More than one variable used for taylor series expansion", [prop_of st]))
       else let
         val t = t
              |> HOLogic.mk_number @{typ nat}
              |> Thm.cterm_of (ProofContext.theory_of ctxt)
         val s = vs |> map lookup_splitting |> hd
              |> Thm.cterm_of (ProofContext.theory_of ctxt)
       in
         rtac (Thm.instantiate ([], [(@{cpat "?s::nat"}, s),
                                     (@{cpat "?t::nat"}, t),
                                     (@{cpat "?prec::nat"}, p)])
              @{thm "approx_tse_form"}) i st
       end
    end

  (* copied from Tools/induct.ML should probably in args.ML *)
  val free = Args.context -- Args.term >> (fn (_, Free (n, t)) => n | (ctxt, t) =>
    error ("Bad free variable: " ^ Syntax.string_of_term ctxt t));

*}

lemma intervalE: "a \<le> x \<and> x \<le> b \<Longrightarrow> \<lbrakk> x \<in> { a .. b } \<Longrightarrow> P\<rbrakk> \<Longrightarrow> P"
  by auto

lemma meta_eqE: "x \<equiv> a \<Longrightarrow> \<lbrakk> x = a \<Longrightarrow> P\<rbrakk> \<Longrightarrow> P"
  by auto

method_setup approximation = {*
  Scan.lift (OuterParse.nat)
  --
  Scan.optional (Scan.lift (Args.$$$ "splitting" |-- Args.colon)
    |-- OuterParse.and_list' (free --| Scan.lift (Args.$$$ "=") -- Scan.lift OuterParse.nat)) []
  --
  Scan.option (Scan.lift (Args.$$$ "taylor" |-- Args.colon)
    |-- (free |-- Scan.lift (Args.$$$ "=") |-- Scan.lift OuterParse.nat))
  >>
  (fn ((prec, splitting), taylor) => fn ctxt =>
    SIMPLE_METHOD' (fn i =>
      REPEAT (FIRST' [etac @{thm intervalE},
                      etac @{thm meta_eqE},
                      rtac @{thm impI}] i)
      THEN Subgoal.FOCUS (fn {prems, ...} => reorder_bounds_tac prems i) @{context} i
      THEN DETERM (TRY (filter_prems_tac (K false) i))
      THEN DETERM (Reflection.genreify_tac ctxt form_equations NONE i)
      THEN rewrite_interpret_form_tac ctxt prec splitting taylor i
      THEN gen_eval_tac eval_oracle ctxt i))
 *} "real number approximation"

ML {*
  fun dest_interpret (@{const "interpret_floatarith"} $ b $ xs) = (b, xs)
  | dest_interpret t = raise TERM ("dest_interpret", [t])

  fun mk_approx' prec t = (@{const "approx'"}
                         $ HOLogic.mk_number @{typ nat} prec
                         $ t $ @{term "[] :: (float * float) option list"})

  fun dest_result (Const (@{const_name "Some"}, _) $
                   ((Const (@{const_name "Pair"}, _)) $
                    (@{const "Float"} $ lm $ le) $
                    (@{const "Float"} $ um $ ue)))
                   = SOME ((snd (HOLogic.dest_number lm), snd (HOLogic.dest_number le)),
                           (snd (HOLogic.dest_number um), snd (HOLogic.dest_number ue)))
    | dest_result (Const (@{const_name "None"}, _)) = NONE
    | dest_result t = raise TERM ("dest_result", [t])

  fun float2_float10 prec round_down (m, e) = (
    let
      val (m, e) = (if e < 0 then (m,e) else (m * Integer.pow e 2, 0))

      fun frac c p 0 digits cnt = (digits, cnt, 0)
        | frac c 0 r digits cnt = (digits, cnt, r)
        | frac c p r digits cnt = (let
          val (d, r) = Integer.div_mod (r * 10) (Integer.pow (~e) 2)
        in frac (c orelse d <> 0) (if d <> 0 orelse c then p - 1 else p) r
                (digits * 10 + d) (cnt + 1)
        end)

      val sgn = Int.sign m
      val m = abs m

      val round_down = (sgn = 1 andalso round_down) orelse
                       (sgn = ~1 andalso not round_down)

      val (x, r) = Integer.div_mod m (Integer.pow (~e) 2)

      val p = ((if x = 0 then prec else prec - (IntInf.log2 x + 1)) * 3) div 10 + 1

      val (digits, e10, r) = if p > 0 then frac (x <> 0) p r 0 0 else (0,0,0)

      val digits = if round_down orelse r = 0 then digits else digits + 1

    in (sgn * (digits + x * (Integer.pow e10 10)), ~e10)
    end)

  fun mk_result prec (SOME (l, u)) = (let
      fun mk_float10 rnd x = (let val (m, e) = float2_float10 prec rnd x
                         in if e = 0 then HOLogic.mk_number @{typ real} m
                       else if e = 1 then @{term "divide :: real \<Rightarrow> real \<Rightarrow> real"} $
                                          HOLogic.mk_number @{typ real} m $
                                          @{term "10"}
                                     else @{term "divide :: real \<Rightarrow> real \<Rightarrow> real"} $
                                          HOLogic.mk_number @{typ real} m $
                                          (@{term "power 10 :: nat \<Rightarrow> real"} $
                                           HOLogic.mk_number @{typ nat} (~e)) end)
      in @{term "atLeastAtMost :: real \<Rightarrow> real \<Rightarrow> real set"} $
         mk_float10 true l $ mk_float10 false u end)
    | mk_result prec NONE = @{term "UNIV :: real set"}


  fun realify t = let
      val t = Logic.varify t
      val m = map (fn (name, sort) => (name, @{typ real})) (Term.add_tvars t [])
      val t = Term.subst_TVars m t
    in t end

  fun approx prec ctxt t = let val t = realify t in
          t
       |> Reflection.genreif ctxt form_equations
       |> prop_of
       |> HOLogic.dest_Trueprop
       |> HOLogic.dest_eq |> snd
       |> dest_interpret |> fst
       |> mk_approx' prec
       |> Codegen.eval_term @{theory}
       |> dest_result
       |> mk_result prec
    end
*}

setup {*
  Value.add_evaluator ("approximate", approx 30)
*}

end
