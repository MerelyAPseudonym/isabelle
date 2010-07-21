(*  Title:      HOL/ex/Quickcheck_Lattice_Examples.thy
    Author:     Lukas Bulwahn
    Copyright   2010 TU Muenchen
*)

theory Quickcheck_Lattice_Examples
imports Quickcheck_Types
begin

text {* We show how other default types help to find counterexamples to propositions if
  the standard default type @{typ int} is insufficient. *}

notation
  less_eq  (infix "\<sqsubseteq>" 50) and
  less  (infix "\<sqsubset>" 50) and
  top ("\<top>") and
  bot ("\<bottom>") and
  inf (infixl "\<sqinter>" 70) and
  sup (infixl "\<squnion>" 65)

subsection {* Distributive lattices *}

lemma sup_inf_distrib2:
 "((y :: 'a :: distrib_lattice) \<sqinter> z) \<squnion> x = (y \<squnion> x) \<sqinter> (z \<squnion> x)"
  quickcheck
by(simp add: inf_sup_aci sup_inf_distrib1)

lemma sup_inf_distrib2_1:
 "((y :: 'a :: lattice) \<sqinter> z) \<squnion> x = (y \<squnion> x) \<sqinter> (z \<squnion> x)"
  quickcheck
  oops

lemma sup_inf_distrib2_2:
 "((y :: 'a :: distrib_lattice) \<sqinter> z') \<squnion> x = (y \<squnion> x) \<sqinter> (z \<squnion> x)"
  quickcheck
  oops

lemma inf_sup_distrib1_1:
 "(x :: 'a :: distrib_lattice) \<sqinter> (y \<squnion> z) = (x \<sqinter> y) \<squnion> (x' \<sqinter> z)"
  quickcheck
  oops

lemma inf_sup_distrib2_1:
 "((y :: 'a :: distrib_lattice) \<squnion> z) \<sqinter> x = (y \<sqinter> x) \<squnion> (y \<sqinter> x)"
  quickcheck
  oops

subsection {* Bounded lattices *}

lemma inf_bot_left [simp]:
  "\<bottom> \<sqinter> (x :: 'a :: bounded_lattice_bot) = \<bottom>"
  quickcheck
  by (rule inf_absorb1) simp

lemma inf_bot_left_1:
  "\<bottom> \<sqinter> (x :: 'a :: bounded_lattice_bot) = x"
  quickcheck
  oops

lemma inf_bot_left_2:
  "y \<sqinter> (x :: 'a :: bounded_lattice_bot) = \<bottom>"
  quickcheck
  oops

lemma inf_bot_left_3:
  "x \<noteq> \<bottom> ==> y \<sqinter> (x :: 'a :: bounded_lattice_bot) \<noteq> \<bottom>"
  quickcheck
  oops

lemma inf_bot_right [simp]:
  "(x :: 'a :: bounded_lattice_bot) \<sqinter> \<bottom> = \<bottom>"
  quickcheck
  by (rule inf_absorb2) simp

lemma inf_bot_right_1:
  "x \<noteq> \<bottom> ==> (x :: 'a :: bounded_lattice_bot) \<sqinter> \<bottom> = y"
  quickcheck
  oops

lemma inf_bot_right_2:
  "(x :: 'a :: bounded_lattice_bot) \<sqinter> \<bottom> ~= \<bottom>"
  quickcheck
  oops

lemma inf_bot_right [simp]:
  "(x :: 'a :: bounded_lattice_bot) \<squnion> \<bottom> = \<bottom>"
  quickcheck
  oops

lemma sup_bot_left [simp]:
  "\<bottom> \<squnion> (x :: 'a :: bounded_lattice_bot) = x"
  quickcheck
  by (rule sup_absorb2) simp

lemma sup_bot_right [simp]:
  "(x :: 'a :: bounded_lattice_bot) \<squnion> \<bottom> = x"
  quickcheck
  by (rule sup_absorb1) simp

lemma sup_eq_bot_iff [simp]:
  "(x :: 'a :: bounded_lattice_bot) \<squnion> y = \<bottom> \<longleftrightarrow> x = \<bottom> \<and> y = \<bottom>"
  quickcheck
  by (simp add: eq_iff)

lemma sup_top_left [simp]:
  "\<top> \<squnion> (x :: 'a :: bounded_lattice_top) = \<top>"
  quickcheck
  by (rule sup_absorb1) simp

lemma sup_top_right [simp]:
  "(x :: 'a :: bounded_lattice_top) \<squnion> \<top> = \<top>"
  quickcheck
  by (rule sup_absorb2) simp

lemma inf_top_left [simp]:
  "\<top> \<sqinter> x = (x :: 'a :: bounded_lattice_top)"
  quickcheck
  by (rule inf_absorb2) simp

lemma inf_top_right [simp]:
  "x \<sqinter> \<top> = (x :: 'a :: bounded_lattice_top)"
  quickcheck
  by (rule inf_absorb1) simp

lemma inf_eq_top_iff [simp]:
  "x \<sqinter> y = \<top> \<longleftrightarrow> x = \<top> \<and> y = \<top>"
  quickcheck
  by (simp add: eq_iff)


no_notation
  less_eq  (infix "\<sqsubseteq>" 50) and
  less (infix "\<sqsubset>" 50) and
  inf  (infixl "\<sqinter>" 70) and
  sup  (infixl "\<squnion>" 65) and
  top ("\<top>") and
  bot ("\<bottom>")

end
