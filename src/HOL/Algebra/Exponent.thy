(*  Title:      HOL/Algebra/Exponent.thy
    Author:     Florian Kammueller
    Author:     L C Paulson

exponent p s   yields the greatest power of p that divides s.
*)

theory Exponent
imports Main "~~/src/HOL/Number_Theory/Primes" "~~/src/HOL/Number_Theory/Binomial"
begin

section {*Sylow's Theorem*}

subsection {*The Combinatorial Argument Underlying the First Sylow Theorem*}

definition
  exponent :: "nat => nat => nat"
  where "exponent p s = (if prime p then (GREATEST r. p^r dvd s) else 0)"


text{*Prime Theorems*}

lemma prime_iff:
  "(prime p) = (Suc 0 < p & (\<forall>a b. p dvd a*b --> (p dvd a) | (p dvd b)))"
apply (auto simp add: prime_gt_Suc_0_nat)
by (metis (full_types) One_nat_def Suc_lessD dvd.order_refl nat_dvd_not_less not_prime_eq_prod_nat)

lemma zero_less_prime_power:
  fixes p::nat shows "prime p ==> 0 < p^a"
by (force simp add: prime_iff)

lemma zero_less_card_empty: "[| finite S; S \<noteq> {} |] ==> 0 < card(S)"
by (rule ccontr, simp)


lemma prime_dvd_cases:
  fixes p::nat
  shows "[| p*k dvd m*n;  prime p |]  
   ==> (\<exists>x. k dvd x*n & m = p*x) | (\<exists>y. k dvd m*y & n = p*y)"
apply (simp add: prime_iff)
apply (frule dvd_mult_left)
apply (subgoal_tac "p dvd m | p dvd n")
 prefer 2 apply blast
apply (erule disjE)
apply (rule disjI1)
apply (rule_tac [2] disjI2)
apply (auto elim!: dvdE)
done


lemma prime_power_dvd_cases [rule_format (no_asm)]: 
fixes p::nat
  shows "prime p
  ==> \<forall>m n. p^c dvd m*n -->  
        (\<forall>a b. a+b = Suc c --> p^a dvd m | p^b dvd n)"
apply (induct c)
apply (metis dvd_1_left nat_power_eq_Suc_0_iff one_is_add)
(*inductive step*)
apply simp
apply clarify
apply (erule prime_dvd_cases [THEN disjE], assumption, auto)
(*case 1: p dvd m*)
 apply (case_tac "a")
  apply simp
 apply clarify
 apply (drule spec, drule spec, erule (1) notE impE)
 apply (drule_tac x = nat in spec)
 apply (drule_tac x = b in spec)
 apply simp
(*case 2: p dvd n*)
apply (case_tac "b")
 apply simp
apply clarify
apply (drule spec, drule spec, erule (1) notE impE)
apply (drule_tac x = a in spec)
apply (drule_tac x = nat in spec, simp)
done

(*needed in this form in Sylow.ML*)
lemma div_combine:
  fixes p::nat
  shows "[| prime p; ~ (p ^ (Suc r) dvd n);  p^(a+r) dvd n*k |] ==> p ^ a dvd k"
by (metis add_Suc add.commute prime_power_dvd_cases)

(*Lemma for power_dvd_bound*)
lemma Suc_le_power: "Suc 0 < p ==> Suc n <= p^n"
apply (induct n)
apply (simp (no_asm_simp))
apply simp
apply (subgoal_tac "2 * n + 2 <= p * p^n", simp)
apply (subgoal_tac "2 * p^n <= p * p^n")
apply arith
apply (drule_tac k = 2 in mult_le_mono2, simp)
done

(*An upper bound for the n such that p^n dvd a: needed for GREATEST to exist*)
lemma power_dvd_bound: "[|p^n dvd a;  Suc 0 < p;  a > 0|] ==> n < a"
apply (drule dvd_imp_le)
apply (drule_tac [2] n = n in Suc_le_power, auto)
done


text{*Exponent Theorems*}

lemma exponent_ge [rule_format]:
  "[|p^k dvd n;  prime p;  0<n|] ==> k <= exponent p n"
apply (simp add: exponent_def)
apply (erule Greatest_le)
apply (blast dest: prime_gt_Suc_0_nat power_dvd_bound)
done

lemma power_exponent_dvd: "s>0 ==> (p ^ exponent p s) dvd s"
apply (simp add: exponent_def)
apply clarify
apply (rule_tac k = 0 in GreatestI)
prefer 2 apply (blast dest: prime_gt_Suc_0_nat power_dvd_bound, simp)
done

lemma power_Suc_exponent_Not_dvd:
  "[|(p * p ^ exponent p s) dvd s;  prime p |] ==> s=0"
apply (subgoal_tac "p ^ Suc (exponent p s) dvd s")
 prefer 2 apply simp 
apply (rule ccontr)
apply (drule exponent_ge, auto)
done

lemma exponent_power_eq [simp]: "prime p ==> exponent p (p^a) = a"
apply (simp add: exponent_def)
apply (rule Greatest_equality, simp)
apply (simp (no_asm_simp) add: prime_gt_Suc_0_nat power_dvd_imp_le)
done

lemma exponent_equalityI:
  "!r::nat. (p^r dvd a) = (p^r dvd b) ==> exponent p a = exponent p b"
by (simp (no_asm_simp) add: exponent_def)

lemma exponent_eq_0 [simp]: "\<not> prime p ==> exponent p s = 0"
by (simp (no_asm_simp) add: exponent_def)


(* exponent_mult_add, easy inclusion.  Could weaken p \<in> prime to Suc 0 < p *)
lemma exponent_mult_add1: "[| a > 0; b > 0 |]
  ==> (exponent p a) + (exponent p b) <= exponent p (a * b)"
apply (case_tac "prime p")
apply (rule exponent_ge)
apply (auto simp add: power_add)
by (metis mult_dvd_mono power_exponent_dvd)

(* exponent_mult_add, opposite inclusion *)
lemma exponent_mult_add2: "[| a > 0; b > 0 |]  
  ==> exponent p (a * b) <= (exponent p a) + (exponent p b)"
apply (case_tac "prime p")
apply (rule leI, clarify)
apply (cut_tac p = p and s = "a*b" in power_exponent_dvd, auto)
apply (subgoal_tac "p ^ (Suc (exponent p a + exponent p b)) dvd a * b")
apply (rule_tac [2] le_imp_power_dvd [THEN dvd_trans])
  prefer 3 apply assumption
 prefer 2 apply simp 
apply (frule_tac a = "Suc (exponent p a) " and b = "Suc (exponent p b) " in prime_power_dvd_cases)
 apply (assumption, force, simp)
apply (blast dest: power_Suc_exponent_Not_dvd)
done

lemma exponent_mult_add: "[| a > 0; b > 0 |]
   ==> exponent p (a * b) = (exponent p a) + (exponent p b)"
by (blast intro: exponent_mult_add1 exponent_mult_add2 order_antisym)


lemma not_divides_exponent_0: "~ (p dvd n) ==> exponent p n = 0"
apply (case_tac "exponent p n", simp)
apply (case_tac "n", simp)
apply (cut_tac s = n and p = p in power_exponent_dvd)
apply (auto dest: dvd_mult_left)
done

lemma exponent_1_eq_0 [simp]:
  fixes p::nat
  shows "exponent p (Suc 0) = 0"
apply (case_tac "prime p")
apply (metis exponent_power_eq nat_power_eq_Suc_0_iff)
apply (simp add: prime_iff not_divides_exponent_0)
done


text{*Main Combinatorial Argument*}

lemma gcd_mult': fixes a::nat shows "gcd b (a * b) = b"
by (simp add: mult.commute[of a b]) 

lemma le_extend_mult: "[| c > 0; a <= b |] ==> a <= b * (c::nat)"
apply (rule_tac P = "%x. x <= b * c" in subst)
apply (rule mult_1_right)
apply (rule mult_le_mono, auto)
done

lemma p_fac_forw_lemma:
  "[| (m::nat) > 0; k > 0; k < p^a; (p^r) dvd (p^a)* m - k |] ==> r <= a"
apply (rule notnotD)
apply (rule notI)
apply (drule contrapos_nn [OF _ leI, THEN notnotD], assumption)
apply (drule less_imp_le [of a])
apply (drule le_imp_power_dvd)
apply (drule_tac b = "p ^ r" in dvd_trans, assumption)
apply (metis diff_is_0_eq dvd_diffD1 gcd_dvd2_nat gcd_mult' gr0I le_extend_mult less_diff_conv nat_dvd_not_less mult.commute not_add_less2 xt1(10))
done

lemma p_fac_forw: "[| (m::nat) > 0; k>0; k < p^a; (p^r) dvd (p^a)* m - k |]  
  ==> (p^r) dvd (p^a) - k"
apply (frule p_fac_forw_lemma [THEN le_imp_power_dvd, of _ k p], auto)
apply (subgoal_tac "p^r dvd p^a*m")
 prefer 2 apply (blast intro: dvd_mult2)
apply (drule dvd_diffD1)
  apply assumption
 prefer 2 apply (blast intro: dvd_diff_nat)
apply (drule gr0_implies_Suc, auto)
done


lemma r_le_a_forw:
  "[| (k::nat) > 0; k < p^a; p>0; (p^r) dvd (p^a) - k |] ==> r <= a"
by (rule_tac m = "Suc 0" in p_fac_forw_lemma, auto)

lemma p_fac_backw: "[| m>0; k>0; (p::nat)\<noteq>0;  k < p^a;  (p^r) dvd p^a - k |]  
  ==> (p^r) dvd (p^a)*m - k"
apply (frule_tac k1 = k and p1 = p in r_le_a_forw [THEN le_imp_power_dvd], auto)
apply (subgoal_tac "p^r dvd p^a*m")
 prefer 2 apply (blast intro: dvd_mult2)
apply (drule dvd_diffD1)
  apply assumption
 prefer 2 apply (blast intro: dvd_diff_nat)
apply (drule less_imp_Suc_add, auto)
done

lemma exponent_p_a_m_k_equation: "[| m>0; k>0; (p::nat)\<noteq>0;  k < p^a |]  
  ==> exponent p (p^a * m - k) = exponent p (p^a - k)"
apply (blast intro: exponent_equalityI p_fac_forw p_fac_backw)
done

text{*Suc rules that we have to delete from the simpset*}
lemmas bad_Sucs = binomial_Suc_Suc mult_Suc mult_Suc_right

(*The bound K is needed; otherwise it's too weak to be used.*)
lemma p_not_div_choose_lemma [rule_format]:
  "[| \<forall>i. Suc i < K --> exponent p (Suc i) = exponent p (Suc(j+i))|]  
   ==> k<K --> exponent p ((j+k) choose k) = 0"
apply (cases "prime p")
 prefer 2 apply simp 
apply (induct k)
apply (simp (no_asm))
(*induction step*)
apply (subgoal_tac "(Suc (j+k) choose Suc k) > 0")
 prefer 2 apply (simp, clarify)
apply (subgoal_tac "exponent p ((Suc (j+k) choose Suc k) * Suc k) = 
                    exponent p (Suc k)")
 txt{*First, use the assumed equation.  We simplify the LHS to
  @{term "exponent p (Suc (j + k) choose Suc k) + exponent p (Suc k)"}
  the common terms cancel, proving the conclusion.*}
 apply (simp del: bad_Sucs add: exponent_mult_add)
apply (simp del: bad_Sucs add: mult_ac Suc_times_binomial exponent_mult_add)

done

(*The lemma above, with two changes of variables*)
lemma p_not_div_choose:
  "[| k<K;  k<=n;
      \<forall>j. 0<j & j<K --> exponent p (n - k + (K - j)) = exponent p (K - j)|]
   ==> exponent p (n choose k) = 0"
apply (cut_tac j = "n-k" and k = k and p = p in p_not_div_choose_lemma)
  prefer 3 apply simp
 prefer 2 apply assumption
apply (drule_tac x = "K - Suc i" in spec)
apply (simp add: Suc_diff_le)
done


lemma const_p_fac_right:
  "m>0 ==> exponent p ((p^a * m - Suc 0) choose (p^a - Suc 0)) = 0"
apply (case_tac "prime p")
 prefer 2 apply simp 
apply (frule_tac a = a in zero_less_prime_power)
apply (rule_tac K = "p^a" in p_not_div_choose)
   apply simp
  apply simp
 apply (case_tac "m")
  apply (case_tac [2] "p^a")
   apply auto
(*now the hard case, simplified to
    exponent p (Suc (p ^ a * m + i - p ^ a)) = exponent p (Suc i) *)
apply (subgoal_tac "0<p")
 prefer 2 apply (force dest!: prime_gt_Suc_0_nat)
apply (subst exponent_p_a_m_k_equation, auto)
done

lemma const_p_fac:
  "m>0 ==> exponent p (((p^a) * m) choose p^a) = exponent p m"
apply (case_tac "prime p")
 prefer 2 apply simp 
apply (subgoal_tac "0 < p^a * m & p^a <= p^a * m")
 prefer 2 apply (force simp add: prime_iff)
txt{*A similar trick to the one used in @{text p_not_div_choose_lemma}:
  insert an equation; use @{text exponent_mult_add} on the LHS; on the RHS,
  first
  transform the binomial coefficient, then use @{text exponent_mult_add}.*}
apply (subgoal_tac "exponent p ((( (p^a) * m) choose p^a) * p^a) = 
                    a + exponent p m")
 apply (simp add: exponent_mult_add)
txt{*one subgoal left!*}
apply (auto simp: mult_ac)
apply (subst times_binomial_minus1_eq, simp)
apply (simp add: diff_le_mono exponent_mult_add)
apply (metis const_p_fac_right mult.commute)
done

end
