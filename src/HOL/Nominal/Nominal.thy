(* $Id$ *)

theory Nominal 
imports Main Infinite_Set
uses
  ("nominal_thmdecls.ML")
  ("nominal_atoms.ML")
  ("nominal_package.ML")
  ("nominal_induct.ML") 
  ("nominal_permeq.ML")
  ("nominal_primrec.ML")
  ("nominal_inductive.ML")
begin 

section {* Permutations *}
(*======================*)

types 
  'x prm = "('x \<times> 'x) list"

(* polymorphic operations for permutation and swapping *)
consts 
  perm :: "'x prm \<Rightarrow> 'a \<Rightarrow> 'a"     (infixr "\<bullet>" 80)
  swap :: "('x \<times> 'x) \<Rightarrow> 'x \<Rightarrow> 'x"

(* for the decision procedure involving permutations *)
(* (to make the perm-composition to be terminating   *)
constdefs
  "perm_aux pi x \<equiv> pi\<bullet>x"

(* permutation on sets *)
defs (unchecked overloaded)
  perm_set_def:  "pi\<bullet>(X::'a set) \<equiv> {pi\<bullet>a | a. a\<in>X}"

lemma empty_eqvt:
  shows "pi\<bullet>{} = {}"
  by (simp add: perm_set_def)

lemma union_eqvt:
  shows "pi \<bullet> (X \<union> Y) = (pi \<bullet> X) \<union> (pi \<bullet> Y)"
  by (auto simp add: perm_set_def)

lemma insert_eqvt:
  shows "pi\<bullet>(insert x X) = insert (pi\<bullet>x) (pi\<bullet>X)"
  by (auto simp add: perm_set_def)

(* permutation on units and products *)
primrec (unchecked perm_unit)
  "pi\<bullet>()    = ()"
  
primrec (unchecked perm_prod)
  "pi\<bullet>(a,b) = (pi\<bullet>a,pi\<bullet>b)"

lemma fst_eqvt:
  "pi\<bullet>(fst x) = fst (pi\<bullet>x)"
 by (cases x) simp

lemma snd_eqvt:
  "pi\<bullet>(snd x) = snd (pi\<bullet>x)"
 by (cases x) simp

(* permutation on lists *)
primrec (unchecked perm_list)
  nil_eqvt:  "pi\<bullet>[]     = []"
  cons_eqvt: "pi\<bullet>(x#xs) = (pi\<bullet>x)#(pi\<bullet>xs)"

lemma append_eqvt:
  fixes pi :: "'x prm"
  and   l1 :: "'a list"
  and   l2 :: "'a list"
  shows "pi\<bullet>(l1@l2) = (pi\<bullet>l1)@(pi\<bullet>l2)"
  by (induct l1) auto

lemma rev_eqvt:
  fixes pi :: "'x prm"
  and   l  :: "'a list"
  shows "pi\<bullet>(rev l) = rev (pi\<bullet>l)"
  by (induct l) (simp_all add: append_eqvt)

(* permutation on functions *)
defs (unchecked overloaded)
  perm_fun_def: "pi\<bullet>(f::'a\<Rightarrow>'b) \<equiv> (\<lambda>x. pi\<bullet>f((rev pi)\<bullet>x))"

(* permutation on bools *)
primrec (unchecked perm_bool)
  true_eqvt:  "pi\<bullet>True  = True"
  false_eqvt: "pi\<bullet>False = False"

lemma perm_bool:
  shows "pi\<bullet>(b::bool) = b"
  by (cases b) auto

lemma perm_boolI:
  assumes a: "P"
  shows "pi\<bullet>P"
  using a by (simp add: perm_bool)

lemma perm_boolE:
  assumes a: "pi\<bullet>P"
  shows "P"
  using a by (simp add: perm_bool)

lemma if_eqvt:
  fixes pi::"'a prm"
  shows "pi\<bullet>(if b then c1 else c2) = (if (pi\<bullet>b) then (pi\<bullet>c1) else (pi\<bullet>c2))"
apply(simp add: perm_fun_def)
done

lemma imp_eqvt:
  shows "pi\<bullet>(A\<longrightarrow>B) = ((pi\<bullet>A)\<longrightarrow>(pi\<bullet>B))"
  by (simp add: perm_bool)

lemma conj_eqvt:
  shows "pi\<bullet>(A\<and>B) = ((pi\<bullet>A)\<and>(pi\<bullet>B))"
  by (simp add: perm_bool)

lemma disj_eqvt:
  shows "pi\<bullet>(A\<or>B) = ((pi\<bullet>A)\<or>(pi\<bullet>B))"
  by (simp add: perm_bool)

lemma neg_eqvt:
  shows "pi\<bullet>(\<not> A) = (\<not> (pi\<bullet>A))"
  by (simp add: perm_bool)

(* permutation on options *)

primrec (unchecked perm_option)
  some_eqvt:  "pi\<bullet>Some(x) = Some(pi\<bullet>x)"
  none_eqvt:  "pi\<bullet>None    = None"

(* a "private" copy of the option type used in the abstraction function *)
datatype 'a noption = nSome 'a | nNone

primrec (unchecked perm_noption)
  nSome_eqvt: "pi\<bullet>nSome(x) = nSome(pi\<bullet>x)"
  nNone_eqvt: "pi\<bullet>nNone    = nNone"

(* a "private" copy of the product type used in the nominal induct method *)
datatype ('a,'b) nprod = nPair 'a 'b

primrec (unchecked perm_nprod)
  perm_nProd_def: "pi\<bullet>(nPair x1 x2)  = nPair (pi\<bullet>x1) (pi\<bullet>x2)"

(* permutation on characters (used in strings) *)
defs (unchecked overloaded)
  perm_char_def: "pi\<bullet>(s::char) \<equiv> s"

(* permutation on ints *)
defs (unchecked overloaded)
  perm_int_def:    "pi\<bullet>(i::int) \<equiv> i"

(* permutation on nats *)
defs (unchecked overloaded)
  perm_nat_def:    "pi\<bullet>(i::nat) \<equiv> i"

section {* permutation equality *}
(*==============================*)

constdefs
  prm_eq :: "'x prm \<Rightarrow> 'x prm \<Rightarrow> bool"  (" _ \<triangleq> _ " [80,80] 80)
  "pi1 \<triangleq> pi2 \<equiv> \<forall>a::'x. pi1\<bullet>a = pi2\<bullet>a"

section {* Support, Freshness and Supports*}
(*========================================*)
constdefs
   supp :: "'a \<Rightarrow> ('x set)"  
   "supp x \<equiv> {a . (infinite {b . [(a,b)]\<bullet>x \<noteq> x})}"

   fresh :: "'x \<Rightarrow> 'a \<Rightarrow> bool" ("_ \<sharp> _" [80,80] 80)
   "a \<sharp> x \<equiv> a \<notin> supp x"

   supports :: "'x set \<Rightarrow> 'a \<Rightarrow> bool" (infixl 80)
   "S supports x \<equiv> \<forall>a b. (a\<notin>S \<and> b\<notin>S \<longrightarrow> [(a,b)]\<bullet>x=x)"

lemma supp_fresh_iff: 
  fixes x :: "'a"
  shows "(supp x) = {a::'x. \<not>a\<sharp>x}"
apply(simp add: fresh_def)
done

lemma supp_unit:
  shows "supp () = {}"
  by (simp add: supp_def)

lemma supp_set_empty:
  shows "supp {} = {}"
  by (force simp add: supp_def perm_set_def)

lemma supp_singleton:
  shows "supp {x} = supp x"
  by (force simp add: supp_def perm_set_def)

lemma supp_prod: 
  fixes x :: "'a"
  and   y :: "'b"
  shows "(supp (x,y)) = (supp x)\<union>(supp y)"
  by  (force simp add: supp_def Collect_imp_eq Collect_neg_eq)

lemma supp_nprod: 
  fixes x :: "'a"
  and   y :: "'b"
  shows "(supp (nPair x y)) = (supp x)\<union>(supp y)"
  by  (force simp add: supp_def Collect_imp_eq Collect_neg_eq)

lemma supp_list_nil:
  shows "supp [] = {}"
apply(simp add: supp_def)
done

lemma supp_list_cons:
  fixes x  :: "'a"
  and   xs :: "'a list"
  shows "supp (x#xs) = (supp x)\<union>(supp xs)"
apply(auto simp add: supp_def Collect_imp_eq Collect_neg_eq)
done

lemma supp_list_append:
  fixes xs :: "'a list"
  and   ys :: "'a list"
  shows "supp (xs@ys) = (supp xs)\<union>(supp ys)"
  by (induct xs, auto simp add: supp_list_nil supp_list_cons)

lemma supp_list_rev:
  fixes xs :: "'a list"
  shows "supp (rev xs) = (supp xs)"
  by (induct xs, auto simp add: supp_list_append supp_list_cons supp_list_nil)

lemma supp_bool:
  fixes x  :: "bool"
  shows "supp (x) = {}"
  apply(case_tac "x")
  apply(simp_all add: supp_def)
done

lemma supp_some:
  fixes x :: "'a"
  shows "supp (Some x) = (supp x)"
  apply(simp add: supp_def)
  done

lemma supp_none:
  fixes x :: "'a"
  shows "supp (None) = {}"
  apply(simp add: supp_def)
  done

lemma supp_int:
  fixes i::"int"
  shows "supp (i) = {}"
  apply(simp add: supp_def perm_int_def)
  done

lemma supp_nat:
  fixes n::"nat"
  shows "supp (n) = {}"
  apply(simp add: supp_def perm_nat_def)
  done

lemma supp_char:
  fixes c::"char"
  shows "supp (c) = {}"
  apply(simp add: supp_def perm_char_def)
  done
  
lemma supp_string:
  fixes s::"string"
  shows "supp (s) = {}"
apply(induct s)
apply(auto simp add: supp_char supp_list_nil supp_list_cons)
done

lemma fresh_set_empty:
  shows "a\<sharp>{}"
  by (simp add: fresh_def supp_set_empty)

lemma fresh_singleton:
  shows "a\<sharp>{x} = a\<sharp>x"
  by (simp add: fresh_def supp_singleton)

lemma fresh_unit:
  shows "a\<sharp>()"
  by (simp add: fresh_def supp_unit)

lemma fresh_prod:
  fixes a :: "'x"
  and   x :: "'a"
  and   y :: "'b"
  shows "a\<sharp>(x,y) = (a\<sharp>x \<and> a\<sharp>y)"
  by (simp add: fresh_def supp_prod)

lemma fresh_list_nil:
  fixes a :: "'x"
  shows "a\<sharp>[]"
  by (simp add: fresh_def supp_list_nil) 

lemma fresh_list_cons:
  fixes a :: "'x"
  and   x :: "'a"
  and   xs :: "'a list"
  shows "a\<sharp>(x#xs) = (a\<sharp>x \<and> a\<sharp>xs)"
  by (simp add: fresh_def supp_list_cons)

lemma fresh_list_append:
  fixes a :: "'x"
  and   xs :: "'a list"
  and   ys :: "'a list"
  shows "a\<sharp>(xs@ys) = (a\<sharp>xs \<and> a\<sharp>ys)"
  by (simp add: fresh_def supp_list_append)

lemma fresh_list_rev:
  fixes a :: "'x"
  and   xs :: "'a list"
  shows "a\<sharp>(rev xs) = a\<sharp>xs"
  by (simp add: fresh_def supp_list_rev)

lemma fresh_none:
  fixes a :: "'x"
  shows "a\<sharp>None"
  apply(simp add: fresh_def supp_none)
  done

lemma fresh_some:
  fixes a :: "'x"
  and   x :: "'a"
  shows "a\<sharp>(Some x) = a\<sharp>x"
  apply(simp add: fresh_def supp_some)
  done

lemma fresh_int:
  fixes a :: "'x"
  and   i :: "int"
  shows "a\<sharp>i"
  apply(simp add: fresh_def supp_int)
  done

lemma fresh_nat:
  fixes a :: "'x"
  and   n :: "nat"
  shows "a\<sharp>n"
  apply(simp add: fresh_def supp_nat)
  done

lemma fresh_char:
  fixes a :: "'x"
  and   c :: "char"
  shows "a\<sharp>c"
  apply(simp add: fresh_def supp_char)
  done

lemma fresh_string:
  fixes a :: "'x"
  and   s :: "string"
  shows "a\<sharp>s"
  apply(simp add: fresh_def supp_string)
  done

text {* Normalization of freshness results; cf.\ @{text nominal_induct} *}

lemma fresh_unit_elim: 
  shows "(a\<sharp>() \<Longrightarrow> PROP C) \<equiv> PROP C"
  by (simp add: fresh_def supp_unit)

lemma fresh_prod_elim: 
  shows "(a\<sharp>(x,y) \<Longrightarrow> PROP C) \<equiv> (a\<sharp>x \<Longrightarrow> a\<sharp>y \<Longrightarrow> PROP C)"
  by rule (simp_all add: fresh_prod)

(* this rule needs to be added before the fresh_prodD is *)
(* added to the simplifier with mksimps                  *) 
lemma [simp]:
  shows "a\<sharp>x1 \<Longrightarrow> a\<sharp>x2 \<Longrightarrow> a\<sharp>(x1,x2)"
  by (simp add: fresh_prod)

lemma fresh_prodD:
  shows "a\<sharp>(x,y) \<Longrightarrow> a\<sharp>x"
  and   "a\<sharp>(x,y) \<Longrightarrow> a\<sharp>y"
  by (simp_all add: fresh_prod)

ML_setup {*
  val mksimps_pairs = ("Nominal.fresh", thms "fresh_prodD")::mksimps_pairs;
  change_simpset (fn ss => ss setmksimps (mksimps mksimps_pairs));
*}


section {* Abstract Properties for Permutations and  Atoms *}
(*=========================================================*)

(* properties for being a permutation type *)
constdefs 
  "pt TYPE('a) TYPE('x) \<equiv> 
     (\<forall>(x::'a). ([]::'x prm)\<bullet>x = x) \<and> 
     (\<forall>(pi1::'x prm) (pi2::'x prm) (x::'a). (pi1@pi2)\<bullet>x = pi1\<bullet>(pi2\<bullet>x)) \<and> 
     (\<forall>(pi1::'x prm) (pi2::'x prm) (x::'a). pi1 \<triangleq> pi2 \<longrightarrow> pi1\<bullet>x = pi2\<bullet>x)"

(* properties for being an atom type *)
constdefs 
  "at TYPE('x) \<equiv> 
     (\<forall>(x::'x). ([]::'x prm)\<bullet>x = x) \<and>
     (\<forall>(a::'x) (b::'x) (pi::'x prm) (x::'x). ((a,b)#(pi::'x prm))\<bullet>x = swap (a,b) (pi\<bullet>x)) \<and> 
     (\<forall>(a::'x) (b::'x) (c::'x). swap (a,b) c = (if a=c then b else (if b=c then a else c))) \<and> 
     (infinite (UNIV::'x set))"

(* property of two atom-types being disjoint *)
constdefs
  "disjoint TYPE('x) TYPE('y) \<equiv> 
       (\<forall>(pi::'x prm)(x::'y). pi\<bullet>x = x) \<and> 
       (\<forall>(pi::'y prm)(x::'x). pi\<bullet>x = x)"

(* composition property of two permutation on a type 'a *)
constdefs
  "cp TYPE ('a) TYPE('x) TYPE('y) \<equiv> 
      (\<forall>(pi2::'y prm) (pi1::'x prm) (x::'a) . pi1\<bullet>(pi2\<bullet>x) = (pi1\<bullet>pi2)\<bullet>(pi1\<bullet>x))" 

(* property of having finite support *)
constdefs 
  "fs TYPE('a) TYPE('x) \<equiv> \<forall>(x::'a). finite ((supp x)::'x set)"

section {* Lemmas about the atom-type properties*}
(*==============================================*)

lemma at1: 
  fixes x::"'x"
  assumes a: "at TYPE('x)"
  shows "([]::'x prm)\<bullet>x = x"
  using a by (simp add: at_def)

lemma at2: 
  fixes a ::"'x"
  and   b ::"'x"
  and   x ::"'x"
  and   pi::"'x prm"
  assumes a: "at TYPE('x)"
  shows "((a,b)#pi)\<bullet>x = swap (a,b) (pi\<bullet>x)"
  using a by (simp only: at_def)

lemma at3: 
  fixes a ::"'x"
  and   b ::"'x"
  and   c ::"'x"
  assumes a: "at TYPE('x)"
  shows "swap (a,b) c = (if a=c then b else (if b=c then a else c))"
  using a by (simp only: at_def)

(* rules to calculate simple premutations *)
lemmas at_calc = at2 at1 at3

lemma at_swap_simps:
  fixes a ::"'x"
  and   b ::"'x"
  assumes a: "at TYPE('x)"
  shows "[(a,b)]\<bullet>a = b"
  and   "[(a,b)]\<bullet>b = a"
  using a by (simp_all add: at_calc)

lemma at4: 
  assumes a: "at TYPE('x)"
  shows "infinite (UNIV::'x set)"
  using a by (simp add: at_def)

lemma at_append:
  fixes pi1 :: "'x prm"
  and   pi2 :: "'x prm"
  and   c   :: "'x"
  assumes at: "at TYPE('x)" 
  shows "(pi1@pi2)\<bullet>c = pi1\<bullet>(pi2\<bullet>c)"
proof (induct pi1)
  case Nil show ?case by (simp add: at1[OF at])
next
  case (Cons x xs)
  have "(xs@pi2)\<bullet>c  =  xs\<bullet>(pi2\<bullet>c)" by fact
  also have "(x#xs)@pi2 = x#(xs@pi2)" by simp
  ultimately show ?case by (cases "x", simp add:  at2[OF at])
qed
 
lemma at_swap:
  fixes a :: "'x"
  and   b :: "'x"
  and   c :: "'x"
  assumes at: "at TYPE('x)" 
  shows "swap (a,b) (swap (a,b) c) = c"
  by (auto simp add: at3[OF at])

lemma at_rev_pi:
  fixes pi :: "'x prm"
  and   c  :: "'x"
  assumes at: "at TYPE('x)"
  shows "(rev pi)\<bullet>(pi\<bullet>c) = c"
proof(induct pi)
  case Nil show ?case by (simp add: at1[OF at])
next
  case (Cons x xs) thus ?case 
    by (cases "x", simp add: at2[OF at] at_append[OF at] at1[OF at] at_swap[OF at])
qed

lemma at_pi_rev:
  fixes pi :: "'x prm"
  and   x  :: "'x"
  assumes at: "at TYPE('x)"
  shows "pi\<bullet>((rev pi)\<bullet>x) = x"
  by (rule at_rev_pi[OF at, of "rev pi" _,simplified])

lemma at_bij1: 
  fixes pi :: "'x prm"
  and   x  :: "'x"
  and   y  :: "'x"
  assumes at: "at TYPE('x)"
  and     a:  "(pi\<bullet>x) = y"
  shows   "x=(rev pi)\<bullet>y"
proof -
  from a have "y=(pi\<bullet>x)" by (rule sym)
  thus ?thesis by (simp only: at_rev_pi[OF at])
qed

lemma at_bij2: 
  fixes pi :: "'x prm"
  and   x  :: "'x"
  and   y  :: "'x"
  assumes at: "at TYPE('x)"
  and     a:  "((rev pi)\<bullet>x) = y"
  shows   "x=pi\<bullet>y"
proof -
  from a have "y=((rev pi)\<bullet>x)" by (rule sym)
  thus ?thesis by (simp only: at_pi_rev[OF at])
qed

lemma at_bij:
  fixes pi :: "'x prm"
  and   x  :: "'x"
  and   y  :: "'x"
  assumes at: "at TYPE('x)"
  shows "(pi\<bullet>x = pi\<bullet>y) = (x=y)"
proof 
  assume "pi\<bullet>x = pi\<bullet>y" 
  hence  "x=(rev pi)\<bullet>(pi\<bullet>y)" by (rule at_bij1[OF at]) 
  thus "x=y" by (simp only: at_rev_pi[OF at])
next
  assume "x=y"
  thus "pi\<bullet>x = pi\<bullet>y" by simp
qed

lemma at_supp:
  fixes x :: "'x"
  assumes at: "at TYPE('x)"
  shows "supp x = {x}"
proof (simp add: supp_def Collect_conj_eq Collect_imp_eq at_calc[OF at], auto)
  assume f: "finite {b::'x. b \<noteq> x}"
  have a1: "{b::'x. b \<noteq> x} = UNIV-{x}" by force
  have a2: "infinite (UNIV::'x set)" by (rule at4[OF at])
  from f a1 a2 show False by force
qed

lemma at_fresh:
  fixes a :: "'x"
  and   b :: "'x"
  assumes at: "at TYPE('x)"
  shows "(a\<sharp>b) = (a\<noteq>b)" 
  by (simp add: at_supp[OF at] fresh_def)

lemma at_prm_fresh:
  fixes c :: "'x"
  and   pi:: "'x prm"
  assumes at: "at TYPE('x)"
  and     a: "c\<sharp>pi" 
  shows "pi\<bullet>c = c"
using a
apply(induct pi)
apply(simp add: at1[OF at]) 
apply(force simp add: fresh_list_cons at2[OF at] fresh_prod at_fresh[OF at] at3[OF at])
done

lemma at_prm_rev_eq:
  fixes pi1 :: "'x prm"
  and   pi2 :: "'x prm"
  assumes at: "at TYPE('x)"
  shows "((rev pi1) \<triangleq> (rev pi2)) = (pi1 \<triangleq> pi2)"
proof (simp add: prm_eq_def, auto)
  fix x
  assume "\<forall>x::'x. (rev pi1)\<bullet>x = (rev pi2)\<bullet>x"
  hence "(rev (pi1::'x prm))\<bullet>(pi2\<bullet>(x::'x)) = (rev (pi2::'x prm))\<bullet>(pi2\<bullet>x)" by simp
  hence "(rev (pi1::'x prm))\<bullet>((pi2::'x prm)\<bullet>x) = (x::'x)" by (simp add: at_rev_pi[OF at])
  hence "(pi2::'x prm)\<bullet>x = (pi1::'x prm)\<bullet>x" by (simp add: at_bij2[OF at])
  thus "pi1\<bullet>x  =  pi2\<bullet>x" by simp
next
  fix x
  assume "\<forall>x::'x. pi1\<bullet>x = pi2\<bullet>x"
  hence "(pi1::'x prm)\<bullet>((rev pi2)\<bullet>x) = (pi2::'x prm)\<bullet>((rev pi2)\<bullet>(x::'x))" by simp
  hence "(pi1::'x prm)\<bullet>((rev pi2)\<bullet>(x::'x)) = x" by (simp add: at_pi_rev[OF at])
  hence "(rev pi2)\<bullet>x = (rev pi1)\<bullet>(x::'x)" by (simp add: at_bij1[OF at])
  thus "(rev pi1)\<bullet>x = (rev pi2)\<bullet>(x::'x)" by simp
qed

lemma at_prm_eq_append:
  fixes pi1 :: "'x prm"
  and   pi2 :: "'x prm"
  and   pi3 :: "'x prm"
  assumes at: "at TYPE('x)"
  and     a: "pi1 \<triangleq> pi2"
  shows "(pi3@pi1) \<triangleq> (pi3@pi2)"
using a by (simp add: prm_eq_def at_append[OF at] at_bij[OF at])

lemma at_prm_eq_append':
  fixes pi1 :: "'x prm"
  and   pi2 :: "'x prm"
  and   pi3 :: "'x prm"
  assumes at: "at TYPE('x)"
  and     a: "pi1 \<triangleq> pi2"
  shows "(pi1@pi3) \<triangleq> (pi2@pi3)"
using a by (simp add: prm_eq_def at_append[OF at])

lemma at_prm_eq_trans:
  fixes pi1 :: "'x prm"
  and   pi2 :: "'x prm"
  and   pi3 :: "'x prm"
  assumes a1: "pi1 \<triangleq> pi2"
  and     a2: "pi2 \<triangleq> pi3"  
  shows "pi1 \<triangleq> pi3"
using a1 a2 by (auto simp add: prm_eq_def)
  
lemma at_prm_eq_refl:
  fixes pi :: "'x prm"
  shows "pi \<triangleq> pi"
by (simp add: prm_eq_def)

lemma at_prm_rev_eq1:
  fixes pi1 :: "'x prm"
  and   pi2 :: "'x prm"
  assumes at: "at TYPE('x)"
  shows "pi1 \<triangleq> pi2 \<Longrightarrow> (rev pi1) \<triangleq> (rev pi2)"
  by (simp add: at_prm_rev_eq[OF at])

lemma at_ds1:
  fixes a  :: "'x"
  assumes at: "at TYPE('x)"
  shows "[(a,a)] \<triangleq> []"
  by (force simp add: prm_eq_def at_calc[OF at])

lemma at_ds2: 
  fixes pi :: "'x prm"
  and   a  :: "'x"
  and   b  :: "'x"
  assumes at: "at TYPE('x)"
  shows "([(a,b)]@pi) \<triangleq> (pi@[((rev pi)\<bullet>a,(rev pi)\<bullet>b)])"
  by (force simp add: prm_eq_def at_append[OF at] at_bij[OF at] at_pi_rev[OF at] 
      at_rev_pi[OF at] at_calc[OF at])

lemma at_ds3: 
  fixes a  :: "'x"
  and   b  :: "'x"
  and   c  :: "'x"
  assumes at: "at TYPE('x)"
  and     a:  "distinct [a,b,c]"
  shows "[(a,c),(b,c),(a,c)] \<triangleq> [(a,b)]"
  using a by (force simp add: prm_eq_def at_calc[OF at])

lemma at_ds4: 
  fixes a  :: "'x"
  and   b  :: "'x"
  and   pi  :: "'x prm"
  assumes at: "at TYPE('x)"
  shows "(pi@[(a,(rev pi)\<bullet>b)]) \<triangleq> ([(pi\<bullet>a,b)]@pi)"
  by (force simp add: prm_eq_def at_append[OF at] at_calc[OF at] at_bij[OF at] 
      at_pi_rev[OF at] at_rev_pi[OF at])

lemma at_ds5: 
  fixes a  :: "'x"
  and   b  :: "'x"
  assumes at: "at TYPE('x)"
  shows "[(a,b)] \<triangleq> [(b,a)]"
  by (force simp add: prm_eq_def at_calc[OF at])

lemma at_ds5': 
  fixes a  :: "'x"
  and   b  :: "'x"
  assumes at: "at TYPE('x)"
  shows "[(a,b),(b,a)] \<triangleq> []"
  by (force simp add: prm_eq_def at_calc[OF at])

lemma at_ds6: 
  fixes a  :: "'x"
  and   b  :: "'x"
  and   c  :: "'x"
  assumes at: "at TYPE('x)"
  and     a: "distinct [a,b,c]"
  shows "[(a,c),(a,b)] \<triangleq> [(b,c),(a,c)]"
  using a by (force simp add: prm_eq_def at_calc[OF at])

lemma at_ds7:
  fixes pi :: "'x prm"
  assumes at: "at TYPE('x)"
  shows "((rev pi)@pi) \<triangleq> []"
  by (simp add: prm_eq_def at1[OF at] at_append[OF at] at_rev_pi[OF at])

lemma at_ds8_aux:
  fixes pi :: "'x prm"
  and   a  :: "'x"
  and   b  :: "'x"
  and   c  :: "'x"
  assumes at: "at TYPE('x)"
  shows "pi\<bullet>(swap (a,b) c) = swap (pi\<bullet>a,pi\<bullet>b) (pi\<bullet>c)"
  by (force simp add: at_calc[OF at] at_bij[OF at])

lemma at_ds8: 
  fixes pi1 :: "'x prm"
  and   pi2 :: "'x prm"
  and   a  :: "'x"
  and   b  :: "'x"
  assumes at: "at TYPE('x)"
  shows "(pi1@pi2) \<triangleq> ((pi1\<bullet>pi2)@pi1)"
apply(induct_tac pi2)
apply(simp add: prm_eq_def)
apply(auto simp add: prm_eq_def)
apply(simp add: at2[OF at])
apply(drule_tac x="aa" in spec)
apply(drule sym)
apply(simp)
apply(simp add: at_append[OF at])
apply(simp add: at2[OF at])
apply(simp add: at_ds8_aux[OF at])
done

lemma at_ds9: 
  fixes pi1 :: "'x prm"
  and   pi2 :: "'x prm"
  and   a  :: "'x"
  and   b  :: "'x"
  assumes at: "at TYPE('x)"
  shows " ((rev pi2)@(rev pi1)) \<triangleq> ((rev pi1)@(rev (pi1\<bullet>pi2)))"
apply(induct_tac pi2)
apply(simp add: prm_eq_def)
apply(auto simp add: prm_eq_def)
apply(simp add: at_append[OF at])
apply(simp add: at2[OF at] at1[OF at])
apply(drule_tac x="swap(pi1\<bullet>a,pi1\<bullet>b) aa" in spec)
apply(drule sym)
apply(simp)
apply(simp add: at_ds8_aux[OF at])
apply(simp add: at_rev_pi[OF at])
done

lemma at_ds10:
  fixes pi :: "'x prm"
  and   a  :: "'x"
  and   b  :: "'x"
  assumes at: "at TYPE('x)"
  and     a:  "b\<sharp>(rev pi)"
  shows "([(pi\<bullet>a,b)]@pi) \<triangleq> (pi@[(a,b)])"
using a
apply -
apply(rule at_prm_eq_trans)
apply(rule at_ds2[OF at])
apply(simp add: at_prm_fresh[OF at] at_rev_pi[OF at])
apply(rule at_prm_eq_refl)
done

--"there always exists an atom that is not being in a finite set"
lemma ex_in_inf:
  fixes   A::"'x set"
  assumes at: "at TYPE('x)"
  and     fs: "finite A"
  obtains c::"'x" where "c\<notin>A"
proof -
  from  fs at4[OF at] have "infinite ((UNIV::'x set) - A)" 
    by (simp add: Diff_infinite_finite)
  hence "((UNIV::'x set) - A) \<noteq> ({}::'x set)" by (force simp only:)
  then obtain c::"'x" where "c\<in>((UNIV::'x set) - A)" by force
  then have "c\<notin>A" by simp
  then show ?thesis using prems by simp 
qed

text {* there always exists a fresh name for an object with finite support *}
lemma at_exists_fresh': 
  fixes  x :: "'a"
  assumes at: "at TYPE('x)"
  and     fs: "finite ((supp x)::'x set)"
  shows "\<exists>c::'x. c\<sharp>x"
  by (auto simp add: fresh_def intro: ex_in_inf[OF at, OF fs])

lemma at_exists_fresh: 
  fixes  x :: "'a"
  assumes at: "at TYPE('x)"
  and     fs: "finite ((supp x)::'x set)"
  obtains c::"'x" where  "c\<sharp>x"
  by (auto intro: ex_in_inf[OF at, OF fs] simp add: fresh_def)

lemma at_finite_select: 
  shows "at (TYPE('a)) \<Longrightarrow> finite (S::'a set) \<Longrightarrow> \<exists>x. x \<notin> S"
  apply (drule Diff_infinite_finite)
  apply (simp add: at_def)
  apply blast
  apply (subgoal_tac "UNIV - S \<noteq> {}")
  apply (simp only: ex_in_conv [symmetric])
  apply blast
  apply (rule notI)
  apply simp
  done

lemma at_different:
  assumes at: "at TYPE('x)"
  shows "\<exists>(b::'x). a\<noteq>b"
proof -
  have "infinite (UNIV::'x set)" by (rule at4[OF at])
  hence inf2: "infinite (UNIV-{a})" by (rule infinite_remove)
  have "(UNIV-{a}) \<noteq> ({}::'x set)" 
  proof (rule_tac ccontr, drule_tac notnotD)
    assume "UNIV-{a} = ({}::'x set)"
    with inf2 have "infinite ({}::'x set)" by simp
    then show "False" by auto
  qed
  hence "\<exists>(b::'x). b\<in>(UNIV-{a})" by blast
  then obtain b::"'x" where mem2: "b\<in>(UNIV-{a})" by blast
  from mem2 have "a\<noteq>b" by blast
  then show "\<exists>(b::'x). a\<noteq>b" by blast
qed

--"the at-props imply the pt-props"
lemma at_pt_inst:
  assumes at: "at TYPE('x)"
  shows "pt TYPE('x) TYPE('x)"
apply(auto simp only: pt_def)
apply(simp only: at1[OF at])
apply(simp only: at_append[OF at]) 
apply(simp only: prm_eq_def)
done

section {* finite support properties *}
(*===================================*)

lemma fs1:
  fixes x :: "'a"
  assumes a: "fs TYPE('a) TYPE('x)"
  shows "finite ((supp x)::'x set)"
  using a by (simp add: fs_def)

lemma fs_at_inst:
  fixes a :: "'x"
  assumes at: "at TYPE('x)"
  shows "fs TYPE('x) TYPE('x)"
apply(simp add: fs_def) 
apply(simp add: at_supp[OF at])
done

lemma fs_unit_inst:
  shows "fs TYPE(unit) TYPE('x)"
apply(simp add: fs_def)
apply(simp add: supp_unit)
done

lemma fs_prod_inst:
  assumes fsa: "fs TYPE('a) TYPE('x)"
  and     fsb: "fs TYPE('b) TYPE('x)"
  shows "fs TYPE('a\<times>'b) TYPE('x)"
apply(unfold fs_def)
apply(auto simp add: supp_prod)
apply(rule fs1[OF fsa])
apply(rule fs1[OF fsb])
done

lemma fs_nprod_inst:
  assumes fsa: "fs TYPE('a) TYPE('x)"
  and     fsb: "fs TYPE('b) TYPE('x)"
  shows "fs TYPE(('a,'b) nprod) TYPE('x)"
apply(unfold fs_def, rule allI)
apply(case_tac x)
apply(auto simp add: supp_nprod)
apply(rule fs1[OF fsa])
apply(rule fs1[OF fsb])
done

lemma fs_list_inst:
  assumes fs: "fs TYPE('a) TYPE('x)"
  shows "fs TYPE('a list) TYPE('x)"
apply(simp add: fs_def, rule allI)
apply(induct_tac x)
apply(simp add: supp_list_nil)
apply(simp add: supp_list_cons)
apply(rule fs1[OF fs])
done

lemma fs_option_inst:
  assumes fs: "fs TYPE('a) TYPE('x)"
  shows "fs TYPE('a option) TYPE('x)"
apply(simp add: fs_def, rule allI)
apply(case_tac x)
apply(simp add: supp_none)
apply(simp add: supp_some)
apply(rule fs1[OF fs])
done

section {* Lemmas about the permutation properties *}
(*=================================================*)

lemma pt1:
  fixes x::"'a"
  assumes a: "pt TYPE('a) TYPE('x)"
  shows "([]::'x prm)\<bullet>x = x"
  using a by (simp add: pt_def)

lemma pt2: 
  fixes pi1::"'x prm"
  and   pi2::"'x prm"
  and   x  ::"'a"
  assumes a: "pt TYPE('a) TYPE('x)"
  shows "(pi1@pi2)\<bullet>x = pi1\<bullet>(pi2\<bullet>x)"
  using a by (simp add: pt_def)

lemma pt3:
  fixes pi1::"'x prm"
  and   pi2::"'x prm"
  and   x  ::"'a"
  assumes a: "pt TYPE('a) TYPE('x)"
  shows "pi1 \<triangleq> pi2 \<Longrightarrow> pi1\<bullet>x = pi2\<bullet>x"
  using a by (simp add: pt_def)

lemma pt3_rev:
  fixes pi1::"'x prm"
  and   pi2::"'x prm"
  and   x  ::"'a"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "pi1 \<triangleq> pi2 \<Longrightarrow> (rev pi1)\<bullet>x = (rev pi2)\<bullet>x"
  by (rule pt3[OF pt], simp add: at_prm_rev_eq[OF at])

section {* composition properties *}
(* ============================== *)
lemma cp1:
  fixes pi1::"'x prm"
  and   pi2::"'y prm"
  and   x  ::"'a"
  assumes cp: "cp TYPE ('a) TYPE('x) TYPE('y)"
  shows "pi1\<bullet>(pi2\<bullet>x) = (pi1\<bullet>pi2)\<bullet>(pi1\<bullet>x)"
  using cp by (simp add: cp_def)

lemma cp_pt_inst:
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "cp TYPE('a) TYPE('x) TYPE('x)"
apply(auto simp add: cp_def pt2[OF pt,symmetric])
apply(rule pt3[OF pt])
apply(rule at_ds8[OF at])
done

section {* disjointness properties *}
(*=================================*)
lemma dj_perm_forget:
  fixes pi::"'y prm"
  and   x ::"'x"
  assumes dj: "disjoint TYPE('x) TYPE('y)"
  shows "pi\<bullet>x=x" 
  using dj by (simp_all add: disjoint_def)

lemma dj_perm_perm_forget:
  fixes pi1::"'x prm"
  and   pi2::"'y prm"
  assumes dj: "disjoint TYPE('x) TYPE('y)"
  shows "pi2\<bullet>pi1=pi1"
  using dj by (induct pi1, auto simp add: disjoint_def)

lemma dj_cp:
  fixes pi1::"'x prm"
  and   pi2::"'y prm"
  and   x  ::"'a"
  assumes cp: "cp TYPE ('a) TYPE('x) TYPE('y)"
  and     dj: "disjoint TYPE('y) TYPE('x)"
  shows "pi1\<bullet>(pi2\<bullet>x) = (pi2)\<bullet>(pi1\<bullet>x)"
  by (simp add: cp1[OF cp] dj_perm_perm_forget[OF dj])

lemma dj_supp:
  fixes a::"'x"
  assumes dj: "disjoint TYPE('x) TYPE('y)"
  shows "(supp a) = ({}::'y set)"
apply(simp add: supp_def dj_perm_forget[OF dj])
done

lemma at_fresh_ineq:
  fixes a :: "'x"
  and   b :: "'y"
  assumes dj: "disjoint TYPE('y) TYPE('x)"
  shows "a\<sharp>b" 
  by (simp add: fresh_def dj_supp[OF dj])

section {* permutation type instances *}
(* ===================================*)

lemma pt_set_inst:
  assumes pt: "pt TYPE('a) TYPE('x)"
  shows  "pt TYPE('a set) TYPE('x)"
apply(simp add: pt_def)
apply(simp_all add: perm_set_def)
apply(simp add: pt1[OF pt])
apply(force simp add: pt2[OF pt] pt3[OF pt])
done

lemma pt_list_nil: 
  fixes xs :: "'a list"
  assumes pt: "pt TYPE('a) TYPE ('x)"
  shows "([]::'x prm)\<bullet>xs = xs" 
apply(induct_tac xs)
apply(simp_all add: pt1[OF pt])
done

lemma pt_list_append: 
  fixes pi1 :: "'x prm"
  and   pi2 :: "'x prm"
  and   xs  :: "'a list"
  assumes pt: "pt TYPE('a) TYPE ('x)"
  shows "(pi1@pi2)\<bullet>xs = pi1\<bullet>(pi2\<bullet>xs)"
apply(induct_tac xs)
apply(simp_all add: pt2[OF pt])
done

lemma pt_list_prm_eq: 
  fixes pi1 :: "'x prm"
  and   pi2 :: "'x prm"
  and   xs  :: "'a list"
  assumes pt: "pt TYPE('a) TYPE ('x)"
  shows "pi1 \<triangleq> pi2  \<Longrightarrow> pi1\<bullet>xs = pi2\<bullet>xs"
apply(induct_tac xs)
apply(simp_all add: prm_eq_def pt3[OF pt])
done

lemma pt_list_inst:
  assumes pt: "pt TYPE('a) TYPE('x)"
  shows  "pt TYPE('a list) TYPE('x)"
apply(auto simp only: pt_def)
apply(rule pt_list_nil[OF pt])
apply(rule pt_list_append[OF pt])
apply(rule pt_list_prm_eq[OF pt],assumption)
done

lemma pt_unit_inst:
  shows  "pt TYPE(unit) TYPE('x)"
  by (simp add: pt_def)

lemma pt_prod_inst:
  assumes pta: "pt TYPE('a) TYPE('x)"
  and     ptb: "pt TYPE('b) TYPE('x)"
  shows  "pt TYPE('a \<times> 'b) TYPE('x)"
  apply(auto simp add: pt_def)
  apply(rule pt1[OF pta])
  apply(rule pt1[OF ptb])
  apply(rule pt2[OF pta])
  apply(rule pt2[OF ptb])
  apply(rule pt3[OF pta],assumption)
  apply(rule pt3[OF ptb],assumption)
  done

lemma pt_nprod_inst:
  assumes pta: "pt TYPE('a) TYPE('x)"
  and     ptb: "pt TYPE('b) TYPE('x)"
  shows  "pt TYPE(('a,'b) nprod) TYPE('x)"
  apply(auto simp add: pt_def)
  apply(case_tac x)
  apply(simp add: pt1[OF pta] pt1[OF ptb])
  apply(case_tac x)
  apply(simp add: pt2[OF pta] pt2[OF ptb])
  apply(case_tac x)
  apply(simp add: pt3[OF pta] pt3[OF ptb])
  done

lemma pt_fun_inst:
  assumes pta: "pt TYPE('a) TYPE('x)"
  and     ptb: "pt TYPE('b) TYPE('x)"
  and     at:  "at TYPE('x)"
  shows  "pt TYPE('a\<Rightarrow>'b) TYPE('x)"
apply(auto simp only: pt_def)
apply(simp_all add: perm_fun_def)
apply(simp add: pt1[OF pta] pt1[OF ptb])
apply(simp add: pt2[OF pta] pt2[OF ptb])
apply(subgoal_tac "(rev pi1) \<triangleq> (rev pi2)")(*A*)
apply(simp add: pt3[OF pta] pt3[OF ptb])
(*A*)
apply(simp add: at_prm_rev_eq[OF at])
done

lemma pt_option_inst:
  assumes pta: "pt TYPE('a) TYPE('x)"
  shows  "pt TYPE('a option) TYPE('x)"
apply(auto simp only: pt_def)
apply(case_tac "x")
apply(simp_all add: pt1[OF pta])
apply(case_tac "x")
apply(simp_all add: pt2[OF pta])
apply(case_tac "x")
apply(simp_all add: pt3[OF pta])
done

lemma pt_noption_inst:
  assumes pta: "pt TYPE('a) TYPE('x)"
  shows  "pt TYPE('a noption) TYPE('x)"
apply(auto simp only: pt_def)
apply(case_tac "x")
apply(simp_all add: pt1[OF pta])
apply(case_tac "x")
apply(simp_all add: pt2[OF pta])
apply(case_tac "x")
apply(simp_all add: pt3[OF pta])
done

section {* further lemmas for permutation types *}
(*==============================================*)

lemma pt_rev_pi:
  fixes pi :: "'x prm"
  and   x  :: "'a"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "(rev pi)\<bullet>(pi\<bullet>x) = x"
proof -
  have "((rev pi)@pi) \<triangleq> ([]::'x prm)" by (simp add: at_ds7[OF at])
  hence "((rev pi)@pi)\<bullet>(x::'a) = ([]::'x prm)\<bullet>x" by (simp add: pt3[OF pt]) 
  thus ?thesis by (simp add: pt1[OF pt] pt2[OF pt])
qed

lemma pt_pi_rev:
  fixes pi :: "'x prm"
  and   x  :: "'a"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "pi\<bullet>((rev pi)\<bullet>x) = x"
  by (simp add: pt_rev_pi[OF pt, OF at,of "rev pi" "x",simplified])

lemma pt_bij1: 
  fixes pi :: "'x prm"
  and   x  :: "'a"
  and   y  :: "'a"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  and     a:  "(pi\<bullet>x) = y"
  shows   "x=(rev pi)\<bullet>y"
proof -
  from a have "y=(pi\<bullet>x)" by (rule sym)
  thus ?thesis by (simp only: pt_rev_pi[OF pt, OF at])
qed

lemma pt_bij2: 
  fixes pi :: "'x prm"
  and   x  :: "'a"
  and   y  :: "'a"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  and     a:  "x = (rev pi)\<bullet>y"
  shows   "(pi\<bullet>x)=y"
  using a by (simp add: pt_pi_rev[OF pt, OF at])

lemma pt_bij:
  fixes pi :: "'x prm"
  and   x  :: "'a"
  and   y  :: "'a"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "(pi\<bullet>x = pi\<bullet>y) = (x=y)"
proof 
  assume "pi\<bullet>x = pi\<bullet>y" 
  hence  "x=(rev pi)\<bullet>(pi\<bullet>y)" by (rule pt_bij1[OF pt, OF at]) 
  thus "x=y" by (simp only: pt_rev_pi[OF pt, OF at])
next
  assume "x=y"
  thus "pi\<bullet>x = pi\<bullet>y" by simp
qed

lemma pt_eq_eqvt:
  fixes pi :: "'x prm"
  and   x  :: "'a"
  and   y  :: "'a"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "pi \<bullet> (x=y) = (pi\<bullet>x = pi\<bullet>y)"
using assms
by (auto simp add: pt_bij perm_bool)

lemma pt_bij3:
  fixes pi :: "'x prm"
  and   x  :: "'a"
  and   y  :: "'a"
  assumes a:  "x=y"
  shows "(pi\<bullet>x = pi\<bullet>y)"
using a by simp 

lemma pt_bij4:
  fixes pi :: "'x prm"
  and   x  :: "'a"
  and   y  :: "'a"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  and     a:  "pi\<bullet>x = pi\<bullet>y"
  shows "x = y"
using a by (simp add: pt_bij[OF pt, OF at])

lemma pt_swap_bij:
  fixes a  :: "'x"
  and   b  :: "'x"
  and   x  :: "'a"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "[(a,b)]\<bullet>([(a,b)]\<bullet>x) = x"
  by (rule pt_bij2[OF pt, OF at], simp)

lemma pt_swap_bij':
  fixes a  :: "'x"
  and   b  :: "'x"
  and   x  :: "'a"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "[(a,b)]\<bullet>([(b,a)]\<bullet>x) = x"
apply(simp add: pt2[OF pt,symmetric])
apply(rule trans)
apply(rule pt3[OF pt])
apply(rule at_ds5'[OF at])
apply(rule pt1[OF pt])
done

lemma pt_set_bij1:
  fixes pi :: "'x prm"
  and   x  :: "'a"
  and   X  :: "'a set"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "((pi\<bullet>x)\<in>X) = (x\<in>((rev pi)\<bullet>X))"
  by (force simp add: perm_set_def pt_rev_pi[OF pt, OF at] pt_pi_rev[OF pt, OF at])

lemma pt_set_bij1a:
  fixes pi :: "'x prm"
  and   x  :: "'a"
  and   X  :: "'a set"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "(x\<in>(pi\<bullet>X)) = (((rev pi)\<bullet>x)\<in>X)"
  by (force simp add: perm_set_def pt_rev_pi[OF pt, OF at] pt_pi_rev[OF pt, OF at])

lemma pt_set_bij:
  fixes pi :: "'x prm"
  and   x  :: "'a"
  and   X  :: "'a set"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "((pi\<bullet>x)\<in>(pi\<bullet>X)) = (x\<in>X)"
  by (simp add: perm_set_def pt_bij[OF pt, OF at])

lemma pt_in_eqvt:
  fixes pi :: "'x prm"
  and   x  :: "'a"
  and   X  :: "'a set"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "pi\<bullet>(x\<in>X)=((pi\<bullet>x)\<in>(pi\<bullet>X))"
using assms
by (auto simp add:  pt_set_bij perm_bool)

lemma pt_set_bij2:
  fixes pi :: "'x prm"
  and   x  :: "'a"
  and   X  :: "'a set"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  and     a:  "x\<in>X"
  shows "(pi\<bullet>x)\<in>(pi\<bullet>X)"
  using a by (simp add: pt_set_bij[OF pt, OF at])

lemma pt_set_bij2a:
  fixes pi :: "'x prm"
  and   x  :: "'a"
  and   X  :: "'a set"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  and     a:  "x\<in>((rev pi)\<bullet>X)"
  shows "(pi\<bullet>x)\<in>X"
  using a by (simp add: pt_set_bij1[OF pt, OF at])

lemma pt_set_bij3:
  fixes pi :: "'x prm"
  and   x  :: "'a"
  and   X  :: "'a set"
  shows "pi\<bullet>(x\<in>X) = (x\<in>X)"
apply(case_tac "x\<in>X = True")
apply(auto)
done

lemma pt_subseteq_eqvt:
  fixes pi :: "'x prm"
  and   Y  :: "'a set"
  and   X  :: "'a set"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "((pi\<bullet>X)\<subseteq>(pi\<bullet>Y)) = (X\<subseteq>Y)"
proof (auto)
  fix x::"'a"
  assume a: "(pi\<bullet>X)\<subseteq>(pi\<bullet>Y)"
  and    "x\<in>X"
  hence  "(pi\<bullet>x)\<in>(pi\<bullet>X)" by (simp add: pt_set_bij[OF pt, OF at])
  with a have "(pi\<bullet>x)\<in>(pi\<bullet>Y)" by force
  thus "x\<in>Y" by (simp add: pt_set_bij[OF pt, OF at])
next
  fix x::"'a"
  assume a: "X\<subseteq>Y"
  and    "x\<in>(pi\<bullet>X)"
  thus "x\<in>(pi\<bullet>Y)" by (force simp add: pt_set_bij1a[OF pt, OF at])
qed

lemma pt_set_diff_eqvt:
  fixes X::"'a set"
  and   Y::"'a set"
  and   pi::"'x prm"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "pi \<bullet> (X - Y) = (pi \<bullet> X) - (pi \<bullet> Y)"
  by (auto simp add: perm_set_def pt_bij[OF pt, OF at])


-- "some helper lemmas for the pt_perm_supp_ineq lemma"
lemma Collect_permI: 
  fixes pi :: "'x prm"
  and   x  :: "'a"
  assumes a: "\<forall>x. (P1 x = P2 x)" 
  shows "{pi\<bullet>x| x. P1 x} = {pi\<bullet>x| x. P2 x}"
  using a by force

lemma Infinite_cong:
  assumes a: "X = Y"
  shows "infinite X = infinite Y"
  using a by (simp)

lemma pt_set_eq_ineq:
  fixes pi :: "'y prm"
  assumes pt: "pt TYPE('x) TYPE('y)"
  and     at: "at TYPE('y)"
  shows "{pi\<bullet>x| x::'x. P x} = {x::'x. P ((rev pi)\<bullet>x)}"
  by (force simp only: pt_rev_pi[OF pt, OF at] pt_pi_rev[OF pt, OF at])

lemma pt_inject_on_ineq:
  fixes X  :: "'y set"
  and   pi :: "'x prm"
  assumes pt: "pt TYPE('y) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "inj_on (perm pi) X"
proof (unfold inj_on_def, intro strip)
  fix x::"'y" and y::"'y"
  assume "pi\<bullet>x = pi\<bullet>y"
  thus "x=y" by (simp add: pt_bij[OF pt, OF at])
qed

lemma pt_set_finite_ineq: 
  fixes X  :: "'x set"
  and   pi :: "'y prm"
  assumes pt: "pt TYPE('x) TYPE('y)"
  and     at: "at TYPE('y)"
  shows "finite (pi\<bullet>X) = finite X"
proof -
  have image: "(pi\<bullet>X) = (perm pi ` X)" by (force simp only: perm_set_def)
  show ?thesis
  proof (rule iffI)
    assume "finite (pi\<bullet>X)"
    hence "finite (perm pi ` X)" using image by (simp)
    thus "finite X" using pt_inject_on_ineq[OF pt, OF at] by (rule finite_imageD)
  next
    assume "finite X"
    hence "finite (perm pi ` X)" by (rule finite_imageI)
    thus "finite (pi\<bullet>X)" using image by (simp)
  qed
qed

lemma pt_set_infinite_ineq: 
  fixes X  :: "'x set"
  and   pi :: "'y prm"
  assumes pt: "pt TYPE('x) TYPE('y)"
  and     at: "at TYPE('y)"
  shows "infinite (pi\<bullet>X) = infinite X"
using pt at by (simp add: pt_set_finite_ineq)

lemma pt_perm_supp_ineq:
  fixes  pi  :: "'x prm"
  and    x   :: "'a"
  assumes pta: "pt TYPE('a) TYPE('x)"
  and     ptb: "pt TYPE('y) TYPE('x)"
  and     at:  "at TYPE('x)"
  and     cp:  "cp TYPE('a) TYPE('x) TYPE('y)"
  shows "(pi\<bullet>((supp x)::'y set)) = supp (pi\<bullet>x)" (is "?LHS = ?RHS")
proof -
  have "?LHS = {pi\<bullet>a | a. infinite {b. [(a,b)]\<bullet>x \<noteq> x}}" by (simp add: supp_def perm_set_def)
  also have "\<dots> = {pi\<bullet>a | a. infinite {pi\<bullet>b | b. [(a,b)]\<bullet>x \<noteq> x}}" 
  proof (rule Collect_permI, rule allI, rule iffI)
    fix a
    assume "infinite {b::'y. [(a,b)]\<bullet>x  \<noteq> x}"
    hence "infinite (pi\<bullet>{b::'y. [(a,b)]\<bullet>x \<noteq> x})" by (simp add: pt_set_infinite_ineq[OF ptb, OF at])
    thus "infinite {pi\<bullet>b |b::'y. [(a,b)]\<bullet>x  \<noteq> x}" by (simp add: perm_set_def)
  next
    fix a
    assume "infinite {pi\<bullet>b |b::'y. [(a,b)]\<bullet>x \<noteq> x}"
    hence "infinite (pi\<bullet>{b::'y. [(a,b)]\<bullet>x \<noteq> x})" by (simp add: perm_set_def)
    thus "infinite {b::'y. [(a,b)]\<bullet>x  \<noteq> x}" 
      by (simp add: pt_set_infinite_ineq[OF ptb, OF at])
  qed
  also have "\<dots> = {a. infinite {b::'y. [((rev pi)\<bullet>a,(rev pi)\<bullet>b)]\<bullet>x \<noteq> x}}" 
    by (simp add: pt_set_eq_ineq[OF ptb, OF at])
  also have "\<dots> = {a. infinite {b. pi\<bullet>([((rev pi)\<bullet>a,(rev pi)\<bullet>b)]\<bullet>x) \<noteq> (pi\<bullet>x)}}"
    by (simp add: pt_bij[OF pta, OF at])
  also have "\<dots> = {a. infinite {b. [(a,b)]\<bullet>(pi\<bullet>x) \<noteq> (pi\<bullet>x)}}"
  proof (rule Collect_cong, rule Infinite_cong, rule Collect_cong)
    fix a::"'y" and b::"'y"
    have "pi\<bullet>(([((rev pi)\<bullet>a,(rev pi)\<bullet>b)])\<bullet>x) = [(a,b)]\<bullet>(pi\<bullet>x)"
      by (simp add: cp1[OF cp] pt_pi_rev[OF ptb, OF at])
    thus "(pi\<bullet>([((rev pi)\<bullet>a,(rev pi)\<bullet>b)]\<bullet>x) \<noteq>  pi\<bullet>x) = ([(a,b)]\<bullet>(pi\<bullet>x) \<noteq> pi\<bullet>x)" by simp
  qed
  finally show "?LHS = ?RHS" by (simp add: supp_def) 
qed

lemma pt_perm_supp:
  fixes  pi  :: "'x prm"
  and    x   :: "'a"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "(pi\<bullet>((supp x)::'x set)) = supp (pi\<bullet>x)"
apply(rule pt_perm_supp_ineq)
apply(rule pt)
apply(rule at_pt_inst)
apply(rule at)+
apply(rule cp_pt_inst)
apply(rule pt)
apply(rule at)
done

lemma pt_supp_finite_pi:
  fixes  pi  :: "'x prm"
  and    x   :: "'a"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  and     f: "finite ((supp x)::'x set)"
  shows "finite ((supp (pi\<bullet>x))::'x set)"
apply(simp add: pt_perm_supp[OF pt, OF at, symmetric])
apply(simp add: pt_set_finite_ineq[OF at_pt_inst[OF at], OF at])
apply(rule f)
done

lemma pt_fresh_left_ineq:  
  fixes  pi :: "'x prm"
  and     x :: "'a"
  and     a :: "'y"
  assumes pta: "pt TYPE('a) TYPE('x)"
  and     ptb: "pt TYPE('y) TYPE('x)"
  and     at:  "at TYPE('x)"
  and     cp:  "cp TYPE('a) TYPE('x) TYPE('y)"
  shows "a\<sharp>(pi\<bullet>x) = ((rev pi)\<bullet>a)\<sharp>x"
apply(simp add: fresh_def)
apply(simp add: pt_set_bij1[OF ptb, OF at])
apply(simp add: pt_perm_supp_ineq[OF pta, OF ptb, OF at, OF cp])
done

lemma pt_fresh_right_ineq:  
  fixes  pi :: "'x prm"
  and     x :: "'a"
  and     a :: "'y"
  assumes pta: "pt TYPE('a) TYPE('x)"
  and     ptb: "pt TYPE('y) TYPE('x)"
  and     at:  "at TYPE('x)"
  and     cp:  "cp TYPE('a) TYPE('x) TYPE('y)"
  shows "(pi\<bullet>a)\<sharp>x = a\<sharp>((rev pi)\<bullet>x)"
apply(simp add: fresh_def)
apply(simp add: pt_set_bij1[OF ptb, OF at])
apply(simp add: pt_perm_supp_ineq[OF pta, OF ptb, OF at, OF cp])
done

lemma pt_fresh_bij_ineq:
  fixes  pi :: "'x prm"
  and     x :: "'a"
  and     a :: "'y"
  assumes pta: "pt TYPE('a) TYPE('x)"
  and     ptb: "pt TYPE('y) TYPE('x)"
  and     at:  "at TYPE('x)"
  and     cp:  "cp TYPE('a) TYPE('x) TYPE('y)"
  shows "(pi\<bullet>a)\<sharp>(pi\<bullet>x) = a\<sharp>x"
apply(simp add: pt_fresh_left_ineq[OF pta, OF ptb, OF at, OF cp])
apply(simp add: pt_rev_pi[OF ptb, OF at])
done

lemma pt_fresh_left:  
  fixes  pi :: "'x prm"
  and     x :: "'a"
  and     a :: "'x"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "a\<sharp>(pi\<bullet>x) = ((rev pi)\<bullet>a)\<sharp>x"
apply(rule pt_fresh_left_ineq)
apply(rule pt)
apply(rule at_pt_inst)
apply(rule at)+
apply(rule cp_pt_inst)
apply(rule pt)
apply(rule at)
done

lemma pt_fresh_right:  
  fixes  pi :: "'x prm"
  and     x :: "'a"
  and     a :: "'x"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "(pi\<bullet>a)\<sharp>x = a\<sharp>((rev pi)\<bullet>x)"
apply(rule pt_fresh_right_ineq)
apply(rule pt)
apply(rule at_pt_inst)
apply(rule at)+
apply(rule cp_pt_inst)
apply(rule pt)
apply(rule at)
done

lemma pt_fresh_bij:
  fixes  pi :: "'x prm"
  and     x :: "'a"
  and     a :: "'x"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "(pi\<bullet>a)\<sharp>(pi\<bullet>x) = a\<sharp>x"
apply(rule pt_fresh_bij_ineq)
apply(rule pt)
apply(rule at_pt_inst)
apply(rule at)+
apply(rule cp_pt_inst)
apply(rule pt)
apply(rule at)
done

lemma pt_fresh_bij1:
  fixes  pi :: "'x prm"
  and     x :: "'a"
  and     a :: "'x"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  and     a:  "a\<sharp>x"
  shows "(pi\<bullet>a)\<sharp>(pi\<bullet>x)"
using a by (simp add: pt_fresh_bij[OF pt, OF at])

lemma pt_fresh_bij2:
  fixes  pi :: "'x prm"
  and     x :: "'a"
  and     a :: "'x"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  and     a:  "(pi\<bullet>a)\<sharp>(pi\<bullet>x)"
  shows  "a\<sharp>x"
using a by (simp add: pt_fresh_bij[OF pt, OF at])

lemma pt_fresh_eqvt:
  fixes  pi :: "'x prm"
  and     x :: "'a"
  and     a :: "'x"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "pi\<bullet>(a\<sharp>x) = (pi\<bullet>a)\<sharp>(pi\<bullet>x)"
  by (simp add: perm_bool pt_fresh_bij[OF pt, OF at])

lemma pt_perm_fresh1:
  fixes a :: "'x"
  and   b :: "'x"
  and   x :: "'a"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE ('x)"
  and     a1: "\<not>(a\<sharp>x)"
  and     a2: "b\<sharp>x"
  shows "[(a,b)]\<bullet>x \<noteq> x"
proof
  assume neg: "[(a,b)]\<bullet>x = x"
  from a1 have a1':"a\<in>(supp x)" by (simp add: fresh_def) 
  from a2 have a2':"b\<notin>(supp x)" by (simp add: fresh_def) 
  from a1' a2' have a3: "a\<noteq>b" by force
  from a1' have "([(a,b)]\<bullet>a)\<in>([(a,b)]\<bullet>(supp x))" 
    by (simp only: pt_set_bij[OF at_pt_inst[OF at], OF at])
  hence "b\<in>([(a,b)]\<bullet>(supp x))" by (simp add: at_calc[OF at])
  hence "b\<in>(supp ([(a,b)]\<bullet>x))" by (simp add: pt_perm_supp[OF pt,OF at])
  with a2' neg show False by simp
qed

(* the next two lemmas are needed in the proof *)
(* of the structural induction principle       *)
lemma pt_fresh_aux:
  fixes a::"'x"
  and   b::"'x"
  and   c::"'x"
  and   x::"'a"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE ('x)"
  assumes a1: "c\<noteq>a" and  a2: "a\<sharp>x" and a3: "c\<sharp>x"
  shows "c\<sharp>([(a,b)]\<bullet>x)"
using a1 a2 a3 by (simp_all add: pt_fresh_left[OF pt, OF at] at_calc[OF at])

lemma pt_fresh_aux_ineq:
  fixes pi::"'x prm"
  and   c::"'y"
  and   x::"'a"
  assumes pta: "pt TYPE('a) TYPE('x)"
  and     ptb: "pt TYPE('y) TYPE('x)"
  and     at:  "at TYPE('x)"
  and     cp:  "cp TYPE('a) TYPE('x) TYPE('y)"
  and     dj:  "disjoint TYPE('y) TYPE('x)"
  assumes a: "c\<sharp>x"
  shows "c\<sharp>(pi\<bullet>x)"
using a by (simp add: pt_fresh_left_ineq[OF pta, OF ptb, OF at, OF cp] dj_perm_forget[OF dj])

lemma pt_fresh_eqvt_ineq:
  fixes pi::"'x prm"
  and   c::"'y"
  and   x::"'a"
  assumes pta: "pt TYPE('a) TYPE('x)"
  and     ptb: "pt TYPE('y) TYPE('x)"
  and     at:  "at TYPE('x)"
  and     cp:  "cp TYPE('a) TYPE('x) TYPE('y)"
  and     dj:  "disjoint TYPE('y) TYPE('x)"
  shows "pi\<bullet>(c\<sharp>x) = (pi\<bullet>c)\<sharp>(pi\<bullet>x)"
by (simp add: pt_fresh_left_ineq[OF pta, OF ptb, OF at, OF cp] dj_perm_forget[OF dj] perm_bool)

-- "three helper lemmas for the perm_fresh_fresh-lemma"
lemma comprehension_neg_UNIV: "{b. \<not> P b} = UNIV - {b. P b}"
  by (auto)

lemma infinite_or_neg_infinite:
  assumes h:"infinite (UNIV::'a set)"
  shows "infinite {b::'a. P b} \<or> infinite {b::'a. \<not> P b}"
proof (subst comprehension_neg_UNIV, case_tac "finite {b. P b}")
  assume j:"finite {b::'a. P b}"
  have "infinite ((UNIV::'a set) - {b::'a. P b})"
    using Diff_infinite_finite[OF j h] by auto
  thus "infinite {b::'a. P b} \<or> infinite (UNIV - {b::'a. P b})" ..
next
  assume j:"infinite {b::'a. P b}"
  thus "infinite {b::'a. P b} \<or> infinite (UNIV - {b::'a. P b})" by simp
qed

--"the co-set of a finite set is infinte"
lemma finite_infinite:
  assumes a: "finite {b::'x. P b}"
  and     b: "infinite (UNIV::'x set)"        
  shows "infinite {b. \<not>P b}"
  using a and infinite_or_neg_infinite[OF b] by simp

lemma pt_fresh_fresh:
  fixes   x :: "'a"
  and     a :: "'x"
  and     b :: "'x"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE ('x)"
  and     a1: "a\<sharp>x" and a2: "b\<sharp>x" 
  shows "[(a,b)]\<bullet>x=x"
proof (cases "a=b")
  assume "a=b"
  hence "[(a,b)] \<triangleq> []" by (simp add: at_ds1[OF at])
  hence "[(a,b)]\<bullet>x=([]::'x prm)\<bullet>x" by (rule pt3[OF pt])
  thus ?thesis by (simp only: pt1[OF pt])
next
  assume c2: "a\<noteq>b"
  from a1 have f1: "finite {c. [(a,c)]\<bullet>x \<noteq> x}" by (simp add: fresh_def supp_def)
  from a2 have f2: "finite {c. [(b,c)]\<bullet>x \<noteq> x}" by (simp add: fresh_def supp_def)
  from f1 and f2 have f3: "finite {c. perm [(a,c)] x \<noteq> x \<or> perm [(b,c)] x \<noteq> x}" 
    by (force simp only: Collect_disj_eq)
  have "infinite {c. [(a,c)]\<bullet>x = x \<and> [(b,c)]\<bullet>x = x}" 
    by (simp add: finite_infinite[OF f3,OF at4[OF at], simplified])
  hence "infinite ({c. [(a,c)]\<bullet>x = x \<and> [(b,c)]\<bullet>x = x}-{a,b})" 
    by (force dest: Diff_infinite_finite)
  hence "({c. [(a,c)]\<bullet>x = x \<and> [(b,c)]\<bullet>x = x}-{a,b}) \<noteq> {}" 
    by (auto iff del: finite_Diff_insert Diff_eq_empty_iff)
  hence "\<exists>c. c\<in>({c. [(a,c)]\<bullet>x = x \<and> [(b,c)]\<bullet>x = x}-{a,b})" by (force)
  then obtain c 
    where eq1: "[(a,c)]\<bullet>x = x" 
      and eq2: "[(b,c)]\<bullet>x = x" 
      and ineq: "a\<noteq>c \<and> b\<noteq>c"
    by (force)
  hence "[(a,c)]\<bullet>([(b,c)]\<bullet>([(a,c)]\<bullet>x)) = x" by simp 
  hence eq3: "[(a,c),(b,c),(a,c)]\<bullet>x = x" by (simp add: pt2[OF pt,symmetric])
  from c2 ineq have "[(a,c),(b,c),(a,c)] \<triangleq> [(a,b)]" by (simp add: at_ds3[OF at])
  hence "[(a,c),(b,c),(a,c)]\<bullet>x = [(a,b)]\<bullet>x" by (rule pt3[OF pt])
  thus ?thesis using eq3 by simp
qed

lemma pt_perm_compose:
  fixes pi1 :: "'x prm"
  and   pi2 :: "'x prm"
  and   x  :: "'a"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "pi2\<bullet>(pi1\<bullet>x) = (pi2\<bullet>pi1)\<bullet>(pi2\<bullet>x)" 
proof -
  have "(pi2@pi1) \<triangleq> ((pi2\<bullet>pi1)@pi2)" by (rule at_ds8)
  hence "(pi2@pi1)\<bullet>x = ((pi2\<bullet>pi1)@pi2)\<bullet>x" by (rule pt3[OF pt])
  thus ?thesis by (simp add: pt2[OF pt])
qed

lemma pt_perm_compose':
  fixes pi1 :: "'x prm"
  and   pi2 :: "'x prm"
  and   x  :: "'a"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "(pi2\<bullet>pi1)\<bullet>x = pi2\<bullet>(pi1\<bullet>((rev pi2)\<bullet>x))" 
proof -
  have "pi2\<bullet>(pi1\<bullet>((rev pi2)\<bullet>x)) = (pi2\<bullet>pi1)\<bullet>(pi2\<bullet>((rev pi2)\<bullet>x))"
    by (rule pt_perm_compose[OF pt, OF at])
  also have "\<dots> = (pi2\<bullet>pi1)\<bullet>x" by (simp add: pt_pi_rev[OF pt, OF at])
  finally have "pi2\<bullet>(pi1\<bullet>((rev pi2)\<bullet>x)) = (pi2\<bullet>pi1)\<bullet>x" by simp
  thus ?thesis by simp
qed

lemma pt_perm_compose_rev:
  fixes pi1 :: "'x prm"
  and   pi2 :: "'x prm"
  and   x  :: "'a"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "(rev pi2)\<bullet>((rev pi1)\<bullet>x) = (rev pi1)\<bullet>(rev (pi1\<bullet>pi2)\<bullet>x)" 
proof -
  have "((rev pi2)@(rev pi1)) \<triangleq> ((rev pi1)@(rev (pi1\<bullet>pi2)))" by (rule at_ds9[OF at])
  hence "((rev pi2)@(rev pi1))\<bullet>x = ((rev pi1)@(rev (pi1\<bullet>pi2)))\<bullet>x" by (rule pt3[OF pt])
  thus ?thesis by (simp add: pt2[OF pt])
qed

section {* equivaraince for some connectives *}

lemma pt_all_eqvt:
  fixes  pi :: "'x prm"
  and     x :: "'a"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "pi\<bullet>(\<forall>(x::'a). P x) = (\<forall>(x::'a). (pi\<bullet>P) x)"
apply(auto simp add: perm_bool perm_fun_def)
apply(drule_tac x="pi\<bullet>x" in spec)
apply(simp add: pt_rev_pi[OF pt, OF at])
done

lemma pt_ex_eqvt:
  fixes  pi :: "'x prm"
  and     x :: "'a"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "pi\<bullet>(\<exists>(x::'a). P x) = (\<exists>(x::'a). (pi\<bullet>P) x)"
apply(auto simp add: perm_bool perm_fun_def)
apply(rule_tac x="pi\<bullet>x" in exI) 
apply(simp add: pt_rev_pi[OF pt, OF at])
done

section {* facts about supports *}
(*==============================*)

lemma supports_subset:
  fixes x  :: "'a"
  and   S1 :: "'x set"
  and   S2 :: "'x set"
  assumes  a: "S1 supports x"
  and      b: "S1 \<subseteq> S2"
  shows "S2 supports x"
  using a b
  by (force simp add: "op supports_def")

lemma supp_is_subset:
  fixes S :: "'x set"
  and   x :: "'a"
  assumes a1: "S supports x"
  and     a2: "finite S"
  shows "(supp x)\<subseteq>S"
proof (rule ccontr)
  assume "\<not>(supp x \<subseteq> S)"
  hence "\<exists>a. a\<in>(supp x) \<and> a\<notin>S" by force
  then obtain a where b1: "a\<in>supp x" and b2: "a\<notin>S" by force
  from a1 b2 have "\<forall>b. (b\<notin>S \<longrightarrow> ([(a,b)]\<bullet>x = x))" by (unfold "op supports_def", force)
  hence "{b. [(a,b)]\<bullet>x \<noteq> x}\<subseteq>S" by force
  with a2 have "finite {b. [(a,b)]\<bullet>x \<noteq> x}" by (simp add: finite_subset)
  hence "a\<notin>(supp x)" by (unfold supp_def, auto)
  with b1 show False by simp
qed

lemma supp_supports:
  fixes x :: "'a"
  assumes  pt: "pt TYPE('a) TYPE('x)"
  and      at: "at TYPE ('x)"
  shows "((supp x)::'x set) supports x"
proof (unfold "op supports_def", intro strip)
  fix a b
  assume "(a::'x)\<notin>(supp x) \<and> (b::'x)\<notin>(supp x)"
  hence "a\<sharp>x" and "b\<sharp>x" by (auto simp add: fresh_def)
  thus "[(a,b)]\<bullet>x = x" by (rule pt_fresh_fresh[OF pt, OF at])
qed

lemma supports_finite:
  fixes S :: "'x set"
  and   x :: "'a"
  assumes a1: "S supports x"
  and     a2: "finite S"
  shows "finite ((supp x)::'x set)"
proof -
  have "(supp x)\<subseteq>S" using a1 a2 by (rule supp_is_subset)
  thus ?thesis using a2 by (simp add: finite_subset)
qed
  
lemma supp_is_inter:
  fixes  x :: "'a"
  assumes  pt: "pt TYPE('a) TYPE('x)"
  and      at: "at TYPE ('x)"
  and      fs: "fs TYPE('a) TYPE('x)"
  shows "((supp x)::'x set) = (\<Inter> {S. finite S \<and> S supports x})"
proof (rule equalityI)
  show "((supp x)::'x set) \<subseteq> (\<Inter> {S. finite S \<and> S supports x})"
  proof (clarify)
    fix S c
    assume b: "c\<in>((supp x)::'x set)" and "finite (S::'x set)" and "S supports x"
    hence  "((supp x)::'x set)\<subseteq>S" by (simp add: supp_is_subset) 
    with b show "c\<in>S" by force
  qed
next
  show "(\<Inter> {S. finite S \<and> S supports x}) \<subseteq> ((supp x)::'x set)"
  proof (clarify, simp)
    fix c
    assume d: "\<forall>(S::'x set). finite S \<and> S supports x \<longrightarrow> c\<in>S"
    have "((supp x)::'x set) supports x" by (rule supp_supports[OF pt, OF at])
    with d fs1[OF fs] show "c\<in>supp x" by force
  qed
qed
    
lemma supp_is_least_supports:
  fixes S :: "'x set"
  and   x :: "'a"
  assumes  pt: "pt TYPE('a) TYPE('x)"
  and      at: "at TYPE ('x)"
  and      a1: "S supports x"
  and      a2: "finite S"
  and      a3: "\<forall>S'. (S' supports x) \<longrightarrow> S\<subseteq>S'"
  shows "S = (supp x)"
proof (rule equalityI)
  show "((supp x)::'x set)\<subseteq>S" using a1 a2 by (rule supp_is_subset)
next
  have "((supp x)::'x set) supports x" by (rule supp_supports[OF pt, OF at])
  with a3 show "S\<subseteq>supp x" by force
qed

lemma supports_set:
  fixes S :: "'x set"
  and   X :: "'a set"
  assumes  pt: "pt TYPE('a) TYPE('x)"
  and      at: "at TYPE ('x)"
  and      a: "\<forall>x\<in>X. (\<forall>(a::'x) (b::'x). a\<notin>S\<and>b\<notin>S \<longrightarrow> ([(a,b)]\<bullet>x)\<in>X)"
  shows  "S supports X"
using a
apply(auto simp add: "op supports_def")
apply(simp add: pt_set_bij1a[OF pt, OF at])
apply(force simp add: pt_swap_bij[OF pt, OF at])
apply(simp add: pt_set_bij1a[OF pt, OF at])
done

lemma supports_fresh:
  fixes S :: "'x set"
  and   a :: "'x"
  and   x :: "'a"
  assumes a1: "S supports x"
  and     a2: "finite S"
  and     a3: "a\<notin>S"
  shows "a\<sharp>x"
proof (simp add: fresh_def)
  have "(supp x)\<subseteq>S" using a1 a2 by (rule supp_is_subset)
  thus "a\<notin>(supp x)" using a3 by force
qed

lemma at_fin_set_supports:
  fixes X::"'x set"
  assumes at: "at TYPE('x)"
  shows "X supports X"
proof -
  have "\<forall>a b. a\<notin>X \<and> b\<notin>X \<longrightarrow> [(a,b)]\<bullet>X = X" by (auto simp add: perm_set_def at_calc[OF at])
  then show ?thesis by (simp add: "op supports_def")
qed

lemma infinite_Collection:
  assumes a1:"infinite X"
  and     a2:"\<forall>b\<in>X. P(b)"
  shows "infinite {b\<in>X. P(b)}"
  using a1 a2 
  apply auto
  apply (subgoal_tac "infinite (X - {b\<in>X. P b})")
  apply (simp add: set_diff_def)
  apply (simp add: Diff_infinite_finite)
  done

lemma at_fin_set_supp:
  fixes X::"'x set" 
  assumes at: "at TYPE('x)"
  and     fs: "finite X"
  shows "(supp X) = X"
proof (rule subset_antisym)
  show "(supp X) \<subseteq> X" using at_fin_set_supports[OF at] using fs by (simp add: supp_is_subset)
next
  have inf: "infinite (UNIV-X)" using at4[OF at] fs by (auto simp add: Diff_infinite_finite)
  { fix a::"'x"
    assume asm: "a\<in>X"
    hence "\<forall>b\<in>(UNIV-X). [(a,b)]\<bullet>X\<noteq>X" by (auto simp add: perm_set_def at_calc[OF at])
    with inf have "infinite {b\<in>(UNIV-X). [(a,b)]\<bullet>X\<noteq>X}" by (rule infinite_Collection)
    hence "infinite {b. [(a,b)]\<bullet>X\<noteq>X}" by (rule_tac infinite_super, auto)
    hence "a\<in>(supp X)" by (simp add: supp_def)
  }
  then show "X\<subseteq>(supp X)" by blast
qed

section {* Permutations acting on Functions *}
(*==========================================*)

lemma pt_fun_app_eq:
  fixes f  :: "'a\<Rightarrow>'b"
  and   x  :: "'a"
  and   pi :: "'x prm"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "pi\<bullet>(f x) = (pi\<bullet>f)(pi\<bullet>x)"
  by (simp add: perm_fun_def pt_rev_pi[OF pt, OF at])


--"sometimes pt_fun_app_eq does too much; this lemma 'corrects it'"
lemma pt_perm:
  fixes x  :: "'a"
  and   pi1 :: "'x prm"
  and   pi2 :: "'x prm"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE ('x)"
  shows "(pi1\<bullet>perm pi2)(pi1\<bullet>x) = pi1\<bullet>(pi2\<bullet>x)" 
  by (simp add: pt_fun_app_eq[OF pt, OF at])


lemma pt_fun_eq:
  fixes f  :: "'a\<Rightarrow>'b"
  and   pi :: "'x prm"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "(pi\<bullet>f = f) = (\<forall> x. pi\<bullet>(f x) = f (pi\<bullet>x))" (is "?LHS = ?RHS")
proof
  assume a: "?LHS"
  show "?RHS"
  proof
    fix x
    have "pi\<bullet>(f x) = (pi\<bullet>f)(pi\<bullet>x)" by (simp add: pt_fun_app_eq[OF pt, OF at])
    also have "\<dots> = f (pi\<bullet>x)" using a by simp
    finally show "pi\<bullet>(f x) = f (pi\<bullet>x)" by simp
  qed
next
  assume b: "?RHS"
  show "?LHS"
  proof (rule ccontr)
    assume "(pi\<bullet>f) \<noteq> f"
    hence "\<exists>x. (pi\<bullet>f) x \<noteq> f x" by (simp add: expand_fun_eq)
    then obtain x where b1: "(pi\<bullet>f) x \<noteq> f x" by force
    from b have "pi\<bullet>(f ((rev pi)\<bullet>x)) = f (pi\<bullet>((rev pi)\<bullet>x))" by force
    hence "(pi\<bullet>f)(pi\<bullet>((rev pi)\<bullet>x)) = f (pi\<bullet>((rev pi)\<bullet>x))" 
      by (simp add: pt_fun_app_eq[OF pt, OF at])
    hence "(pi\<bullet>f) x = f x" by (simp add: pt_pi_rev[OF pt, OF at])
    with b1 show "False" by simp
  qed
qed

-- "two helper lemmas for the equivariance of functions"
lemma pt_swap_eq_aux:
  fixes   y :: "'a"
  and    pi :: "'x prm"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     a: "\<forall>(a::'x) (b::'x). [(a,b)]\<bullet>y = y"
  shows "pi\<bullet>y = y"
proof(induct pi)
    case Nil show ?case by (simp add: pt1[OF pt])
  next
    case (Cons x xs)
    have "\<exists>a b. x=(a,b)" by force
    then obtain a b where p: "x=(a,b)" by force
    assume i: "xs\<bullet>y = y"
    have "x#xs = [x]@xs" by simp
    hence "(x#xs)\<bullet>y = ([x]@xs)\<bullet>y" by simp
    hence "(x#xs)\<bullet>y = [x]\<bullet>(xs\<bullet>y)" by (simp only: pt2[OF pt])
    thus ?case using a i p by force
  qed

lemma pt_swap_eq:
  fixes   y :: "'a"
  assumes pt: "pt TYPE('a) TYPE('x)"
  shows "(\<forall>(a::'x) (b::'x). [(a,b)]\<bullet>y = y) = (\<forall>pi::'x prm. pi\<bullet>y = y)"
  by (force intro: pt_swap_eq_aux[OF pt])

lemma pt_eqvt_fun1a:
  fixes f     :: "'a\<Rightarrow>'b"
  assumes pta: "pt TYPE('a) TYPE('x)"
  and     ptb: "pt TYPE('b) TYPE('x)"
  and     at:  "at TYPE('x)"
  and     a:   "((supp f)::'x set)={}"
  shows "\<forall>(pi::'x prm). pi\<bullet>f = f" 
proof (intro strip)
  fix pi
  have "\<forall>a b. a\<notin>((supp f)::'x set) \<and> b\<notin>((supp f)::'x set) \<longrightarrow> (([(a,b)]\<bullet>f) = f)" 
    by (intro strip, fold fresh_def, 
      simp add: pt_fresh_fresh[OF pt_fun_inst[OF pta, OF ptb, OF at],OF at])
  with a have "\<forall>(a::'x) (b::'x). ([(a,b)]\<bullet>f) = f" by force
  hence "\<forall>(pi::'x prm). pi\<bullet>f = f" 
    by (simp add: pt_swap_eq[OF pt_fun_inst[OF pta, OF ptb, OF at]])
  thus "(pi::'x prm)\<bullet>f = f" by simp
qed

lemma pt_eqvt_fun1b:
  fixes f     :: "'a\<Rightarrow>'b"
  assumes a: "\<forall>(pi::'x prm). pi\<bullet>f = f"
  shows "((supp f)::'x set)={}"
using a by (simp add: supp_def)

lemma pt_eqvt_fun1:
  fixes f     :: "'a\<Rightarrow>'b"
  assumes pta: "pt TYPE('a) TYPE('x)"
  and     ptb: "pt TYPE('b) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "(((supp f)::'x set)={}) = (\<forall>(pi::'x prm). pi\<bullet>f = f)" (is "?LHS = ?RHS")
by (rule iffI, simp add: pt_eqvt_fun1a[OF pta, OF ptb, OF at], simp add: pt_eqvt_fun1b)

lemma pt_eqvt_fun2a:
  fixes f     :: "'a\<Rightarrow>'b"
  assumes pta: "pt TYPE('a) TYPE('x)"
  and     ptb: "pt TYPE('b) TYPE('x)"
  and     at: "at TYPE('x)"
  assumes a: "((supp f)::'x set)={}"
  shows "\<forall>(pi::'x prm) (x::'a). pi\<bullet>(f x) = f(pi\<bullet>x)" 
proof (intro strip)
  fix pi x
  from a have b: "\<forall>(pi::'x prm). pi\<bullet>f = f" by (simp add: pt_eqvt_fun1[OF pta, OF ptb, OF at]) 
  have "(pi::'x prm)\<bullet>(f x) = (pi\<bullet>f)(pi\<bullet>x)" by (simp add: pt_fun_app_eq[OF pta, OF at]) 
  with b show "(pi::'x prm)\<bullet>(f x) = f (pi\<bullet>x)" by force 
qed

lemma pt_eqvt_fun2b:
  fixes f     :: "'a\<Rightarrow>'b"
  assumes pt1: "pt TYPE('a) TYPE('x)"
  and     pt2: "pt TYPE('b) TYPE('x)"
  and     at: "at TYPE('x)"
  assumes a: "\<forall>(pi::'x prm) (x::'a). pi\<bullet>(f x) = f(pi\<bullet>x)"
  shows "((supp f)::'x set)={}"
proof -
  from a have "\<forall>(pi::'x prm). pi\<bullet>f = f" by (simp add: pt_fun_eq[OF pt1, OF at, symmetric])
  thus ?thesis by (simp add: supp_def)
qed

lemma pt_eqvt_fun2:
  fixes f     :: "'a\<Rightarrow>'b"
  assumes pta: "pt TYPE('a) TYPE('x)"
  and     ptb: "pt TYPE('b) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "(((supp f)::'x set)={}) = (\<forall>(pi::'x prm) (x::'a). pi\<bullet>(f x) = f(pi\<bullet>x))" 
by (rule iffI, 
    simp add: pt_eqvt_fun2a[OF pta, OF ptb, OF at], 
    simp add: pt_eqvt_fun2b[OF pta, OF ptb, OF at])

lemma pt_supp_fun_subset:
  fixes f :: "'a\<Rightarrow>'b"
  assumes pta: "pt TYPE('a) TYPE('x)"
  and     ptb: "pt TYPE('b) TYPE('x)"
  and     at: "at TYPE('x)" 
  and     f1: "finite ((supp f)::'x set)"
  and     f2: "finite ((supp x)::'x set)"
  shows "supp (f x) \<subseteq> (((supp f)\<union>(supp x))::'x set)"
proof -
  have s1: "((supp f)\<union>((supp x)::'x set)) supports (f x)"
  proof (simp add: "op supports_def", fold fresh_def, auto)
    fix a::"'x" and b::"'x"
    assume "a\<sharp>f" and "b\<sharp>f"
    hence a1: "[(a,b)]\<bullet>f = f" 
      by (rule pt_fresh_fresh[OF pt_fun_inst[OF pta, OF ptb, OF at], OF at])
    assume "a\<sharp>x" and "b\<sharp>x"
    hence a2: "[(a,b)]\<bullet>x = x" by (rule pt_fresh_fresh[OF pta, OF at])
    from a1 a2 show "[(a,b)]\<bullet>(f x) = (f x)" by (simp add: pt_fun_app_eq[OF pta, OF at])
  qed
  from f1 f2 have "finite ((supp f)\<union>((supp x)::'x set))" by force
  with s1 show ?thesis by (rule supp_is_subset)
qed
      
lemma pt_empty_supp_fun_subset:
  fixes f :: "'a\<Rightarrow>'b"
  assumes pta: "pt TYPE('a) TYPE('x)"
  and     ptb: "pt TYPE('b) TYPE('x)"
  and     at:  "at TYPE('x)" 
  and     e:   "(supp f)=({}::'x set)"
  shows "supp (f x) \<subseteq> ((supp x)::'x set)"
proof (unfold supp_def, auto)
  fix a::"'x"
  assume a1: "finite {b. [(a, b)]\<bullet>x \<noteq> x}"
  assume "infinite {b. [(a, b)]\<bullet>(f x) \<noteq> f x}"
  hence a2: "infinite {b. f ([(a, b)]\<bullet>x) \<noteq> f x}" using e
    by (simp add: pt_eqvt_fun2[OF pta, OF ptb, OF at])
  have a3: "{b. f ([(a,b)]\<bullet>x) \<noteq> f x}\<subseteq>{b. [(a,b)]\<bullet>x \<noteq> x}" by force
  from a1 a2 a3 show False by (force dest: finite_subset)
qed

section {* Facts about the support of finite sets of finitely supported things *}
(*=============================================================================*)

constdefs
  X_to_Un_supp :: "('a set) \<Rightarrow> 'x set"
  "X_to_Un_supp X \<equiv> \<Union>x\<in>X. ((supp x)::'x set)"

lemma UNION_f_eqvt:
  fixes X::"('a set)"
  and   f::"'a \<Rightarrow> 'x set"
  and   pi::"'x prm"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "pi\<bullet>(\<Union>x\<in>X. f x) = (\<Union>x\<in>(pi\<bullet>X). (pi\<bullet>f) x)"
proof -
  have pt_x: "pt TYPE('x) TYPE('x)" by (force intro: at_pt_inst at)
  show ?thesis
  proof (rule equalityI)
    case goal1
    show "pi\<bullet>(\<Union>x\<in>X. f x) \<subseteq> (\<Union>x\<in>(pi\<bullet>X). (pi\<bullet>f) x)"
      apply(auto simp add: perm_set_def)
      apply(rule_tac x="pi\<bullet>xa" in exI)
      apply(rule conjI)
      apply(rule_tac x="xa" in exI)
      apply(simp)
      apply(subgoal_tac "(pi\<bullet>f) (pi\<bullet>xa) = pi\<bullet>(f xa)")(*A*)
      apply(simp)
      apply(rule pt_set_bij2[OF pt_x, OF at])
      apply(assumption)
      (*A*)
      apply(rule sym)
      apply(rule pt_fun_app_eq[OF pt, OF at])
      done
  next
    case goal2
    show "(\<Union>x\<in>(pi\<bullet>X). (pi\<bullet>f) x) \<subseteq> pi\<bullet>(\<Union>x\<in>X. f x)"
      apply(auto simp add: perm_set_def)
      apply(rule_tac x="(rev pi)\<bullet>x" in exI)
      apply(rule conjI)
      apply(simp add: pt_pi_rev[OF pt_x, OF at])
      apply(rule_tac x="a" in bexI)
      apply(simp add: pt_set_bij1[OF pt_x, OF at])
      apply(simp add: pt_fun_app_eq[OF pt, OF at])
      apply(assumption)
      done
  qed
qed

lemma X_to_Un_supp_eqvt:
  fixes X::"('a set)"
  and   pi::"'x prm"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "pi\<bullet>(X_to_Un_supp X) = ((X_to_Un_supp (pi\<bullet>X))::'x set)"
  apply(simp add: X_to_Un_supp_def)
  apply(simp add: UNION_f_eqvt[OF pt, OF at] perm_fun_def)
  apply(simp add: pt_perm_supp[OF pt, OF at])
  apply(simp add: pt_pi_rev[OF pt, OF at])
  done

lemma Union_supports_set:
  fixes X::"('a set)"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "(\<Union>x\<in>X. ((supp x)::'x set)) supports X"
  apply(simp add: "op supports_def" fresh_def[symmetric])
  apply(rule allI)+
  apply(rule impI)
  apply(erule conjE)
  apply(simp add: perm_set_def)
  apply(auto)
  apply(subgoal_tac "[(a,b)]\<bullet>aa = aa")(*A*)
  apply(simp)
  apply(rule pt_fresh_fresh[OF pt, OF at])
  apply(force)
  apply(force)
  apply(rule_tac x="x" in exI)
  apply(simp)
  apply(rule sym)
  apply(rule pt_fresh_fresh[OF pt, OF at])
  apply(force)+
  done

lemma Union_of_fin_supp_sets:
  fixes X::"('a set)"
  assumes fs: "fs TYPE('a) TYPE('x)" 
  and     fi: "finite X"   
  shows "finite (\<Union>x\<in>X. ((supp x)::'x set))"
using fi by (induct, auto simp add: fs1[OF fs])

lemma Union_included_in_supp:
  fixes X::"('a set)"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  and     fs: "fs TYPE('a) TYPE('x)" 
  and     fi: "finite X"
  shows "(\<Union>x\<in>X. ((supp x)::'x set)) \<subseteq> supp X"
proof -
  have "supp ((X_to_Un_supp X)::'x set) \<subseteq> ((supp X)::'x set)"  
    apply(rule pt_empty_supp_fun_subset)
    apply(force intro: pt_set_inst at_pt_inst pt at)+
    apply(rule pt_eqvt_fun2b)
    apply(force intro: pt_set_inst at_pt_inst pt at)+
    apply(rule allI)+
    apply(rule X_to_Un_supp_eqvt[OF pt, OF at])
    done
  hence "supp (\<Union>x\<in>X. ((supp x)::'x set)) \<subseteq> ((supp X)::'x set)" by (simp add: X_to_Un_supp_def)
  moreover
  have "supp (\<Union>x\<in>X. ((supp x)::'x set)) = (\<Union>x\<in>X. ((supp x)::'x set))"
    apply(rule at_fin_set_supp[OF at])
    apply(rule Union_of_fin_supp_sets[OF fs, OF fi])
    done
  ultimately show ?thesis by force
qed

lemma supp_of_fin_sets:
  fixes X::"('a set)"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  and     fs: "fs TYPE('a) TYPE('x)" 
  and     fi: "finite X"
  shows "(supp X) = (\<Union>x\<in>X. ((supp x)::'x set))"
apply(rule equalityI)
apply(rule supp_is_subset)
apply(rule Union_supports_set[OF pt, OF at])
apply(rule Union_of_fin_supp_sets[OF fs, OF fi])
apply(rule Union_included_in_supp[OF pt, OF at, OF fs, OF fi])
done

lemma supp_fin_union:
  fixes X::"('a set)"
  and   Y::"('a set)"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  and     fs: "fs TYPE('a) TYPE('x)" 
  and     f1: "finite X"
  and     f2: "finite Y"
  shows "(supp (X\<union>Y)) = (supp X)\<union>((supp Y)::'x set)"
using f1 f2 by (force simp add: supp_of_fin_sets[OF pt, OF at, OF fs])

lemma supp_fin_insert:
  fixes X::"('a set)"
  and   x::"'a"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  and     fs: "fs TYPE('a) TYPE('x)" 
  and     f:  "finite X"
  shows "(supp (insert x X)) = (supp x)\<union>((supp X)::'x set)"
proof -
  have "(supp (insert x X)) = ((supp ({x}\<union>(X::'a set)))::'x set)" by simp
  also have "\<dots> = (supp {x})\<union>(supp X)"
    by (rule supp_fin_union[OF pt, OF at, OF fs], simp_all add: f)
  finally show "(supp (insert x X)) = (supp x)\<union>((supp X)::'x set)" 
    by (simp add: supp_singleton)
qed

lemma fresh_fin_union:
  fixes X::"('a set)"
  and   Y::"('a set)"
  and   a::"'x"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  and     fs: "fs TYPE('a) TYPE('x)" 
  and     f1: "finite X"
  and     f2: "finite Y"
  shows "a\<sharp>(X\<union>Y) = (a\<sharp>X \<and> a\<sharp>Y)"
apply(simp add: fresh_def)
apply(simp add: supp_fin_union[OF pt, OF at, OF fs, OF f1, OF f2])
done

lemma fresh_fin_insert:
  fixes X::"('a set)"
  and   x::"'a"
  and   a::"'x"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  and     fs: "fs TYPE('a) TYPE('x)" 
  and     f:  "finite X"
  shows "a\<sharp>(insert x X) = (a\<sharp>x \<and> a\<sharp>X)"
apply(simp add: fresh_def)
apply(simp add: supp_fin_insert[OF pt, OF at, OF fs, OF f])
done

lemma fresh_fin_insert1:
  fixes X::"('a set)"
  and   x::"'a"
  and   a::"'x"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  and     fs: "fs TYPE('a) TYPE('x)" 
  and     f:  "finite X"
  and     a1:  "a\<sharp>x"
  and     a2:  "a\<sharp>X"
  shows "a\<sharp>(insert x X)"
using a1 a2
apply(simp add: fresh_fin_insert[OF pt, OF at, OF fs, OF f])
done

lemma pt_set_eqvt:
  fixes pi :: "'x prm"
  and   xs :: "'a list"
  assumes pt: "pt TYPE('a) TYPE('x)"
  shows "pi\<bullet>(set xs) = set (pi\<bullet>xs)"
by (induct xs, auto simp add: perm_set_def pt1[OF pt])

lemma pt_list_set_supp:
  fixes xs :: "'a list"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  and     fs: "fs TYPE('a) TYPE('x)"
  shows "supp (set xs) = ((supp xs)::'x set)"
proof -
  have "supp (set xs) = (\<Union>x\<in>(set xs). ((supp x)::'x set))"
    by (rule supp_of_fin_sets[OF pt, OF at, OF fs], rule finite_set)
  also have "(\<Union>x\<in>(set xs). ((supp x)::'x set)) = (supp xs)"
  proof(induct xs)
    case Nil show ?case by (simp add: supp_list_nil)
  next
    case (Cons h t) thus ?case by (simp add: supp_list_cons)
  qed
  finally show ?thesis by simp
qed
    
lemma pt_list_set_fresh:
  fixes a :: "'x"
  and   xs :: "'a list"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  and     fs: "fs TYPE('a) TYPE('x)"
  and     a: "a\<sharp>xs"
  shows "a\<sharp>(set xs) = a\<sharp>xs"
by (simp add: fresh_def pt_list_set_supp[OF pt, OF at, OF fs])
 
section {* composition instances *}
(* ============================= *)

lemma cp_list_inst:
  assumes c1: "cp TYPE ('a) TYPE('x) TYPE('y)"
  shows "cp TYPE ('a list) TYPE('x) TYPE('y)"
using c1
apply(simp add: cp_def)
apply(auto)
apply(induct_tac x)
apply(auto)
done

lemma cp_set_inst:
  assumes c1: "cp TYPE ('a) TYPE('x) TYPE('y)"
  shows "cp TYPE ('a set) TYPE('x) TYPE('y)"
using c1
apply(simp add: cp_def)
apply(auto)
apply(auto simp add: perm_set_def)
apply(rule_tac x="pi2\<bullet>aa" in exI)
apply(auto)
done

lemma cp_option_inst:
  assumes c1: "cp TYPE ('a) TYPE('x) TYPE('y)"
  shows "cp TYPE ('a option) TYPE('x) TYPE('y)"
using c1
apply(simp add: cp_def)
apply(auto)
apply(case_tac x)
apply(auto)
done

lemma cp_noption_inst:
  assumes c1: "cp TYPE ('a) TYPE('x) TYPE('y)"
  shows "cp TYPE ('a noption) TYPE('x) TYPE('y)"
using c1
apply(simp add: cp_def)
apply(auto)
apply(case_tac x)
apply(auto)
done

lemma cp_unit_inst:
  shows "cp TYPE (unit) TYPE('x) TYPE('y)"
apply(simp add: cp_def)
done

lemma cp_bool_inst:
  shows "cp TYPE (bool) TYPE('x) TYPE('y)"
apply(simp add: cp_def)
apply(rule allI)+
apply(induct_tac x)
apply(simp_all)
done

lemma cp_prod_inst:
  assumes c1: "cp TYPE ('a) TYPE('x) TYPE('y)"
  and     c2: "cp TYPE ('b) TYPE('x) TYPE('y)"
  shows "cp TYPE ('a\<times>'b) TYPE('x) TYPE('y)"
using c1 c2
apply(simp add: cp_def)
done

lemma cp_fun_inst:
  assumes c1: "cp TYPE ('a) TYPE('x) TYPE('y)"
  and     c2: "cp TYPE ('b) TYPE('x) TYPE('y)"
  and     pt: "pt TYPE ('y) TYPE('x)"
  and     at: "at TYPE ('x)"
  shows "cp TYPE ('a\<Rightarrow>'b) TYPE('x) TYPE('y)"
using c1 c2
apply(auto simp add: cp_def perm_fun_def expand_fun_eq)
apply(simp add: rev_eqvt[symmetric])
apply(simp add: pt_rev_pi[OF pt_list_inst[OF pt_prod_inst[OF pt, OF pt]], OF at])
done


section {* Andy's freshness lemma *}
(*================================*)

lemma freshness_lemma:
  fixes h :: "'x\<Rightarrow>'a"
  assumes pta: "pt TYPE('a) TYPE('x)"
  and     at:  "at TYPE('x)" 
  and     f1:  "finite ((supp h)::'x set)"
  and     a: "\<exists>a::'x. a\<sharp>(h,h a)"
  shows  "\<exists>fr::'a. \<forall>a::'x. a\<sharp>h \<longrightarrow> (h a) = fr"
proof -
  have ptb: "pt TYPE('x) TYPE('x)" by (simp add: at_pt_inst[OF at]) 
  have ptc: "pt TYPE('x\<Rightarrow>'a) TYPE('x)" by (simp add: pt_fun_inst[OF ptb, OF pta, OF at]) 
  from a obtain a0 where a1: "a0\<sharp>h" and a2: "a0\<sharp>(h a0)" by (force simp add: fresh_prod)
  show ?thesis
  proof
    let ?fr = "h (a0::'x)"
    show "\<forall>(a::'x). (a\<sharp>h \<longrightarrow> ((h a) = ?fr))" 
    proof (intro strip)
      fix a
      assume a3: "(a::'x)\<sharp>h"
      show "h (a::'x) = h a0"
      proof (cases "a=a0")
	case True thus "h (a::'x) = h a0" by simp
      next
	case False 
	assume "a\<noteq>a0"
	hence c1: "a\<notin>((supp a0)::'x set)" by  (simp add: fresh_def[symmetric] at_fresh[OF at])
	have c2: "a\<notin>((supp h)::'x set)" using a3 by (simp add: fresh_def)
	from c1 c2 have c3: "a\<notin>((supp h)\<union>((supp a0)::'x set))" by force
	have f2: "finite ((supp a0)::'x set)" by (simp add: at_supp[OF at])
	from f1 f2 have "((supp (h a0))::'x set)\<subseteq>((supp h)\<union>(supp a0))"
	  by (simp add: pt_supp_fun_subset[OF ptb, OF pta, OF at])
	hence "a\<notin>((supp (h a0))::'x set)" using c3 by force
	hence "a\<sharp>(h a0)" by (simp add: fresh_def) 
	with a2 have d1: "[(a0,a)]\<bullet>(h a0) = (h a0)" by (rule pt_fresh_fresh[OF pta, OF at])
	from a1 a3 have d2: "[(a0,a)]\<bullet>h = h" by (rule pt_fresh_fresh[OF ptc, OF at])
	from d1 have "h a0 = [(a0,a)]\<bullet>(h a0)" by simp
	also have "\<dots>= ([(a0,a)]\<bullet>h)([(a0,a)]\<bullet>a0)" by (simp add: pt_fun_app_eq[OF ptb, OF at])
	also have "\<dots> = h ([(a0,a)]\<bullet>a0)" using d2 by simp
	also have "\<dots> = h a" by (simp add: at_calc[OF at])
	finally show "h a = h a0" by simp
      qed
    qed
  qed
qed
	    
lemma freshness_lemma_unique:
  fixes h :: "'x\<Rightarrow>'a"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)" 
  and     f1: "finite ((supp h)::'x set)"
  and     a: "\<exists>(a::'x). a\<sharp>(h,h a)"
  shows  "\<exists>!(fr::'a). \<forall>(a::'x). a\<sharp>h \<longrightarrow> (h a) = fr"
proof (rule ex_ex1I)
  from pt at f1 a show "\<exists>fr::'a. \<forall>a::'x. a\<sharp>h \<longrightarrow> h a = fr" by (simp add: freshness_lemma)
next
  fix fr1 fr2
  assume b1: "\<forall>a::'x. a\<sharp>h \<longrightarrow> h a = fr1"
  assume b2: "\<forall>a::'x. a\<sharp>h \<longrightarrow> h a = fr2"
  from a obtain a where "(a::'x)\<sharp>h" by (force simp add: fresh_prod) 
  with b1 b2 have "h a = fr1 \<and> h a = fr2" by force
  thus "fr1 = fr2" by force
qed

-- "packaging the freshness lemma into a function"
constdefs
  fresh_fun :: "('x\<Rightarrow>'a)\<Rightarrow>'a"
  "fresh_fun (h) \<equiv> THE fr. (\<forall>(a::'x). a\<sharp>h \<longrightarrow> (h a) = fr)"

lemma fresh_fun_app:
  fixes h :: "'x\<Rightarrow>'a"
  and   a :: "'x"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)" 
  and     f1: "finite ((supp h)::'x set)"
  and     a: "\<exists>(a::'x). a\<sharp>(h,h a)"
  and     b: "a\<sharp>h"
  shows "(fresh_fun h) = (h a)"
proof (unfold fresh_fun_def, rule the_equality)
  show "\<forall>(a'::'x). a'\<sharp>h \<longrightarrow> h a' = h a"
  proof (intro strip)
    fix a'::"'x"
    assume c: "a'\<sharp>h"
    from pt at f1 a have "\<exists>(fr::'a). \<forall>(a::'x). a\<sharp>h \<longrightarrow> (h a) = fr" by (rule freshness_lemma)
    with b c show "h a' = h a" by force
  qed
next
  fix fr::"'a"
  assume "\<forall>a. a\<sharp>h \<longrightarrow> h a = fr"
  with b show "fr = h a" by force
qed

lemma fresh_fun_equiv_ineq:
  fixes h :: "'y\<Rightarrow>'a"
  and   pi:: "'x prm"
  assumes pta: "pt TYPE('a) TYPE('x)"
  and     ptb: "pt TYPE('y) TYPE('x)"
  and     ptb':"pt TYPE('a) TYPE('y)"
  and     at:  "at TYPE('x)" 
  and     at': "at TYPE('y)"
  and     cpa: "cp TYPE('a) TYPE('x) TYPE('y)"
  and     cpb: "cp TYPE('y) TYPE('x) TYPE('y)"
  and     f1: "finite ((supp h)::'y set)"
  and     a1: "\<exists>(a::'y). a\<sharp>(h,h a)"
  shows "pi\<bullet>(fresh_fun h) = fresh_fun(pi\<bullet>h)" (is "?LHS = ?RHS")
proof -
  have ptd: "pt TYPE('y) TYPE('y)" by (simp add: at_pt_inst[OF at']) 
  have ptc: "pt TYPE('y\<Rightarrow>'a) TYPE('x)" by (simp add: pt_fun_inst[OF ptb, OF pta, OF at]) 
  have cpc: "cp TYPE('y\<Rightarrow>'a) TYPE ('x) TYPE ('y)" by (rule cp_fun_inst[OF cpb,OF cpa])
  have f2: "finite ((supp (pi\<bullet>h))::'y set)"
  proof -
    from f1 have "finite (pi\<bullet>((supp h)::'y set))"
      by (simp add: pt_set_finite_ineq[OF ptb, OF at])
    thus ?thesis
      by (simp add: pt_perm_supp_ineq[OF ptc, OF ptb, OF at, OF cpc])
  qed
  from a1 obtain a' where c0: "a'\<sharp>(h,h a')" by force
  hence c1: "a'\<sharp>h" and c2: "a'\<sharp>(h a')" by (simp_all add: fresh_prod)
  have c3: "(pi\<bullet>a')\<sharp>(pi\<bullet>h)" using c1
  by (simp add: pt_fresh_bij_ineq[OF ptc, OF ptb, OF at, OF cpc])
  have c4: "(pi\<bullet>a')\<sharp>(pi\<bullet>h) (pi\<bullet>a')"
  proof -
    from c2 have "(pi\<bullet>a')\<sharp>(pi\<bullet>(h a'))"
      by (simp add: pt_fresh_bij_ineq[OF pta, OF ptb, OF at,OF cpa])
    thus ?thesis by (simp add: pt_fun_app_eq[OF ptb, OF at])
  qed
  have a2: "\<exists>(a::'y). a\<sharp>(pi\<bullet>h,(pi\<bullet>h) a)" using c3 c4 by (force simp add: fresh_prod)
  have d1: "?LHS = pi\<bullet>(h a')" using c1 a1 by (simp add: fresh_fun_app[OF ptb', OF at', OF f1])
  have d2: "?RHS = (pi\<bullet>h) (pi\<bullet>a')" using c3 a2 
    by (simp add: fresh_fun_app[OF ptb', OF at', OF f2])
  show ?thesis using d1 d2 by (simp add: pt_fun_app_eq[OF ptb, OF at])
qed

lemma fresh_fun_equiv:
  fixes h :: "'x\<Rightarrow>'a"
  and   pi:: "'x prm"
  assumes pta: "pt TYPE('a) TYPE('x)"
  and     at:  "at TYPE('x)" 
  and     f1:  "finite ((supp h)::'x set)"
  and     a1: "\<exists>(a::'x). a\<sharp>(h,h a)"
  shows "pi\<bullet>(fresh_fun h) = fresh_fun(pi\<bullet>h)" (is "?LHS = ?RHS")
proof -
  have ptb: "pt TYPE('x) TYPE('x)" by (simp add: at_pt_inst[OF at]) 
  have ptc: "pt TYPE('x\<Rightarrow>'a) TYPE('x)" by (simp add: pt_fun_inst[OF ptb, OF pta, OF at]) 
  have f2: "finite ((supp (pi\<bullet>h))::'x set)"
  proof -
    from f1 have "finite (pi\<bullet>((supp h)::'x set))" by (simp add: pt_set_finite_ineq[OF ptb, OF at])
    thus ?thesis by (simp add: pt_perm_supp[OF ptc, OF at])
  qed
  from a1 obtain a' where c0: "a'\<sharp>(h,h a')" by force
  hence c1: "a'\<sharp>h" and c2: "a'\<sharp>(h a')" by (simp_all add: fresh_prod)
  have c3: "(pi\<bullet>a')\<sharp>(pi\<bullet>h)" using c1 by (simp add: pt_fresh_bij[OF ptc, OF at])
  have c4: "(pi\<bullet>a')\<sharp>(pi\<bullet>h) (pi\<bullet>a')"
  proof -
    from c2 have "(pi\<bullet>a')\<sharp>(pi\<bullet>(h a'))" by (simp add: pt_fresh_bij[OF pta, OF at])
    thus ?thesis by (simp add: pt_fun_app_eq[OF ptb, OF at])
  qed
  have a2: "\<exists>(a::'x). a\<sharp>(pi\<bullet>h,(pi\<bullet>h) a)" using c3 c4 by (force simp add: fresh_prod)
  have d1: "?LHS = pi\<bullet>(h a')" using c1 a1 by (simp add: fresh_fun_app[OF pta, OF at, OF f1])
  have d2: "?RHS = (pi\<bullet>h) (pi\<bullet>a')" using c3 a2 by (simp add: fresh_fun_app[OF pta, OF at, OF f2])
  show ?thesis using d1 d2 by (simp add: pt_fun_app_eq[OF ptb, OF at])
qed

lemma fresh_fun_supports:
  fixes h :: "'x\<Rightarrow>'a"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)" 
  and     f1: "finite ((supp h)::'x set)"
  and     a: "\<exists>(a::'x). a\<sharp>(h,h a)"
  shows "((supp h)::'x set) supports (fresh_fun h)"
  apply(simp add: "op supports_def" fresh_def[symmetric])
  apply(auto)
  apply(simp add: fresh_fun_equiv[OF pt, OF at, OF f1, OF a])
  apply(simp add: pt_fresh_fresh[OF pt_fun_inst[OF at_pt_inst[OF at], OF pt], OF at, OF at])
  done
  
section {* Abstraction function *}
(*==============================*)

lemma pt_abs_fun_inst:
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "pt TYPE('x\<Rightarrow>('a noption)) TYPE('x)"
  by (rule pt_fun_inst[OF at_pt_inst[OF at],OF pt_noption_inst[OF pt],OF at])

constdefs
  abs_fun :: "'x\<Rightarrow>'a\<Rightarrow>('x\<Rightarrow>('a noption))" ("[_]._" [100,100] 100)
  "[a].x \<equiv> (\<lambda>b. (if b=a then nSome(x) else (if b\<sharp>x then nSome([(a,b)]\<bullet>x) else nNone)))"

(* FIXME: should be called perm_if and placed close to the definition of permutations on bools *)
lemma abs_fun_if: 
  fixes pi :: "'x prm"
  and   x  :: "'a"
  and   y  :: "'a"
  and   c  :: "bool"
  shows "pi\<bullet>(if c then x else y) = (if c then (pi\<bullet>x) else (pi\<bullet>y))"   
  by force

lemma abs_fun_pi_ineq:
  fixes a  :: "'y"
  and   x  :: "'a"
  and   pi :: "'x prm"
  assumes pta: "pt TYPE('a) TYPE('x)"
  and     ptb: "pt TYPE('y) TYPE('x)"
  and     at:  "at TYPE('x)"
  and     cp:  "cp TYPE('a) TYPE('x) TYPE('y)"
  shows "pi\<bullet>([a].x) = [(pi\<bullet>a)].(pi\<bullet>x)"
  apply(simp add: abs_fun_def perm_fun_def abs_fun_if)
  apply(simp only: expand_fun_eq)
  apply(rule allI)
  apply(subgoal_tac "(((rev pi)\<bullet>(xa::'y)) = (a::'y)) = (xa = pi\<bullet>a)")(*A*)
  apply(subgoal_tac "(((rev pi)\<bullet>xa)\<sharp>x) = (xa\<sharp>(pi\<bullet>x))")(*B*)
  apply(subgoal_tac "pi\<bullet>([(a,(rev pi)\<bullet>xa)]\<bullet>x) = [(pi\<bullet>a,xa)]\<bullet>(pi\<bullet>x)")(*C*)
  apply(simp)
(*C*)
  apply(simp add: cp1[OF cp])
  apply(simp add: pt_pi_rev[OF ptb, OF at])
(*B*)
  apply(simp add: pt_fresh_left_ineq[OF pta, OF ptb, OF at, OF cp])
(*A*)
  apply(rule iffI)
  apply(rule pt_bij2[OF ptb, OF at, THEN sym])
  apply(simp)
  apply(rule pt_bij2[OF ptb, OF at])
  apply(simp)
done

lemma abs_fun_pi:
  fixes a  :: "'x"
  and   x  :: "'a"
  and   pi :: "'x prm"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "pi\<bullet>([a].x) = [(pi\<bullet>a)].(pi\<bullet>x)"
apply(rule abs_fun_pi_ineq)
apply(rule pt)
apply(rule at_pt_inst)
apply(rule at)+
apply(rule cp_pt_inst)
apply(rule pt)
apply(rule at)
done

lemma abs_fun_eq1: 
  fixes x  :: "'a"
  and   y  :: "'a"
  and   a  :: "'x"
  shows "([a].x = [a].y) = (x = y)"
apply(auto simp add: abs_fun_def)
apply(auto simp add: expand_fun_eq)
apply(drule_tac x="a" in spec)
apply(simp)
done

lemma abs_fun_eq2:
  fixes x  :: "'a"
  and   y  :: "'a"
  and   a  :: "'x"
  and   b  :: "'x"
  assumes pt: "pt TYPE('a) TYPE('x)"
      and at: "at TYPE('x)"
      and a1: "a\<noteq>b" 
      and a2: "[a].x = [b].y" 
  shows "x=[(a,b)]\<bullet>y \<and> a\<sharp>y"
proof -
  from a2 have "\<forall>c::'x. ([a].x) c = ([b].y) c" by (force simp add: expand_fun_eq)
  hence "([a].x) a = ([b].y) a" by simp
  hence a3: "nSome(x) = ([b].y) a" by (simp add: abs_fun_def)
  show "x=[(a,b)]\<bullet>y \<and> a\<sharp>y"
  proof (cases "a\<sharp>y")
    assume a4: "a\<sharp>y"
    hence "x=[(b,a)]\<bullet>y" using a3 a1 by (simp add: abs_fun_def)
    moreover
    have "[(a,b)]\<bullet>y = [(b,a)]\<bullet>y" by (rule pt3[OF pt], rule at_ds5[OF at])
    ultimately show ?thesis using a4 by simp
  next
    assume "\<not>a\<sharp>y"
    hence "nSome(x) = nNone" using a1 a3 by (simp add: abs_fun_def)
    hence False by simp
    thus ?thesis by simp
  qed
qed

lemma abs_fun_eq3: 
  fixes x  :: "'a"
  and   y  :: "'a"
  and   a   :: "'x"
  and   b   :: "'x"
  assumes pt: "pt TYPE('a) TYPE('x)"
      and at: "at TYPE('x)"
      and a1: "a\<noteq>b" 
      and a2: "x=[(a,b)]\<bullet>y" 
      and a3: "a\<sharp>y" 
  shows "[a].x =[b].y"
proof -
  show ?thesis 
  proof (simp only: abs_fun_def expand_fun_eq, intro strip)
    fix c::"'x"
    let ?LHS = "if c=a then nSome(x) else if c\<sharp>x then nSome([(a,c)]\<bullet>x) else nNone"
    and ?RHS = "if c=b then nSome(y) else if c\<sharp>y then nSome([(b,c)]\<bullet>y) else nNone"
    show "?LHS=?RHS"
    proof -
      have "(c=a) \<or> (c=b) \<or> (c\<noteq>a \<and> c\<noteq>b)" by blast
      moreover  --"case c=a"
      { have "nSome(x) = nSome([(a,b)]\<bullet>y)" using a2 by simp
	also have "\<dots> = nSome([(b,a)]\<bullet>y)" by (simp, rule pt3[OF pt], rule at_ds5[OF at])
	finally have "nSome(x) = nSome([(b,a)]\<bullet>y)" by simp
	moreover
	assume "c=a"
	ultimately have "?LHS=?RHS" using a1 a3 by simp
      }
      moreover  -- "case c=b"
      { have a4: "y=[(a,b)]\<bullet>x" using a2 by (simp only: pt_swap_bij[OF pt, OF at])
	hence "a\<sharp>([(a,b)]\<bullet>x)" using a3 by simp
	hence "b\<sharp>x" by (simp add: at_calc[OF at] pt_fresh_left[OF pt, OF at])
	moreover
	assume "c=b"
	ultimately have "?LHS=?RHS" using a1 a4 by simp
      }
      moreover  -- "case c\<noteq>a \<and> c\<noteq>b"
      { assume a5: "c\<noteq>a \<and> c\<noteq>b"
	moreover 
	have "c\<sharp>x = c\<sharp>y" using a2 a5 by (force simp add: at_calc[OF at] pt_fresh_left[OF pt, OF at])
	moreover 
	have "c\<sharp>y \<longrightarrow> [(a,c)]\<bullet>x = [(b,c)]\<bullet>y" 
	proof (intro strip)
	  assume a6: "c\<sharp>y"
	  have "[(a,c),(b,c),(a,c)] \<triangleq> [(a,b)]" using a1 a5 by (force intro: at_ds3[OF at])
	  hence "[(a,c)]\<bullet>([(b,c)]\<bullet>([(a,c)]\<bullet>y)) = [(a,b)]\<bullet>y" 
	    by (simp add: pt2[OF pt, symmetric] pt3[OF pt])
 	  hence "[(a,c)]\<bullet>([(b,c)]\<bullet>y) = [(a,b)]\<bullet>y" using a3 a6 
	    by (simp add: pt_fresh_fresh[OF pt, OF at])
	  hence "[(a,c)]\<bullet>([(b,c)]\<bullet>y) = x" using a2 by simp
	  hence "[(b,c)]\<bullet>y = [(a,c)]\<bullet>x" by (drule_tac pt_bij1[OF pt, OF at], simp)
	  thus "[(a,c)]\<bullet>x = [(b,c)]\<bullet>y" by simp
	qed
	ultimately have "?LHS=?RHS" by simp
      }
      ultimately show "?LHS = ?RHS" by blast
    qed
  qed
qed
	
lemma abs_fun_eq: 
  fixes x  :: "'a"
  and   y  :: "'a"
  and   a  :: "'x"
  and   b  :: "'x"
  assumes pt: "pt TYPE('a) TYPE('x)"
      and at: "at TYPE('x)"
  shows "([a].x = [b].y) = ((a=b \<and> x=y)\<or>(a\<noteq>b \<and> x=[(a,b)]\<bullet>y \<and> a\<sharp>y))"
proof (rule iffI)
  assume b: "[a].x = [b].y"
  show "(a=b \<and> x=y)\<or>(a\<noteq>b \<and> x=[(a,b)]\<bullet>y \<and> a\<sharp>y)"
  proof (cases "a=b")
    case True with b show ?thesis by (simp add: abs_fun_eq1)
  next
    case False with b show ?thesis by (simp add: abs_fun_eq2[OF pt, OF at])
  qed
next
  assume "(a=b \<and> x=y)\<or>(a\<noteq>b \<and> x=[(a,b)]\<bullet>y \<and> a\<sharp>y)"
  thus "[a].x = [b].y"
  proof
    assume "a=b \<and> x=y" thus ?thesis by simp
  next
    assume "a\<noteq>b \<and> x=[(a,b)]\<bullet>y \<and> a\<sharp>y" 
    thus ?thesis by (simp add: abs_fun_eq3[OF pt, OF at])
  qed
qed

lemma abs_fun_eq': 
  fixes x :: "'a"
  and   y :: "'a"
  and   c :: "'x"
  and   a :: "'x"
  and   b :: "'x"
  assumes pt: "pt TYPE('a) TYPE('x)"
      and at: "at TYPE('x)"
      and fr: "c\<noteq>a" "c\<noteq>b" "c\<sharp>x" "c\<sharp>y" 
  shows "([a].x = [b].y) = ([(a,c)]\<bullet>x = [(b,c)]\<bullet>y)"
proof (rule iffI)
  assume eq0: "[a].x = [b].y"
  show "[(a,c)]\<bullet>x = [(b,c)]\<bullet>y"
  proof (cases "a=b")
    case True then show ?thesis using eq0 by (simp add: pt_bij[OF pt, OF at] abs_fun_eq[OF pt, OF at])
  next
    case False 
    have ineq: "a\<noteq>b" by fact
    with eq0 have eq: "x=[(a,b)]\<bullet>y" and fr': "a\<sharp>y" by (simp_all add: abs_fun_eq[OF pt, OF at])
    from eq have "[(a,c)]\<bullet>x = [(a,c)]\<bullet>[(a,b)]\<bullet>y" by (simp add: pt_bij[OF pt, OF at])
    also have "\<dots> = ([(a,c)]\<bullet>[(a,b)])\<bullet>([(a,c)]\<bullet>y)" by (rule pt_perm_compose[OF pt, OF at])
    also have "\<dots> = [(c,b)]\<bullet>y" using ineq fr fr' 
      by (simp add: pt_fresh_fresh[OF pt, OF at] at_calc[OF at])
    also have "\<dots> = [(b,c)]\<bullet>y" by (rule pt3[OF pt], rule at_ds5[OF at])
    finally show ?thesis by simp
  qed
next
  assume eq: "[(a,c)]\<bullet>x = [(b,c)]\<bullet>y"
  thus "[a].x = [b].y"
  proof (cases "a=b")
    case True then show ?thesis using eq by (simp add: pt_bij[OF pt, OF at] abs_fun_eq[OF pt, OF at])
  next
    case False
    have ineq: "a\<noteq>b" by fact
    from fr have "([(a,c)]\<bullet>c)\<sharp>([(a,c)]\<bullet>x)" by (simp add: pt_fresh_bij[OF pt, OF at])
    hence "a\<sharp>([(b,c)]\<bullet>y)" using eq fr by (simp add: at_calc[OF at])
    hence fr0: "a\<sharp>y" using ineq fr by (simp add: pt_fresh_left[OF pt, OF at] at_calc[OF at])
    from eq have "x = (rev [(a,c)])\<bullet>([(b,c)]\<bullet>y)" by (rule pt_bij1[OF pt, OF at])
    also have "\<dots> = [(a,c)]\<bullet>([(b,c)]\<bullet>y)" by simp
    also have "\<dots> = ([(a,c)]\<bullet>[(b,c)])\<bullet>([(a,c)]\<bullet>y)" by (rule pt_perm_compose[OF pt, OF at])
    also have "\<dots> = [(b,a)]\<bullet>y" using ineq fr fr0  
      by (simp add: pt_fresh_fresh[OF pt, OF at] at_calc[OF at])
    also have "\<dots> = [(a,b)]\<bullet>y" by (rule pt3[OF pt], rule at_ds5[OF at])
    finally show ?thesis using ineq fr0 by (simp add: abs_fun_eq[OF pt, OF at])
  qed
qed

lemma abs_fun_supp_approx:
  fixes x :: "'a"
  and   a :: "'x"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "((supp ([a].x))::'x set) \<subseteq> (supp (x,a))"
proof 
  fix c
  assume "c\<in>((supp ([a].x))::'x set)"
  hence "infinite {b. [(c,b)]\<bullet>([a].x) \<noteq> [a].x}" by (simp add: supp_def)
  hence "infinite {b. [([(c,b)]\<bullet>a)].([(c,b)]\<bullet>x) \<noteq> [a].x}" by (simp add: abs_fun_pi[OF pt, OF at])
  moreover
  have "{b. [([(c,b)]\<bullet>a)].([(c,b)]\<bullet>x) \<noteq> [a].x} \<subseteq> {b. ([(c,b)]\<bullet>x,[(c,b)]\<bullet>a) \<noteq> (x, a)}" by force
  ultimately have "infinite {b. ([(c,b)]\<bullet>x,[(c,b)]\<bullet>a) \<noteq> (x, a)}" by (simp add: infinite_super)
  thus "c\<in>(supp (x,a))" by (simp add: supp_def)
qed

lemma abs_fun_finite_supp:
  fixes x :: "'a"
  and   a :: "'x"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  and     f:  "finite ((supp x)::'x set)"
  shows "finite ((supp ([a].x))::'x set)"
proof -
  from f have "finite ((supp (x,a))::'x set)" by (simp add: supp_prod at_supp[OF at])
  moreover
  have "((supp ([a].x))::'x set) \<subseteq> (supp (x,a))" by (rule abs_fun_supp_approx[OF pt, OF at])
  ultimately show ?thesis by (simp add: finite_subset)
qed

lemma fresh_abs_funI1:
  fixes  x :: "'a"
  and    a :: "'x"
  and    b :: "'x"
  assumes pt:  "pt TYPE('a) TYPE('x)"
  and     at:   "at TYPE('x)"
  and f:  "finite ((supp x)::'x set)"
  and a1: "b\<sharp>x" 
  and a2: "a\<noteq>b"
  shows "b\<sharp>([a].x)"
  proof -
    have "\<exists>c::'x. c\<sharp>(b,a,x,[a].x)" 
    proof (rule at_exists_fresh'[OF at], auto simp add: supp_prod at_supp[OF at] f)
      show "finite ((supp ([a].x))::'x set)" using f
	by (simp add: abs_fun_finite_supp[OF pt, OF at])	
    qed
    then obtain c where fr1: "c\<noteq>b"
                  and   fr2: "c\<noteq>a"
                  and   fr3: "c\<sharp>x"
                  and   fr4: "c\<sharp>([a].x)"
                  by (force simp add: fresh_prod at_fresh[OF at])
    have e: "[(c,b)]\<bullet>([a].x) = [a].([(c,b)]\<bullet>x)" using a2 fr1 fr2 
      by (force simp add: abs_fun_pi[OF pt, OF at] at_calc[OF at])
    from fr4 have "([(c,b)]\<bullet>c)\<sharp> ([(c,b)]\<bullet>([a].x))"
      by (simp add: pt_fresh_bij[OF pt_abs_fun_inst[OF pt, OF at], OF at])
    hence "b\<sharp>([a].([(c,b)]\<bullet>x))" using fr1 fr2 e  
      by (simp add: at_calc[OF at])
    thus ?thesis using a1 fr3 
      by (simp add: pt_fresh_fresh[OF pt, OF at])
qed

lemma fresh_abs_funE:
  fixes a :: "'x"
  and   b :: "'x"
  and   x :: "'a"
  assumes pt:  "pt TYPE('a) TYPE('x)"
  and     at:  "at TYPE('x)"
  and     f:  "finite ((supp x)::'x set)"
  and     a1: "b\<sharp>([a].x)" 
  and     a2: "b\<noteq>a" 
  shows "b\<sharp>x"
proof -
  have "\<exists>c::'x. c\<sharp>(b,a,x,[a].x)"
  proof (rule at_exists_fresh'[OF at], auto simp add: supp_prod at_supp[OF at] f)
    show "finite ((supp ([a].x))::'x set)" using f
      by (simp add: abs_fun_finite_supp[OF pt, OF at])	
  qed
  then obtain c where fr1: "b\<noteq>c"
                and   fr2: "c\<noteq>a"
                and   fr3: "c\<sharp>x"
                and   fr4: "c\<sharp>([a].x)" by (force simp add: fresh_prod at_fresh[OF at])
  have "[a].x = [(b,c)]\<bullet>([a].x)" using a1 fr4 
    by (simp add: pt_fresh_fresh[OF pt_abs_fun_inst[OF pt, OF at], OF at])
  hence "[a].x = [a].([(b,c)]\<bullet>x)" using fr2 a2 
    by (force simp add: abs_fun_pi[OF pt, OF at] at_calc[OF at])
  hence b: "([(b,c)]\<bullet>x) = x" by (simp add: abs_fun_eq1)
  from fr3 have "([(b,c)]\<bullet>c)\<sharp>([(b,c)]\<bullet>x)" 
    by (simp add: pt_fresh_bij[OF pt, OF at]) 
  thus ?thesis using b fr1 by (simp add: at_calc[OF at])
qed

lemma fresh_abs_funI2:
  fixes a :: "'x"
  and   x :: "'a"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  and     f: "finite ((supp x)::'x set)"
  shows "a\<sharp>([a].x)"
proof -
  have "\<exists>c::'x. c\<sharp>(a,x)"
    by  (rule at_exists_fresh'[OF at], auto simp add: supp_prod at_supp[OF at] f) 
  then obtain c where fr1: "a\<noteq>c" and fr1_sym: "c\<noteq>a" 
                and   fr2: "c\<sharp>x" by (force simp add: fresh_prod at_fresh[OF at])
  have "c\<sharp>([a].x)" using f fr1 fr2 by (simp add: fresh_abs_funI1[OF pt, OF at])
  hence "([(c,a)]\<bullet>c)\<sharp>([(c,a)]\<bullet>([a].x))" using fr1  
    by (simp only: pt_fresh_bij[OF pt_abs_fun_inst[OF pt, OF at], OF at])
  hence a: "a\<sharp>([c].([(c,a)]\<bullet>x))" using fr1_sym 
    by (simp add: abs_fun_pi[OF pt, OF at] at_calc[OF at])
  have "[c].([(c,a)]\<bullet>x) = ([a].x)" using fr1_sym fr2 
    by (simp add: abs_fun_eq[OF pt, OF at])
  thus ?thesis using a by simp
qed

lemma fresh_abs_fun_iff: 
  fixes a :: "'x"
  and   b :: "'x"
  and   x :: "'a"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  and     f: "finite ((supp x)::'x set)"
  shows "(b\<sharp>([a].x)) = (b=a \<or> b\<sharp>x)" 
  by (auto  dest: fresh_abs_funE[OF pt, OF at,OF f] 
           intro: fresh_abs_funI1[OF pt, OF at,OF f] 
                  fresh_abs_funI2[OF pt, OF at,OF f])

lemma abs_fun_supp: 
  fixes a :: "'x"
  and   x :: "'a"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  and     f: "finite ((supp x)::'x set)"
  shows "supp ([a].x) = (supp x)-{a}"
 by (force simp add: supp_fresh_iff fresh_abs_fun_iff[OF pt, OF at, OF f])

(* maybe needs to be better stated as supp intersection supp *)
lemma abs_fun_supp_ineq: 
  fixes a :: "'y"
  and   x :: "'a"
  assumes pta: "pt TYPE('a) TYPE('x)"
  and     ptb: "pt TYPE('y) TYPE('x)"
  and     at:  "at TYPE('x)"
  and     cp:  "cp TYPE('a) TYPE('x) TYPE('y)"
  and     dj:  "disjoint TYPE('y) TYPE('x)"
  shows "((supp ([a].x))::'x set) = (supp x)"
apply(auto simp add: supp_def)
apply(auto simp add: abs_fun_pi_ineq[OF pta, OF ptb, OF at, OF cp])
apply(auto simp add: dj_perm_forget[OF dj])
apply(auto simp add: abs_fun_eq1) 
done

lemma fresh_abs_fun_iff_ineq: 
  fixes a :: "'y"
  and   b :: "'x"
  and   x :: "'a"
  assumes pta: "pt TYPE('a) TYPE('x)"
  and     ptb: "pt TYPE('y) TYPE('x)"
  and     at:  "at TYPE('x)"
  and     cp:  "cp TYPE('a) TYPE('x) TYPE('y)"
  and     dj:  "disjoint TYPE('y) TYPE('x)"
  shows "b\<sharp>([a].x) = b\<sharp>x" 
  by (simp add: fresh_def abs_fun_supp_ineq[OF pta, OF ptb, OF at, OF cp, OF dj])

section {* abstraction type for the parsing in nominal datatype *}
(*==============================================================*)
consts
  "ABS_set" :: "('x\<Rightarrow>('a noption)) set"
inductive ABS_set
  intros
  ABS_in: "(abs_fun a x)\<in>ABS_set"

typedef (ABS) ('x,'a) ABS = "ABS_set::('x\<Rightarrow>('a noption)) set"
proof 
  fix x::"'a" and a::"'x"
  show "(abs_fun a x)\<in> ABS_set" by (rule ABS_in)
qed

syntax ABS :: "type \<Rightarrow> type \<Rightarrow> type" ("\<guillemotleft>_\<guillemotright>_" [1000,1000] 1000)


section {* lemmas for deciding permutation equations *}
(*===================================================*)

lemma perm_aux_fold:
  shows "perm_aux pi x = pi\<bullet>x" by (simp only: perm_aux_def)

lemma pt_perm_compose_aux:
  fixes pi1 :: "'x prm"
  and   pi2 :: "'x prm"
  and   x  :: "'a"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "pi2\<bullet>(pi1\<bullet>x) = perm_aux (pi2\<bullet>pi1) (pi2\<bullet>x)" 
proof -
  have "(pi2@pi1) \<triangleq> ((pi2\<bullet>pi1)@pi2)" by (rule at_ds8)
  hence "(pi2@pi1)\<bullet>x = ((pi2\<bullet>pi1)@pi2)\<bullet>x" by (rule pt3[OF pt])
  thus ?thesis by (simp add: pt2[OF pt] perm_aux_def)
qed  

lemma cp1_aux:
  fixes pi1::"'x prm"
  and   pi2::"'y prm"
  and   x  ::"'a"
  assumes cp: "cp TYPE ('a) TYPE('x) TYPE('y)"
  shows "pi1\<bullet>(pi2\<bullet>x) = perm_aux (pi1\<bullet>pi2) (pi1\<bullet>x)"
  using cp by (simp add: cp_def perm_aux_def)

lemma perm_eq_app:
  fixes f  :: "'a\<Rightarrow>'b"
  and   x  :: "'a"
  and   pi :: "'x prm"
  assumes pt: "pt TYPE('a) TYPE('x)"
  and     at: "at TYPE('x)"
  shows "(pi\<bullet>(f x)=y) = ((pi\<bullet>f)(pi\<bullet>x)=y)"
  by (simp add: pt_fun_app_eq[OF pt, OF at])

lemma perm_eq_lam:
  fixes f  :: "'a\<Rightarrow>'b"
  and   x  :: "'a"
  and   pi :: "'x prm"
  shows "((pi\<bullet>(\<lambda>x. f x))=y) = ((\<lambda>x. (pi\<bullet>(f ((rev pi)\<bullet>x))))=y)"
  by (simp add: perm_fun_def)

section {* test *}
lemma at_prm_eq_compose:
  fixes pi1 :: "'x prm"
  and   pi2 :: "'x prm"
  and   pi3 :: "'x prm"
  assumes at: "at TYPE('x)"
  and     a: "pi1 \<triangleq> pi2"
  shows "(pi3\<bullet>pi1) \<triangleq> (pi3\<bullet>pi2)"
proof -
  have pt: "pt TYPE('x) TYPE('x)" by (rule at_pt_inst[OF at])
  have pt_prm: "pt TYPE('x prm) TYPE('x)" 
    by (rule pt_list_inst[OF pt_prod_inst[OF pt, OF pt]])  
  from a show ?thesis
    apply -
    apply(auto simp add: prm_eq_def)
    apply(rule_tac pi="rev pi3" in pt_bij4[OF pt, OF at])
    apply(rule trans)
    apply(rule pt_perm_compose[OF pt, OF at])
    apply(simp add: pt_rev_pi[OF pt_prm, OF at])
    apply(rule sym)
    apply(rule trans)
    apply(rule pt_perm_compose[OF pt, OF at])
    apply(simp add: pt_rev_pi[OF pt_prm, OF at])
    done
qed

(************************)
(* Various eqvt-lemmas  *)

lemma Zero_nat_eqvt:
  shows "pi\<bullet>(0::nat) = 0" 
by (auto simp add: perm_nat_def)

lemma One_nat_eqvt:
  shows "pi\<bullet>(1::nat) = 1"
by (simp add: perm_nat_def)

lemma Suc_eqvt:
  shows "pi\<bullet>(Suc x) = Suc (pi\<bullet>x)" 
by (auto simp add: perm_nat_def)

lemma numeral_nat_eqvt: 
 shows "pi\<bullet>((number_of n)::nat) = number_of n" 
by (simp add: perm_nat_def perm_int_def)

lemma max_nat_eqvt:
  fixes x::"nat"
  shows "pi\<bullet>(max x y) = max (pi\<bullet>x) (pi\<bullet>y)" 
by (simp add:perm_nat_def) 

lemma min_nat_eqvt:
  fixes x::"nat"
  shows "pi\<bullet>(min x y) = min (pi\<bullet>x) (pi\<bullet>y)" 
by (simp add:perm_nat_def) 

lemma plus_nat_eqvt:
  fixes x::"nat"
  shows "pi\<bullet>(x + y) = (pi\<bullet>x) + (pi\<bullet>y)" 
by (simp add:perm_nat_def) 

lemma minus_nat_eqvt:
  fixes x::"nat"
  shows "pi\<bullet>(x - y) = (pi\<bullet>x) - (pi\<bullet>y)" 
by (simp add:perm_nat_def) 

lemma mult_nat_eqvt:
  fixes x::"nat"
  shows "pi\<bullet>(x * y) = (pi\<bullet>x) * (pi\<bullet>y)" 
by (simp add:perm_nat_def) 

lemma div_nat_eqvt:
  fixes x::"nat"
  shows "pi\<bullet>(x div y) = (pi\<bullet>x) div (pi\<bullet>y)" 
by (simp add:perm_nat_def) 

lemma Zero_int_eqvt:
  shows "pi\<bullet>(0::int) = 0" 
by (auto simp add: perm_int_def)

lemma One_int_eqvt:
  shows "pi\<bullet>(1::int) = 1"
by (simp add: perm_int_def)

lemma numeral_int_eqvt: 
 shows "pi\<bullet>((number_of n)::int) = number_of n" 
by (simp add: perm_int_def perm_int_def)

lemma max_int_eqvt:
  fixes x::"int"
  shows "pi\<bullet>(max (x::int) y) = max (pi\<bullet>x) (pi\<bullet>y)" 
by (simp add:perm_int_def) 

lemma min_int_eqvt:
  fixes x::"int"
  shows "pi\<bullet>(min x y) = min (pi\<bullet>x) (pi\<bullet>y)" 
by (simp add:perm_int_def) 

lemma plus_int_eqvt:
  fixes x::"int"
  shows "pi\<bullet>(x + y) = (pi\<bullet>x) + (pi\<bullet>y)" 
by (simp add:perm_int_def) 

lemma minus_int_eqvt:
  fixes x::"int"
  shows "pi\<bullet>(x - y) = (pi\<bullet>x) - (pi\<bullet>y)" 
by (simp add:perm_int_def) 

lemma mult_int_eqvt:
  fixes x::"int"
  shows "pi\<bullet>(x * y) = (pi\<bullet>x) * (pi\<bullet>y)" 
by (simp add:perm_int_def) 

lemma div_int_eqvt:
  fixes x::"int"
  shows "pi\<bullet>(x div y) = (pi\<bullet>x) div (pi\<bullet>y)" 
by (simp add:perm_int_def) 

(*******************************************************************)
(* Setup of the theorem attributes eqvt, eqvt_force, fresh and bij *)
use "nominal_thmdecls.ML"
setup "NominalThmDecls.setup"

lemmas [eqvt] = 
  (* connectives *)
  if_eqvt imp_eqvt disj_eqvt conj_eqvt neg_eqvt
  
  (* datatypes *)
  perm_unit.simps
  perm_list.simps append_eqvt
  perm_prod.simps
  fst_eqvt snd_eqvt
  perm_option.simps

  (* nats *)
  Suc_eqvt Zero_nat_eqvt One_nat_eqvt min_nat_eqvt max_nat_eqvt
  plus_nat_eqvt minus_nat_eqvt mult_nat_eqvt div_nat_eqvt
  
  (* ints *)
  Zero_int_eqvt One_int_eqvt min_int_eqvt max_int_eqvt
  plus_int_eqvt minus_int_eqvt mult_int_eqvt div_int_eqvt
  
  (* sets *)
  union_eqvt empty_eqvt insert_eqvt
  
 
(* the lemmas numeral_nat_eqvt numeral_int_eqvt do not conform with the *)
(* usual form of an eqvt-lemma, but they are needed for analysing       *)
(* permutations on nats and ints *)
lemmas [eqvt_force] = numeral_nat_eqvt numeral_int_eqvt

(***************************************)
(* setup for the individial atom-kinds *)
(* and nominal datatypes               *)
use "nominal_atoms.ML"
setup "NominalAtoms.setup"

(************************************************************)
(* various tactics for analysing permutations, supports etc *)
use "nominal_permeq.ML";

method_setup perm_simp =
  {* NominalPermeq.perm_simp_meth *}
  {* simp rules and simprocs for analysing permutations *}

method_setup perm_simp_debug =
  {* NominalPermeq.perm_simp_meth_debug *}
  {* simp rules and simprocs for analysing permutations including debugging facilities *}

method_setup perm_full_simp =
  {* NominalPermeq.perm_full_simp_meth *}
  {* tactic for deciding equalities involving permutations *}

method_setup perm_full_simp_debug =
  {* NominalPermeq.perm_full_simp_meth_debug *}
  {* tactic for deciding equalities involving permutations including debugging facilities *}

method_setup supports_simp =
  {* NominalPermeq.supports_meth *}
  {* tactic for deciding whether something supports something else *}

method_setup supports_simp_debug =
  {* NominalPermeq.supports_meth_debug *}
  {* tactic for deciding whether something supports something else including debugging facilities *}

method_setup finite_guess =
  {* NominalPermeq.finite_guess_meth *}
  {* tactic for deciding whether something has finite support *}

method_setup finite_guess_debug =
  {* NominalPermeq.finite_guess_meth_debug *}
  {* tactic for deciding whether something has finite support including debugging facilities *}

method_setup fresh_guess =
  {* NominalPermeq.fresh_guess_meth *}
  {* tactic for deciding whether an atom is fresh for something*}

method_setup fresh_guess_debug =
  {* NominalPermeq.fresh_guess_meth_debug *}
  {* tactic for deciding whether an atom is fresh for something including debugging facilities *}

(************************************************)
(* main file for constructing nominal datatypes *)
use "nominal_package.ML"
setup "NominalPackage.setup"

(******************************************************)
(* primitive recursive functions on nominal datatypes *)
use "nominal_primrec.ML"

(****************************************************)
(* inductive definition involving nominal datatypes *)
use "nominal_inductive.ML"

(*****************************************)
(* setup for induction principles method *)
use "nominal_induct.ML";
method_setup nominal_induct =
  {* NominalInduct.nominal_induct_method *}
  {* nominal induction *}

end
