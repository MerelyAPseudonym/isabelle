(*  Title:      HOL/Power.thy
    ID:         $Id$
    Author:     Lawrence C Paulson, Cambridge University Computer Laboratory
    Copyright   1997  University of Cambridge

*)

header{*Exponentiation*}

theory Power
imports Divides
begin

subsection{*Powers for Arbitrary Monoids*}

axclass recpower \<subseteq> monoid_mult, power
  power_0 [simp]: "a ^ 0       = 1"
  power_Suc:      "a ^ (Suc n) = a * (a ^ n)"

lemma power_0_Suc [simp]: "(0::'a::{recpower,semiring_0}) ^ (Suc n) = 0"
by (simp add: power_Suc)

text{*It looks plausible as a simprule, but its effect can be strange.*}
lemma power_0_left: "0^n = (if n=0 then 1 else (0::'a::{recpower,semiring_0}))"
by (induct "n", auto)

lemma power_one [simp]: "1^n = (1::'a::recpower)"
apply (induct "n")
apply (auto simp add: power_Suc)
done

lemma power_one_right [simp]: "(a::'a::recpower) ^ 1 = a"
by (simp add: power_Suc)

lemma power_commutes: "(a::'a::recpower) ^ n * a = a * a ^ n"
by (induct "n") (simp_all add:power_Suc mult_assoc)

lemma power_add: "(a::'a::recpower) ^ (m+n) = (a^m) * (a^n)"
apply (induct "m")
apply (simp_all add: power_Suc mult_ac)
done

lemma power_mult: "(a::'a::recpower) ^ (m*n) = (a^m) ^ n"
apply (induct "n") 
apply (simp_all add: power_Suc power_add)
done

lemma power_mult_distrib: "((a::'a::{recpower,comm_monoid_mult}) * b) ^ n = (a^n) * (b^n)"
apply (induct "n")
apply (auto simp add: power_Suc mult_ac)
done

lemma zero_less_power:
     "0 < (a::'a::{ordered_semidom,recpower}) ==> 0 < a^n"
apply (induct "n")
apply (simp_all add: power_Suc zero_less_one mult_pos_pos)
done

lemma zero_le_power:
     "0 \<le> (a::'a::{ordered_semidom,recpower}) ==> 0 \<le> a^n"
apply (simp add: order_le_less)
apply (erule disjE)
apply (simp_all add: zero_less_power zero_less_one power_0_left)
done

lemma one_le_power:
     "1 \<le> (a::'a::{ordered_semidom,recpower}) ==> 1 \<le> a^n"
apply (induct "n")
apply (simp_all add: power_Suc)
apply (rule order_trans [OF _ mult_mono [of 1 _ 1]])
apply (simp_all add: zero_le_one order_trans [OF zero_le_one])
done

lemma gt1_imp_ge0: "1 < a ==> 0 \<le> (a::'a::ordered_semidom)"
  by (simp add: order_trans [OF zero_le_one order_less_imp_le])

lemma power_gt1_lemma:
  assumes gt1: "1 < (a::'a::{ordered_semidom,recpower})"
  shows "1 < a * a^n"
proof -
  have "1*1 < a*1" using gt1 by simp
  also have "\<dots> \<le> a * a^n" using gt1
    by (simp only: mult_mono gt1_imp_ge0 one_le_power order_less_imp_le
        zero_le_one order_refl)
  finally show ?thesis by simp
qed

lemma power_gt1:
     "1 < (a::'a::{ordered_semidom,recpower}) ==> 1 < a ^ (Suc n)"
by (simp add: power_gt1_lemma power_Suc)

lemma power_le_imp_le_exp:
  assumes gt1: "(1::'a::{recpower,ordered_semidom}) < a"
  shows "!!n. a^m \<le> a^n ==> m \<le> n"
proof (induct m)
  case 0
  show ?case by simp
next
  case (Suc m)
  show ?case
  proof (cases n)
    case 0
    from prems have "a * a^m \<le> 1" by (simp add: power_Suc)
    with gt1 show ?thesis
      by (force simp only: power_gt1_lemma
          linorder_not_less [symmetric])
  next
    case (Suc n)
    from prems show ?thesis
      by (force dest: mult_left_le_imp_le
          simp add: power_Suc order_less_trans [OF zero_less_one gt1])
  qed
qed

text{*Surely we can strengthen this? It holds for @{text "0<a<1"} too.*}
lemma power_inject_exp [simp]:
     "1 < (a::'a::{ordered_semidom,recpower}) ==> (a^m = a^n) = (m=n)"
  by (force simp add: order_antisym power_le_imp_le_exp)

text{*Can relax the first premise to @{term "0<a"} in the case of the
natural numbers.*}
lemma power_less_imp_less_exp:
     "[| (1::'a::{recpower,ordered_semidom}) < a; a^m < a^n |] ==> m < n"
by (simp add: order_less_le [of m n] order_less_le [of "a^m" "a^n"]
              power_le_imp_le_exp)


lemma power_mono:
     "[|a \<le> b; (0::'a::{recpower,ordered_semidom}) \<le> a|] ==> a^n \<le> b^n"
apply (induct "n")
apply (simp_all add: power_Suc)
apply (auto intro: mult_mono zero_le_power order_trans [of 0 a b])
done

lemma power_strict_mono [rule_format]:
     "[|a < b; (0::'a::{recpower,ordered_semidom}) \<le> a|]
      ==> 0 < n --> a^n < b^n"
apply (induct "n")
apply (auto simp add: mult_strict_mono zero_le_power power_Suc
                      order_le_less_trans [of 0 a b])
done

lemma power_eq_0_iff [simp]:
     "(a^n = 0) = (a = (0::'a::{ordered_idom,recpower}) & 0<n)"
apply (induct "n")
apply (auto simp add: power_Suc zero_neq_one [THEN not_sym])
done

lemma field_power_eq_0_iff [simp]:
     "(a^n = 0) = (a = (0::'a::{field,recpower}) & 0<n)"
apply (induct "n")
apply (auto simp add: power_Suc field_mult_eq_0_iff zero_neq_one[THEN not_sym])
done

lemma field_power_not_zero: "a \<noteq> (0::'a::{field,recpower}) ==> a^n \<noteq> 0"
by force

lemma nonzero_power_inverse:
  "a \<noteq> 0 ==> inverse ((a::'a::{field,recpower}) ^ n) = (inverse a) ^ n"
apply (induct "n")
apply (auto simp add: power_Suc nonzero_inverse_mult_distrib mult_commute)
done

text{*Perhaps these should be simprules.*}
lemma power_inverse:
  "inverse ((a::'a::{field,division_by_zero,recpower}) ^ n) = (inverse a) ^ n"
apply (induct "n")
apply (auto simp add: power_Suc inverse_mult_distrib)
done

lemma power_one_over: "1 / (a::'a::{field,division_by_zero,recpower})^n = 
    (1 / a)^n"
apply (simp add: divide_inverse)
apply (rule power_inverse)
done

lemma nonzero_power_divide:
    "b \<noteq> 0 ==> (a/b) ^ n = ((a::'a::{field,recpower}) ^ n) / (b ^ n)"
by (simp add: divide_inverse power_mult_distrib nonzero_power_inverse)

lemma power_divide:
    "(a/b) ^ n = ((a::'a::{field,division_by_zero,recpower}) ^ n / b ^ n)"
apply (case_tac "b=0", simp add: power_0_left)
apply (rule nonzero_power_divide)
apply assumption
done

lemma power_abs: "abs(a ^ n) = abs(a::'a::{ordered_idom,recpower}) ^ n"
apply (induct "n")
apply (auto simp add: power_Suc abs_mult)
done

lemma zero_less_power_abs_iff [simp]:
     "(0 < (abs a)^n) = (a \<noteq> (0::'a::{ordered_idom,recpower}) | n=0)"
proof (induct "n")
  case 0
    show ?case by (simp add: zero_less_one)
next
  case (Suc n)
    show ?case by (force simp add: prems power_Suc zero_less_mult_iff)
qed

lemma zero_le_power_abs [simp]:
     "(0::'a::{ordered_idom,recpower}) \<le> (abs a)^n"
apply (induct "n")
apply (auto simp add: zero_le_one zero_le_power)
done

lemma power_minus: "(-a) ^ n = (- 1)^n * (a::'a::{comm_ring_1,recpower}) ^ n"
proof -
  have "-a = (- 1) * a"  by (simp add: minus_mult_left [symmetric])
  thus ?thesis by (simp only: power_mult_distrib)
qed

text{*Lemma for @{text power_strict_decreasing}*}
lemma power_Suc_less:
     "[|(0::'a::{ordered_semidom,recpower}) < a; a < 1|]
      ==> a * a^n < a^n"
apply (induct n)
apply (auto simp add: power_Suc mult_strict_left_mono)
done

lemma power_strict_decreasing:
     "[|n < N; 0 < a; a < (1::'a::{ordered_semidom,recpower})|]
      ==> a^N < a^n"
apply (erule rev_mp)
apply (induct "N")
apply (auto simp add: power_Suc power_Suc_less less_Suc_eq)
apply (rename_tac m)
apply (subgoal_tac "a * a^m < 1 * a^n", simp)
apply (rule mult_strict_mono)
apply (auto simp add: zero_le_power zero_less_one order_less_imp_le)
done

text{*Proof resembles that of @{text power_strict_decreasing}*}
lemma power_decreasing:
     "[|n \<le> N; 0 \<le> a; a \<le> (1::'a::{ordered_semidom,recpower})|]
      ==> a^N \<le> a^n"
apply (erule rev_mp)
apply (induct "N")
apply (auto simp add: power_Suc  le_Suc_eq)
apply (rename_tac m)
apply (subgoal_tac "a * a^m \<le> 1 * a^n", simp)
apply (rule mult_mono)
apply (auto simp add: zero_le_power zero_le_one)
done

lemma power_Suc_less_one:
     "[| 0 < a; a < (1::'a::{ordered_semidom,recpower}) |] ==> a ^ Suc n < 1"
apply (insert power_strict_decreasing [of 0 "Suc n" a], simp)
done

text{*Proof again resembles that of @{text power_strict_decreasing}*}
lemma power_increasing:
     "[|n \<le> N; (1::'a::{ordered_semidom,recpower}) \<le> a|] ==> a^n \<le> a^N"
apply (erule rev_mp)
apply (induct "N")
apply (auto simp add: power_Suc le_Suc_eq)
apply (rename_tac m)
apply (subgoal_tac "1 * a^n \<le> a * a^m", simp)
apply (rule mult_mono)
apply (auto simp add: order_trans [OF zero_le_one] zero_le_power)
done

text{*Lemma for @{text power_strict_increasing}*}
lemma power_less_power_Suc:
     "(1::'a::{ordered_semidom,recpower}) < a ==> a^n < a * a^n"
apply (induct n)
apply (auto simp add: power_Suc mult_strict_left_mono order_less_trans [OF zero_less_one])
done

lemma power_strict_increasing:
     "[|n < N; (1::'a::{ordered_semidom,recpower}) < a|] ==> a^n < a^N"
apply (erule rev_mp)
apply (induct "N")
apply (auto simp add: power_less_power_Suc power_Suc less_Suc_eq)
apply (rename_tac m)
apply (subgoal_tac "1 * a^n < a * a^m", simp)
apply (rule mult_strict_mono)
apply (auto simp add: order_less_trans [OF zero_less_one] zero_le_power
                 order_less_imp_le)
done

lemma power_increasing_iff [simp]: 
     "1 < (b::'a::{ordered_semidom,recpower}) ==> (b ^ x \<le> b ^ y) = (x \<le> y)"
  by (blast intro: power_le_imp_le_exp power_increasing order_less_imp_le) 

lemma power_strict_increasing_iff [simp]:
     "1 < (b::'a::{ordered_semidom,recpower}) ==> (b ^ x < b ^ y) = (x < y)"
  by (blast intro: power_less_imp_less_exp power_strict_increasing) 

lemma power_le_imp_le_base:
  assumes le: "a ^ Suc n \<le> b ^ Suc n"
      and xnonneg: "(0::'a::{ordered_semidom,recpower}) \<le> a"
      and ynonneg: "0 \<le> b"
  shows "a \<le> b"
 proof (rule ccontr)
   assume "~ a \<le> b"
   then have "b < a" by (simp only: linorder_not_le)
   then have "b ^ Suc n < a ^ Suc n"
     by (simp only: prems power_strict_mono)
   from le and this show "False"
      by (simp add: linorder_not_less [symmetric])
 qed

lemma power_inject_base:
     "[| a ^ Suc n = b ^ Suc n; 0 \<le> a; 0 \<le> b |]
      ==> a = (b::'a::{ordered_semidom,recpower})"
by (blast intro: power_le_imp_le_base order_antisym order_eq_refl sym)


subsection{*Exponentiation for the Natural Numbers*}

primrec (power)
  "p ^ 0 = 1"
  "p ^ (Suc n) = (p::nat) * (p ^ n)"

instance nat :: recpower
proof
  fix z n :: nat
  show "z^0 = 1" by simp
  show "z^(Suc n) = z * (z^n)" by simp
qed

lemma nat_one_le_power [simp]: "1 \<le> i ==> Suc 0 \<le> i^n"
by (insert one_le_power [of i n], simp)

lemma le_imp_power_dvd: "!!i::nat. m \<le> n ==> i^m dvd i^n"
apply (unfold dvd_def)
apply (erule linorder_not_less [THEN iffD2, THEN add_diff_inverse, THEN subst])
apply (simp add: power_add)
done

text{*Valid for the naturals, but what if @{text"0<i<1"}?
Premises cannot be weakened: consider the case where @{term "i=0"},
@{term "m=1"} and @{term "n=0"}.*}
lemma nat_power_less_imp_less: "!!i::nat. [| 0 < i; i^m < i^n |] ==> m < n"
apply (rule ccontr)
apply (drule leI [THEN le_imp_power_dvd, THEN dvd_imp_le, THEN leD])
apply (erule zero_less_power, auto)
done

lemma nat_zero_less_power_iff [simp]: "(0 < x^n) = (x \<noteq> (0::nat) | n=0)"
by (induct "n", auto)

lemma power_le_dvd [rule_format]: "k^j dvd n --> i\<le>j --> k^i dvd (n::nat)"
apply (induct "j")
apply (simp_all add: le_Suc_eq)
apply (blast dest!: dvd_mult_right)
done

lemma power_dvd_imp_le: "[|i^m dvd i^n;  (1::nat) < i|] ==> m \<le> n"
apply (rule power_le_imp_le_exp, assumption)
apply (erule dvd_imp_le, simp)
done

lemma power_diff:
  assumes nz: "a ~= 0"
  shows "n <= m ==> (a::'a::{recpower, field}) ^ (m-n) = (a^m) / (a^n)"
  by (induct m n rule: diff_induct)
    (simp_all add: power_Suc nonzero_mult_divide_cancel_left nz)


text{*ML bindings for the general exponentiation theorems*}
ML
{*
val power_0 = thm"power_0";
val power_Suc = thm"power_Suc";
val power_0_Suc = thm"power_0_Suc";
val power_0_left = thm"power_0_left";
val power_one = thm"power_one";
val power_one_right = thm"power_one_right";
val power_add = thm"power_add";
val power_mult = thm"power_mult";
val power_mult_distrib = thm"power_mult_distrib";
val zero_less_power = thm"zero_less_power";
val zero_le_power = thm"zero_le_power";
val one_le_power = thm"one_le_power";
val gt1_imp_ge0 = thm"gt1_imp_ge0";
val power_gt1_lemma = thm"power_gt1_lemma";
val power_gt1 = thm"power_gt1";
val power_le_imp_le_exp = thm"power_le_imp_le_exp";
val power_inject_exp = thm"power_inject_exp";
val power_less_imp_less_exp = thm"power_less_imp_less_exp";
val power_mono = thm"power_mono";
val power_strict_mono = thm"power_strict_mono";
val power_eq_0_iff = thm"power_eq_0_iff";
val field_power_eq_0_iff = thm"field_power_eq_0_iff";
val field_power_not_zero = thm"field_power_not_zero";
val power_inverse = thm"power_inverse";
val nonzero_power_divide = thm"nonzero_power_divide";
val power_divide = thm"power_divide";
val power_abs = thm"power_abs";
val zero_less_power_abs_iff = thm"zero_less_power_abs_iff";
val zero_le_power_abs = thm "zero_le_power_abs";
val power_minus = thm"power_minus";
val power_Suc_less = thm"power_Suc_less";
val power_strict_decreasing = thm"power_strict_decreasing";
val power_decreasing = thm"power_decreasing";
val power_Suc_less_one = thm"power_Suc_less_one";
val power_increasing = thm"power_increasing";
val power_strict_increasing = thm"power_strict_increasing";
val power_le_imp_le_base = thm"power_le_imp_le_base";
val power_inject_base = thm"power_inject_base";
*}

text{*ML bindings for the remaining theorems*}
ML
{*
val nat_one_le_power = thm"nat_one_le_power";
val le_imp_power_dvd = thm"le_imp_power_dvd";
val nat_power_less_imp_less = thm"nat_power_less_imp_less";
val nat_zero_less_power_iff = thm"nat_zero_less_power_iff";
val power_le_dvd = thm"power_le_dvd";
val power_dvd_imp_le = thm"power_dvd_imp_le";
*}

end

