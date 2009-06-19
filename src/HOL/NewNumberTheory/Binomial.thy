(*  Title:      Binomial.thy
    Authors:    Lawrence C. Paulson, Jeremy Avigad, Tobias Nipkow


Defines factorial and the "choose" function, and establishes basic properties.

The original theory "Binomial" was by Lawrence C. Paulson, based on
the work of Andy Gordon and Florian Kammueller. The approach here,
which derives the definition of binomial coefficients in terms of the
factorial function, is due to Jeremy Avigad. The binomial theorem was
formalized by Tobias Nipkow.

*)


header {* Binomial *}

theory Binomial
imports Cong
begin


subsection {* Main definitions *}

class binomial =

fixes 
  fact :: "'a \<Rightarrow> 'a" and
  binomial :: "'a \<Rightarrow> 'a \<Rightarrow> 'a" (infixl "choose" 65)

(* definitions for the natural numbers *)

instantiation nat :: binomial

begin 

fun
  fact_nat :: "nat \<Rightarrow> nat"
where
  "fact_nat x = 
   (if x = 0 then 1 else
                  x * fact(x - 1))"

fun
  binomial_nat :: "nat \<Rightarrow> nat \<Rightarrow> nat"
where
  "binomial_nat n k =
   (if k = 0 then 1 else
    if n = 0 then 0 else
      (binomial (n - 1) k) + (binomial (n - 1) (k - 1)))"

instance proof qed

end

(* definitions for the integers *)

instantiation int :: binomial

begin 

definition
  fact_int :: "int \<Rightarrow> int"
where  
  "fact_int x = (if x >= 0 then int (fact (nat x)) else 0)"

definition
  binomial_int :: "int => int \<Rightarrow> int"
where
  "binomial_int n k = (if n \<ge> 0 \<and> k \<ge> 0 then int (binomial (nat n) (nat k))
      else 0)"
instance proof qed

end


subsection {* Set up Transfer *}


lemma transfer_nat_int_binomial:
  "(x::int) >= 0 \<Longrightarrow> fact (nat x) = nat (fact x)"
  "(n::int) >= 0 \<Longrightarrow> k >= 0 \<Longrightarrow> binomial (nat n) (nat k) = 
      nat (binomial n k)"
  unfolding fact_int_def binomial_int_def 
  by auto


lemma transfer_nat_int_binomial_closures:
  "x >= (0::int) \<Longrightarrow> fact x >= 0"
  "n >= (0::int) \<Longrightarrow> k >= 0 \<Longrightarrow> binomial n k >= 0"
  by (auto simp add: fact_int_def binomial_int_def)

declare TransferMorphism_nat_int[transfer add return: 
    transfer_nat_int_binomial transfer_nat_int_binomial_closures]

lemma transfer_int_nat_binomial:
  "fact (int x) = int (fact x)"
  "binomial (int n) (int k) = int (binomial n k)"
  unfolding fact_int_def binomial_int_def by auto

lemma transfer_int_nat_binomial_closures:
  "is_nat x \<Longrightarrow> fact x >= 0"
  "is_nat n \<Longrightarrow> is_nat k \<Longrightarrow> binomial n k >= 0"
  by (auto simp add: fact_int_def binomial_int_def)

declare TransferMorphism_int_nat[transfer add return: 
    transfer_int_nat_binomial transfer_int_nat_binomial_closures]


subsection {* Factorial *}

lemma nat_fact_zero [simp]: "fact (0::nat) = 1"
  by simp

lemma int_fact_zero [simp]: "fact (0::int) = 1"
  by (simp add: fact_int_def)

lemma nat_fact_one [simp]: "fact (1::nat) = 1"
  by simp

lemma nat_fact_Suc_0 [simp]: "fact (Suc 0) = Suc 0"
  by (simp add: One_nat_def)

lemma int_fact_one [simp]: "fact (1::int) = 1"
  by (simp add: fact_int_def)

lemma nat_fact_plus_one: "fact ((n::nat) + 1) = (n + 1) * fact n"
  by simp

lemma nat_fact_Suc: "fact (Suc n) = (Suc n) * fact n"
  by (simp add: One_nat_def)

lemma int_fact_plus_one: 
  assumes "n >= 0"
  shows "fact ((n::int) + 1) = (n + 1) * fact n"

  using prems by (rule nat_fact_plus_one [transferred])

lemma nat_fact_reduce: "(n::nat) > 0 \<Longrightarrow> fact n = n * fact (n - 1)"
  by simp

lemma int_fact_reduce: 
  assumes "(n::int) > 0"
  shows "fact n = n * fact (n - 1)"

  using prems apply (subst tsub_eq [symmetric], auto)
  apply (rule nat_fact_reduce [transferred])
  using prems apply auto
done

declare fact_nat.simps [simp del]

lemma nat_fact_nonzero [simp]: "fact (n::nat) \<noteq> 0"
  apply (induct n rule: nat_induct')
  apply (auto simp add: nat_fact_plus_one)
done

lemma int_fact_nonzero [simp]: "n >= 0 \<Longrightarrow> fact (n::int) ~= 0"
  by (simp add: fact_int_def)

lemma nat_fact_gt_zero [simp]: "fact (n :: nat) > 0"
  by (insert nat_fact_nonzero [of n], arith)

lemma int_fact_gt_zero [simp]: "n >= 0 \<Longrightarrow> fact (n :: int) > 0"
  by (auto simp add: fact_int_def)

lemma nat_fact_ge_one [simp]: "fact (n :: nat) >= 1"
  by (insert nat_fact_nonzero [of n], arith)

lemma nat_fact_ge_Suc_0 [simp]: "fact (n :: nat) >= Suc 0"
  by (insert nat_fact_nonzero [of n], arith)

lemma int_fact_ge_one [simp]: "n >= 0 \<Longrightarrow> fact (n :: int) >= 1"
  apply (auto simp add: fact_int_def)
  apply (subgoal_tac "1 = int 1")
  apply (erule ssubst)
  apply (subst zle_int)
  apply auto
done

lemma nat_dvd_fact [rule_format]: "1 <= m \<longrightarrow> m <= n \<longrightarrow> m dvd fact (n::nat)"
  apply (induct n rule: nat_induct')
  apply (auto simp add: nat_fact_plus_one)
  apply (subgoal_tac "m = n + 1")
  apply auto
done

lemma int_dvd_fact [rule_format]: "1 <= m \<longrightarrow> m <= n \<longrightarrow> m dvd fact (n::int)"
  apply (case_tac "1 <= n")
  apply (induct n rule: int_ge_induct)
  apply (auto simp add: int_fact_plus_one)
  apply (subgoal_tac "m = i + 1")
  apply auto
done

lemma nat_interval_plus_one: "(i::nat) <= j + 1 \<Longrightarrow> 
  {i..j+1} = {i..j} Un {j+1}"
  by auto

lemma int_interval_plus_one: "(i::int) <= j + 1 \<Longrightarrow> {i..j+1} = {i..j} Un {j+1}"
  by auto

lemma nat_fact_altdef: "fact (n::nat) = (PROD i:{1..n}. i)"
  apply (induct n rule: nat_induct')
  apply force
  apply (subst nat_fact_plus_one)
  apply (subst nat_interval_plus_one)
  apply auto
done

lemma int_fact_altdef: "n >= 0 \<Longrightarrow> fact (n::int) = (PROD i:{1..n}. i)"
  apply (induct n rule: int_ge_induct)
  apply force
  apply (subst int_fact_plus_one, assumption)
  apply (subst int_interval_plus_one)
  apply auto
done

subsection {* Infinitely many primes *}

lemma next_prime_bound: "\<exists>(p::nat). prime p \<and> n < p \<and> p <= fact n + 1"
proof-
  have f1: "fact n + 1 \<noteq> 1" using nat_fact_ge_one [of n] by arith 
  from nat_prime_factor [OF f1]
      obtain p where "prime p" and "p dvd fact n + 1" by auto
  hence "p \<le> fact n + 1" 
    by (intro dvd_imp_le, auto)
  {assume "p \<le> n"
    from `prime p` have "p \<ge> 1" 
      by (cases p, simp_all)
    with `p <= n` have "p dvd fact n" 
      by (intro nat_dvd_fact)
    with `p dvd fact n + 1` have "p dvd fact n + 1 - fact n"
      by (rule nat_dvd_diff)
    hence "p dvd 1" by simp
    hence "p <= 1" by auto
    moreover from `prime p` have "p > 1" by auto
    ultimately have False by auto}
  hence "n < p" by arith
  with `prime p` and `p <= fact n + 1` show ?thesis by auto
qed

lemma bigger_prime: "\<exists>p. prime p \<and> p > (n::nat)" 
using next_prime_bound by auto

lemma primes_infinite: "\<not> (finite {(p::nat). prime p})"
proof
  assume "finite {(p::nat). prime p}"
  with Max_ge have "(EX b. (ALL x : {(p::nat). prime p}. x <= b))"
    by auto
  then obtain b where "ALL (x::nat). prime x \<longrightarrow> x <= b"
    by auto
  with bigger_prime [of b] show False by auto
qed


subsection {* Binomial coefficients *}

lemma nat_choose_zero [simp]: "(n::nat) choose 0 = 1"
  by simp

lemma int_choose_zero [simp]: "n \<ge> 0 \<Longrightarrow> (n::int) choose 0 = 1"
  by (simp add: binomial_int_def)

lemma nat_zero_choose [rule_format,simp]: "ALL (k::nat) > n. n choose k = 0"
  by (induct n rule: nat_induct', auto)

lemma int_zero_choose [rule_format,simp]: "(k::int) > n \<Longrightarrow> n choose k = 0"
  unfolding binomial_int_def apply (case_tac "n < 0")
  apply force
  apply (simp del: binomial_nat.simps)
done

lemma nat_choose_reduce: "(n::nat) > 0 \<Longrightarrow> 0 < k \<Longrightarrow>
    (n choose k) = ((n - 1) choose k) + ((n - 1) choose (k - 1))"
  by simp

lemma int_choose_reduce: "(n::int) > 0 \<Longrightarrow> 0 < k \<Longrightarrow>
    (n choose k) = ((n - 1) choose k) + ((n - 1) choose (k - 1))"
  unfolding binomial_int_def apply (subst nat_choose_reduce)
    apply (auto simp del: binomial_nat.simps 
      simp add: nat_diff_distrib)
done

lemma nat_choose_plus_one: "((n::nat) + 1) choose (k + 1) = 
    (n choose (k + 1)) + (n choose k)"
  by (simp add: nat_choose_reduce)

lemma nat_choose_Suc: "(Suc n) choose (Suc k) = 
    (n choose (Suc k)) + (n choose k)"
  by (simp add: nat_choose_reduce One_nat_def)

lemma int_choose_plus_one: "n \<ge> 0 \<Longrightarrow> k \<ge> 0 \<Longrightarrow> ((n::int) + 1) choose (k + 1) = 
    (n choose (k + 1)) + (n choose k)"
  by (simp add: binomial_int_def nat_choose_plus_one nat_add_distrib 
    del: binomial_nat.simps)

declare binomial_nat.simps [simp del]

lemma nat_choose_self [simp]: "((n::nat) choose n) = 1"
  by (induct n rule: nat_induct', auto simp add: nat_choose_plus_one)

lemma int_choose_self [simp]: "n \<ge> 0 \<Longrightarrow> ((n::int) choose n) = 1"
  by (auto simp add: binomial_int_def)

lemma nat_choose_one [simp]: "(n::nat) choose 1 = n"
  by (induct n rule: nat_induct', auto simp add: nat_choose_reduce)

lemma int_choose_one [simp]: "n \<ge> 0 \<Longrightarrow> (n::int) choose 1 = n"
  by (auto simp add: binomial_int_def)

lemma nat_plus_one_choose_self [simp]: "(n::nat) + 1 choose n = n + 1"
  apply (induct n rule: nat_induct', force)
  apply (case_tac "n = 0")
  apply auto
  apply (subst nat_choose_reduce)
  apply (auto simp add: One_nat_def)  
  (* natdiff_cancel_numerals introduces Suc *)
done

lemma nat_Suc_choose_self [simp]: "(Suc n) choose n = Suc n"
  using nat_plus_one_choose_self by (simp add: One_nat_def)

lemma int_plus_one_choose_self [rule_format, simp]: 
    "(n::int) \<ge> 0 \<longrightarrow> n + 1 choose n = n + 1"
   by (auto simp add: binomial_int_def nat_add_distrib)

(* bounded quantification doesn't work with the unicode characters? *)
lemma nat_choose_pos [rule_format]: "ALL k <= (n::nat). 
    ((n::nat) choose k) > 0"
  apply (induct n rule: nat_induct') 
  apply force
  apply clarify
  apply (case_tac "k = 0")
  apply force
  apply (subst nat_choose_reduce)
  apply auto
done

lemma int_choose_pos: "n \<ge> 0 \<Longrightarrow> k >= 0 \<Longrightarrow> k \<le> n \<Longrightarrow>
    ((n::int) choose k) > 0"
  by (auto simp add: binomial_int_def nat_choose_pos)

lemma binomial_induct [rule_format]: "(ALL (n::nat). P n n) \<longrightarrow> 
    (ALL n. P (n + 1) 0) \<longrightarrow> (ALL n. (ALL k < n. P n k \<longrightarrow> P n (k + 1) \<longrightarrow>
    P (n + 1) (k + 1))) \<longrightarrow> (ALL k <= n. P n k)"
  apply (induct n rule: nat_induct')
  apply auto
  apply (case_tac "k = 0")
  apply auto
  apply (case_tac "k = n + 1")
  apply auto
  apply (drule_tac x = n in spec) back back 
  apply (drule_tac x = "k - 1" in spec) back back back
  apply auto
done

lemma nat_choose_altdef_aux: "(k::nat) \<le> n \<Longrightarrow> 
    fact k * fact (n - k) * (n choose k) = fact n"
  apply (rule binomial_induct [of _ k n])
  apply auto
proof -
  fix k :: nat and n
  assume less: "k < n"
  assume ih1: "fact k * fact (n - k) * (n choose k) = fact n"
  hence one: "fact (k + 1) * fact (n - k) * (n choose k) = (k + 1) * fact n"
    by (subst nat_fact_plus_one, auto)
  assume ih2: "fact (k + 1) * fact (n - (k + 1)) * (n choose (k + 1)) = 
      fact n"
  with less have "fact (k + 1) * fact ((n - (k + 1)) + 1) * 
      (n choose (k + 1)) = (n - k) * fact n"
    by (subst (2) nat_fact_plus_one, auto)
  with less have two: "fact (k + 1) * fact (n - k) * (n choose (k + 1)) = 
      (n - k) * fact n" by simp
  have "fact (k + 1) * fact (n - k) * (n + 1 choose (k + 1)) =
      fact (k + 1) * fact (n - k) * (n choose (k + 1)) + 
      fact (k + 1) * fact (n - k) * (n choose k)" 
    by (subst nat_choose_reduce, auto simp add: ring_simps)
  also note one
  also note two
  also with less have "(n - k) * fact n + (k + 1) * fact n= fact (n + 1)" 
    apply (subst nat_fact_plus_one)
    apply (subst left_distrib [symmetric])
    apply simp
    done
  finally show "fact (k + 1) * fact (n - k) * (n + 1 choose (k + 1)) = 
    fact (n + 1)" .
qed

lemma nat_choose_altdef: "(k::nat) \<le> n \<Longrightarrow> 
    n choose k = fact n div (fact k * fact (n - k))"
  apply (frule nat_choose_altdef_aux)
  apply (erule subst)
  apply (simp add: mult_ac)
done


lemma int_choose_altdef: 
  assumes "(0::int) <= k" and "k <= n"
  shows "n choose k = fact n div (fact k * fact (n - k))"
  
  apply (subst tsub_eq [symmetric], rule prems)
  apply (rule nat_choose_altdef [transferred])
  using prems apply auto
done

lemma nat_choose_dvd: "(k::nat) \<le> n \<Longrightarrow> fact k * fact (n - k) dvd fact n"
  unfolding dvd_def apply (frule nat_choose_altdef_aux)
  (* why don't blast and auto get this??? *)
  apply (rule exI)
  apply (erule sym)
done

lemma int_choose_dvd: 
  assumes "(0::int) <= k" and "k <= n"
  shows "fact k * fact (n - k) dvd fact n"
 
  apply (subst tsub_eq [symmetric], rule prems)
  apply (rule nat_choose_dvd [transferred])
  using prems apply auto
done

(* generalizes Tobias Nipkow's proof to any commutative semiring *)
theorem binomial: "(a+b::'a::{comm_ring_1,power})^n = 
  (SUM k=0..n. (of_nat (n choose k)) * a^k * b^(n-k))" (is "?P n")
proof (induct n rule: nat_induct')
  show "?P 0" by simp
next
  fix n
  assume ih: "?P n"
  have decomp: "{0..n+1} = {0} Un {n+1} Un {1..n}"
    by auto
  have decomp2: "{0..n} = {0} Un {1..n}"
    by auto
  have decomp3: "{1..n+1} = {n+1} Un {1..n}"
    by auto
  have "(a+b)^(n+1) = 
      (a+b) * (SUM k=0..n. of_nat (n choose k) * a^k * b^(n-k))"
    using ih by (simp add: power_plus_one)
  also have "... =  a*(SUM k=0..n. of_nat (n choose k) * a^k * b^(n-k)) +
                   b*(SUM k=0..n. of_nat (n choose k) * a^k * b^(n-k))"
    by (rule distrib)
  also have "... = (SUM k=0..n. of_nat (n choose k) * a^(k+1) * b^(n-k)) +
                  (SUM k=0..n. of_nat (n choose k) * a^k * b^(n-k+1))"
    by (subst (1 2) power_plus_one, simp add: setsum_right_distrib mult_ac)
  also have "... = (SUM k=0..n. of_nat (n choose k) * a^k * b^(n+1-k)) +
                  (SUM k=1..n+1. of_nat (n choose (k - 1)) * a^k * b^(n+1-k))"
    by (simp add:setsum_shift_bounds_cl_Suc_ivl Suc_diff_le 
             power_Suc ring_simps One_nat_def del:setsum_cl_ivl_Suc)
  also have "... = a^(n+1) + b^(n+1) +
                  (SUM k=1..n. of_nat (n choose (k - 1)) * a^k * b^(n+1-k)) +
                  (SUM k=1..n. of_nat (n choose k) * a^k * b^(n+1-k))"
    by (simp add: decomp2 decomp3)
  also have
      "... = a^(n+1) + b^(n+1) + 
         (SUM k=1..n. of_nat(n+1 choose k) * a^k * b^(n+1-k))"
    by (auto simp add: ring_simps setsum_addf [symmetric]
      nat_choose_reduce)
  also have "... = (SUM k=0..n+1. of_nat (n+1 choose k) * a^k * b^(n+1-k))"
    using decomp by (simp add: ring_simps)
  finally show "?P (n + 1)" by simp
qed

lemma set_explicit: "{S. S = T \<and> P S} = (if P T then {T} else {})"
  by auto

lemma nat_card_subsets [rule_format]:
  fixes S :: "'a set"
  assumes "finite S"
  shows "ALL k. card {T. T \<le> S \<and> card T = k} = card S choose k" 
      (is "?P S")
using `finite S`
proof (induct set: finite)
  show "?P {}" by (auto simp add: set_explicit)
  next fix x :: "'a" and F
  assume iassms: "finite F" "x ~: F"
  assume ih: "?P F"
  show "?P (insert x F)" (is "ALL k. ?Q k")
  proof
    fix k
    show "card {T. T \<subseteq> (insert x F) \<and> card T = k} = 
        card (insert x F) choose k" (is "?Q k")
    proof (induct k rule: nat_induct')
      from iassms have "{T. T \<le> (insert x F) \<and> card T = 0} = {{}}"
        apply auto
        apply (subst (asm) card_0_eq)
        apply (auto elim: finite_subset)
        done
      thus "?Q 0" 
        by auto
      next fix k
      show "?Q (k + 1)"
      proof -
        from iassms have fin: "finite (insert x F)" by auto
        hence "{ T. T \<subseteq> insert x F \<and> card T = k + 1} =
          {T. T \<le> F & card T = k + 1} Un 
          {T. T \<le> insert x F & x : T & card T = k + 1}"
          by (auto intro!: subsetI)
        with iassms fin have "card ({T. T \<le> insert x F \<and> card T = k + 1}) = 
          card ({T. T \<subseteq> F \<and> card T = k + 1}) + 
          card ({T. T \<subseteq> insert x F \<and> x : T \<and> card T = k + 1})"
          apply (subst card_Un_disjoint [symmetric])
          apply auto
          (* note: nice! Didn't have to say anything here *)
          done
        also from ih have "card ({T. T \<subseteq> F \<and> card T = k + 1}) = 
          card F choose (k+1)" by auto
        also have "card ({T. T \<subseteq> insert x F \<and> x : T \<and> card T = k + 1}) =
          card ({T. T <= F & card T = k})"
        proof -
          let ?f = "%T. T Un {x}"
          from iassms have "inj_on ?f {T. T <= F & card T = k}"
            unfolding inj_on_def by (auto intro!: subsetI)
          hence "card ({T. T <= F & card T = k}) = 
            card(?f ` {T. T <= F & card T = k})"
            by (rule card_image [symmetric])
          also from iassms fin have "?f ` {T. T <= F & card T = k} = 
            {T. T \<subseteq> insert x F \<and> x : T \<and> card T = k + 1}"
            unfolding image_def 
            (* I can't figure out why this next line takes so long *)
            apply auto
            apply (frule (1) finite_subset, force)
            apply (rule_tac x = "xa - {x}" in exI)
            apply (subst card_Diff_singleton)
            apply (auto elim: finite_subset)
            done
          finally show ?thesis by (rule sym)
        qed
        also from ih have "card ({T. T <= F & card T = k}) = card F choose k"
          by auto
        finally have "card ({T. T \<le> insert x F \<and> card T = k + 1}) = 
          card F choose (k + 1) + (card F choose k)".
        with iassms nat_choose_plus_one show ?thesis
          by auto
      qed
    qed
  qed
qed

end
