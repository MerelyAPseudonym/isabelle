(*  Title:      HOL/Orderings.thy
    ID:         $Id$
    Author:     Tobias Nipkow, Markus Wenzel, and Larry Paulson
*)

header {* Syntactic and abstract orders *}

theory Orderings
imports Set Fun
uses
  (*"~~/src/Provers/quasi.ML"*)
  "~~/src/Provers/order.ML"
begin

subsection {* Partial orders *}

class order = ord +
  assumes less_le: "x \<sqsubset> y \<longleftrightarrow> x \<sqsubseteq> y \<and> x \<noteq> y"
  and order_refl [iff]: "x \<sqsubseteq> x"
  and order_trans: "x \<sqsubseteq> y \<Longrightarrow> y \<sqsubseteq> z \<Longrightarrow> x \<sqsubseteq> z"
  assumes antisym: "x \<sqsubseteq> y \<Longrightarrow> y \<sqsubseteq> x \<Longrightarrow> x = y"

begin

text {* Reflexivity. *}

lemma eq_refl: "x = y \<Longrightarrow> x \<^loc>\<le> y"
    -- {* This form is useful with the classical reasoner. *}
by (erule ssubst) (rule order_refl)

lemma less_irrefl [iff]: "\<not> x \<^loc>< x"
by (simp add: less_le)

lemma le_less: "x \<^loc>\<le> y \<longleftrightarrow> x \<^loc>< y \<or> x = y"
    -- {* NOT suitable for iff, since it can cause PROOF FAILED. *}
by (simp add: less_le) blast

lemma le_imp_less_or_eq: "x \<^loc>\<le> y \<Longrightarrow> x \<^loc>< y \<or> x = y"
unfolding less_le by blast

lemma less_imp_le: "x \<^loc>< y \<Longrightarrow> x \<^loc>\<le> y"
unfolding less_le by blast

lemma less_imp_neq: "x \<^loc>< y \<Longrightarrow> x \<noteq> y"
by (erule contrapos_pn, erule subst, rule less_irrefl)


text {* Useful for simplification, but too risky to include by default. *}

lemma less_imp_not_eq: "x \<^loc>< y \<Longrightarrow> (x = y) \<longleftrightarrow> False"
by auto

lemma less_imp_not_eq2: "x \<^loc>< y \<Longrightarrow> (y = x) \<longleftrightarrow> False"
by auto


text {* Transitivity rules for calculational reasoning *}

lemma neq_le_trans: "a \<noteq> b \<Longrightarrow> a \<^loc>\<le> b \<Longrightarrow> a \<^loc>< b"
by (simp add: less_le)

lemma le_neq_trans: "a \<^loc>\<le> b \<Longrightarrow> a \<noteq> b \<Longrightarrow> a \<^loc>< b"
by (simp add: less_le)


text {* Asymmetry. *}

lemma less_not_sym: "x \<^loc>< y \<Longrightarrow> \<not> (y \<^loc>< x)"
by (simp add: less_le antisym)

lemma less_asym: "x \<^loc>< y \<Longrightarrow> (\<not> P \<Longrightarrow> y \<^loc>< x) \<Longrightarrow> P"
by (drule less_not_sym, erule contrapos_np) simp

lemma eq_iff: "x = y \<longleftrightarrow> x \<^loc>\<le> y \<and> y \<^loc>\<le> x"
by (blast intro: antisym)

lemma antisym_conv: "y \<^loc>\<le> x \<Longrightarrow> x \<^loc>\<le> y \<longleftrightarrow> x = y"
by (blast intro: antisym)

lemma less_imp_neq: "x \<^loc>< y \<Longrightarrow> x \<noteq> y"
by (erule contrapos_pn, erule subst, rule less_irrefl)


text {* Transitivity. *}

lemma less_trans: "x \<^loc>< y \<Longrightarrow> y \<^loc>< z \<Longrightarrow> x \<^loc>< z"
by (simp add: less_le) (blast intro: order_trans antisym)

lemma le_less_trans: "x \<^loc>\<le> y \<Longrightarrow> y \<^loc>< z \<Longrightarrow> x \<^loc>< z"
by (simp add: less_le) (blast intro: order_trans antisym)

lemma less_le_trans: "x \<^loc>< y \<Longrightarrow> y \<^loc>\<le> z \<Longrightarrow> x \<^loc>< z"
by (simp add: less_le) (blast intro: order_trans antisym)


text {* Useful for simplification, but too risky to include by default. *}

lemma less_imp_not_less: "x \<^loc>< y \<Longrightarrow> (\<not> y \<^loc>< x) \<longleftrightarrow> True"
by (blast elim: less_asym)

lemma less_imp_triv: "x \<^loc>< y \<Longrightarrow> (y \<^loc>< x \<longrightarrow> P) \<longleftrightarrow> True"
by (blast elim: less_asym)


text {* Transitivity rules for calculational reasoning *}

lemma less_asym': "a \<^loc>< b \<Longrightarrow> b \<^loc>< a \<Longrightarrow> P"
by (rule less_asym)


text {* Reverse order *}

lemma order_reverse:
  "order (\<lambda>x y. y \<^loc>\<le> x) (\<lambda>x y. y \<^loc>< x)"
by unfold_locales
   (simp add: less_le, auto intro: antisym order_trans)

end


subsection {* Linear (total) orders *}

class linorder = order +
  assumes linear: "x \<sqsubseteq> y \<or> y \<sqsubseteq> x"
begin

lemma less_linear: "x \<^loc>< y \<or> x = y \<or> y \<^loc>< x"
unfolding less_le using less_le linear by blast

lemma le_less_linear: "x \<^loc>\<le> y \<or> y \<^loc>< x"
by (simp add: le_less less_linear)

lemma le_cases [case_names le ge]:
  "(x \<^loc>\<le> y \<Longrightarrow> P) \<Longrightarrow> (y \<^loc>\<le> x \<Longrightarrow> P) \<Longrightarrow> P"
using linear by blast

lemma linorder_cases [case_names less equal greater]:
  "(x \<^loc>< y \<Longrightarrow> P) \<Longrightarrow> (x = y \<Longrightarrow> P) \<Longrightarrow> (y \<^loc>< x \<Longrightarrow> P) \<Longrightarrow> P"
using less_linear by blast

lemma not_less: "\<not> x \<^loc>< y \<longleftrightarrow> y \<^loc>\<le> x"
apply (simp add: less_le)
using linear apply (blast intro: antisym)
done

lemma not_less_iff_gr_or_eq:
 "\<not>(x \<^loc>< y) \<longleftrightarrow> (x \<^loc>> y | x = y)"
apply(simp add:not_less le_less)
apply blast
done

lemma not_le: "\<not> x \<^loc>\<le> y \<longleftrightarrow> y \<^loc>< x"
apply (simp add: less_le)
using linear apply (blast intro: antisym)
done

lemma neq_iff: "x \<noteq> y \<longleftrightarrow> x \<^loc>< y \<or> y \<^loc>< x"
by (cut_tac x = x and y = y in less_linear, auto)

lemma neqE: "x \<noteq> y \<Longrightarrow> (x \<^loc>< y \<Longrightarrow> R) \<Longrightarrow> (y \<^loc>< x \<Longrightarrow> R) \<Longrightarrow> R"
by (simp add: neq_iff) blast

lemma antisym_conv1: "\<not> x \<^loc>< y \<Longrightarrow> x \<^loc>\<le> y \<longleftrightarrow> x = y"
by (blast intro: antisym dest: not_less [THEN iffD1])

lemma antisym_conv2: "x \<^loc>\<le> y \<Longrightarrow> \<not> x \<^loc>< y \<longleftrightarrow> x = y"
by (blast intro: antisym dest: not_less [THEN iffD1])

lemma antisym_conv3: "\<not> y \<^loc>< x \<Longrightarrow> \<not> x \<^loc>< y \<longleftrightarrow> x = y"
by (blast intro: antisym dest: not_less [THEN iffD1])

text{*Replacing the old Nat.leI*}
lemma leI: "\<not> x \<^loc>< y \<Longrightarrow> y \<^loc>\<le> x"
unfolding not_less .

lemma leD: "y \<^loc>\<le> x \<Longrightarrow> \<not> x \<^loc>< y"
unfolding not_less .

(*FIXME inappropriate name (or delete altogether)*)
lemma not_leE: "\<not> y \<^loc>\<le> x \<Longrightarrow> x \<^loc>< y"
unfolding not_le .


text {* Reverse order *}

lemma linorder_reverse:
  "linorder (\<lambda>x y. y \<^loc>\<le> x) (\<lambda>x y. y \<^loc>< x)"
by unfold_locales
  (simp add: less_le, auto intro: antisym order_trans simp add: linear)


text {* min/max *}

text {* for historic reasons, definitions are done in context ord *}

definition (in ord)
  min :: "'a \<Rightarrow> 'a \<Rightarrow> 'a" where
  [code unfold, code inline del]: "min a b = (if a \<^loc>\<le> b then a else b)"

definition (in ord)
  max :: "'a \<Rightarrow> 'a \<Rightarrow> 'a" where
  [code unfold, code inline del]: "max a b = (if a \<^loc>\<le> b then b else a)"

lemma min_le_iff_disj:
  "min x y \<^loc>\<le> z \<longleftrightarrow> x \<^loc>\<le> z \<or> y \<^loc>\<le> z"
unfolding min_def using linear by (auto intro: order_trans)

lemma le_max_iff_disj:
  "z \<^loc>\<le> max x y \<longleftrightarrow> z \<^loc>\<le> x \<or> z \<^loc>\<le> y"
unfolding max_def using linear by (auto intro: order_trans)

lemma min_less_iff_disj:
  "min x y \<^loc>< z \<longleftrightarrow> x \<^loc>< z \<or> y \<^loc>< z"
unfolding min_def le_less using less_linear by (auto intro: less_trans)

lemma less_max_iff_disj:
  "z \<^loc>< max x y \<longleftrightarrow> z \<^loc>< x \<or> z \<^loc>< y"
unfolding max_def le_less using less_linear by (auto intro: less_trans)

lemma min_less_iff_conj [simp]:
  "z \<^loc>< min x y \<longleftrightarrow> z \<^loc>< x \<and> z \<^loc>< y"
unfolding min_def le_less using less_linear by (auto intro: less_trans)

lemma max_less_iff_conj [simp]:
  "max x y \<^loc>< z \<longleftrightarrow> x \<^loc>< z \<and> y \<^loc>< z"
unfolding max_def le_less using less_linear by (auto intro: less_trans)

lemma split_min [noatp]:
  "P (min i j) \<longleftrightarrow> (i \<^loc>\<le> j \<longrightarrow> P i) \<and> (\<not> i \<^loc>\<le> j \<longrightarrow> P j)"
by (simp add: min_def)

lemma split_max [noatp]:
  "P (max i j) \<longleftrightarrow> (i \<^loc>\<le> j \<longrightarrow> P j) \<and> (\<not> i \<^loc>\<le> j \<longrightarrow> P i)"
by (simp add: max_def)

end


subsection {* Name duplicates *}

lemmas order_less_le = less_le
lemmas order_eq_refl = order_class.eq_refl
lemmas order_less_irrefl = order_class.less_irrefl
lemmas order_le_less = order_class.le_less
lemmas order_le_imp_less_or_eq = order_class.le_imp_less_or_eq
lemmas order_less_imp_le = order_class.less_imp_le
lemmas order_less_imp_not_eq = order_class.less_imp_not_eq
lemmas order_less_imp_not_eq2 = order_class.less_imp_not_eq2
lemmas order_neq_le_trans = order_class.neq_le_trans
lemmas order_le_neq_trans = order_class.le_neq_trans

lemmas order_antisym = antisym
lemmas order_less_not_sym = order_class.less_not_sym
lemmas order_less_asym = order_class.less_asym
lemmas order_eq_iff = order_class.eq_iff
lemmas order_antisym_conv = order_class.antisym_conv
lemmas order_less_trans = order_class.less_trans
lemmas order_le_less_trans = order_class.le_less_trans
lemmas order_less_le_trans = order_class.less_le_trans
lemmas order_less_imp_not_less = order_class.less_imp_not_less
lemmas order_less_imp_triv = order_class.less_imp_triv
lemmas order_less_asym' = order_class.less_asym'

lemmas linorder_linear = linear
lemmas linorder_less_linear = linorder_class.less_linear
lemmas linorder_le_less_linear = linorder_class.le_less_linear
lemmas linorder_le_cases = linorder_class.le_cases
lemmas linorder_not_less = linorder_class.not_less
lemmas linorder_not_le = linorder_class.not_le
lemmas linorder_neq_iff = linorder_class.neq_iff
lemmas linorder_neqE = linorder_class.neqE
lemmas linorder_antisym_conv1 = linorder_class.antisym_conv1
lemmas linorder_antisym_conv2 = linorder_class.antisym_conv2
lemmas linorder_antisym_conv3 = linorder_class.antisym_conv3

lemmas min_le_iff_disj = linorder_class.min_le_iff_disj
lemmas le_max_iff_disj = linorder_class.le_max_iff_disj
lemmas min_less_iff_disj = linorder_class.min_less_iff_disj
lemmas less_max_iff_disj = linorder_class.less_max_iff_disj
lemmas min_less_iff_conj [simp] = linorder_class.min_less_iff_conj
lemmas max_less_iff_conj [simp] = linorder_class.max_less_iff_conj
lemmas split_min = linorder_class.split_min
lemmas split_max = linorder_class.split_max


subsection {* Reasoning tools setup *}

ML {*
local

fun decomp_gen sort thy (Trueprop $ t) =
  let
    fun of_sort t =
      let
        val T = type_of t
      in
        (* exclude numeric types: linear arithmetic subsumes transitivity *)
        T <> HOLogic.natT andalso T <> HOLogic.intT
          andalso T <> HOLogic.realT andalso Sign.of_sort thy (T, sort)
      end;
    fun dec (Const (@{const_name Not}, _) $ t) = (case dec t
          of NONE => NONE
           | SOME (t1, rel, t2) => SOME (t1, "~" ^ rel, t2))
      | dec (Const (@{const_name "op ="},  _) $ t1 $ t2) =
          if of_sort t1
          then SOME (t1, "=", t2)
          else NONE
      | dec (Const (@{const_name HOL.less_eq},  _) $ t1 $ t2) =
          if of_sort t1
          then SOME (t1, "<=", t2)
          else NONE
      | dec (Const (@{const_name HOL.less},  _) $ t1 $ t2) =
          if of_sort t1
          then SOME (t1, "<", t2)
          else NONE
      | dec _ = NONE;
  in dec t end;

in

(* sorry - there is no preorder class
structure Quasi_Tac = Quasi_Tac_Fun (
struct
  val le_trans = thm "order_trans";
  val le_refl = thm "order_refl";
  val eqD1 = thm "order_eq_refl";
  val eqD2 = thm "sym" RS thm "order_eq_refl";
  val less_reflE = thm "order_less_irrefl" RS thm "notE";
  val less_imp_le = thm "order_less_imp_le";
  val le_neq_trans = thm "order_le_neq_trans";
  val neq_le_trans = thm "order_neq_le_trans";
  val less_imp_neq = thm "less_imp_neq";
  val decomp_trans = decomp_gen ["Orderings.preorder"];
  val decomp_quasi = decomp_gen ["Orderings.preorder"];
end);*)

structure Order_Tac = Order_Tac_Fun (
struct
  val less_reflE = thm "order_less_irrefl" RS thm "notE";
  val le_refl = thm "order_refl";
  val less_imp_le = thm "order_less_imp_le";
  val not_lessI = thm "linorder_not_less" RS thm "iffD2";
  val not_leI = thm "linorder_not_le" RS thm "iffD2";
  val not_lessD = thm "linorder_not_less" RS thm "iffD1";
  val not_leD = thm "linorder_not_le" RS thm "iffD1";
  val eqI = thm "order_antisym";
  val eqD1 = thm "order_eq_refl";
  val eqD2 = thm "sym" RS thm "order_eq_refl";
  val less_trans = thm "order_less_trans";
  val less_le_trans = thm "order_less_le_trans";
  val le_less_trans = thm "order_le_less_trans";
  val le_trans = thm "order_trans";
  val le_neq_trans = thm "order_le_neq_trans";
  val neq_le_trans = thm "order_neq_le_trans";
  val less_imp_neq = thm "less_imp_neq";
  val eq_neq_eq_imp_neq = thm "eq_neq_eq_imp_neq";
  val not_sym = thm "not_sym";
  val decomp_part = decomp_gen ["Orderings.order"];
  val decomp_lin = decomp_gen ["Orderings.linorder"];
end);

end;
*}

setup {*
let

fun prp t thm = (#prop (rep_thm thm) = t);

fun prove_antisym_le sg ss ((le as Const(_,T)) $ r $ s) =
  let val prems = prems_of_ss ss;
      val less = Const (@{const_name less}, T);
      val t = HOLogic.mk_Trueprop(le $ s $ r);
  in case find_first (prp t) prems of
       NONE =>
         let val t = HOLogic.mk_Trueprop(HOLogic.Not $ (less $ r $ s))
         in case find_first (prp t) prems of
              NONE => NONE
            | SOME thm => SOME(mk_meta_eq(thm RS @{thm linorder_antisym_conv1}))
         end
     | SOME thm => SOME(mk_meta_eq(thm RS @{thm order_antisym_conv}))
  end
  handle THM _ => NONE;

fun prove_antisym_less sg ss (NotC $ ((less as Const(_,T)) $ r $ s)) =
  let val prems = prems_of_ss ss;
      val le = Const (@{const_name less_eq}, T);
      val t = HOLogic.mk_Trueprop(le $ r $ s);
  in case find_first (prp t) prems of
       NONE =>
         let val t = HOLogic.mk_Trueprop(NotC $ (less $ s $ r))
         in case find_first (prp t) prems of
              NONE => NONE
            | SOME thm => SOME(mk_meta_eq(thm RS @{thm linorder_antisym_conv3}))
         end
     | SOME thm => SOME(mk_meta_eq(thm RS @{thm linorder_antisym_conv2}))
  end
  handle THM _ => NONE;

fun add_simprocs procs thy =
  (Simplifier.change_simpset_of thy (fn ss => ss
    addsimprocs (map (fn (name, raw_ts, proc) =>
      Simplifier.simproc thy name raw_ts proc)) procs); thy);
fun add_solver name tac thy =
  (Simplifier.change_simpset_of thy (fn ss => ss addSolver
    (mk_solver name (K tac))); thy);

in
  add_simprocs [
       ("antisym le", ["(x::'a::order) <= y"], prove_antisym_le),
       ("antisym less", ["~ (x::'a::linorder) < y"], prove_antisym_less)
     ]
  #> add_solver "Trans_linear" Order_Tac.linear_tac
  #> add_solver "Trans_partial" Order_Tac.partial_tac
  (* Adding the transitivity reasoners also as safe solvers showed a slight
     speed up, but the reasoning strength appears to be not higher (at least
     no breaking of additional proofs in the entire HOL distribution, as
     of 5 March 2004, was observed). *)
end
*}


subsection {* Bounded quantifiers *}

syntax
  "_All_less" :: "[idt, 'a, bool] => bool"    ("(3ALL _<_./ _)"  [0, 0, 10] 10)
  "_Ex_less" :: "[idt, 'a, bool] => bool"    ("(3EX _<_./ _)"  [0, 0, 10] 10)
  "_All_less_eq" :: "[idt, 'a, bool] => bool"    ("(3ALL _<=_./ _)" [0, 0, 10] 10)
  "_Ex_less_eq" :: "[idt, 'a, bool] => bool"    ("(3EX _<=_./ _)" [0, 0, 10] 10)

  "_All_greater" :: "[idt, 'a, bool] => bool"    ("(3ALL _>_./ _)"  [0, 0, 10] 10)
  "_Ex_greater" :: "[idt, 'a, bool] => bool"    ("(3EX _>_./ _)"  [0, 0, 10] 10)
  "_All_greater_eq" :: "[idt, 'a, bool] => bool"    ("(3ALL _>=_./ _)" [0, 0, 10] 10)
  "_Ex_greater_eq" :: "[idt, 'a, bool] => bool"    ("(3EX _>=_./ _)" [0, 0, 10] 10)

syntax (xsymbols)
  "_All_less" :: "[idt, 'a, bool] => bool"    ("(3\<forall>_<_./ _)"  [0, 0, 10] 10)
  "_Ex_less" :: "[idt, 'a, bool] => bool"    ("(3\<exists>_<_./ _)"  [0, 0, 10] 10)
  "_All_less_eq" :: "[idt, 'a, bool] => bool"    ("(3\<forall>_\<le>_./ _)" [0, 0, 10] 10)
  "_Ex_less_eq" :: "[idt, 'a, bool] => bool"    ("(3\<exists>_\<le>_./ _)" [0, 0, 10] 10)

  "_All_greater" :: "[idt, 'a, bool] => bool"    ("(3\<forall>_>_./ _)"  [0, 0, 10] 10)
  "_Ex_greater" :: "[idt, 'a, bool] => bool"    ("(3\<exists>_>_./ _)"  [0, 0, 10] 10)
  "_All_greater_eq" :: "[idt, 'a, bool] => bool"    ("(3\<forall>_\<ge>_./ _)" [0, 0, 10] 10)
  "_Ex_greater_eq" :: "[idt, 'a, bool] => bool"    ("(3\<exists>_\<ge>_./ _)" [0, 0, 10] 10)

syntax (HOL)
  "_All_less" :: "[idt, 'a, bool] => bool"    ("(3! _<_./ _)"  [0, 0, 10] 10)
  "_Ex_less" :: "[idt, 'a, bool] => bool"    ("(3? _<_./ _)"  [0, 0, 10] 10)
  "_All_less_eq" :: "[idt, 'a, bool] => bool"    ("(3! _<=_./ _)" [0, 0, 10] 10)
  "_Ex_less_eq" :: "[idt, 'a, bool] => bool"    ("(3? _<=_./ _)" [0, 0, 10] 10)

syntax (HTML output)
  "_All_less" :: "[idt, 'a, bool] => bool"    ("(3\<forall>_<_./ _)"  [0, 0, 10] 10)
  "_Ex_less" :: "[idt, 'a, bool] => bool"    ("(3\<exists>_<_./ _)"  [0, 0, 10] 10)
  "_All_less_eq" :: "[idt, 'a, bool] => bool"    ("(3\<forall>_\<le>_./ _)" [0, 0, 10] 10)
  "_Ex_less_eq" :: "[idt, 'a, bool] => bool"    ("(3\<exists>_\<le>_./ _)" [0, 0, 10] 10)

  "_All_greater" :: "[idt, 'a, bool] => bool"    ("(3\<forall>_>_./ _)"  [0, 0, 10] 10)
  "_Ex_greater" :: "[idt, 'a, bool] => bool"    ("(3\<exists>_>_./ _)"  [0, 0, 10] 10)
  "_All_greater_eq" :: "[idt, 'a, bool] => bool"    ("(3\<forall>_\<ge>_./ _)" [0, 0, 10] 10)
  "_Ex_greater_eq" :: "[idt, 'a, bool] => bool"    ("(3\<exists>_\<ge>_./ _)" [0, 0, 10] 10)

translations
  "ALL x<y. P"   =>  "ALL x. x < y \<longrightarrow> P"
  "EX x<y. P"    =>  "EX x. x < y \<and> P"
  "ALL x<=y. P"  =>  "ALL x. x <= y \<longrightarrow> P"
  "EX x<=y. P"   =>  "EX x. x <= y \<and> P"
  "ALL x>y. P"   =>  "ALL x. x > y \<longrightarrow> P"
  "EX x>y. P"    =>  "EX x. x > y \<and> P"
  "ALL x>=y. P"  =>  "ALL x. x >= y \<longrightarrow> P"
  "EX x>=y. P"   =>  "EX x. x >= y \<and> P"

print_translation {*
let
  val All_binder = Syntax.binder_name @{const_syntax All};
  val Ex_binder = Syntax.binder_name @{const_syntax Ex};
  val impl = @{const_syntax "op -->"};
  val conj = @{const_syntax "op &"};
  val less = @{const_syntax less};
  val less_eq = @{const_syntax less_eq};

  val trans =
   [((All_binder, impl, less), ("_All_less", "_All_greater")),
    ((All_binder, impl, less_eq), ("_All_less_eq", "_All_greater_eq")),
    ((Ex_binder, conj, less), ("_Ex_less", "_Ex_greater")),
    ((Ex_binder, conj, less_eq), ("_Ex_less_eq", "_Ex_greater_eq"))];

  fun matches_bound v t = 
     case t of (Const ("_bound", _) $ Free (v', _)) => (v = v')
              | _ => false
  fun contains_var v = Term.exists_subterm (fn Free (x, _) => x = v | _ => false)
  fun mk v c n P = Syntax.const c $ Syntax.mark_bound v $ n $ P

  fun tr' q = (q,
    fn [Const ("_bound", _) $ Free (v, _), Const (c, _) $ (Const (d, _) $ t $ u) $ P] =>
      (case AList.lookup (op =) trans (q, c, d) of
        NONE => raise Match
      | SOME (l, g) =>
          if matches_bound v t andalso not (contains_var v u) then mk v l u P
          else if matches_bound v u andalso not (contains_var v t) then mk v g t P
          else raise Match)
     | _ => raise Match);
in [tr' All_binder, tr' Ex_binder] end
*}


subsection {* Transitivity reasoning *}

lemma ord_le_eq_trans: "a <= b ==> b = c ==> a <= c"
by (rule subst)

lemma ord_eq_le_trans: "a = b ==> b <= c ==> a <= c"
by (rule ssubst)

lemma ord_less_eq_trans: "a < b ==> b = c ==> a < c"
by (rule subst)

lemma ord_eq_less_trans: "a = b ==> b < c ==> a < c"
by (rule ssubst)

lemma order_less_subst2: "(a::'a::order) < b ==> f b < (c::'c::order) ==>
  (!!x y. x < y ==> f x < f y) ==> f a < c"
proof -
  assume r: "!!x y. x < y ==> f x < f y"
  assume "a < b" hence "f a < f b" by (rule r)
  also assume "f b < c"
  finally (order_less_trans) show ?thesis .
qed

lemma order_less_subst1: "(a::'a::order) < f b ==> (b::'b::order) < c ==>
  (!!x y. x < y ==> f x < f y) ==> a < f c"
proof -
  assume r: "!!x y. x < y ==> f x < f y"
  assume "a < f b"
  also assume "b < c" hence "f b < f c" by (rule r)
  finally (order_less_trans) show ?thesis .
qed

lemma order_le_less_subst2: "(a::'a::order) <= b ==> f b < (c::'c::order) ==>
  (!!x y. x <= y ==> f x <= f y) ==> f a < c"
proof -
  assume r: "!!x y. x <= y ==> f x <= f y"
  assume "a <= b" hence "f a <= f b" by (rule r)
  also assume "f b < c"
  finally (order_le_less_trans) show ?thesis .
qed

lemma order_le_less_subst1: "(a::'a::order) <= f b ==> (b::'b::order) < c ==>
  (!!x y. x < y ==> f x < f y) ==> a < f c"
proof -
  assume r: "!!x y. x < y ==> f x < f y"
  assume "a <= f b"
  also assume "b < c" hence "f b < f c" by (rule r)
  finally (order_le_less_trans) show ?thesis .
qed

lemma order_less_le_subst2: "(a::'a::order) < b ==> f b <= (c::'c::order) ==>
  (!!x y. x < y ==> f x < f y) ==> f a < c"
proof -
  assume r: "!!x y. x < y ==> f x < f y"
  assume "a < b" hence "f a < f b" by (rule r)
  also assume "f b <= c"
  finally (order_less_le_trans) show ?thesis .
qed

lemma order_less_le_subst1: "(a::'a::order) < f b ==> (b::'b::order) <= c ==>
  (!!x y. x <= y ==> f x <= f y) ==> a < f c"
proof -
  assume r: "!!x y. x <= y ==> f x <= f y"
  assume "a < f b"
  also assume "b <= c" hence "f b <= f c" by (rule r)
  finally (order_less_le_trans) show ?thesis .
qed

lemma order_subst1: "(a::'a::order) <= f b ==> (b::'b::order) <= c ==>
  (!!x y. x <= y ==> f x <= f y) ==> a <= f c"
proof -
  assume r: "!!x y. x <= y ==> f x <= f y"
  assume "a <= f b"
  also assume "b <= c" hence "f b <= f c" by (rule r)
  finally (order_trans) show ?thesis .
qed

lemma order_subst2: "(a::'a::order) <= b ==> f b <= (c::'c::order) ==>
  (!!x y. x <= y ==> f x <= f y) ==> f a <= c"
proof -
  assume r: "!!x y. x <= y ==> f x <= f y"
  assume "a <= b" hence "f a <= f b" by (rule r)
  also assume "f b <= c"
  finally (order_trans) show ?thesis .
qed

lemma ord_le_eq_subst: "a <= b ==> f b = c ==>
  (!!x y. x <= y ==> f x <= f y) ==> f a <= c"
proof -
  assume r: "!!x y. x <= y ==> f x <= f y"
  assume "a <= b" hence "f a <= f b" by (rule r)
  also assume "f b = c"
  finally (ord_le_eq_trans) show ?thesis .
qed

lemma ord_eq_le_subst: "a = f b ==> b <= c ==>
  (!!x y. x <= y ==> f x <= f y) ==> a <= f c"
proof -
  assume r: "!!x y. x <= y ==> f x <= f y"
  assume "a = f b"
  also assume "b <= c" hence "f b <= f c" by (rule r)
  finally (ord_eq_le_trans) show ?thesis .
qed

lemma ord_less_eq_subst: "a < b ==> f b = c ==>
  (!!x y. x < y ==> f x < f y) ==> f a < c"
proof -
  assume r: "!!x y. x < y ==> f x < f y"
  assume "a < b" hence "f a < f b" by (rule r)
  also assume "f b = c"
  finally (ord_less_eq_trans) show ?thesis .
qed

lemma ord_eq_less_subst: "a = f b ==> b < c ==>
  (!!x y. x < y ==> f x < f y) ==> a < f c"
proof -
  assume r: "!!x y. x < y ==> f x < f y"
  assume "a = f b"
  also assume "b < c" hence "f b < f c" by (rule r)
  finally (ord_eq_less_trans) show ?thesis .
qed

text {*
  Note that this list of rules is in reverse order of priorities.
*}

lemmas order_trans_rules [trans] =
  order_less_subst2
  order_less_subst1
  order_le_less_subst2
  order_le_less_subst1
  order_less_le_subst2
  order_less_le_subst1
  order_subst2
  order_subst1
  ord_le_eq_subst
  ord_eq_le_subst
  ord_less_eq_subst
  ord_eq_less_subst
  forw_subst
  back_subst
  rev_mp
  mp
  order_neq_le_trans
  order_le_neq_trans
  order_less_trans
  order_less_asym'
  order_le_less_trans
  order_less_le_trans
  order_trans
  order_antisym
  ord_le_eq_trans
  ord_eq_le_trans
  ord_less_eq_trans
  ord_eq_less_trans
  trans


(* FIXME cleanup *)

text {* These support proving chains of decreasing inequalities
    a >= b >= c ... in Isar proofs. *}

lemma xt1:
  "a = b ==> b > c ==> a > c"
  "a > b ==> b = c ==> a > c"
  "a = b ==> b >= c ==> a >= c"
  "a >= b ==> b = c ==> a >= c"
  "(x::'a::order) >= y ==> y >= x ==> x = y"
  "(x::'a::order) >= y ==> y >= z ==> x >= z"
  "(x::'a::order) > y ==> y >= z ==> x > z"
  "(x::'a::order) >= y ==> y > z ==> x > z"
  "(a::'a::order) > b ==> b > a ==> P"
  "(x::'a::order) > y ==> y > z ==> x > z"
  "(a::'a::order) >= b ==> a ~= b ==> a > b"
  "(a::'a::order) ~= b ==> a >= b ==> a > b"
  "a = f b ==> b > c ==> (!!x y. x > y ==> f x > f y) ==> a > f c" 
  "a > b ==> f b = c ==> (!!x y. x > y ==> f x > f y) ==> f a > c"
  "a = f b ==> b >= c ==> (!!x y. x >= y ==> f x >= f y) ==> a >= f c"
  "a >= b ==> f b = c ==> (!! x y. x >= y ==> f x >= f y) ==> f a >= c"
by auto

lemma xt2:
  "(a::'a::order) >= f b ==> b >= c ==> (!!x y. x >= y ==> f x >= f y) ==> a >= f c"
by (subgoal_tac "f b >= f c", force, force)

lemma xt3: "(a::'a::order) >= b ==> (f b::'b::order) >= c ==> 
    (!!x y. x >= y ==> f x >= f y) ==> f a >= c"
by (subgoal_tac "f a >= f b", force, force)

lemma xt4: "(a::'a::order) > f b ==> (b::'b::order) >= c ==>
  (!!x y. x >= y ==> f x >= f y) ==> a > f c"
by (subgoal_tac "f b >= f c", force, force)

lemma xt5: "(a::'a::order) > b ==> (f b::'b::order) >= c==>
    (!!x y. x > y ==> f x > f y) ==> f a > c"
by (subgoal_tac "f a > f b", force, force)

lemma xt6: "(a::'a::order) >= f b ==> b > c ==>
    (!!x y. x > y ==> f x > f y) ==> a > f c"
by (subgoal_tac "f b > f c", force, force)

lemma xt7: "(a::'a::order) >= b ==> (f b::'b::order) > c ==>
    (!!x y. x >= y ==> f x >= f y) ==> f a > c"
by (subgoal_tac "f a >= f b", force, force)

lemma xt8: "(a::'a::order) > f b ==> (b::'b::order) > c ==>
    (!!x y. x > y ==> f x > f y) ==> a > f c"
by (subgoal_tac "f b > f c", force, force)

lemma xt9: "(a::'a::order) > b ==> (f b::'b::order) > c ==>
    (!!x y. x > y ==> f x > f y) ==> f a > c"
by (subgoal_tac "f a > f b", force, force)

lemmas xtrans = xt1 xt2 xt3 xt4 xt5 xt6 xt7 xt8 xt9

(* 
  Since "a >= b" abbreviates "b <= a", the abbreviation "..." stands
  for the wrong thing in an Isar proof.

  The extra transitivity rules can be used as follows: 

lemma "(a::'a::order) > z"
proof -
  have "a >= b" (is "_ >= ?rhs")
    sorry
  also have "?rhs >= c" (is "_ >= ?rhs")
    sorry
  also (xtrans) have "?rhs = d" (is "_ = ?rhs")
    sorry
  also (xtrans) have "?rhs >= e" (is "_ >= ?rhs")
    sorry
  also (xtrans) have "?rhs > f" (is "_ > ?rhs")
    sorry
  also (xtrans) have "?rhs > z"
    sorry
  finally (xtrans) show ?thesis .
qed

  Alternatively, one can use "declare xtrans [trans]" and then
  leave out the "(xtrans)" above.
*)

subsection {* Order on bool *}

instance bool :: order 
  le_bool_def: "P \<le> Q \<equiv> P \<longrightarrow> Q"
  less_bool_def: "P < Q \<equiv> P \<le> Q \<and> P \<noteq> Q"
  by intro_classes (auto simp add: le_bool_def less_bool_def)

lemma le_boolI: "(P \<Longrightarrow> Q) \<Longrightarrow> P \<le> Q"
by (simp add: le_bool_def)

lemma le_boolI': "P \<longrightarrow> Q \<Longrightarrow> P \<le> Q"
by (simp add: le_bool_def)

lemma le_boolE: "P \<le> Q \<Longrightarrow> P \<Longrightarrow> (Q \<Longrightarrow> R) \<Longrightarrow> R"
by (simp add: le_bool_def)

lemma le_boolD: "P \<le> Q \<Longrightarrow> P \<longrightarrow> Q"
by (simp add: le_bool_def)

lemma [code func]:
  "False \<le> b \<longleftrightarrow> True"
  "True \<le> b \<longleftrightarrow> b"
  "False < b \<longleftrightarrow> b"
  "True < b \<longleftrightarrow> False"
  unfolding le_bool_def less_bool_def by simp_all


subsection {* Order on sets *}

instance set :: (type) order
  by (intro_classes,
      (assumption | rule subset_refl subset_trans subset_antisym psubset_eq)+)

lemmas basic_trans_rules [trans] =
  order_trans_rules set_rev_mp set_mp


subsection {* Order on functions *}

instance "fun" :: (type, ord) ord
  le_fun_def: "f \<le> g \<equiv> \<forall>x. f x \<le> g x"
  less_fun_def: "f < g \<equiv> f \<le> g \<and> f \<noteq> g" ..

lemmas [code func del] = le_fun_def less_fun_def

instance "fun" :: (type, order) order
  by default
    (auto simp add: le_fun_def less_fun_def expand_fun_eq
       intro: order_trans order_antisym)

lemma le_funI: "(\<And>x. f x \<le> g x) \<Longrightarrow> f \<le> g"
  unfolding le_fun_def by simp

lemma le_funE: "f \<le> g \<Longrightarrow> (f x \<le> g x \<Longrightarrow> P) \<Longrightarrow> P"
  unfolding le_fun_def by simp

lemma le_funD: "f \<le> g \<Longrightarrow> f x \<le> g x"
  unfolding le_fun_def by simp

text {*
  Handy introduction and elimination rules for @{text "\<le>"}
  on unary and binary predicates
*}

lemma predicate1I [Pure.intro!, intro!]:
  assumes PQ: "\<And>x. P x \<Longrightarrow> Q x"
  shows "P \<le> Q"
  apply (rule le_funI)
  apply (rule le_boolI)
  apply (rule PQ)
  apply assumption
  done

lemma predicate1D [Pure.dest, dest]: "P \<le> Q \<Longrightarrow> P x \<Longrightarrow> Q x"
  apply (erule le_funE)
  apply (erule le_boolE)
  apply assumption+
  done

lemma predicate2I [Pure.intro!, intro!]:
  assumes PQ: "\<And>x y. P x y \<Longrightarrow> Q x y"
  shows "P \<le> Q"
  apply (rule le_funI)+
  apply (rule le_boolI)
  apply (rule PQ)
  apply assumption
  done

lemma predicate2D [Pure.dest, dest]: "P \<le> Q \<Longrightarrow> P x y \<Longrightarrow> Q x y"
  apply (erule le_funE)+
  apply (erule le_boolE)
  apply assumption+
  done

lemma rev_predicate1D: "P x ==> P <= Q ==> Q x"
  by (rule predicate1D)

lemma rev_predicate2D: "P x y ==> P <= Q ==> Q x y"
  by (rule predicate2D)


subsection {* Monotonicity, least value operator and min/max *}

locale mono =
  fixes f
  assumes mono: "A \<le> B \<Longrightarrow> f A \<le> f B"

lemmas monoI [intro?] = mono.intro
  and monoD [dest?] = mono.mono

lemma LeastI2_order:
  "[| P (x::'a::order);
      !!y. P y ==> x <= y;
      !!x. [| P x; ALL y. P y --> x \<le> y |] ==> Q x |]
   ==> Q (Least P)"
apply (unfold Least_def)
apply (rule theI2)
  apply (blast intro: order_antisym)+
done

lemma Least_mono:
  "mono (f::'a::order => 'b::order) ==> EX x:S. ALL y:S. x <= y
    ==> (LEAST y. y : f ` S) = f (LEAST x. x : S)"
    -- {* Courtesy of Stephan Merz *}
  apply clarify
  apply (erule_tac P = "%x. x : S" in LeastI2_order, fast)
  apply (rule LeastI2_order)
  apply (auto elim: monoD intro!: order_antisym)
  done

lemma Least_equality:
  "[| P (k::'a::order); !!x. P x ==> k <= x |] ==> (LEAST x. P x) = k"
apply (simp add: Least_def)
apply (rule the_equality)
apply (auto intro!: order_antisym)
done

lemma min_leastL: "(!!x. least <= x) ==> min least x = least"
by (simp add: min_def)

lemma max_leastL: "(!!x. least <= x) ==> max least x = x"
by (simp add: max_def)

lemma min_leastR: "(\<And>x\<Colon>'a\<Colon>order. least \<le> x) \<Longrightarrow> min x least = least"
apply (simp add: min_def)
apply (blast intro: order_antisym)
done

lemma max_leastR: "(\<And>x\<Colon>'a\<Colon>order. least \<le> x) \<Longrightarrow> max x least = x"
apply (simp add: max_def)
apply (blast intro: order_antisym)
done

lemma min_of_mono:
  "(!!x y. (f x <= f y) = (x <= y)) ==> min (f m) (f n) = f (min m n)"
by (simp add: min_def)

lemma max_of_mono:
  "(!!x y. (f x <= f y) = (x <= y)) ==> max (f m) (f n) = f (max m n)"
by (simp add: max_def)


subsection {* legacy ML bindings *}

ML {*
val monoI = @{thm monoI};
*}

end
